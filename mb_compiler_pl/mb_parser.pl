#!/usr/bin/perl -C63

use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use constant
{ FALSE => 0
, TRUE => 1
};
use Data::Dumper;
use JSON;
use Math::BigInt lib => 'GMP';
use List::Util qw(min max);
use POSIX qw(floor ceil round);

require "./mb_common.pl";

my $Types =
{ 'List' =>
  { arguments => 1
  }
, 'String' =>
  { arguments => 0
  }
, 'Unsigned8BitInteger' =>
  { arguments => 0
  }
, 'Procedure' =>
  { arguments => 0
  }
};
my $TypeAnnotationEndings =
{ 'END_OF_LINE' => 1
, 'ARROW_THIN' => 1
};

my($BIT_DEPTHS) =
{ 8 => {}
, 16 => {}
, 32 => {}
, 64 => {}
};
my($BIT_DEPTH_KEYS) = [ sort { $a <=> $b } keys %$BIT_DEPTHS ];
my($INTEGER_LITERAL_BASES) =
{ '' => 10
, '0d' => 10
, '0x' => 16
, '0b' => 2
, '0o' => 8
};

sub ParseProgram
{ my($tokens) = shift;

  { NodeType => 'Program'
  , Position => PeekPosition($tokens)
  , OnlyProcedure => ParseProcedure($tokens)
  };
}

sub ParseProcedure
{ my($tokens) = shift;

  my($notused, $parsePosition) =
    PeekTokens
    ( $tokens
    , [ qw(IDENTIFIER_NOCAPS main) ]
    , 'Only procedure name supported right now is lowercase "main".'
    );

  my($procedureName) = $tokens->[1];

  my($typeAnnotation) = ParseTypeAnnotation($tokens, $parsePosition);

  { NodeType => 'Procedure'
  , Position => $parsePosition
  , ProcedureName => $procedureName
  , TypeAnnotation => $typeAnnotation
  , ProcedureBody => ParseProcedureBody($tokens, $typeAnnotation)
  };
}

sub ParseTypeAnnotation
{ my($tokens) = shift;
  my($typeAnnotationPosition) = shift;

  ExpectTokens
  ( $tokens
  , 'IDENTIFIER_NOCAPS'
  , 'Type annotations must start with a lowercase identifier'
  );
  my($procedureName) = shift @$tokens;

  ExpectTokens
  ( $tokens
  , 'COLON'
  , 'Procedure name is not immediately followed by a colon'
  );

  my($argumentTypes) =
    ParseArgumentTypes($tokens);

  ExpectTokens
  ( $tokens
  , 'END_OF_LINE'
  , '(unreachable error) Complete Type Annotations must end with a newline.'
  );

  { NodeType => 'TypeAnnotation'
  , Position => $typeAnnotationPosition
  , ProcedureName => $procedureName
  , ArgumentTypes => $argumentTypes
  };
}

sub ParseArgumentTypes
{ my($tokens) = shift;
  my($arguments) =
  { ParentType => FALSE
  , WantsDelimiter => TRUE
  , @_ # accept remaining arguments to stomp over defaults given
  };
  my($parentType) = $arguments->{ParentType};

  $arguments->{WantsDelimiter} = FALSE if($parentType);

  my($identifierCaps, $typePosition) =
    ExpectTokens
    ( $tokens
    , 'IDENTIFIER_CAPS'
    , ( !$parentType
      ? 'Types must always be uppercase identifiers'
      : ( "We are expecting a Type Argument to type '$parentType' here.\n"
        . $parentType
        . ' has '
        . Plural($Types->{$parentType}{arguments}, 'Type Argument')
        . ', and Types must always be uppercase identifiers.'
        )
      )
    );

  my($primaryType) = shift @$tokens;
  my($typeProperties) = $Types->{$primaryType};

  Error("'$primaryType' is not a known Type", $typePosition)
    unless(defined($typeProperties));

  my($argumentCount) = $typeProperties->{arguments};

  my($typeArguments) = [];

  while($argumentCount-->0)
  { push
    ( @$typeArguments
    , ParseArgumentTypes($tokens, ParentType => $primaryType)
    );
  }

  if($arguments->{WantsDelimiter})
  { my($delimiterPosition) = ParsePossiblePosition($tokens);
    Error
    ( ( "Type Annotation Arguments must end with either a thin arrow `->`"
      . " or a newline.\n"
      . "Type '$primaryType' only allows "
      . Plural($typeProperties->{arguments}, 'argument')
      . '.'
      ) # $errorMessage
    , $delimiterPosition
    , join(' or ', keys %$TypeAnnotationEndings)
    , $tokens->[0]
    ) unless(defined $TypeAnnotationEndings->{$tokens->[0]});

    if($tokens->[0] eq 'ARROW_THIN')
    { shift @$tokens; # discard the thin arrow.

      return
      { NodeType => 'ArgumentTypes'
      , Position => $typePosition
      , MoreArguments => TRUE
      , PrimaryType => $primaryType
      , TypeArguments => $typeArguments
      , NextArgument => ParseArgumentTypes($tokens)
      };
    }
    # the only other possibility is that $tokens->[0] eq 'END_OF_LINE'
    # which will output the same data as a
    # subtype "doesn't want delimiter" case would have.
  }

  return
  { NodeType => 'ArgumentTypes'
  , Position => $typePosition
  , MoreArguments => FALSE
  , PrimaryType => $primaryType
  , TypeArguments => $typeArguments
  };
}

sub ParseProcedureBody
{ my($tokens) = shift;
  my($typeAnnotation) = shift;

  my($notused, $procedureBodyPosition) =
    ExpectTokens
    ( $tokens
    , 'IDENTIFIER_NOCAPS'
    , 'Procedure definitions must start with a lowercase identifier'
    );

  my($procedureName, $notused2) =
    ExpectTokens
    ( $tokens
    , $typeAnnotation->{ProcedureName}
    , ( 'Procedure name in type annotation'
      . ' does not match procedure name in procedure body.'
      )
    , $procedureBodyPosition
    );

  ParseSkipEndOfLine($tokens);

  ExpectTokens
  ( $tokens
  , ['IDENTIFIER_NOCAPS', qr(^_\w*)]
  , "Procedure `$procedureName` not followed by single argument."
  );


  ExpectTokens
  ( $tokens
  , 'EQUALS'
  , ( "Procedure Name `$procedureName` and single argument not followed by"
    . " an equals sign in Procedure body."
    )
  );

  ExpectTokens
  ( $tokens
  , [ qw( IDENTIFIER_CAPS Procedure INVOKE_MODULE_METHOD begin ) ]
  , 'Procedure body must start with a call to "Procedure.begin"'
  );

  ParseSkipEndOfLine($tokens);

  my($statements) = [ParseStatement($tokens)];

  ExpectTokens
  ( $tokens
  , [ qw( IDENTIFIER_CAPS Procedure INVOKE_MODULE_METHOD end ) ]
  , 'Procedure body must end with a call to "Procedure.end"'
  );

  { NodeType => 'ProcedureBody'
  , Position => $procedureBodyPosition
  , ProcedureName => $procedureName
  , Statements => $statements
  }
}

sub ParseStatement
{ my($tokens) = shift;

  my($junk, $statementPosition) =
    ExpectTokens
    ( $tokens
    , [ qw( IDENTIFIER_CAPS System INVOKE_MODULE_METHOD exit ) ]
    , 'Only allowed Procedure call in Procedure body is `System.exit`'
    );

  my($arguments) = [ParseExpression($tokens)];

  ExpectTokens
  ( $tokens
  , 'END_OF_LINE'
  , 'Procedure call must terminate with an end of line'
  );

  { NodeType => 'System.exit'
  , Arguments => $arguments
  , Position => $statementPosition
  };
}

sub ParseExpression
{ my($tokens) = shift;

  my($initial, $expressionPosition) = ExpectTokens
  ( $tokens
  # , qr(^LITERAL_INTEGER$|^OPERATOR_UNARY_)
  , 'LITERAL_INTEGER'
  , ( 'Expression did not evaluate to either'
    . ' an integer literal or a unary expression.'
    )
  );
  my($value, $type);

  if($initial eq 'LITERAL_INTEGER')
  { my $arguments = shift @$tokens;
    my $sign = $arguments->{sign};
    $type = $sign eq ''?'Unsigned':'Signed';
    my $positiveValueWaste1 = ($sign eq '-'?0:1);
    my $signWasteBit = ($type eq 'Unsigned'?0:1);

    my $base = $INTEGER_LITERAL_BASES->{lc($arguments->{base})};
    my $bitsByLengthNerfIfNotAligned = $base==10 || $base==8?1:0;

    my $leadingZeros = $arguments->{leadingZeros}; # stays a string
    $leadingZeros =~ s/_//g;

    my $mantissa = $arguments->{mantissa};
    my $exponent = $arguments->{exponent} || 0;

    $mantissa =~ s/_//g;
    $exponent =~ s/_//g;
    my $magnitude = Math::BigInt->from_base($mantissa, $base);
# CORE::say
#   Dumper
#   ( [ magnitude => $magnitude->bdstr
#     , mantissa => $mantissa
#     , base => $base
#     ]
#   );
    $magnitude = $magnitude * Math::BigInt->new($base)->bpow($exponent);

# CORE::say
#   Dumper
#   ( [ magnitude => $magnitude->bdstr
#     , mantissa => $mantissa
#     , base => $base
#     , extra => Math::BigInt->new($base)->bpow($exponent)->bdstr
#     ]
#   );

    my($bitsByLength) =
    ( ( length($leadingZeros . $magnitude->to_base($base))
      - $bitsByLengthNerfIfNotAligned
      )
    * log($base)/log(2)
    + $signWasteBit
    );
    my($bitsByValue) =
    ( ceil(log($magnitude->bdstr + $positiveValueWaste1) / log(2))
    + $signWasteBit
    );
    my($bitsNeeded) = max($bitsByLength, $bitsByValue);
    my($typeSize) = 0;
    my($largestBitDepth) = $BIT_DEPTH_KEYS->[-1];

    for my $bits (@$BIT_DEPTH_KEYS)
    { if($bits>=$bitsNeeded)
      { $typeSize = $bits;
        last;
      }
    }

    if($typeSize < 1)
    { Error
      ( "Integer literal is too large to express in $largestBitDepth bits"
      , $expressionPosition
      , ( "An integer literal less than 2^$largestBitDepth aka "
        . Math::BigInt->bone()->blsft($largestBitDepth)
        )
      , 'An integer whose magnitude is '. $magnitude
      )
    }

    $type .= $typeSize . 'BitInteger';
    $value = "${sign}1" * $magnitude;
# die
# ( Dumper
#   ( [ sign => $sign
#     , positiveValueWaste1 => $positiveValueWaste1
#     , signWasteBit => $signWasteBit
#     , base => $base
#     , bitsByLengthNerfIfNotAligned => $bitsByLengthNerfIfNotAligned
#     , leadingZeros => $leadingZeros
#     , mantissa => $mantissa
#     , exponent => $exponent
#     , magnitude => $magnitude->bdstr
#     , a => ($leadingZeros . $magnitude->to_base($base))
#     , b => length($leadingZeros . $magnitude->to_base($base))
#     , bitsByLength => $bitsByLength
#     , bitsByValue => $bitsByValue
#     , bitsNeeded => $bitsNeeded
#     , typeSize => $typeSize
#     , largestBitDepth => $largestBitDepth
#     , type => $type
#     , value => $value->bdstr
#     ]
#   )
# )
  }

  { NodeType => 'Expression'
  , Value => $value
  , Type => $type
  , Position => $expressionPosition
  };
}

sub ParseUnaryExpression
{ my($tokens) = shift;

  my($operator) = shift @$tokens;
  my($expression) = ParseExpression($tokens);

  { NoteType => 'UnaryExpression'
  , Operator => $operator
  , Expression => $expression
  }
}

sub ParseSkipEndOfLine
{ my($tokens) = shift;
  ParsePossiblePosition($tokens);
  if($tokens->[0] eq 'END_OF_LINE')
  { shift @$tokens;
  }
}

sub PeekPosition
{ my($tokens) = shift;

  if($tokens->[0] ne 'POSITION')
  { die
    ( Dumper
      ( [ 'Internal error: Expected "Position" token, none found at:'
        , $tokens
        ]
      )
    );
  }
  return $tokens->[1];
}

sub ExpectTokens
{ my @args = @_;
  my(@ret) = PeekTokens(@args);
  my($foundTokens, $position) = @ret;
  my($tokens) = shift @args;

  if(ref($foundTokens) ne 'ARRAY')
  { $foundTokens = [$foundTokens];
  }
  if(scalar(@$foundTokens)) # if this list is nonempty
  { foreach my $token (@$foundTokens)
    { my($compare);
      do # Inspect and discard each token until one matches this returned token
      { $compare = shift @$tokens;
      } while($token ne $compare);
    } # repeat that for the entire list of returned tokens.
  }
  @ret;
}

sub PeekTokens
{ my($tokens) = shift;
  my($expectedTokens) = shift;
  my($errorMessage) = shift;
  my($position) = ParsePossiblePosition($tokens) || shift;
  my($foundToken) = $tokens->[0];
  my($furtherExpectedTokens) = [];
  my($expectedToken);

  if(ref($expectedTokens) eq 'ARRAY')
  { if(scalar(@$expectedTokens) < 1)
    { return(undef, $position);
    }
    $furtherExpectedTokens = [splice @$expectedTokens, 1];
    $expectedToken = $expectedTokens->[0];
  }
  else # We assume $expectedTokens is either a String or a Regexp
  { $expectedToken = $expectedTokens; # singularize variable name
  }

  unless
  ( ref($expectedToken) eq 'Regexp'
  ? $foundToken =~ $expectedToken # Match a Regexp
  : $foundToken eq $expectedToken # Equate a String
  )
  { Error($errorMessage, $position, $expectedToken, $foundToken);
  }

  my($q) =
    PeekTokens
    # ( [ splice @{[@$tokens]}, 1 ]
    ( slice($tokens, 0, 1)
    , $furtherExpectedTokens
    , $errorMessage
    , $position
    );

  ( defined $q
  ? ( ref($q) eq 'ARRAY'
    ? [ $foundToken, @$q ]
    : [ $foundToken, $q ]
    )
  : $foundToken
  ), $position;
}

sub ParsePossiblePosition
{ my($tokens) = shift;
  if
  ( ref($tokens) eq 'ARRAY'
  &&defined $tokens->[0]
  &&$tokens->[0] eq 'POSITION'
  )
  { shift @$tokens;
    return shift @$tokens;
  }
  return undef; # Not at a position token, so no position returned.
}

sub ParseCountTypeAnnotation
{ my $typeAnnotation = shift || {};
  my $argumentType = shift || FALSE;
  my $position = $typeAnnotation->{position} || shift;

  if($argumentType)
  { AssertEqual
    ( $typeAnnotation->{NodeType} || ''
    , 'ArgumentTypes'
    , 'Expected a type annotation argument type.'
    , $position
    );
    if($typeAnnotation->{NextArgument})
    { my $q =
      ( 1
      + ParseCountTypeAnnotation
        ( $typeAnnotation->{NextArgument}
        , 1
        , $position
        )
      );
      return $q;
    }
    else # To get this far to begin with $argumentType MUST be true
    { return 1; # no subtypes means this type represetns only one argument.
    }
  }
  else
  { AssertEqual
    ( $typeAnnotation->{NodeType} || ''
    , 'TypeAnnotation'
    , 'Expected a Type Annotation.'
    , $position
    );

    Assert
    ( $typeAnnotation->{ArgumentTypes}
    , 'Type annotation appears to lack any argument types.'
    , $position
    );

    return
    ( ParseCountTypeAnnotation
      ( $typeAnnotation->{ArgumentTypes}
      , 1
      , $position
      )
    );
  }
}


1;
