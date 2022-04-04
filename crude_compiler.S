.include "libmb_s.h"

// 2022-04-03 Current status:
// I'm debugging Index verb, which is just now really starting to
// rock and roll thanks to the magic (and allegedly slow! pextrq/pinsrq
// opcodes.
// Index into my current test stack of 1 position, or 2 position works.
// 3 position is failing, where the target has different values in
// each lane so I need to find out why.
// I also need to test "different indices in each lane" after that.

// SSE-related values.
// Later expansion to AVX & AVX512 will use .ifdef to define these per platform.
// SIMD_WIDTH = 16
#define SIMD_WIDTH 16
#define SIMD_META_WIDTH 4 // how many bits long is the number describing the width
#define DATA_SIZE_IN_BITS 64
#define DATA_SIZE_IN_BITS_MINUS_ONE 63
#define DATA_METASIZE_IN_BITS 6 // how many bits long is the number describing the size
#define DATA_SIZE_IN_BYTES 8

// Linux ABI Syscall identifiers
// Later expansion to Windows/BSD/Mac will use .ifdef to define these per platform.
#define ALIEN_INTEGER64_ARGUMENT1 rdi
#define ALIEN_INTEGER64_ARGUMENT2 rsi
#define ALIEN_INTEGER64_ARGUMENT3 rdx
#define ALIEN_INTEGER64_ARGUMENT4 rcx
#define ALIEN_INTEGER64_ARGUMENT5 r8
#define ALIEN_INTEGER64_ARGUMENT6 r9
#define ALIEN_INTEGER64_RETURN1 rax
#define ALIEN_INTEGER64_RETURN_LS rax
#define ALIEN_INTEGER64_RETURN2 rdx
#define ALIEN_INTEGER64_RETURN_MS rdx
#define SYSCALL_REGISTER rax
#define SYSCALL_SYS_EXIT 60

// x64 values
#define STACK_BASE_POINTER rbp
#define STACK_POINTER rsp
#define TOP_OF_STACK (%STACK_POINTER)

// sensitive to SIMD_WIDTH :P  I'm too lazy to look up how to do gas variable arithmetic right now.
#define STACK0 (%STACK_POINTER)
#define STACK0_5 8(%STACK_POINTER)
#define STACK1 16(%STACK_POINTER)
#define STACK1_5 24(%STACK_POINTER)
#define STACK2 32(%STACK_POINTER)
#define STACK2_5 40(%STACK_POINTER)
#define STACK3 48(%STACK_POINTER)
#define STACK3_5 56(%STACK_POINTER)
#define STACK4 64(%STACK_POINTER)
#define STACK4_5 72(%STACK_POINTER)
#define STACK5 80(%STACK_POINTER)
#define STACK5_5 88(%STACK_POINTER)
#define STACK6 96(%STACK_POINTER)
#define STACK6_5 104(%STACK_POINTER)
#define STACK7 112(%STACK_POINTER)
#define STACK7_5 120(%STACK_POINTER)

.data
// Align to start of a cache line. (or center of a very large one perhaps?)
.balign 64
.global ALL_LANES_0x01
ALL_LANES_0x01:
  .quad 1,1
  .quad 1,1
  .quad 1,1
  .quad 1,1

.global ALL_LANES_0x3F
ALL_LANES_0x3F: // That's 63dec, or 0011 1111 binary
  .quad 0x3F,0x3F
  .quad 0x3F,0x3F
  .quad 0x3F,0x3F
  .quad 0x3F,0x3F

.global MEMORY_SCRATCHPAD
MEMORY_SCRATCHPAD:
.skip 512

#define COLON_LENGTH 1
COLON:
  .string ":"




// Does not return, does not tidy stack. Yields control back to the calling shell.
.macro systemExit
  // mov SYSCALL_SYS_EXIT, %SYSCALL_REGISTER
  mov $SYSCALL_SYS_EXIT, %SYSCALL_REGISTER
  movq TOP_OF_STACK, %ALIEN_INTEGER64_ARGUMENT1
  // movq (%rsp),%ALIEN_INTEGER64_ARGUMENT1
  // don't need to pop stack or fix parent frame.. just bail! :D
  syscall
.endm

// Is this Linux only, or does it also work the same for Windows/BSD/Mac?
// This macro doesn't try to handle inbound arguments, but should be
// able to co-operate with something that does.
.macro EndAlienStackFrame
  push %STACK_BASE_POINTER
  push %STACK_BASE_POINTER
  mov %STACK_POINTER, %STACK_BASE_POINTER // End parent's stack frame, start new one.
.endm

// Is this Linux only, or does it also work the same for Windows/BSD/Mac?
// This macro is compatible with already-prepared return values through Registers,
// and/or registers-pointing-to-RAM. It is not compatible with return
// values being passed through the stack.
.macro ReturnToAlienCaller
  ClearStack
  pop %STACK_BASE_POINTER
  ret
.endm

.macro ClearStack
  mov %STACK_BASE_POINTER, %STACK_POINTER
.endm

// .macro SIMDPop register=%xmm0 // Pop into a register
//   // shrink stack pointer upward width of a SIMD register.
//   movdqa TOP_OF_STACK, \register
//   SIMDPopDestructive
// .endm

.macro SIMDPush register=%xmm0
  // grow stack pointer downward width of a SIMD register.
  subq $SIMD_WIDTH, %STACK_POINTER
  movdqa \register, STACK0
.endm

.macro SIMDPopDestructive
  // shrink stack pointer upward width of a SIMD register.
  addq $SIMD_WIDTH, %STACK_POINTER
.endm

// Copies the value in a 64 bit scalar aka "general purpose" register
// directly into EVERY lane of an SIMD register.
// Currently only coded for 128 bit registers,
// I need to dream up the best way to make this more general
// for future expansion.
// luckily, in AVX2 and AVX512 there's a single opcode for it lel!
.macro ScalarBroadcastToSIMD scalarRegister:req receiveRegister:req
  pinsrq $0, \scalarRegister, \receiveRegister
  pinsrq $1, \scalarRegister, \receiveRegister
.endm

// Gathers all of the Integer64 data found at each memory location in each lane of indexRegister and loads those into the same lanes of receiveRegister.
// No clobbering goes on here.
.macro SIMDGather indexRegister=%xmm1 receiveRegister=%xmm0
  pextrq $0, \indexRegister, %rax
  pinsrq $0, (%rax), \receiveRegister
  pextrq $1, \indexRegister, %rax
  pinsrq $1, (%rax), \receiveRegister
.endm

// .macro SIMDScatter indexRegister=%xmm1 sendRegister=%xmm0 tempRegister=%xmm2
//   movdqa (\indexRegister), \sendRegister
// .endm

// Pushes current length of stack onto top of stack,
// which in turn makes it one longer and instantly out of date lol.
// EG: () Count (0)
// EG: (9 9 9) Count (9 9 9 3)
// Current count => Top of stack (all lanes) and %rax
.macro Count
  mov %STACK_BASE_POINTER, %rax
  sub %STACK_POINTER, %rax
  sarl $SIMD_META_WIDTH, %eax
  push %rax // Lane 2
  push %rax // Lane 1
.endm

// Pushes a duplicate of the current top of stack onto the stack.
// EG: (1 2 3 4) Duplicate (1 2 3 4 4)
// () Duplicate <like all "reads stack contents" ops, undefined probable crash>
// New (and identical old) top of stack => xmm0
.macro Duplicate
  movdqa STACK0, %xmm0
  SIMDPush
.endm

// Swaps the top two positions on the stack, does not change stack length.
// EG: (1 2 3 4) Exchange (1 2 4 3)
// New top of stack (old second item) => xmm0
// New second item (old top of stack) => xmm1
.macro Exchange
  movdqa STACK0, %xmm1
  movdqa STACK1, %xmm0
  movdqa %xmm1, STACK1
  movdqa %xmm0, STACK0
.endm

// Replaces top of stack N with the stack element N places back.
// 0 does nothing (it fetches 0 and replaces 0 with 0..)
// 1+ gets older stack elements.
// Does not change the length of the stack.
// Ex: (11 22 33 44 3) index -> (11 22 33 44 22)
// Ex: (11 22 33 44 0) index -> (11 22 33 44 0)
// New top of stack => xmm0
// Current stack pointer => every lane of xmm1
.macro Index
  movdqa STACK0, %xmm0 // get index
  // turn into memory offset depths into the stack
  psllq $SIMD_META_WIDTH, %xmm0
  // Load stack pointer into xmm1
  // ScalarBroadcastToSIMD scalarRegister=%rsp,receiveRegister=%xmm1
  // least significant half gets most recent data lane
  pinsrq $0, %rsp, %xmm1
  // most significant half will be offset into lane 2
  addq $DATA_SIZE_IN_BYTES, %rsp
  pinsrq $1, %rsp, %xmm1
  subq $DATA_SIZE_IN_BYTES, %rsp
  // add offsets, yielding target locations in xmm0.
  paddq %xmm1, %xmm0
  SIMDGather indexRegister=%xmm0,receiveRegister=%xmm0
  movdqa %xmm0, STACK0
.endm

.macro SetAllBitsZero register=%xmm7
  pxor \register, \register
.endm

.macro SetAllBitsOne register=%xmm7
  pcmpeqd \register, \register
.endm

// Pop top of stack, calculate its two's compliment
// and push the result.
// NEW top of stack => %xmm0
// 0 in every lane => %xmm1
// input 1 unit, output 1 unit
// If output high bit set, then input was a valid UnsignedInteger63.
// Tested and passed 2022-04-03T02:23-07:00
.macro UnsignedInteger63negate
  movdqa STACK0, %xmm1
  SetAllBitsZero register=%xmm0
  psubq %xmm1, %xmm0
  movdqa %xmm0, STACK0
.endm

// NEW top of stack => %xmm0
// old Stack1 => %xmm1
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Tested and passed 2022-04-03T06:07-07:00
.macro UnsignedInteger63add
  movdqa STACK0, %xmm0
  movdqa STACK1, %xmm1
  paddq %xmm1, %xmm0
  movdqa STACK1, %Dereferencemm1
STACK1
  SIMDPopDestructive
.endm

// NEW top of stack => %xmm0
// Clobbered => %xmm1, %xmm2, %xmm3
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T08:15-07:00
// Does this method return signed or unsigned when input has high bit set?
// I think in two's compliment those two outcomes are always identical?
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
  pmuludq %xmm1, %Dereference0
%xmm0
  paddq   %xmm2, %xmm0
  psllq   $32, %Dereference0
STACK1
  SIMDPopDestructive
.endm

// NEW top of stack => %xmm0
// input 2 unit, output 1 unit
// If output high bit set, then TRUE. Otherwise FALSE.
// WARNING: always ensure your boolean registers are pure 0 or 1.
// This macro guarantees that on output.
// Tested and passed 2022-04-03T06:07-07:00
.macro UnsignedInteger63equal
  movdqa STACK0, %xmm0
  pcmpeqq STACK1, %xmm0
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
// Tested and passed 2022-04-03T06:07-07:00
.macro UnsignedInteger63greaterThan
  movdqa STACK1, %xmm0
  pcmpgtq STACK0, %xmm0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the right (lesser significance).
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x300 4) bitShiftDownZeroPad -> (1 2 0x30)
// NEW top of stack => %xmm0
// Normalized number of bits shifted (modulo number of data element bits) => %xmm1
// 0x3F => xmm2
// input 2 unit, output 1 unit
// If output high bit set, then count must have been zero and source unchanged.
// Tested and passed 2022-04-03T14:53-07:00
.macro UnsignedInteger63bitShiftDownZeroPad
  movq STACK0, %rbx
  movq STACK1, %rax
  shrx %rbx, %rax, %rax
  movq %rax, STACK1
  movq STACK0_5, %rbx
  movq STACK1_5, %rax
  shrx %rbx, %rax, %rax
  movq %rax, STACK1_5
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the left (greater significance).
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x300 4) bitShiftUpZeroPad -> (1 2 0x3000)
// NEW top of stack => %xmm0
// Normalized number of bits shifted (modulo number of data element bits) => %xmm1
// 0x3F => xmm2
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T14:53-07:00
.macro UnsignedInteger63bitShiftUpZeroPad
  movq STACK0, %rbx
  movq STACK1, %rax
  shlx %rbx, %rax, %rax
  movq %rax, STACK1
  movq STACK0_5, %rbx
  movq STACK1_5, %rax
  shlx %rbx, %rax, %rax
  movq %rax, STACK1_5
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the right (lesser significance).
// Bits shifted off the end of each item will be put into most significant
// positions. No extra positions such as Carry are traded from
// (but I think Carry does somehow get traded to? How that lanes I cannot be sure though..)
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x34 4) bitRotateDown -> (1 2 0x4000000000000003)
// NEW top of stack => %xmm0
// Cobbered: %xmm1, %xmm2
// 0x40 => %xmm3
// 0x3F => %xmm7
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T14:53-07:00
.macro UnsignedInteger63bitRotateDown
  movb STACK0, %cl
  movq STACK1, %rax
  ror %cl, %rax
  movq %rax, STACK1
  movb STACK0_5, %cl
  movq STACK1_5, %rax
  ror %cl, %rax
  movq %rax, STACK1_5
  SIMDPopDestructive
.endm

// STACK1 will be shifted by STACK0%64 bits to the right (lesser significance).
// Bits shifted off the end of each item will be put into most significant
// positions. No extra positions such as Carry are traded from
// (but I think Carry does somehow get traded to? How that lanes I cannot be sure though..)
// as of 2022-04-03, tested and it appears as though the lane1 bit shift value is the only one that gets applied to all lanes of the bit shift subject. Disgusting!
// My reaction: get bent, for SSE level I'll do the bit shift operations in general registers. For AVX+ levels I'll probably shuffle vectors.. but I WILL get per lane shifts like Gawd intended, ISA be damned!
// EG: (1 2 0x34 4) bitRotateDown -> (1 2 0x4000000000000003)
// NEW top of stack => %xmm0
// Cobbered: %xmm1, %xmm2
// input 2 unit, output 1 unit
// If output high bit set, then overflow UnsignedInteger63.
// Overflow without high bit set is also possible. Just.. don't overflow jeez.
// Tested and passed 2022-04-03T14:53-07:00
.macro UnsignedInteger63bitRotateUp
  movb STACK0, %cl
  movq STACK1, %rax
  rol %cl, %rax
  movq %rax, STACK1
  movb STACK0_5, %cl
  movq STACK1_5, %rax
  rol %cl, %rax
  movq %rax, STACK1_5
  SIMDPopDestructive
.endm

// STACK0 will be set to all 0 if high bit is 0, or all 1 if high bit is 1.
// EG: (-1) castToBoolean -> (0xFFFFFFFFFFFFFFFF) aka Boolean TRUE
// EG: (0) castToBoolean -> (0) aka Boolean FALSE
// EG: (0xFFFFF) -> (0) aka Boolean FALSE
// EG: (0x8000000000000000) -> (0xFFFFFFFFFFFFFFFF) aka Boolean TRUE
// NEW top of stack => %xmm0
// OLD top of stack => %xmm1
// input 1 unit, output 1 unit
// Tested and passed 2022-04-03T07:26-07:00
.macro UnsignedInteger63castToBoolean
  movdqa STACK0, %xmm1 // Integer63 to cast
  SetAllBitsZero register=%xmm0 // fill bits on %xmm1
  pcmpgtq %xmm1, %xmm0 // Is subject greater than 0?
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// EG: () BooleanPushTrue (TRUE)
// NEW top of stack (always TRUE) => %xmm0
// Tested and passed 2022-04-03T09:57-07:00
.macro BooleanPushTrue
  SetAllBitsOne register=%xmm0
  SIMDPush
.endm

// EG: () BooleanPushFalse (FALSE)
// NEW top of stack (always FALSE) => %xmm0
// Tested and passed 2022-04-03T09:57-07:00
.macro BooleanPushFalse
  SetAllBitsZero register=%xmm0
  SIMDPush
.endm

// EG: (1 2 3 TRUE) BooleanNot (1 2 3 FALSE)
// EG: (1 2 3 FALSE) BooleanNot (1 2 3 TRUE)
// EG: (1 2 3 [something that would cast to TRUE]) BooleanNot (1 2 3 [something that would cast to FALSE]), and vice versa.
// NEW top of stack (only pure valid boolean if input was) => %xmm0
// If you wish to force purity, simply run this command
// and then chase it with UnsignedInteger63castToBoolean: job done.
// Tested and passed 2022-04-03T09:57-07:00
.macro BooleanNot
  SetAllBitsOne register=%xmm0
  pxor STACK0, %xmm0
  movdqa %xmm0, STACK0
.endm

// EG: (1 7 TRUE FALSE) BooleanAnd (1 7 FALSE)
// EG: (6 9 FALSE TRUE) BooleanAnd (6 9 FALSE)
// EG: (666 FALSE FALSE) BooleanAnd (666 FALSE)
// EG: (999 TRUE TRUE) BooleanAnd (999 TRUE)
// NEW top of stack (only pure valid boolean if input was) => %xmm0
// If you wish to force purity, simply run this command
// and then chase it with UnsignedInteger63castToBoolean: job done.
// Tested and passed 2022-04-03T09:57-07:00
.macro BooleanAnd
  movdqa %xmm0, STACK0
  pand STACK1, %xmm0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// EG: (1 7 TRUE FALSE) BooleanOr (1 7 FALSE)
// EG: (6 9 FALSE TRUE) BooleanOr (6 9 TRUE)
// EG: (666 FALSE FALSE) BooleanOr (666 TRUE)
// EG: (999 TRUE TRUE) BooleanOr (999 TRUE)
// NEW top of stack (only pure valid boolean if input was) => %xmm0
// If you wish to force purity, simply run this command
// and then chase it with UnsignedInteger63castToBoolean: job done.
// Tested and passed 2022-04-03T09:57-07:00
.macro BooleanOr
  movdqa %xmm0, STACK0
  por STACK1, %xmm0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm

// EG: (1 7 TRUE FALSE) BooleanXor (1 7 TRUE)
// EG: (6 9 FALSE TRUE) BooleanXor (6 9 FALSE)
// EG: (666 FALSE FALSE) BooleanXor (666 FALSE)
// EG: (999 TRUE TRUE) BooleanXor (999 TRUE)
// NEW top of stack (only pure valid boolean if input was) => %xmm0
// If you wish to force purity, simply run this command
// and then chase it with UnsignedInteger63castToBoolean: job done.
// Tested and passed 2022-04-03T09:57-07:00
.macro BooleanXor
  movdqa %xmm0, STACK0
  pxor STACK1, %xmm0
  movdqa %xmm0, STACK1
  SIMDPopDestructive
.endm



##### End of macros



.text
.globl _start
_start:
  // Treating inbound rbp=0 as parent's stack frame.
  EndAlienStackFrame
  mov $0x8123456789ABCDEF, %rax
  // mov $0x8000000000000000, %rax
  // mov $0x0, %rax
  push %rax // Lane 2 pushed first
  // mov $0x1000000000000000, %rax
  mov $0x1020304050607080, %rax
  push %rax // Lane 1 pushed second
  // mov $0x8000000000000000, %rax
  // sub $1, %rax
  // mov $-1, %rax
  // push %rax // Lane 2 pushed first
  // mov $16, %rax
  // push %rax // Lane 1 pushed second
  // Count
  // Count
  mov $4, %rax
  push %rax // Lane 2 pushed first
  mov $8, %rax
  push %rax // Lane 1 pushed second
  // Index
  // BooleanPushFalse
  // BooleanPushTrue
  // BooleanPushTrue
  // BooleanPushFalse
  // BooleanXor
  // UnsignedInteger63castToBoolean
  UnsignedInteger63bitRotateUp

PrintStack:
  cmp %STACK_BASE_POINTER, %STACK_POINTER
  jae End

# Print Lane 1 of current stack top
  mov STACK0, %rdi
  // mov STACK1, %rdi
  leaq MEMORY_SCRATCHPAD(%rip), %rsi
  call unsignedIntegerToStringBase16
  //%rax has new pointer to string
  //%rdx has length of new string
  putMemoryMacro messageLocation=(%rax),length=%rdx

//Print a colon
  mov $STDOUT, %rdi
  lea COLON(%rip), %rsi
  mov $COLON_LENGTH, %rdx
  mov $sys_write, %rax
  syscall

# Print Lane 2 of current stack top
  mov 8(%STACK_POINTER), %rdi // STACK0 lane 2
  // mov 24(%STACK_POINTER), %rdi // STACK0 lane 2
  leaq MEMORY_SCRATCHPAD(%rip), %rsi
  call unsignedIntegerToStringBase16
  //%rax has new pointer to string
  //%rdx has length of new string
  putMemoryMacro messageLocation=(%rax),length=%rdx

  SIMDPopDestructive
  putNewlineMacro
  jmp PrintStack

End:
  // putNewlineMacro
  systemExit


