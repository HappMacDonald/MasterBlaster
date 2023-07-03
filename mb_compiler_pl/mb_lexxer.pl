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
use List::Util qw(min max);
use POSIX qw(floor ceil round);

require "./mb_common.pl";

my $SUPPRESS_WHITESPACE = qr([ \t]*);
my $END_OF_LINE = qr((?:\r|\n)+);
my $SUPPRESS_WS_AND_EOL = $SUPPRESS_WHITESPACE . $END_OF_LINE;

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
    , pattern => qr(([a-z_]\w*))
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

sub lex
{ my($input) = shift;
  my($position) = { %{shift()} };
  my($output) = [];

  my($fullLine) = $input;
  $input =~ s/^(\s+)//; # drop all leading whitespace
  $position = incrementPosition($1, $position);

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
          $position = incrementPosition($1, $position);

          last TOKEN_SEARCH;
        }
        # else Match NOT found
      }
    }

    if($input eq $inputClone)
    { trim($input);
      trim($fullLine);
die(Dumper($output));
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

1;
