.include "libmb_s.h"

	.globl _start


.text
_start:
  movabsq $0xFFFFFFFFFFFFFFFF, %rdi
  leaq numberPrintBuffer(%rip), %rsi
# call _unsignedIntegerToStringBase16
  call _unsignedIntegerToStringBase10
  mov %rax, %rdi # move memory location from ret1 into arg1
  mov %rdx, %rsi # move length from ret2 into arg2
  mov $STDOUT, %rdx # define recently vacated arg3
  call putMemoryProcedure
  putNewlineMacro
  systemExitMacro 69

# Data

  .data
numberPrintBuffer:
  .skip 20

