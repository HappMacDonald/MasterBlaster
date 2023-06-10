#!/usr/bin/perl

; use 5.20.1
; use strict
; use warnings
; use Data::Dumper

; my $SCRIPT_NAME = __FILE__
; my $returnValue = 1 # default "not ok" return value until at least some data gets processed

; foreach my $arg (@ARGV)
  { if($arg =~ /^--?(?:\?$|(?:h|he|hel|help)\b)/)
    { CORE::say
      ( "Usage:"
      . "\n\tcat source_file.ext | $SCRIPT_NAME > preprocessed_source_file.ext"
      . "\n\t$SCRIPT_NAME source_file.ext > preprocessed_source_file.ext"
      . "\n\t$SCRIPT_NAME source_file.ext | gcc --flags"
      )
    ; exit
    }
  }

# Goal of this preprocessor is to ease Gas (and C Preprocessor) syntax while
# writing Morlock Crude (EG Crude expressed as Gas macros instead of
# being compiled from token source).
#
# Initial motivation is to ease defining blocks of memory
# to compare against the stack in TAP testing.

; my $READMODE_NONE = 0
; my $READMODE_MEMORY_BLOCK = 1

; my $readMode = $READMODE_NONE
; my $effectiveInputLine = -1
; while(my $line = <>)
  { chomp $line
  ; my $interpretLine = $line
  ; $interpretLine =~ s/^\s+|\s+$//g # trim whitespace from line
  ; if($readMode eq $READMODE_NONE)
    { if($interpretLine =~ /^\s*.memoryBlock\s+(\S+)$/)
      { my $memoryBlockHandle = $1
      ; $effectiveInputLine = $.
      ; CORE::say "  jmp crudePreprocessorEndMemoryBlock$effectiveInputLine"
      ; CORE::say ".balign SIMD_WIDTH"
      ; CORE::say "$memoryBlockHandle:"
      ; $readMode = $READMODE_MEMORY_BLOCK
      ; $returnValue = 1; # not ok until end memory block satisfied
      }
      else
      { # in readmode none, if no command to interpret, then simply print line.
      ; CORE::say $line
      ; $returnValue = 0; # ok: processed ordinary line
      }
    }
    elsif($readMode eq $READMODE_MEMORY_BLOCK)
    { if($interpretLine =~ /^\s*.endMemoryBlock$/)
      { CORE::say "crudePreprocessorEndMemoryBlock$effectiveInputLine:"
      ; $readMode = $READMODE_NONE
      ; $returnValue = 0; # ok: end memory block satisfied
      }
      else
      { # in readmode memoryblock, if no command to interpret, print .byte's.
      ; $interpretLine =~ s/[^[:xdigit:]]//g
      ; # If odd number of hex digits, prepend a single zero digit.
      ; if(length($interpretLine) % 2 != 0)
        { $interpretLine = '0'. $interpretLine
        }
      ; my $bytes = [unpack("(A2)*", $interpretLine)]
      ; CORE::say ".byte 0x". join(", 0x", @$bytes)
      ; $returnValue = 1; # not ok until end memory block satisfied
      }
    }
  }

; exit $returnValue
