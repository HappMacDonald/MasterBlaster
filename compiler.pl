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

  { NodeType => 'Statement'
  , Expression => $expression
  };
}

sub ProcessExpression
{ my($tokens) = shift;

  die("Expression does not consist of a simple, literal integer")
    unless(shift @$tokens eq 'LITERAL_INTEGER');

  my($value) = shift @$tokens;

  { NodeType => 'Expression'
  , value => $value
  };
}

my($lexxed) = [];
while(my $line = <>)
{ push(@$lexxed, @{lex($line)});
}

CORE::say STDERR Dumper($lexxed);

my($ast) = ProcessProgram($lexxed);

CORE::say STDERR Dumper($ast);
