#!/usr/bin/perl -C63

die(<<'EOL'
Status:
1. Trying to figure out where to enforce what `main`'s type annotation must be
2. Also trying to figure out how to enforce function type annotations vs
number of arguments listed
3. Once all of that's done, then I want to figure out how to both define
and enforce upon callers the type annotations for builtin functions
such as System.exit.
Maybe treat them like user-defined functions with the exception that
they have dedicated Generate routines?
Should also go through the import rigamarole.
EOL
);

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
require "./mb_lexxer.pl";
require "./mb_parser.pl";
require "./mb_generator.pl";

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
