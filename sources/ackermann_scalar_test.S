.include "libmb_s.h"

.data
buffer: .skip 20

.text
.globl _start
_start:
  push $4
  push $1
  call Ackermann
  pop %rdx // clear arguments from stack
  pop %rdx
  mov %rax, %rdi // Number to print
  leaq buffer(%rip), %rsi
  call _unsignedIntegerToStringBase10
  //%rax has new pointer to string
  //%rdx has length of new string
  putMemoryMacro \
    messageLocation=(%rax) \
  , length=%rdx

  systemExitMacro

// 16(%rsp) => %rax = m
//  8(%rsp) => %rcx = n
// Output returned via %rax
Ackermann:
  mov 16(%rsp), %rax
  mov  8(%rsp), %rcx
  test %rax, %rax // m==0?
  jne B
  mov %rcx, %rax // yes.. return n+1.
  add $1, %rax
  ret
B:test %rcx, %rcx // n==0?
  jne C
  // yes.. return Ackermann(m-1, 1)
  sub $1, %rax
  push %rax
  push $1
  call Ackermann
  pop %rdx // clear arguments from stack
  pop %rdx
  ret
C:// no, so return Ackermann(m-1, Ackermann(m, n-1))
  push %rax // store m
  sub $1, %rcx
  push %rcx // store n
  call Ackermann
  pop %rdx // clear arguments from stack
  pop %rdx
  // %rax now has the result of the interior ackermann function
  mov 16(%rsp), %rdx // restore the m value I got from my caller
  sub $1, %rdx
  push %rdx // m for exterior ackermann call (m-1)
  push %rax // result of interior call is n for exterior call.
  call Ackermann
  pop %rdx // clear arguments from stack
  pop %rdx
  ret
