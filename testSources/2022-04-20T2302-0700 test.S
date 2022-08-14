#include "libmb_s.h"
.globl _start
_start:
  EndAlienCallStackFrame
  Bitfield8ImmediateVector128 69, 124, 177, 196, 115, 21, 174, 68, 89, 237, 31, 185, 94, 153, 185, 192
  Bitfield8ImmediateVector128 80, 213, 65, 217, 120, 111, 48, 209, 130, 77, 35, 146, 143, 183, 238, 27
  PrintStackMessage "Inputs"
  movq %rsp, %xmm0
  BooleanAnd
  PrintStackMessage "Boolean And output"
  SystemExit


