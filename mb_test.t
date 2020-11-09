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
use Test::More;
use Test::Trap;

require "./mb_common.pl";
require "./mb_lexxer.pl";
require "./mb_parser.pl";
require "./mb_generator.pl";

my $junk;
my $position = {line=>1,column=>2};

####################
##  mb_common.pl  ##
####################
trap { Error('msg'); };
is($trap->stderr, "\nmsg\n\n", 'Just an error message');

trap { Error('msg', $position); };
is($trap->stderr, "\nmsg\nAt Line 1, Column 2\n\n", 'Error message with position');

trap { Error('msg', $position, 'a', 'b'); };
is($trap->stderr, "\nmsg\nExpected: a\nFound: b\nAt Line 1, Column 2\n\n", 'Error message with position, expected, and found');

trap { Error('msg', undef, 'a', 'b'); };
is($trap->stderr, "\nmsg\nExpected: a\nFound: b\n\n", 'Error message with just expected and found');


is(Plural(1, 'thing'), '1 thing', 'Plural');
is(Plural(2, 'thing'), '2 things', 'Plural');
is(Plural(2, 'goose', 'geese'), '2 geese', 'Plural');

trim($junk = "  \t Hello  there\n\n ");
is($junk, 'Hello  there', 'trim');

my $junk2 = [qw(a b c d)];

is_deeply
( $junk = slice($junk2)
, $junk2
, 'slice identity'
) || diag Dumper($junk);

is_deeply
( $junk = slice($junk2, 0, 1)
, [qw(b c d)]
, 'slice: [qw(a b c d)], 0, 1'
) || diag Dumper($junk);

is_deeply
( $junk = slice($junk2, 1, 2)
, [qw(a d)]
, 'slice: [qw(a b c d)], 1, 2'
) || diag Dumper($junk);

is_deeply
( $junk = slice($junk2, 1, 2, ['q'])
, [qw(a q d)]
, 'slice: [qw(a b c d)], 1, 2, ["q"]'
) || diag Dumper($junk);



####################
##  mb_lexxer.pl  ##
####################
is_deeply
( $junk = lex('main: -0x0005', $position)
, [ 'POSITION'
  , $position
  , 'IDENTIFIER_NOCAPS'
  , 'main'
  , 'POSITION'
  , { 'column' => 6
    , 'line' => 1
    }
  , 'COLON'
  , 'POSITION'
  , { 'column' => 8
    , 'line' => 1
    }
  , 'LITERAL_INTEGER'
  , { 'base' => '0x'
    , 'sign' => '-'
    , 'leadingZeros' => '000'
    , 'mantissa' => '5'
    }
  ]
, 'lex: main'
) || diag Dumper $junk;

is_deeply
( $junk =
    incrementPosition
    ( "    \nHello\n\n \tThere   "
    , { line => 1, column => 1}
    )
, { line => 4, column => 11}
, 'incrementPosition: \'    \nHello\n\n \tThere   \', (1,1)'
) || diag Dumper $junk;




####################
##  mb_parser.pl  ##
####################
my($junkTokens1) = [qw(a b c d e f g)];
my($junkTokens2) = [@$junkTokens1];
my($junkTokens3) = [ qw(a b POSITION), $position, qw(c d e f g)];

is_deeply
( $junk = ParsePossiblePosition(slice($junkTokens3, 0, 2))
, $position
, 'ParsePossiblePosition: $junkTokens3 (middle)'
) || diag Dumper $junk;

is_deeply
( $junk = ParsePossiblePosition(slice($junkTokens1))
, undef
, 'ParsePossiblePosition: $junkTokens1'
) || diag Dumper $junk;

is_deeply
( $junk = [ PeekTokens($junkTokens1, 'a', 'Error Message') ]
, [ 'a', undef ]
, 'PeekTokens: j1, a'
) || diag Dumper $junk;

is_deeply
( $junk = [ PeekTokens($junkTokens1, [qw(a b)], 'Error Message') ]
, [ [qw(a b)], undef ]
, 'PeekTokens: j1, [qw(a b)]'
) || diag Dumper $junk;

is_deeply
( $junk = [ PeekTokens($junkTokens1, [qw(a b)], 'Error Message', $position) ]
, [ [qw(a b)], $position ]
, 'PeekTokens: j1, [qw(a b)], $position'
) || diag Dumper $junk;

is_deeply
( $junk = [ PeekTokens($junkTokens3, [qw(a b c)], 'Error Message') ]
, [ [qw(a b c)], undef ] # no position found because none provided up front
, 'PeekTokens: j3, [qw(a b c)], $position'
) || diag Dumper $junk;

is_deeply
( $junk =
    [ PeekTokens
      ( slice($junkTokens3, 0, 2)
      , 'c'
      , 'Error Message'
      )
    ]
, [ 'c', $position ]
, 'PeekTokens: j3 (middle), "c", $position'
) || diag Dumper $junk;

is_deeply
( $junk =
    [ PeekTokens
      ( slice($junkTokens3, 0, 2)
      , [qw(c d e)]
      , 'Error Message'
      )
    ]
, [ [qw(c d e)], $position ]
, 'PeekTokens: j3 (middle), [qw(c d e)], $position'
) || diag Dumper $junk;

trap { PeekTokens([qw(a b)], 'b', 'Error Message') };
is
($trap->stderr
, "\nError Message\nExpected: b\nFound: a\n\n"
, 'PeekTokens fail test: [a, b] vs b'
);

trap { PeekTokens([qw(a b)], [qw(a c)], 'Error Message') };
is
($trap->stderr
, "\nError Message\nExpected: c\nFound: b\n\n"
, 'PeekTokens fail test: [a, b] vs [a, c]'
);

trap { PeekTokens([qw(a b)], [qw(a c)], 'Error Message', $position) };
is
($trap->stderr
, "\nError Message\nExpected: c\nFound: b\nAt Line 1, Column 2\n\n"
, 'PeekTokens fail test: [a, b] vs [a, c] with caller-supplied position'
);

trap
{ PeekTokens
  ( ['POSITION', $position, qw(a b)]
  , [qw(a c)]
  , 'Error Message'
  )
};
is
($trap->stderr
, "\nError Message\nExpected: c\nFound: b\nAt Line 1, Column 2\n\n"
, 'PeekTokens fail test: [a, b] vs [a, c] internal position 1'
);

trap
{ PeekTokens
  ( ['a', 'POSITION', $position, 'b']
  , [qw(a c)]
  , 'Error Message'
  )
};
is
($trap->stderr
, "\nError Message\nExpected: c\nFound: b\nAt Line 1, Column 2\n\n"
, 'PeekTokens fail test: [a, b] vs [a, c] internal position 2'
);

TODO: { local $TODO = "Stubbed out tests for ExpectTokens"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for PeekPosition"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseSkipEndOfLine"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseUnaryExpression"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseExpression"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseStatement"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseProcedureBody"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseArgumentTypes"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseTypeAnnotation"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseProcedure"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for ParseProgram"; ok 1; }




#######################
##  mb_generator.pl  ##
#######################
TODO: { local $TODO = "Stubbed out tests for GenerateUnaryExpression"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for GenerateExpression"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for GenerateSystemExit"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for GenerateProcedureBody"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for GenerateProcedureGlobal"; ok 1; }
TODO: { local $TODO = "Stubbed out tests for GenerateProgram"; ok 1; }




done_testing();