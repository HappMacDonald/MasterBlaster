#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use JSON;

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
  , KEYWORD_INT =>
    { argumentCount => 0
    , pattern => qr(int)
    }
  , KEYWORD_RETURN =>
    { argumentCount => 0
    , pattern => qr(return)
    }
  , OPERATOR_UNARY_COMLPEMENT_ADDITIVE =>
    { argumentCount => 0
    , pattern => qr(-)
    }
  , OPERATOR_UNARY_COMPLEMENT_BITWISE =>
    { argumentCount => 0
    , pattern => qr(~)
    }
  , OPERATOR_UNARY_COMPLEMENT_BOOLEAN =>
    { argumentCount => 0
    , pattern => qr(!)
    }
  }
, { IDENTIFIER =>
    { argumentCount => 1
    , pattern => qr(([a-zA-Z]\w*))
    }
  , LITERAL_INTEGER =>
    { argumentCount => 1
    , pattern => qr(([0-9]+))
    }
  }
];

sub lex
{ my($input) = shift;
  my($output) = [];

  my($fullLine) = $input;
  $input =~ s/^\s+//; # drop all leading whitespace

  while(length $input)
  { my($inputClone) = $input;
#CORE::say "---";
#CORE::say Dumper($input);
#sleep 1;
    TOKEN_SEARCH:
    for my $tokenLevel (@$TOKENS)
    { for my $token (keys %$tokenLevel)
      { my($argumentCount) = $tokenLevel->{$token}{argumentCount};
        my($pattern) = $tokenLevel->{$token}{pattern};

        if(my(@matches) = $input =~ /^$pattern/)
        { # truncated @matches array to be at most $argumentCount in length.
          splice @matches, $argumentCount;
          
#CORE::say "Match found: ". Dumper($token, $tokenLevel->{$token}, \@matches);
          $input =~ s/^$pattern\s*//;
          push(@$output, $token, @matches);
          last TOKEN_SEARCH;
        }
        else
        {
#CORE::say "Match NOT found: $token" . Dumper($tokenLevel->{$token}, @matches);
        }
      }
    }

    die("Unrecognized token: $input\n$fullLine")
      if($input eq $inputClone);
  }

  $output;
}

# Will I need this to create closures at the Perl/compiler stage, or not?
sub ADT
{ my(@args) = @_;
  sub
  { \@args;
  }
}

sub ProcessProgram
{ my($tokens) = shift;

  { NodeType => "Program"
  , OnlyFunction => ProcessFunction($tokens)
  };
}

sub ProcessFunction
{ my($tokens) = shift;

  die("Program does not start by declaring a function which returns an Integer")
    unless(shift @$tokens eq 'KEYWORD_INT');

  die("Program definition does not follow int keyword with a valid identifier to name it's primary function")
    unless(shift @$tokens eq 'IDENTIFIER');

  my($functionName) = shift @$tokens;

  die("Program's primary function is named '$functionName' instead of case-sensitive 'main' as required")
    unless($functionName eq 'main');

  die("Function name is not immediately followed by an open parenthesis")
    unless(shift @$tokens eq 'PAREN_ROUND_OPEN');

  die("Function definition has something besides whitespace in it's argument section (current compiler cannot support any function arguments)")
    unless(shift @$tokens eq 'PAREN_ROUND_CLOSED');

  die("Function definition is not immediately followed by an open curly brace to denote the beginning of the function body")
    unless(shift @$tokens eq 'PAREN_CURLY_OPEN');

  my($statement) = ProcessStatement($tokens);

  die("Single allowed statement in function definition is not immediately followed by a closed curly brace to end the function body")
    unless(shift @$tokens eq 'PAREN_CURLY_CLOSED');

  die("Garbage found after the end of the only allowed function body")
    unless(scalar(@$tokens) == 0);

  { NodeType => "Function"
  , FunctionName => $functionName
  , OnlyStatement => $statement
  };
}

sub ProcessStatement
{ my($tokens) = shift;

  die("Statement begins with something other than the 'return' case sensitive keyword")
    unless(shift @$tokens eq 'KEYWORD_RETURN');

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

sub GenerateProgram
{ my($ast) = shift;

  my($onlyFunction) = $ast->{OnlyFunction};

  my($ret) = GenerateFunctionGlobal($onlyFunction);
  $ret .= GenerateFunctionBody($onlyFunction);
  $ret;
}

sub GenerateFunctionGlobal
{ my($ast) = shift;

  "\t.globl\t". $ast->{FunctionName} ."\n";
}

sub GenerateFunctionBody
{ my($ast) = shift;

  my($ret) = $ast->{FunctionName} .":\n";
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

my($lexxed) = [];
while(my $line = <>)
{ push(@$lexxed, @{lex($line)});
}

CORE::say STDERR Dumper($lexxed);

my($ast) = ProcessProgram($lexxed);

CORE::say STDERR Dumper($ast);

CORE::say GenerateProgram($ast);
