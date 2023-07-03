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
trap { CORE::say STDERR "!"; exit 1;  Error(); };
CORE::say '[', $trap->stderr, ']';
is($trap->stderr, "\nUnspecified error\n\n", 'No error message given');

trap { die("!"); };
CORE::say '[', $trap->stderr, ']';
