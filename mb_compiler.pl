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
