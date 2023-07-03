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

1;
