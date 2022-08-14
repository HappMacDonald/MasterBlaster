#include "libmb_s.h"

.text

factorial:
  Duplicate
  Duplicate
  Immediate 1
  UnsignedInteger63GreaterThan
  Exchange
  leaq factorialInner(%rip), %rax
  DataStackPushGeneral %rax
  ConditionalMaskBlendOneArgument
  UnsignedInteger63Multiply
  ret

factorialInner:
  Immediate -1
  UnsignedInteger63Add
  call factorial
  ret

.globl _start
_start:
  // Treating inbound rbp=0 as parent's stack frame.
  EndAlienCallStackFrame
  
  ImmediateVector 3,20
PrintStackMessage "input"
  call factorial
PrintStackMessage "Output"
  systemExit