#include "../include/libmb_s.h"

.text
# Procedures

# extern void putMemoryProcedure
# ( /*rdi*/ char *message
# , /*rsi*/ uint64_t length
# , /*rdx*/ uint64_t fileDescriptor
# );
.global putMemoryProcedure
putMemoryProcedure:
  mov %rdx, %rax # put file descriptor into temporary place
  mov %rsi, %rdx # put length into newly vacated syscall arg2
  mov %rdi, %rsi # put memory location into newly freed syscall arg1
  mov %rax, %rdi # dig fd from temporary location and put into newly vacated syscall arg3
  mov $sys_write, %rax # define syscall arg0
  syscall
  ret

# extern /*???*/ uint64_t getMemoryProcedure
# ( /*rdi*/ char *messageBuffer
# , /*rsi*/ uint64_t length
# , /*rdx*/ uint64_t fileDescriptor
# );
.global getMemoryProcedure
getMemoryProcedure:
  mov %rdx, %rax # put file descriptor into temporary place
  mov %rsi, %rdx # put length into newly vacated syscall arg2
  mov %rdi, %rsi # put memory location into newly freed syscall arg1
  mov %rax, %rdi # dig fd from temporary location and put into newly vacated syscall arg3
  mov $sys_read, %rax # define syscall arg0
  syscall
  ret

# Accepts arg1(%rdi)=number to convert to hex string, and arg2(%rsi)=16 byte buffer space.
# Returns ret1(%rax)=pointer to inside of buffer where RIGHT-ALIGNED answer sits,
# and ret2(%rdx)=total length of the answer string. That is not null-terminated.
# Unused portion of buffer left of ret1(%rax) is considered clobbered.
# extern struct MasterBlasterString _unsignedIntegerToStringBase16
# ( /*rdi*/ uint64_t valueToConvert
# , /*rsi*/ char resultBuffer[16] // Largest possible results are 16 digits
# );
.global _unsignedIntegerToStringBase16
_unsignedIntegerToStringBase16:
bufferLength = 16
bufferLast = bufferLength-1
  addq $bufferLast, %ALIEN_INTEGER64_ARGUMENT2 # advance arg2 to end of buffer
  # copy new arg2 to ret1, which will track the left side of answer.
  # arg2 will stay at the right side of answer.
  movq %ALIEN_INTEGER64_ARGUMENT2, %ALIEN_INTEGER64_RETURN1
0: #.loop
  movq %ALIEN_INTEGER64_ARGUMENT1, %ALIEN_INTEGER64_ARGUMENT3 # copy arg1 (number to cast) into arg3
  andq $0x0F, %ALIEN_INTEGER64_ARGUMENT3  # mask out all but the last four bits of arg3, leaving LSnibble.
  leaq TrigentasenaryUppercaseDigits(%rip), %ALIEN_INTEGER64_ARGUMENT4 # Load digit list address into arg4
  #####
  # ( Add nibble digit (arg3) to base of digit list (arg4)
  # , pull ASCII digit character at that location
  # , put into arg5(LSB)
  # )
  movb \
  ( %ALIEN_INTEGER64_ARGUMENT4\
  , %ALIEN_INTEGER64_ARGUMENT3\
  , 1\
  )\
  , %ALIEN_INTEGER8_ARGUMENT5

  movb %ALIEN_INTEGER8_ARGUMENT5, (%ALIEN_INTEGER64_RETURN1) # .. then put it into current left end of result.
  dec %ALIEN_INTEGER64_RETURN1 # March left side of result further left by one byte.
  shrq $4, %ALIEN_INTEGER64_ARGUMENT1 # demote all nibbles of arg1 by one nibble position
  jnz 0b # .loop
# .endLoop
  inc %ALIEN_INTEGER64_RETURN1 # backpedal left side to point at most recently written HSdigit
  inc %ALIEN_INTEGER64_ARGUMENT2 # step arg2 forward to one byte past end of result/buffer
  subq %ALIEN_INTEGER64_RETURN1, %ALIEN_INTEGER64_ARGUMENT2 # transform arg2 from "end of result&buffer" to "length of result"
  movq %ALIEN_INTEGER64_ARGUMENT2, %ALIEN_INTEGER64_RETURN2 # .. and then copy that to proper ret2.
  # ret1(%rax) still holds left side of result
  ret


# Accepts arg1(%rdi)=number to convert to decimal string, and arg2(%rsi)=20 byte buffer space.
# Returns ret1(%rax)=pointer to inside of buffer where RIGHT-ALIGNED answer sits,
# and ret2(%rdx)=total length of the answer string. That is not null-terminated.
# Unused portion of buffer left of ret1(%rax) is considered clobbered.
# I'm doing division, so %rdx and %rax get locked down by that process until
# the end of the procedure.

# arg1(%rdi) number to convert to decimal string
# arg2(%rsi) 20 byte buffer space .. becomes right side of answer
#   , then temp value length of answer.
# arg3(%rdx) gets abused as division scratchpad
# arg4(%rcx) temp left side of answer, copies to ret1(%rax) at the end.
# ret1(%rax) left side of answer, most likely not equal to beginning of buffer
#   as answer is right-aligned in buffer.
# ret2(%rdx) length of answer (%rax+%rdx = right/high end of buffer)
# extern struct MasterBlasterString _unsignedIntegerToStringBase10
# ( /*rdi*/ uint64_t valueToConvert
# , /*rsi*/ char resultBuffer[20] // Largest possible results are 20 digits
# );
.global _unsignedIntegerToStringBase10
_unsignedIntegerToStringBase10:
bufferLength = 20
bufferLast = bufferLength-1
  addq $bufferLast, %rsi # skip arg2 to end of buffer
  # copy arg2 to arg5, which will track the left side of answer.
  # arg2 will stay at the right side of answer.
  movq %rsi, %rcx
  movq %rdi, %rax # copy arg1 (number to cast) into Division Numerator Low Register
0: #.loop
  xor %edx, %edx # zero out Division Numerator High Register RDX
  mov $10, %edi # load numeric base (10) into arg1
  divq %rdi # divide by base: RDX = remainder, RAX = quotient
  leaq TrigentasenaryUppercaseDigits(%rip), %rdi # Load digit list address into arg1
  #####
  # ( Add digit (remainder from division) to base of digit list
  # , pull ascii/UTF-8 digit character at that location
  # , put into arg5(LSB)
  # )
  movb (%rdi,%rdx,1), %r8b
  movb %r8b, (%rcx) # .. then put it into current left end of result.
  dec %rcx # March left side of result further left by one byte.
  test %rax, %rax
  jnz 0b # .loop
# .endLoop
  inc %rcx # backpedal left side to point at most recently written HSdigit
  inc %rsi # step forward to one byte past end of result/buffer
  subq %rcx, %rsi # change arg2 from "end of result&buffer" to "length of result"
  movq %rsi, %rdx # .. and then copy that to proper ret2.
  movq %rcx, %rax # copy left side of result from arg4 to ret1
  ret

# This prints each lane of each stack element.
# Bottom of stack first, lane 1 first.
# lanes delimited by colons, stack elements delimited by newlines.
.global PrintStack
PrintStack:
  mov %DATA_STACK_POINTER, %rcx
PrintStackLoop:
  cmp BOTTOM_OF_CALL_STACK, %rcx
  jae End

# Print Lane 1 of current stack top
  mov (%rcx), %rdi
  push %rcx
  mov $0x30, %eax // ascii zero character
  movd %eax, %xmm0
  _SetAllBitsZero %xmm7 // lane 0 new source for every lane
  pshufb %xmm7, %xmm0 // "broadcast xmm0's lowest 8 bits to all lanes."
  leaq MEMORY_SCRATCHPAD(%rip), %rsi
  movdqa %xmm0, (%rsi) // Put 16x ascii zero character into MEMORY_SCRATCHPAD
  call _unsignedIntegerToStringBase16
  //%rax has new pointer to string
  //%rdx has length of new string
  putMemoryMacro messageLocation=MEMORY_SCRATCHPAD(%rip),length=$16

//Print a colon
  mov $STDOUT, %rdi
  lea COLON(%rip), %rsi
  mov $singleCharacterLength, %rdx
  mov $sys_write, %rax
  syscall

//Print Lane 2 of current stack top
  pop %rcx
  mov 8(%rcx), %rdi // DATA_STACK0 lane 2
  push %rcx
  mov $0x30, %eax // ascii zero character
  movd %eax, %xmm0
  _SetAllBitsZero %xmm7 // lane 0 new source for every lane
  pshufb %xmm7, %xmm0 // "broadcast xmm0's lowest 8 bits to all lanes."
  leaq MEMORY_SCRATCHPAD(%rip), %rsi
  movdqa %xmm0, (%rsi) // Put 16x ascii zero character into MEMORY_SCRATCHPAD
  call _unsignedIntegerToStringBase16
  //%rax has new pointer to string
  //%rdx has length of new string
  putMemoryMacro messageLocation=MEMORY_SCRATCHPAD(%rip),length=$16

  pop %rcx
  add $SIMD_WIDTH, %rcx
  push %rcx
  putNewlineMacro
  pop %rcx
  jmp PrintStackLoop

End:
  ret


# "
# This metafunction consumes the following stack arguments in push order:
# * pre-call top of stack (accumulator etc should be kept here)
# * Iterable RAM buffer address (pointer to byteLength followed by data)
# * Number of bytes from which to start reading into RAM buffer
# * lambda address
# Then it repeatedly invokes the lambda.
# With each invocation, it leaves:
# * the current state of the accumulator,
# * a one vector-sized chunk of data, SOME bytes of which are valid,
# * and a mask of which bytes are valid (0xFF/TRUE=valid, 0x00/FALSE=invalid).
# It is lambda's responsibility to properly handle every possible permutation
# of valid/invalid bytes via this mask, ensuring that invalid bytes do not
# affect the accumulator.
# Lambda must leave only the new accumulator on the stack.
# Maybe someday later I'll pair the accumulator with a lambda/caller-controlled
# mask, but I don't feel that's necessary just yet.
# == DETAILS AAAAAH
# For example, if mask = FFFFFF00 and input = ABCX, lambda must output an
# identical accumulator this round to if mask = FF00FFFF and input = AYBC.
# lambda IS guaranteed that whole (8-bit) bytes will be either valid or invalid,
# and that if you isolated only the valid bytes from this chunk, they would
# be both in order and contiguous bytes from the iterable.
# For now I will also tentatively offer the guarantee of lane confluence:
# ..if caller intends data to be acted on with a maximum lane size of N bits —
# where N=2^k where k>=3 —
# then through some mechanism I have yet to perfect I will guarantee that
# valid/invalid bytes will also only ever appear in groupings N bits wide,
# and thus that said groupings will also pack evenly into the vector.
# EG (How I am arriving at this guarantee so far):
# Creator of iterable is relied upon to ensure iterable's length is
# a multiple of N bits, and last modifier of iterable is relied upon
# to ensure that the sanctity of every N-bit data chunk is respected
# (whatever that means to the coder)..
# AND any possible iterable fragmentation I am trying to
# reserve liberty for in the future will yield to caller demands of a minimum
# "block" size of N-bits.
# I think one day I would like some kind of test suite to allow coders and
# compiler makers to do a shakedown of a given lambda, whether it is honoring
# this commitment or not. Shakedown test could run a version of the reduce
# metafunction (and matching variant of the crude verbs) that don't even have
# to run on the SIMD registers and accepts an "N-bit confluence" request hint,
# but then calls lambda with fuzzers of input data vectors and masks
# of varying 2^k*Nbit sizes, and randomized
# accumulators, and tests whether lambda always "accumulates" any given
# random input iterable (both end-value and every intermediate confluence value)
# regardless of how said iterable gets sliced up into N-bit chunks, and
# regardless of how said N-bit chunks get re-packed into vectors along with
# invalid/adversarial N-bit fuzzer chunks anywhere in each payload vector.
# "
.text
.globl IterableRAM # Warning! renamed from IterableRAM, AND call order changed!
IterableRAM:
  # "
  # yeah.. no fscking with alien call frames interior to Crude, a'ight?
  # At least not until I change how primary data stack's pointer is saved. :P
  # Which I'm not sold on doing yet anyway.
  # Long story short, Crude procedures should not require a call stack
  # base pointer. They should just use fixed size callstack frames,
  # in the rare event that is required at all.
  # // PrepareSimpleCallStackFrame
  # "
  _DataStackPopGeneral %rax # pop lambda address
  push %rax # set IterableRAMLambda
  _DataStackPopGeneral %rcx # pop byte offset
  _DataStackPopGeneral %rax # pop iterable length pointer
  pushq (%rax) # set IterableRAMLength
  add $SIMD_WIDTH, %rax # Advance to where the data lives
  add %rcx, %rax # Advance farther to our desired byte offset
  push %rax # set IterableRAMDataPointer
  push %rcx # set IterableRAMByteCounter
  leaq IterableRAMLast(%rip), %rax
  push %rax # " set IterableRAMLastClause
  #Now Call Stack frame is set up,
  #and all inbound arguments have been popped from the Data Stack,
  #except for the initial accumulator which we'll just leave
  #sitting there for now.
  # "
IterableRAMLoopStart:
  mov IterableRAMDataPointer, %rax
  _DataStackPushFromRAM address=(%rax) #(first vector of data)
  mov $SIMD_WIDTH, %rax
  cmpq IterableRAMLength, %rax # Do we have more than one vector left to process?
  jge IterableRAMShortMask # simd_width>=length
  # Otherwise, use an "all bytes valid" mask,
  # and we are assured to loop again.
  _SetAllBitsOne %xmm0
  _SIMDPush %xmm0
IterableRAMCallLambda:
  mov IterableRAMLambda, %rdx
  call *%rdx
IterableRAMLoopFinish:
  mov IterableRAMLength, %rax # reloading reg after lambda
  sub $SIMD_WIDTH, %rax
  js IterableRAMLast
  mov %rax, IterableRAMLength
  mov IterableRAMDataPointer, %rax
  add $SIMD_WIDTH, %rax
  mov %rax, IterableRAMDataPointer
  mov IterableRAMByteCounter, %rax
  add $SIMD_WIDTH, %rax
  mov %rax, IterableRAMByteCounter
  jmp IterableRAMLoopStart
IterableRAMLast:
  leaq IterableRAMParentCallStackAddress, %rsp # tear down fixed size crude callstack frame
  ret

IterableRAMShortMask:
  # We are shoveling the last vector now,
  # whether that vector is full or not.
  leaq lengthMaskTableMiddle(%rip), %rax
  sub IterableRAMLength, %rax
  movdqu (%rax), %xmm0
  _SIMDPush %xmm0
  mov IterableRAMLambda, %rdx
  lea IterableRAMLast(%rip), %rax
  push %rax # ^^^ Make next ret send you back there
  # EG, every LoopNext is short circuited into a LoopBail.
  # %rdx loaded before push to use correct stack offset.
  jmp *%rdx





	.data
.global TrigentasenaryUppercaseDigits
TrigentasenaryUppercaseDigits:
  .string "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


.balign 64
.global MEMORY_SCRATCHPAD
MEMORY_SCRATCHPAD:
.skip 512


COLON:
  .string ":"

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

lengthMaskTable:
  .skip SIMD_WIDTH, 0xFF
lengthMaskTableMiddle:
  .skip SIMD_WIDTH, 0x00
