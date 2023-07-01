.include "libmb_s.h"

.data
.global MEMORY_SCRATCHPAD
MEMORY_SCRATCHPAD:
.skip 512

#define ANSICodeToClearLineLength 5
ANSICodeToClearLine:
  .byte 13,0x1B
  .string "[2K"

// This code was cut/pasted out of another file when it was no longer needed.
// In this file it will needs some headers and junk to run again. :/

// Testing stack size
  xor %rbx, %rbx // 0 out %rbx
StackTestLoop:
  add $1, %rbx
  push %rbx
  mov %rbx, %rdi // rbx counter into rdi arg1
  and $65535, %rdi 
  jne StackTestLoop // Only report count every 2^16 loops

//Reset terminal line
  mov $STDOUT, %rdi
  lea ANSICodeToClearLine(%rip), %rsi
  mov $ANSICodeToClearLineLength, %rdx
  mov $sys_write, %rax
  syscall

//Write current count
  mov %rbx, %rdi // rbx counter into rdi arg1
  leaq MEMORY_SCRATCHPAD(%rip), %rsi // memory sandbox into rsi arg2
  call _unsignedIntegerToStringBase10
  // %rax has new pointer to string
  // %rdx has length of new string
  putMemoryMacro messageLocation=(%rax),length=%rdx

  cmpq $0xFFFFF, %rbx
  jl StackTestLoop

  putNewlineMacro
