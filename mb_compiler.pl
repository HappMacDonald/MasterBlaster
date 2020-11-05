#!/usr/bin/perl -C63

use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use Data::Dumper;
use JSON;
use Math::BigInt lib => 'GMP';
use List::Util qw(min max);
use POSIX qw(floor ceil round);
use constant
{ FALSE => 0
, TRUE => 1
};

my $SUPPRESS_WHITESPACE = qr([ \t]*);
my $END_OF_LINE = qr((?:\r|\n)+);
my $SUPPRESS_WS_AND_EOL = $SUPPRESS_WHITESPACE . $END_OF_LINE;
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
my $TOKENS = 
[ { PAREN_ROUND_OPEN =>
    { argumentCount => 0
    , pattern => qr(\()
    }
  , PAREN_ROUND_CLOSED =>
    { argumentCount => 0
    , pattern => qr(\))
    }
  , PAREN_SQUARE_OPEN =>
    { argumentCount => 0
    , pattern => qr(\[)
    }
  , PAREN_SQUARE_CLOSED =>
    { argumentCount => 0
    , pattern => qr(\])
    }
  , PAREN_CURLY_OPEN =>
    { argumentCount => 0
    , pattern => qr(\{)
    }
  , PAREN_CURLY_CLOSED =>
    { argumentCount => 0
    , pattern => qr(\})
    }
  , SEMICOLON =>
    { argumentCount => 0
    , pattern => qr(;)
    }
  , COLON =>
    { argumentCount => 0
    , pattern => qr(:)
    }
  , KEYWORD_INT =>
    { argumentCount => 0
    , pattern => qr(int)
    }
  , KEYWORD_RETURN =>
    { argumentCount => 0
    , pattern => qr(return)
    }
  , OPERATOR_UNARY_COMPLEMENT_BITWISE =>
    { argumentCount => 0
    , pattern => qr(~)
    }
  , OPERATOR_UNARY_COMPLEMENT_BOOLEAN =>
    { argumentCount => 0
    , pattern => qr(!)
    }
  , ARROW_THIN =>
    { argumentCount => 0
    , pattern => qr(->)
    }
  , ARROW_FAT =>
    { argumentCount => 0
    , pattern => qr(=>)
    }
  , COMMENT_SINGLE_LINE =>
    { argumentCount => 0
    , pattern => qr(--[^\n]*)
    }
  , END_OF_LINE_ESCAPED =>
    { argumentCount => 0
    , skip => TRUE
    , suppressEndOfLine => TRUE
    , pattern => qr(\\)
    }
  , INVOKE_MODULE_METHOD =>
    { argumentCount => 1
    , pattern => qr(^\.([a-z]\w*))
    }
  }
, { IDENTIFIER_CAPS =>
    { argumentCount => 1
    , pattern => qr(((?:[A-Z]\w*(?:\.[A-Z]\w*)*)))
    }
  , IDENTIFIER_NOCAPS =>
    { argumentCount => 1
    , pattern => qr(([a-z]\w*))
    }
  , LITERAL_INTEGER =>
    { argumentCount => 'named'
    , pattern =>
      qr(
        (?<sign>[+-]?)
        (?:
          (?<base>0b) # binary = 2
          (?<leadingZeros>[0_]*)
          (?<mantissa>1[01_]*)
        |
          (?<base>0o) # octal = 8
          (?<leadingZeros>[0_]*)
          (?<mantissa>[1-7][0-7_]*)
        |
          (?<base>(?:0d)?) # decimal = 10
          (?<leadingZeros>[0_]*)
          (?<mantissa>[1-9][0-9_]*)
        |
          (?<base>0x) # hexadecimal = 16
          (?<leadingZeros>[0_]*)
          (?<mantissa>[1-9a-f][0-9a-f_]*)
        )
        (?:[e](?<exponent>[0-9_]+))? # always expresed in decimal
        (?![a-z]) # We must NOT directly abut a letter character.
      )xi
    }
  , EQUALS =>
    { argumentCount => 0
    , suppressEndOfLine => TRUE
    , pattern => qr(=)
    }
  , END_OF_LINE =>
    { argumentCount => 0
    , pattern => qr($END_OF_LINE)
    }
  }
  # This token is generated instead of "detected"
  #
  # POSITION =>
  # { argumentCount => 1
  # }
];
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

sub lex
{ my($input) = shift;
  my($position) = shift;
  my($output) = [];

  my($fullLine) = $input;
  $input =~ s/^(\s+)//; # drop all leading whitespace
  incrementPosition($1, $position);

  while(length $input)
  { my($inputClone) = $input; 
    TOKEN_SEARCH:
    for my $tokenLevel (@$TOKENS)
    { for my $token (keys %$tokenLevel)
      { my($tokenProperties) = $tokenLevel->{$token};
        my($argumentCount) = $tokenProperties->{argumentCount};
        my($pattern) = $tokenProperties->{pattern};

        if(my(@matches) = $input =~ /^$pattern/)
        { # truncated @matches array to be at most $argumentCount in length.
          if($argumentCount eq 'named')
          { # an array with one element,
            # a hashref of all named capture groups.
            @matches = 
            ( { %+ }
            )
          }
          else
          { splice @matches, $argumentCount;
          }

          my($localSuppressedWhitespace) =
            ( $tokenProperties->{suppressEndOfLine}
            ? $SUPPRESS_WS_AND_EOL
            : $SUPPRESS_WHITESPACE
            );

          push
          ( @$output
          , 'POSITION'
          , { %$position }
          , $token
          , @matches
          ) unless($tokenProperties->{skip});

          $input =~ s/^($pattern$localSuppressedWhitespace?)//;
          incrementPosition($1, $position);

          last TOKEN_SEARCH;
        }
        # else Match NOT found
      }
    }

    if($input eq $inputClone)
    { trim($input);
      trim($fullLine);
      Error
      ( ( "Unrecognized token: $input"
        . "\nIn full line: $fullLine"
        )
      , $position
      );
    }
  }

  $output;
}

sub incrementPosition
{ my($str) = shift || '';
  my($position) = shift;

  # this flat-out counts the newlines in the string
  # Notice the capital "L" in this variable name?
  # It is using 'newlines' as a proxy to count New Lines. Get it? xD
  my($newLines) = $str =~ tr/\n/\n/;

  if($newLines>0)
  { # perform a carriage return. :P
    $position->{column} = 1;  # 1-based counting
  }

  $position->{line} += $newLines;

  unless($str =~ /(?:^|\n)(.*)\z/)
  { die("Parser error: could not universally count number of characters in the last line of:\n$str");
  }
  $position->{column} += length($1);

  $position;
}

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
  , 'EQUALS'
  , ( "Procedure Name '$procedureName' not followed by"
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
    ( [ splice @{[@$tokens]}, 1 ]
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

sub Error
{ my($errorMessage) = shift;
  my($position) = shift;
  my($expectedToken) = shift;
  my($foundToken) = shift;
  
  CORE::say STDERR '';
  CORE::say STDERR $errorMessage;
  CORE::say STDERR "Expected: $expectedToken" if(defined $expectedToken);
  CORE::say STDERR "Found: $foundToken" if(defined $expectedToken);
  CORE::say STDERR "At Line $position->{line}, Column $position->{column}"
    if(defined $position);
  CORE::say STDERR '';
  exit 1;
}

sub GenerateProgram
{ my($ast) = shift;

  my($onlyProcedure) = $ast->{OnlyProcedure};

  my($ret) = GenerateProcedureGlobal($onlyProcedure->{ProcedureName});
  $ret .= GenerateProcedureBody($onlyProcedure->{ProcedureBody});
  $ret;
}

sub GenerateProcedureGlobal
{ my($procedureName) = shift;

  "\t.globl\t". $procedureName ."\n";
}

sub GenerateProcedureBody
{ my($ast) = shift;

  my($ret) = $ast->{ProcedureName} .":\n";

  # Assumption: Only one statement, that is a System.exit statement.
  Error
  ( "Compiler can only handle exactly one statement"
  , $ast->{Position}
  ) unless(scalar(@{$ast->{Statements}}) == 1);

  my($statement) = $ast->{Statements}[0];

  # Assumption: the singleton statement is System.exit
  Error
  ( "Compiler can only generate the System.exit statement"
  , $statement->{Position}
  ) unless(scalar($statement->{NodeType}) eq 'System.exit');

  $ret .= GenerateSystemExit($statement);
  $ret;
}

sub GenerateSystemExit
{ my($ast) = shift;

  # Assumption: Only one argument
  Error
  ( "System.exit statment can only have exactly one argument"
  , $ast->{Position}
  ) unless(@{$ast->{Arguments}} == 1);

  my($ret) = GenerateExpression($ast->{Arguments}[0]);
  $ret .= "\tret\n";
}

sub GenerateExpression
{ my($ast) = shift;

  if($ast->{Type} eq 'Unsigned8BitInteger')
  # { return "\tmov\t\$". $ast->{Value} .", %rax\n";
  { return "\tmov\t\$". $ast->{Value} .", %al\n";
  }
  # elsif($ast->{Type} eq 'Unary')
  # { return GenerateUnaryExpression($ast->{Value});
  # }
  else
  { die("Failed sanity check: unknown type of expression.\n". Dumper($ast));
  }
}

sub GenerateUnaryExpression
{ my($ast) = shift;
  my($ret) = GenerateExpression($ast->{Expression});
  
  if($ast->{Operator} eq 'OPERATOR_UNARY_COMLPEMENT_ADDITIVE')
  { $ret .= "\tneg\t%rax\n";
  }
  elsif($ast->{Operator} eq 'OPERATOR_UNARY_COMPLEMENT_BITWISE')
  { $ret .= "\tnot\t%rax\n";
  }
#   elsif($ast->{Operator} eq 'OPERATOR_UNARY_COMPLEMENT_BOOLEAN')
#   { $ret .= <<"EOL";
# \tcmp\t\$0, %rax
# \tmov\t\$0, %rax
# \tsete\t%al
# EOL
#   }
  else
  { die("Failed sanity check: unknown type of unary expression.\n". Dumper($ast));
  }

  $ret;
}

sub Plural
{ my($number) = shift;
  my($singular) = shift;
  my($plural) = shift || "${singular}s";

  $number==1?"$number $singular":"$number $plural";
}

sub trim { $_[0] =~ s/^\s+|\s+$//g; return $_[0]; };


my($position) =
{ line => 1 # 1-based counting
, column => 1 # 1-based counting
};

my($lexxed) = [];
while(my $line = <>)
{ push(@$lexxed, @{lex($line, $position)});
}

# CORE::say STDERR Dumper($lexxed);
# die Dumper($lexxed);

my($ast) = ParseProgram($lexxed);

# CORE::say STDERR Dumper($ast);

CORE::say GenerateProgram($ast);
