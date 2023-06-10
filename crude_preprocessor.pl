#!/usr/bin/perl

; use 5.20.1
; use strict
; use warnings
; use Data::Dumper

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
    { if($interpretLine =~ /.memoryBlock\s+(\S+)/)
      { my $memoryBlockHandle = $1
      ; $effectiveInputLine = $.
      ; CORE::say "  jmp crudePreprocessorEndMemoryBlock$effectiveInputLine"
      ; CORE::say "$memoryBlockHandle:"
      ; $readMode = $READMODE_MEMORY_BLOCK
      }
      else
      { # in readmode none, if no command to interpret, then simply print line.
      ; CORE::say $line
      }
    }
    elsif($readMode eq $READMODE_MEMORY_BLOCK)
    { if($interpretLine eq '.endMemoryBlock')
      { CORE::say "crudePreprocessorEndMemoryBlock$effectiveInputLine:"
      ; $readMode = $READMODE_NONE
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
      }
    }
  }