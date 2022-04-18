#include "libmb_s.h"

.macro TestSet operand:req message:req operator:req

  PrintStackMessage \message
  Immediate 5
  Immediate 1
  PrintStackMessage "5 \operator\() 1?"
  \operand doingStuff
  Immediate 1
  Immediate 5
  PrintStackMessage "1 \operator\() 4?"
  \operand doingStuff
  Immediate 8
  Immediate 8
  PrintStackMessage "8 \operator\() 8?"
  \operand doingStuff
  Immediate -16
  Immediate 7
  PrintStackMessage "0xF..F0 \operator\() 7?"
  \operand doingStuff
  Immediate 7
  Immediate -3
  PrintStackMessage "7 \operator\() 0xF..FD?"
  \operand doingStuff
  putNewlineMacro

.endm

.text
doingStuff:
  PrintStackMessage "! ! ! ! ! ! ! ! ! ! ! !"
  ret

.globl _start
_start:
  // Treating inbound rbp=0 as parent's stack frame.
  EndAlienCallStackFrame

  Immediate 0x666
  PrintStackMessage "Starting test. Unconditional."
  BranchUnconditional doingStuff

  TestSet "ScalarBranchLessThan","Less_than","<"
  TestSet "ScalarBranchGreaterThan","Greater_than",">"
  TestSet "ScalarBranchEqual","Equality","=="
  TestSet "ScalarBranchAnd","And","&"
  TestSet "ScalarBranchGreaterThanOrEqual","GreaterThanOrEqual",">="
  TestSet "ScalarBranchLessThanOrEqual","LessThanOrEqual","<="
  TestSet "ScalarBranchNotEqual","NotEqual","!="
  TestSet "ScalarBranchNand","NAND","NAND"

  systemExit
