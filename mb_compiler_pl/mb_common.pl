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

sub Error
{ my($errorMessage) = shift || 'Unspecified error';
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

sub Assert
{ my $test = shift;

  if(!$test)
  { Error @_;
  }
}

sub AssertEqual
{ my($foundToken) = shift;
  my($expectedToken) = shift;
  my($errorMessage) = shift;
  my($position) = shift;

  Assert
  ( $expectedToken eq $foundToken
  , $errorMessage
  , $position
  , $expectedToken
  , $foundToken
  );
}

sub Plural
{ my($number) = shift;
  my($singular) = shift;
  my($plural) = shift || "${singular}s";

  $number==1?"$number $singular":"$number $plural";
}

sub trim { $_[0] =~ s/^\s+|\s+$//g; return $_[0]; };

# Like splice except:
# * Does not alter input array
# * returns resulting altered array
sub slice
{ my($array) = shift;
  my($start) = shift || 0;
  my($length) = shift || 0;
  my($end) = $start + $length;
  my($insert) = shift || [];

  my($result) = [];

  for(my $index=0; $index<@$array; $index++)
  {
    if($index == $start)
    { push @$result, @$insert;
    }

    if($index >= $start && $index < $end)
    { # do nuttin'
    }
    else
    { push @$result, $array->[$index];
    }
  }
  $result;
};

1;
