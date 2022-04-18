#include "libmb_s.h"

.data
.balign SIMD_WIDTH
inputBuffer:
.skip 4096
outputBuffer:
.skip 4096
.text

.globl _start
_start:
  EndAlienCallStackFrame



  systemExit
