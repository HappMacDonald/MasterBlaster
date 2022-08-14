#include "libmb_s.h"

# test results as of 2022-05-11T03:44-07:00:
# MinimumSignedInteger64 => correct
# MinimumUnsignedInteger64 => correct
# MinimumSignedInteger8 => correct!
# MinimumUnsignedInteger8 => correct!
# MaximumSignedInteger64 => correct
# MaximumUnsignedInteger64 => correct
# MaximumSignedInteger8 => correct!
# MaximumUnsignedInteger8 => correct!

.text
.globl _start
_start:
  EndAlienCallStackFrame
  
  Bitfield64ImmediateVector128 -1, 7
  Bitfield64ImmediateVector128 3, 3
  PrintStackMessage "Inputs to MinimumSignedInteger64:"
  MinimumSignedInteger64
  PrintStackMessage "Output to MinimumSignedInteger64:"
  ClearDataStack

  Bitfield64ImmediateVector128 -1, 3
  Bitfield64ImmediateVector128 3, 7
  PrintStackMessage "Inputs to MinimumUnsignedInteger64:"
  MinimumUnsignedInteger64
  PrintStackMessage "Output to MinimumUnsignedInteger64:"
  ClearDataStack

  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  PrintStackMessage "Inputs to MinimumSignedInteger8:"
  MinimumSignedInteger8
  PrintStackMessage "Output to MinimumSignedInteger8:"
  ClearDataStack

  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  PrintStackMessage "Inputs to MinimumUnsignedInteger8:"
  MinimumUnsignedInteger8
  PrintStackMessage "Output to MinimumUnsignedInteger8:"
  ClearDataStack

  Bitfield64ImmediateVector128 -1, 7
  Bitfield64ImmediateVector128 3, 3
  PrintStackMessage "Inputs to MaximumSignedInteger64:"
  MaximumSignedInteger64
  PrintStackMessage "Output to MaximumSignedInteger64:"
  ClearDataStack

  Bitfield64ImmediateVector128 -1, 3
  Bitfield64ImmediateVector128 3, 7
  PrintStackMessage "Inputs to MaximumUnsignedInteger64:"
  MaximumUnsignedInteger64
  PrintStackMessage "Output to MaximumUnsignedInteger64:"
  ClearDataStack

  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  PrintStackMessage "Inputs to MaximumSignedInteger8:"
  MaximumSignedInteger8
  PrintStackMessage "Output to MaximumSignedInteger8:"
  ClearDataStack

  Bitfield8ImmediateVector128 -2, 3, -5, 7, -11, 13, -17, 19, -23, 29, -31, 37, -41, 43, -47, 53
  Bitfield8ImmediateVector128 -53, -47, 43, 41, -37, -31, 29, 23, -19, -17, 13, 11, -7, -5, 3, 2
  PrintStackMessage "Inputs to MaximumUnsignedInteger8:"
  MaximumUnsignedInteger8
  PrintStackMessage "Output to MaximumUnsignedInteger8:"

  SystemExit

