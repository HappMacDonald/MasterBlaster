// 2022-03-31 Current status:
// I think I need to work out macros to either handle or act as building
// blocks to handle immediate values, and constant declaration.

// SSE-related values.
// Later expansion to AVX & AVX512 will use .ifdef to define these per platform.
SIMD_WIDTH = $16

// Linux ABI Syscall identifiers
// Later expansion to Windows/BSD/Mac will use .ifdef to define these per platform.
ALIEN_INTEGER64_ARGUMENT1 = %rdi
ALIEN_INTEGER64_ARGUMENT2 = %rsi
ALIEN_INTEGER64_ARGUMENT3 = %rdx
ALIEN_INTEGER64_ARGUMENT4 = %rcx
ALIEN_INTEGER64_ARGUMENT5 = %r8
ALIEN_INTEGER64_ARGUMENT6 = %r9
ALIEN_INTEGER64_RETURN1 = %rax
ALIEN_INTEGER64_RETURN_LS = %rax
ALIEN_INTEGER64_RETURN2 = %rdx
ALIEN_INTEGER64_RETURN_MS = %rdx
SYSCALL_REGISTER = %rax
SYSCALL_SYS_EXIT = $60

// x64 values
STACK_BASE_POINTER = %rbp
STACK_POINTER = %rsp
.macro TOP_OF_STACK
  (STACK_POINTER)
.endm

// sensitive to SIMD_WIDTH :P  I'm too lazy to look up how to do gas variable arithmetic right now.
STACK0 = "(STACK_POINTER)"
STACK1 = "-16(STACK_POINTER)"
STACK2 = "-32(STACK_POINTER)"
STACK3 = "-48(STACK_POINTER)"
STACK4 = "-64(STACK_POINTER)"
STACK5 = "-80(STACK_POINTER)"
STACK6 = "-96(STACK_POINTER)"
STACK7 = "-112(STACK_POINTER)"

.data
// Align to start of a cache line. (or center of a very large one perhaps?)
.balign 64
.global MSBIT_SET
MSBIT_SET:
// SSE uses 2, AVX1/2 uses 4, and AVX512 uses all 8 of these quadwords.
  .quad 0x8000000000000000
  .quad 0x8000000000000000
  .quad 0x8000000000000000
  .quad 0x8000000000000000
  .quad 0x8000000000000000
  .quad 0x8000000000000000
  .quad 0x8000000000000000
  .quad 0x8000000000000000

.global ALL_LANES_0x40
ALL_LANES_0x40:
// SSE uses 2, AVX1/2 uses 4, and AVX512 uses all 8 of these quadwords.
  .quad 0x40, 0x40
  .quad 0x40, 0x40
  .quad 0x40, 0x40
  .quad 0x40, 0x40



// Does not return, does not tidy stack. Yields control back to the calling shell.
.macro systemExit
  // mov SYSCALL_SYS_EXIT, SYSCALL_REGISTER
  mov $60, SYSCALL_REGISTER
  movq TOP_OF_STACK, ALIEN_INTEGER64_ARGUMENT1
  // movq (%rsp),ALIEN_INTEGER64_ARGUMENT1
  // don't need to pop stack or fix parent frame.. just bail! :D
  syscall
.endm

// Is this Linux only, or does it also work the same for Windows/BSD/Mac?
// This macro doesn't try to handle inbound arguments, but should be
// able to co-operate with something that does.
.macro EndAlienStackFrame
  push STACK_BASE_POINTER
  mov STACK_POINTER, STACK_BASE_POINTER // End parent's stack frame, start new one.
.endm

// Is this Linux only, or does it also work the same for Windows/BSD/Mac?
// This macro is compatible with already-prepared return values through Registers,
// and/or registers-pointing-to-RAM. It is not compatible with return
// values being passed through the stack.
.macro ReturnToAlienCaller
  ClearStack
  pop STACK_BASE_POINTER
  ret
.endm

.macro ClearStack
  mov STACK_BASE_POINTER, STACK_POINTER
.endm

// .macro SIMDPop register=%xmm0 // Pop into a register
//   // shrink stack pointer upward width of a SIMD register.
//   movdqa TOP_OF_STACK, \register
//   SIMDPopDestructive
// .endm

.macro SIMDPush register=%xmm0
  // grow stack pointer downward width of a SIMD register.
  sub SIMD_WIDTH, STACK_POINTER
  movdqa \register, TOP_OF_STACK
.endm

.macro SIMDPopDestructive
  // shrink stack pointer upward width of a SIMD register.
  add \SIMD_WIDTH, STACK_POINTER
.endm

.macro SetAllBitsZero register=%xmm7
  pxor \register, \register
.endm

.macro SetAllBitsOne register=%xmm7
  pcmpeqd \register, \register
.endm

// NEW top of stack => %xmm0
// 0b0 x 128 => %xmm1
// input 1 unit, output 1 unit
// If output high bit set, then input was a valid UnsignedInteger63.
.macro UnsignedInteger63negate
  movdqa STACK0, %xmm1
  SetAllBitsZero register=%xmm0
  psubq %xmm0, %xmm1
  movdqa %xmm0, STACK0
.endm

// NEW top of stack => %xmm0
// old Stack1 => %xmm1
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
.macro UnsignedInteger63add
  movdqa STACK0, %xmm0
  movdqa STACK1, %xmm1
  paddq %xmm0, %xmm1
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// NEW top of stack => %xmm0
// Clobbered => %xmm1, %xmm2, %xmm3
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
.macro UnsignedInteger63multiply
  movdqa STACK0, %xmm0
  movdqa STACK1, %xmm1
  movdqa  %xmm0, %xmm3
  movdqa  %xmm0, %xmm2
  psrlq   $32, %xmm3
  pmuludq %xmm1, %xmm2
  pmuludq %xmm1, %xmm3
  psrlq   $32, %xmm1
  pmuludq %xmm1, %xmm0
  paddq   %xmm3, %xmm0
  psllq   $32, %xmm0
  paddq   %xmm2, %xmm0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then TRUE. Otherwise FALSE.
// WARNING: always ensure your boolean registers are pure 0 or 1.
// This macro guarantees that on output.
.macro UnsignedInteger63equal
  movdqa STACK0, %xmm0
  pcmpeqq %xmm0, STACK1
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// test STACK1 > STACK0
// EG: (1 2 3 4) greaterThan -> (1 2 FALSE)
// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then TRUE. Otherwise FALSE.
// WARNING: always ensure your boolean registers are pure 0 or 1.
// This macro guarantees that on output.
.macro UnsignedInteger63greaterThan
  movdqa STACK1, %xmm0
  pcmpgtq %xmm0, STACK0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the right (lesser significance).
// as of 2022-04-02, not yet clear if STACK0 is interpreted as only first lane
// applying to all lanes of STACK1, or if each lane gets it's own offset
// from STACK0. :o
// EG: (1 2 0x300 4) bitShiftDownZeroPad -> (1 2 0x30)
// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then count must have been zero and source unchanged.
.macro UnsignedInteger63bitShiftDownZeroPad
  movdqa STACK1, %xmm0
  psrlq  %xmm0, STACK0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the left (greater significance).
// as of 2022-04-02, not yet clear if STACK0 is interpreted as only first lane
// applying to all lanes of STACK1, or if each lane gets it's own offset
// from STACK0. :o
// EG: (1 2 0x300 4) bitShiftUpZeroPad -> (1 2 0x3000)
// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
.macro UnsignedInteger63bitShiftUpZeroPad
  movdqa STACK1, %xmm0
  psllq  %xmm0, STACK0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the right (lesser significance).
// Bits shifted off the end of each item will be put into most significant
// positions. No extra positions such as Carry are traded from
// (but I think Carry does somehow get traded to? How that lanes I cannot be sure though..)
// as of 2022-04-02, not yet clear if STACK0 is interpreted as only first lane
// applying to all lanes of STACK1, or if each lane gets it's own offset
// from STACK0. :o
// EG: (1 2 0x34 4) bitRotateDown -> (1 2 0x4000000000000003)
// NEW top of stack => %xmm0
// Cobbered: %xmm1, %xmm2
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
.macro UnsignedInteger63bitRotateDown
  movdqa STACK0, %xmm2 // Number of bits to rotate
  movdqa STACK1, %xmm0 // Value to modify
  movdqa STACK1, %xmm1 // Value to modify (copy)
  psrlq  %xmm0, %xmm2 // shift first copy right with zero fill
  psubq %xmm2, ALL_LANES_0x40(%rip) // invert number of bits to rotate
  psllq  %xmm1, %xmm2 // shift second copy left inverse number of bits with zero fill
  por %xmm0, %xmm1 // Or the two shifted copies together to form a rotated copy.
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the right (lesser significance).
// Bits shifted off the end of each item will be put into most significant
// positions. No extra positions such as Carry are traded from
// (but I think Carry does somehow get traded to? How that lanes I cannot be sure though..)
// as of 2022-04-02, not yet clear if STACK0 is interpreted as only first lane
// applying to all lanes of STACK1, or if each lane gets it's own offset
// from STACK0. :o
// EG: (1 2 0x34 4) bitRotateDown -> (1 2 0x4000000000000003)
// NEW top of stack => %xmm0
// Cobbered: %xmm1, %xmm2
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
.macro UnsignedInteger63bitRotateUp
  movdqa STACK0, %xmm2 // Number of bits to rotate
  movdqa STACK1, %xmm0 // Value to modify
  movdqa STACK1, %xmm1 // Value to modify (copy)
  psllq  %xmm0, %xmm2 // shift first copy left with zero fill
  psubq %xmm2, ALL_LANES_0x40(%rip) // invert number of bits to rotate
  psrlq  %xmm1, %xmm2 // shift second copy right inverse number of bits with zero fill
  por %xmm0, %xmm1 // Or the two shifted copies together to form a rotated copy.
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// STACK0 will be set to all 0 if high bit is 0, or all 1 if high bit is 1.
// as of 2022-04-02, not yet clear if STACK0 is interpreted as only first lane
// applying to all lanes of STACK1, or if each lane gets it's own offset
// from STACK0. :o
// EG: (-1) castToBoolean -> (0xFFFFFFFFFFFFFFFF) aka Boolean TRUE
// EG: (0) castToBoolean -> (0) aka Boolean FALSE
// EG: (0xFFFFF) -> (0) aka Boolean FALSE
// EG: (0x8000000000000000) -> (0xFFFFFFFFFFFFFFFF) aka Boolean TRUE
// NEW top of stack => %xmm0
// Clobbered => %xmm1
// All bits set => %xmm7
// input 1 unit, output 1 unit
.macro UnsignedInteger63castToBoolean
  movdqa STACK0, %xmm0 // Integer63 to cast
  SetAllBitsOne // fill bits on %xmm7
  movdqa MSBIT_SET_64(%rip), %xmm1
  pxor %xmm1, %xmm7 // transforms 0x80..00 to 0x7F..FF
  pcmpgtq %xmm0, %xmm1 // Is subject greater than largest Integer63?
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

##### End of macros



.text
.globl _start
_start:
  mov $0x0123456789abcdef, %rax
  push %rax
  // UnsignedInteger63negate
  systemExit
