#include "TestAnythingProtocolProducer_s.h"

.text

.globl _start
_start:
  EndAlienCallStackFrame

  plan1 10 "bitfield8 tests"

  // only lowest 8 bits will survive,
  // but hardware limitations require me
  // to pass this value around as 32-bit or greater.
  mov $0xac, %eax
  _Bitfield8DataStackPushGeneral %eax
  // PrintStackMessage "_Bitfield8DataStackPushGeneral value %ax"
.crudeMemoryBlock Expected_Bitfield8DataStackPushGeneral
ACACACACACACACAC ACACACACACACACAC
.crudeEndMemoryBlock
  stackFullTest Expected_Bitfield8DataStackPushGeneral(%rip), count=1
  ok1 "_Bitfield8DataStackPushGeneral", "oof"

  ClearDataStack

  Bitfield8Immediate 0x10
.crudeMemoryBlock ExpectedBitfield8Immediate
1010101010101010 1010101010101010
.crudeEndMemoryBlock
  stackFullTest ExpectedBitfield8Immediate(%rip), count=1
  ok1 "Bitfield8Immediate", "oof"

  ClearDataStack
  Bitfield8ImmediateVector128 \
  0x01, 0x03, 0x05, 0x0c, 0x18, 0x30, 0x50, 0xc0 \
  0xe0, 0x70, 0x38, 0x1c, 0x0e, 0x07, 0x03, 0x01

.crudeMemoryBlock Bitfield8ImmediateVector128
0103050C183050C0 E070381C0E070301
.crudeEndMemoryBlock
  stackFullTest Bitfield8ImmediateVector128(%rip), count=1
  ok1 "Bitfield8ImmediateVector128", "oof"
  // PrintStackMessage "Bitfield8ImmediateVector128"


  Bitfield8negate
.crudeMemoryBlock Bitfield8negate
FFFDFBF4E8D0B040 2090C8E4F2F9FDFF
.crudeEndMemoryBlock
  stackFullTest Bitfield8negate(%rip), count=1
  ok1 "Bitfield8negate", "oof"
  // PrintStackMessage "Bitfield8negate"

  Bitfield8Immediate 0xFF
  Bitfield8add
.crudeMemoryBlock Bitfield8add
FEFCFAF3E7CFAF3F 1F8FC7E3F1F8FCFE
.crudeEndMemoryBlock
  stackFullTest Bitfield8add(%rip), count=1
  ok1 "Bitfield8add", "oof"
  // PrintStackMessage "Bitfield8add"


  ClearDataStack

  Bitfield8ImmediateVector128 \
  0x01, 0x03, 0x05, 0x0c, 0x18, 0x30, 0x50, 0xc0 \
  0xe0, 0x70, 0x38, 0x1c, 0x0e, 0x07, 0x03, 0x01

  Bitfield8ImmediateVector128 \
  0x00, 0x03, 0x04, 0x0c, 0x18, 0x30, 0x4f, 0xc0 \
  0xe0, 0x6f, 0x38, 0x1b, 0x0e, 0x06, 0x03, 0x00

  Bitfield64Immediate 2
  Bitfield64Index
  Bitfield64Immediate 2
  Bitfield64Index
.crudeMemoryBlock UpcomingComparison
0003040c18304fc0 e06f381b0e060300
0103050c183050c0 e070381c0e070301
0003040c18304fc0 e06f381b0e060300
0103050c183050c0 e070381c0e070301
.crudeEndMemoryBlock
  stackFullTest UpcomingComparison(%rip), count=4
  ok1 "Upcoming comparison between zomgoodness and hurblgurble", "oof"
  // PrintStackMessage "UpcomingComparison"

  Bitfield8equal
.crudeMemoryBlock Bitfield8equal
00FF00FFFFFF00FF FF00FF00FF00FF00
0003040c18304fc0 e06f381b0e060300
0103050c183050c0 e070381c0e070301
.crudeEndMemoryBlock
  stackPartialTest Bitfield8equal(%rip), count=1
  ok1 "Bitfield8equal", "oof"
  // PrintStackMessage "Bitfield8equal"

  DataStackRetreat
  Bitfield64Immediate 2
  Bitfield64Index
  Bitfield64Immediate 2
  Bitfield64Index

  SignedInteger8greaterThan
.crudeMemoryBlock SignedInteger8greaterThan
FF00FF000000FF00 00FF00FF00FF00FF
0003040c18304fc0 e06f381b0e060300
0103050c183050c0 e070381c0e070301
.crudeEndMemoryBlock
  stackPartialTest SignedInteger8greaterThan(%rip), count=1
  ok1 "SignedInteger8greaterThan", "oof"
  // PrintStackMessage "SignedInteger8greaterThan"

  ClearDataStack

.crudeMemoryBlock zomg
2597C00002C3527C C300C3C32400C364
F2C30CF7F25CF1F6 AAA94E0406CF8245
.crudeEndMemoryBlock
  zomg2 = zomg+SIMD_WIDTH
  _DataStackPushFromRAM zomg2(%rip)
  _DataStackPushFromRAM zomg(%rip)

  // PrintStackMessage "About to cast zomg-1 to boolean."

  Bitfield8castToBoolean
  // PrintStackMessage "Bitfield8castToBoolean"
.crudeMemoryBlock Bitfield8castToBoolean
FFFFFF00FFFFFFFF FF00FFFFFF00FFFF
.crudeEndMemoryBlock
  stackPartialTest Bitfield8castToBoolean(%rip), count=1
  ok1 "Bitfield8castToBoolean", "oof"

  Bitfield64Immediate 0
  Exchange
  // PrintStackMessage "About to Bitfield8MaskBlend"

  Bitfield8MaskBlend
  // PrintStackMessage "Bitfield8MaskBlend done"
.crudeMemoryBlock Bitfield8MaskBlend
000000F700000000 00A9000000CF0000
.crudeEndMemoryBlock
  stackPartialTest Bitfield8MaskBlend(%rip), count=1
  ok1 "Bitfield8MaskBlend", "oof"

  // PrintStackMessage "Bitfield8MaskBlend"

  Bitfield64Immediate 0
  systemExit
