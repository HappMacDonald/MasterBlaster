#!/usr/bin/perl -C63

use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use Data::Dumper;
use JSON;
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
  }
, { IDENTIFIER_CAPS =>
    { argumentCount => 1
    , pattern => qr(([A-Z]\w*))
    }
  , IDENTIFIER_NOCAPS =>
    { argumentCount => 1
    , pattern => qr(([a-z]\w*))
    }
  , LITERAL_INTEGER =>
    { argumentCount => 1
    , pattern => qr(([0-9]+))
    }
  , EQUALS =>
    { argumentCount => 0
    , suppressEndOfLine => TRUE
    , pattern => qr(=)
    }
  , OPERATOR_UNARY_COMLPEMENT_ADDITIVE =>
    { argumentCount => 0
    , pattern => qr(-)
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

sub lex
{ my($input) = shift;
  my($position) = shift;
  my($output) = [];

  my($fullLine) = $input;
  $input =~ s/^(\s+)//; # drop all leading whitespace
  incrementPosition($1, $position);

  while(length $input)
  { my($inputClone) = $input; 
#CORE::say "---";
#CORE::say Dumper($input);
#sleep 1;
    TOKEN_SEARCH:
    for my $tokenLevel (@$TOKENS)
    { for my $token (keys %$tokenLevel)
      { my($tokenProperties) = $tokenLevel->{$token};
        my($argumentCount) = $tokenProperties->{argumentCount};
        my($pattern) = $tokenProperties->{pattern};

        if(my(@matches) = $input =~ /^$pattern/)
        { # truncated @matches array to be at most $argumentCount in length.
          splice @matches, $argumentCount;
          
#CORE::say "Match found: ". Dumper($token, $tokenProperties, \@matches);
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

          $input =~ s/^($pattern$localSuppressedWhitespace)//;
          incrementPosition($1, $position);

          last TOKEN_SEARCH;
        }
        else
        {
#CORE::say "Match NOT found: $token" . Dumper($tokenProperties, @matches);
        }
      }
    }

    die("Unrecognized token: $input\n$fullLine")
      if($input eq $inputClone);
  }

  $output;
}

sub incrementPosition
{ my($str) = shift;
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

sub ProcessProgram
{ my($tokens) = shift;

  { NodeType => "Program"
  , OnlyProcedure => ProcessProcedure($tokens)
  };
}

sub ProcessProcedure
{ my($tokens) = shift;

  PeekToken
  ( $tokens
  , 'IDENTIFIER_NOCAPS'
  , 'Procedure names must begin lowercase'
  );

  # $tokens->[0] remains 'IDENTIFIER_NOCAPS'
  my($procedureName) = $tokens->[1];
  #   PeekToken
  #   ( $tokens
  #   # , 'main'
  #   , qr(^[a-z])
  #   , 'Program\'s (only) procedure must be named "main" (case sensitive)'
  #   );

  my($typeAnnotation) = ProcessTypeAnnotation($tokens);

  { NodeType => "Procedure"
  , ProcedureName => $procedureName
  , TypeAnnotation => $typeAnnotation
  , ProcedureBody => ProcessProcedureBody($typeAnnotation, $tokens)
  };
}

sub ProcessTypeAnnotation
{ my($tokens) = shift;

  ExpectToken
  ( $tokens
  , 'IDENTIFIER_NOCAPS'
  , 'Type annotations must start with a lowercase identifier'
  );

  my($procedureName) = shift @$tokens;

  ExpectToken
  ( $tokens
  , 'COLON'
  , 'Procedure name is not immediately followed by a colon'
  );

  my($argumentTypes) = ProcessArgumentTypes($tokens, WantsDelimiter => TRUE);

  ExpectToken
  ( $tokens
  , 'END_OF_LINE'
  , '(unreachable error) Complete Type Annotations must end with a newline.'
  );

  { NodeType => "TypeAnnotation"
  , ProcedureName => $procedureName
  , ArgumentTypes => $argumentTypes
  };
}

sub ProcessArgumentTypes
{ my($tokens) = shift;
  my($arguments) =
  { WantsDelimiter => TRUE
  , @_ # accept remaining arguments to stomp over defaults given 
  };

  my($identifierCaps) = 
    ExpectToken($tokens, 'IDENTIFIER_CAPS', 'Types must be uppercase identifiers');

  my($primaryType) = shift @$tokens;
  my($typeProperties) = $Types->{$primaryType};

  die("'$primaryType' is not a known Type")
    unless(defined($typeProperties));

  my($argumentCount) = $typeProperties->{arguments};

  my($typeArguments) = [];

  while($argumentCount-->0)
  { push @$typeArguments, ProcessArgumentTypes($tokens, WantsDelimiter => FALSE);
  }

  if($arguments->{WantsDelimiter})
  { my($position) = ProcessPossiblePosition($tokens);
    Error
    ( ( "Type Annotation Arguments must end with either a thin arrow `->`"
      . " or a newline.\n"
      . " Type $primaryType only allows $typeProperties->{arguments} arguments."
      ) # $errorMessage
    , $position
    ) unless(defined $TypeAnnotationEndings->{$tokens->[0]});

    if($tokens->[0] eq 'ARROW_THIN')
    { shift @$tokens; # discard the thin arrow.

      return
      { NodeType => "ArgumentTypes"
      , MoreArguments => TRUE
      , PrimaryType => $primaryType
      , TypeArguments => $typeArguments
      , NextArgument => ProcessArgumentTypes($tokens, WantsDelimiter => TRUE)
      };
    }
    # the only other possibility is that $tokens->[0] eq 'END_OF_LINE'
    # which will output the same data as a
    # subtype "doesn't want delimiter" case would have.
  }

  return
  { NodeType => "ArgumentTypes"
  , MoreArguments => FALSE
  , PrimaryType => $primaryType
  , TypeArguments => $typeArguments
  };
}

sub ProcessProcedureBody
{ my($typeAnnotation) = shift;
  my($tokens) = shift;

  my($procedureName) = 
    ExpectToken
    ( $tokens
    , 'IDENTIFIER_NOCAPS'
    , 'Procedure definitions must start with a lowercase identifier'
    );

  ExpectToken
  ( $tokens
  , $typeAnnotation->{ProcedureName}
  , ( 'Procedure name in type annotation'
    . ' does not match procedure name in procedure body.'
    )
  );
  ProcessSkipEndOfLine($tokens);

  ExpectToken
  ( $tokens
  , 'EQUALS'
  , ( "Procedure Name '$procedureName' not followed by"
    . " an equals sign in Procedure body."
    )
  );

  my($errorMessage) = 'Procedure body must start with token "Procedure"';
  ExpectToken($tokens, 'IDENTIFIER_CAPS', $errorMessage);
  ExpectToken($tokens, 'Procedure', $errorMessage);
}

sub ProcessStatement
{ my($tokens) = shift;

  die("Statement begins with something other than the 'return' case sensitive keyword")
    unless(shift(@$tokens) eq 'KEYWORD_RETURN');

  my($expression) = ProcessExpression($tokens);

  die("Return statement does not immediately follow expression with a line-ending semicolon")
    unless(shift @$tokens eq 'SEMICOLON');

  { NodeType => 'ReturnStatement'
  , Expression => $expression
  };
}

sub ProcessExpression
{ my($tokens) = shift;

  my($initial) = shift @$tokens;
  my($value, $type);

  if($initial eq 'LITERAL_INTEGER')
  { $value = shift @$tokens;
    $type = 'LiteralInteger';
  }
  elsif($initial =~ /^OPERATOR_UNARY_/)
  { #$tokens = [$initial, @$tokens];
    unshift @$tokens, $initial;
    $value = ProcessUnaryExpression($tokens);
    $type = 'Unary';
  }
  else
  { die("Expression did not evaluate to either an integer literal or a unary expression.");
  }

  { NodeType => 'Expression'
  , Value => $value
  , Type => $type
  };
}

sub ProcessUnaryExpression
{ my($tokens) = shift;

  my($operator) = shift @$tokens;
  my($expression) = ProcessExpression($tokens);

  { NoteType => 'UnaryExpression'
  , Operator => $operator
  , Expression => $expression
  }
}

sub ProcessSkipEndOfLine
{ my($tokens) = shift;
  if($tokens->[0] eq 'END_OF_LINE')
  { shift @$tokens;
  }
}

sub ProcessPossiblePosition
{ my($tokens) = shift;
  if($tokens->[0] eq 'POSITION')
  { shift @$tokens;
    return shift @$tokens;
  }
  return undef; # Not at a position token, so no position returned.
}

sub ExpectToken
{ my($tokens) = shift;
  my(@ret) = PeekToken($tokens, @_);
  shift @$tokens;
  @ret;
}

sub PeekToken
{ my($tokens) = shift;
  my($expectedToken) = shift;
  my($errorMessage) = shift;
  my($position) = ProcessPossiblePosition($tokens);

  my($foundToken) = $tokens->[0];

  unless($foundToken =~ $expectedToken)
  { Error($errorMessage, $position, $expectedToken, $foundToken);
  }
  
  $foundToken, $position; # return valid token
}

sub Error
{ my($errorMessage) = shift;
  my($position) = shift;
  my($expectedToken) = shift;
  my($foundToken) = shift;
  CORE::say STDERR $errorMessage;
  CORE::say "Expected: $expectedToken" if(defined $expectedToken);
  CORE::say "Found: $foundToken" if(defined $expectedToken);
  CORE::say "At Line $position->{line}, Column $position->{column}"
    if(defined $position);
  exit 1;
}

sub GenerateProgram
{ my($ast) = shift;

  my($onlyProcedure) = $ast->{OnlyProcedure};

  my($ret) = GenerateProcedureGlobal($onlyProcedure);
  $ret .= GenerateProcedureBody($onlyProcedure);
  $ret;
}

sub GenerateProcedureGlobal
{ my($ast) = shift;

  "\t.globl\t". $ast->{ProcedureName} ."\n";
}

sub GenerateProcedureBody
{ my($ast) = shift;

  my($ret) = $ast->{ProcedureName} .":\n";
  $ret .= GenerateReturnStatement($ast->{OnlyStatement});
  $ret;
}

sub GenerateReturnStatement
{ my($ast) = shift;

  my($ret) = GenerateExpression($ast->{Expression});
  $ret .= "\tret\n";
}

sub GenerateExpression
{ my($ast) = shift;

  if($ast->{Type} eq 'LiteralInteger')
  { return "\tmov\t\$". $ast->{Value} .", %rax\n";
  }
  elsif($ast->{Type} eq 'Unary')
  { return GenerateUnaryExpression($ast->{Value});
  }
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
  elsif($ast->{Operator} eq 'OPERATOR_UNARY_COMPLEMENT_BOOLEAN')
  { $ret .= <<"EOL";
\tcmp\t\$0, %rax
\tmov\t\$0, %rax
\tsete\t%al
EOL
  }
  else
  { die("Failed sanity check: unknown type of unary expression.\n". Dumper($ast));
  }

  $ret;
}

my($position) =
{ line => 1 # 1-based counting
, column => 1 # 1-based counting
};

my($lexxed) = [];
while(my $line = <>)
{ push(@$lexxed, @{lex($line, $position)});
}

CORE::say STDERR Dumper($lexxed);

my($ast) = ProcessProgram($lexxed);

CORE::say STDERR Dumper($ast);

# CORE::say GenerateProgram($ast);
