#include "TestAnythingProtocolProducer.h"
.text
.globl _start
_start:
  EndAlienCallStackFrame

  plan1 4 "BooleanOperatorTests"


  ClearDataStack
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192
  Bitfield8ImmediateVector128 80, 213, 65, 217, 120, 111, 48, 209, 130, 77, 35, 146, 143, 183, 238, 27

  BooleanAnd
.memoryBlock BooleanAnd
405401C070052040 004D03900E91A800
.endMemoryBlock
  stackFullTest BooleanAnd(%rip), count=1
  ok1 "BooleanAnd", "oof"


  ClearDataStack
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192
  Bitfield8ImmediateVector128 80, 213, 65, 217, 120, 111, 48, 209, 130, 77, 35, 146, 143, 183, 238, 27

  BooleanOr
  // PrintStackMessage "BooleanOr"
.memoryBlock BooleanOr
55FDF1DD7B7FBED5 DBED3FBBDFBFFFDB
.endMemoryBlock
  stackFullTest BooleanOr(%rip), count=1
  ok1 "BooleanOr", "oof"


  ClearDataStack
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192

  BooleanNot
  // PrintStackMessage "BooleanNot"
.memoryBlock BooleanNot
BA834E3B8CEA51BB A612E046A166463F
.endMemoryBlock
  stackFullTest BooleanNot(%rip), count=1
  ok1 "BooleanNot", "oof"


  ClearDataStack
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192
  Bitfield8ImmediateVector128 80, 213, 65, 217, 120, 111, 48, 209, 130, 77, 35, 146, 143, 183, 238, 27

  BooleanXor
  // PrintStackMessage "BooleanXor"
.memoryBlock BooleanXor
15A9F01D0B7A9E95 DBA03C2BD12E57DB
.endMemoryBlock
  stackFullTest BooleanXor(%rip), count=1
  ok1 "BooleanXor", "oof"



  SystemExit
