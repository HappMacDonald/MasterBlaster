#include "TestAnythingProtocolProducer.h"

.text

.globl _start
_start:
  EndAlienCallStackFrame

  // only lowest 8 bits will survive,
  // but hardware limitations require me
  // to pass this value around as 32-bit or greater.
  mov $0xac, %eax
  _Bitfield8DataStackPushGeneral %eax
  PrintStackMessage "_Bitfield8DataStackPushGeneral value %ax"

  ClearDataStack
  PrintStackMessage "ClearDataStack"

  Bitfield8Immediate 0x10
  PrintStackMessage "Bitfield8Immediate $0x10"

  ClearDataStack
  Bitfield8ImmediateVector128 \
  0x01, 0x03, 0x05, 0x0c, 0x18, 0x30, 0x50, 0xc0 \
  0xe0, 0x70, 0x38, 0x1c, 0x0e, 0x07, 0x03, 0x01

  PrintStackMessage "Bitfield8ImmediateVector128 zomgoodness"

  Bitfield8negate
  PrintStackMessage "Bitfield8negate zomgoodness"

  Bitfield8Immediate 0xFF
  Bitfield8add
  PrintStackMessage "Bitfield8add zomgoodness + -1"

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
  PrintStackMessage "Upcoming comparison between zomgoodness and hurblgurble"

  Bitfield8equal
  PrintStackMessage "Bitfield8equal"

  DataStackRetreat
  Bitfield64Immediate 2
  Bitfield64Index
  Bitfield64Immediate 2
  Bitfield64Index

  SignedInteger8greaterThan
  PrintStackMessage "SignedInteger8greaterThan"

  DataStackRetreatTwice
  PrintStackMessage "About to cast zomg-1 to boolean."

  Duplicate
  Bitfield8castToBoolean
  PrintStackMessage "Bitfield8castToBoolean"

  Bitfield64Immediate 0
  Exchange
  PrintStackMessage "About to Bitfield8MaskBlend"

  Bitfield8MaskBlend
  PrintStackMessage "Bitfield8MaskBlend"

  systemExit
