#include "TestAnythingProtocolProducer_s.h"
.text
.globl _start
_start:
  EndAlienCallStackFrame

  plan1 7 "BooleanOperatorTests"


  ClearDataStack
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192
  Bitfield8ImmediateVector128 80, 213, 65, 217, 120, 111, 48, 209, 130, 77, 35, 146, 143, 183, 238, 27

  BooleanAnd
.memoryBlock Expected_BooleanAnd
405401C070052040 004D03900E91A800
.endMemoryBlock
  stackFullTest Expected_BooleanAnd(%rip), count=1
  ok1 "BooleanAnd", "oof"


  ClearDataStack
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192
  Bitfield8ImmediateVector128 80, 213, 65, 217, 120, 111, 48, 209, 130, 77, 35, 146, 143, 183, 238, 27

  BooleanOr
  // PrintStackMessage "BooleanOr"
.memoryBlock Expected_BooleanOr
55FDF1DD7B7FBED5 DBED3FBBDFBFFFDB
.endMemoryBlock
  stackFullTest Expected_BooleanOr(%rip), count=1
  ok1 "BooleanOr", "oof"


  ClearDataStack
  Bitfield8ImmediateVector128 0x80, 159, 118, 0x01, 0x7F, 0x7E, 14, 190, 192, 164, 48, 0xFE, 0x81, 0x00, 222, 0xFF

  Bitfield8BooleanNot
  // PrintStackMessage "Bitfield8BooleanNot"
.memoryBlock Expected_Bitfield8BooleanNot
0000000000000000 0000000000FF0000
.endMemoryBlock
  stackFullTest Expected_Bitfield8BooleanNot(%rip), count=1
  ok1 "Bitfield8BooleanNot", "oof"


.memoryBlock Expected_Bitfield64BooleanNot1
FFFFFFFFFFFFFFFF 0000000000000000
0000000000000000 0000000000000000
0000000000000000 0000000000000000
.endMemoryBlock
  Expected_Bitfield64BooleanNot2 = Expected_Bitfield64BooleanNot1 + SIMD_WIDTH
  Expected_Bitfield64BooleanNot3 = Expected_Bitfield64BooleanNot1 + SIMD_WIDTH_TIMES_2

  ClearDataStack
  Bitfield64ImmediateVector128 0, 1

  Bitfield64BooleanNot
  // PrintStackMessage "Bitfield64BooleanNot1"
  stackFullTest Expected_Bitfield64BooleanNot1(%rip), count=1
  ok1 "Bitfield64BooleanNot1", "oof"


  ClearDataStack
  Bitfield64ImmediateVector128 0x7FFFFFFFFFFFFFFF, 0x8000000000000000

  Bitfield64BooleanNot
  // PrintStackMessage "Bitfield64BooleanNot2"
  stackFullTest Expected_Bitfield64BooleanNot2(%rip), count=1
  ok1 "Bitfield64BooleanNot2", "oof"


  ClearDataStack
  Bitfield64ImmediateVector128 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF

  Bitfield64BooleanNot
  // PrintStackMessage "Bitfield64BooleanNot3"
  stackFullTest Expected_Bitfield64BooleanNot3(%rip), count=1
  ok1 "Bitfield64BooleanNot3", "oof"


  ClearDataStack
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192
  Bitfield8ImmediateVector128 80, 213, 65, 217, 120, 111, 48, 209, 130, 77, 35, 146, 143, 183, 238, 27

  // I've observed one implementation error that bled %xmm0 onto the stack
  // at the beginning of BooleanXor, so preemptively forcing uncorrelated
  // data into %xmm0
  _SetAllBitsZero %xmm0

  // PrintStackMessage "BooleanXor"
  BooleanXor
  // PrintStackMessage "BooleanXor"
.memoryBlock Expected_BooleanXor
15A9F01D0B7A9E95 DBA03C2BD12E57DB
.endMemoryBlock
  stackFullTest Expected_BooleanXor(%rip), count=1
  ok1 "BooleanXor", "oof"



  SystemExit
