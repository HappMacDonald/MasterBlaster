#include "TestAnythingProtocolProducer_s.h"

# Warning: pending name clarification, but in the meantime:
# These macros accept TWO vectors of various lane sizes and types of value,
# and render a blended result containing only the largest or smallest
# values found in each lane. Do NOT confuse this with something that
# would take zero inputs and render the largest or smallest *possible* values
# of a given type, as I did at one point in time. 😣

.text
.globl _start
_start:
  EndAlienCallStackFrame

  plan1 8 "minmax tests"

.memoryBlock Expected_MinimumSignedInteger64
FFFFFFFFFFFFFFFF 0300000000000000
.endMemoryBlock
  Bitfield64ImmediateVector128 -1, 7
  Bitfield64ImmediateVector128 3, 3
  // PrintStackMessage "Inputs to MinimumSignedInteger64:"
  MinimumSignedInteger64
  // PrintStackMessage "Output to MinimumSignedInteger64:"
  stackFullTest Expected_MinimumSignedInteger64(%rip), count=1
  ok1 "MinimumSignedInteger64", "oof"
  ClearDataStack

.memoryBlock Expected_MinimumUnsignedInteger64
0300000000000000 0300000000000000
.endMemoryBlock
  Bitfield64ImmediateVector128 -1, 3
  Bitfield64ImmediateVector128 3, 7
  // PrintStackMessage "Inputs to MinimumUnsignedInteger64:"
  MinimumUnsignedInteger64
  // PrintStackMessage "Output to MinimumUnsignedInteger64:"
  stackFullTest Expected_MinimumUnsignedInteger64(%rip), count=1
  ok1 "MinimumUnsignedInteger64", "oof"
  ClearDataStack

.memoryBlock Expected_MinimumSignedInteger8
CB	D1	FB	07	DB	E1	EF	13	E9	EF	E1	0B	D7	FB	D1	02
.endMemoryBlock
  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  // PrintStackMessage "Inputs to MinimumSignedInteger8:"
  MinimumSignedInteger8
  // PrintStackMessage "Output to MinimumSignedInteger8:"
  stackFullTest Expected_MinimumSignedInteger8(%rip), count=1
  ok1 "MinimumSignedInteger8", "oof"
  ClearDataStack

.memoryBlock Expected_MinimumUnsignedInteger8
CB	03	2B	07	DB	0D	1D	13	E9	1D	0D	0B	D7	2B	03	02
.endMemoryBlock
  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  // PrintStackMessage "Inputs to MinimumUnsignedInteger8:"
  MinimumUnsignedInteger8
  // PrintStackMessage "Output to MinimumUnsignedInteger8:"
  stackFullTest Expected_MinimumUnsignedInteger8(%rip), count=1
  ok1 "MinimumUnsignedInteger8", "oof"
  ClearDataStack

.memoryBlock Expected_MaximumSignedInteger64
0300000000000000 0700000000000000
.endMemoryBlock
  Bitfield64ImmediateVector128 -1, 7
  Bitfield64ImmediateVector128 3, 3
  // PrintStackMessage "Inputs to MaximumSignedInteger64:"
  MaximumSignedInteger64
  // PrintStackMessage "Output to MaximumSignedInteger64:"
  stackFullTest Expected_MaximumSignedInteger64(%rip), count=1
  ok1 "MaximumSignedInteger64", "oof"
  ClearDataStack

.memoryBlock Expected_MaximumUnsignedInteger64
FFFFFFFFFFFFFFFF 0700000000000000
.endMemoryBlock
  Bitfield64ImmediateVector128 -1, 3
  Bitfield64ImmediateVector128 3, 7
  // PrintStackMessage "Inputs to MaximumUnsignedInteger64:"
  MaximumUnsignedInteger64
  // PrintStackMessage "Output to MaximumUnsignedInteger64:"
  stackFullTest Expected_MaximumUnsignedInteger64(%rip), count=1
  ok1 "MaximumUnsignedInteger64", "oof"
  ClearDataStack

.memoryBlock Expected_MaximumSignedInteger8
FE	03	2B	29	F5	0D	1D	17	ED	1D	0D	25	F9	2B	03	35
.endMemoryBlock
  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  // PrintStackMessage "Inputs to MaximumSignedInteger8:"
  MaximumSignedInteger8
  // PrintStackMessage "Output to MaximumSignedInteger8:"
  stackFullTest Expected_MaximumSignedInteger8(%rip), count=1
  ok1 "MaximumSignedInteger8", "oof"
  ClearDataStack

.memoryBlock Expected_MaximumUnsignedInteger8
FE	D1	FB	29	F5	E1	EF	17	ED	EF	E1	25	F9	FB	D1	35
.endMemoryBlock
  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  // PrintStackMessage "Inputs to MaximumUnsignedInteger8:"
  MaximumUnsignedInteger8
  // PrintStackMessage "Output to MaximumUnsignedInteger8:"
  stackFullTest Expected_MaximumUnsignedInteger8(%rip), count=1
  ok1 "MaximumUnsignedInteger8", "oof"
  ClearDataStack
  // movl $0, 0xfa17(%rbx)

  Bitfield64Immediate 0
  SystemExit
