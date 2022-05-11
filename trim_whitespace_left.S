#include "libmb_s.h"

# "
# 2022-05-11T04:21-07:00 current status:
# OK, all of the min/max verbs have been created and tested.
# Next up: trim fails on 16+ WS. More research needed.
#
# 2022-05-06T23:40-07:00 current status:
# OK, I've now got ReduceUnaligned generating a "valid mask" to offer along
# with the vector worth of data.
# Next up, make sure caller is feeding in an accumulator
# and then teach lambda to use that as well as respecting the new
# mask.
# If I haven't already started defining the accumulator,
# then it should probably be -1 cast as scalarBroadcastUnsignedInteger64.
# Then that can be the output indicating "whitespace not found".

# 2022-05-01T20:48-07:00 current status:
# The following works, and reports 15 spaces:
# $ echo "               Hello" | ./trim_whitespace_left.elf64
# longer sequences of spaces at the beginning are only partly being handled
# properly right now.
# They return a "whitespace skip" value that is mod 16 of what it ought
# to be .. but they *are* looking ahead multiple chunks to learn that, 
# at least.
# My next job is to shoehorn an accumulator into my Map to make it
# behave like a Reduce instead, so that lambda can keep track of
# how many bytes its had to skip in previous loops.
# .. or, alternately, it knows the real iterable data start so
# it could find the delta between that and the last chunk pointer it
# was given. however.... that strategy treads on the black box toes of the
# Metafunction, so I might not appreciate it any better.
#-----------
# ALSO, it appears that any string with only whitespace (or blank) hangs
# the trimmer. I suspect it is counting nulls at the "end" of the string as
# whitespace, and not knowing when to stop.
# So, I need to revisit my "length" parameter and make sure that it gets
# properly honored.
# -- nulls SHOULD definitely be counted as whitespace though.
# After all they can technically exist before the "length"-defined
# end of the iterable.

# 2022-04-30T23:19-07:00 current status:
# This code is ready for first test.
# It is using an iterable metafunction as planned.
# Currently it will return `amount of whitespace to skip` mod 16,
# cleaning that out of a 16 loop will be my next task once I have this bit
# functioning properly.
# Yay! The following produces what might be valid output,
# I just have to vet it by eyeball and then work from there:
# $ echo "   Hello" | ./trim_whitespace_left.elf64
# Warning: before gdb'ing this thing, recompile it since my comment here screws
# with gdb's sense of source code line numbering. :P

# 2022-04-30T01:27-07:00 current status:
# revisiting the below, more importantly still I have to devise a method to 
# make the looping strategy modular. >.<

# 2022-04-22T20:54-07:00 current status:
# The masking strategy appears to be strictly functioning:
# I get a mask of whitespace vs. non-whitespace,
# and I boil that mask down to "how many WS bytes to skip",
# from 0 to 15.
# Now when we start with at least 16 WS characters spec says
# that the numeric output is "undefined" so we shouldn't rely on it.
# Also FWIW it gives back zero which is numerically indistinguishable
# from "no WS to skip", but we should not even rely on that.
# So I need to test for zero flag from bsf, and kick in a routine
# to test further bucketfuls in that circumstance.
# But I also need that routine to bail early if the end of the most
# recent bucket > total input length.
# "

# #define BUFFER_LENGTH SIMD_WIDTH
#define BUFFER_LENGTH 4096

.data
.balign CACHE_LINE_WIDTH, 0
characterSpace:
  .skip SIMD_WIDTH, 32
characterDelete:
  .skip SIMD_WIDTH, 127
# this area is considered unaligned: it will be accessed as such.
lengthMaskTable:
  .skip SIMD_WIDTH, 0xFF
lengthMaskTableMiddle:
  .skip SIMD_WIDTH, 0x00

inputBufferByteLength:
  .skip SIMD_WIDTH, 0
inputBuffer: # this area is considered unaligned
  .skip BUFFER_LENGTH

.macro _RAMDataStackPush address:req SIMDClobber=%xmm0 aligned=TRUE
  .if \aligned
    movdqa \address, \SIMDClobber
  .else
    movdqu \address, \SIMDClobber
  .endif
  _SIMDPush \SIMDClobber
.endm

#define ReduceUnalignedLambda CALL_STACK3
#define ReduceUnalignedLength CALL_STACK2
#define ReduceUnalignedDataPointer CALL_STACK1
#define ReduceUnalignedLastClause CALL_STACK0


#define LoopNext ret

.macro LoopBail
  add $SCALAR_NATIVE_WIDTH_IN_BYTES, %rsp # silently pop caller address
  jmp *ReduceUnalignedLastClause # go to last clause instead of returning there.
.endm

# "
# This metafunction consumes the following stack arguments in push order:
# * Initial Accumulator
# * Iterable Address (pointer to byteLength followed by data)
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
ReduceUnaligned:
  # "
  # yeah.. no fscking with alien call frames interior to Crude, a'ight?
  # At least not until I change how primary data stack's pointer is saved. :P
  # Which I'm not sold on doing yet anyway.
  # Long story short, Crude procedures should not require a call stack
  # base pointer. They should just use fixed size callstack frames,
  # in the rare event that is required at all.
  # PrepareSimpleCallStackFrame
  # "
PrintStackMessage "debug"
  _DataStackPopGeneral %rax # pop lambda address
  push %rax # set ReduceUnalignedLambda
  _DataStackPopGeneral %rax # pop iterable length pointer
  pushq (%rax) # set ReduceUnalignedLength
  add $SIMD_WIDTH, %rax # advance to where the data lives
  push %rax # set ReduceUnalignedDataPointer
  leaq ReduceUnalignedLast(%rip), %rax
  push %rax # " set ReduceUnalignedLastClause
  #Now Call Stack frame is set up,
  #and all inbound arguments have been popped from the Data Stack,
  #except for the initial accumulator which we'll just leave
  #sitting there for now.
  # "
ReduceUnalignedLoopStart:
  mov ReduceUnalignedDataPointer, %rax
  _RAMDataStackPush address=(%rax),aligned=FALSE #(first vector of data)
  mov $SIMD_WIDTH, %rax
  cmpq ReduceUnalignedLength, %rax # Do we have more than one vector left to process?
  jge ReduceUnalignedShortMask # simd_width>=length
  # Otherwise, use an "all bytes valid" mask,
  # and we are assured to loop again.
  _SetAllBitsOne %xmm0
  _SIMDPush %xmm0
ReduceUnalignedCallLambda:
  mov ReduceUnalignedLambda, %rdx
  call *%rdx
ReduceUnalignedLoopFinish:
  cmpq ReduceUnalignedLength, %rax # reloading reg after lambda
  sub $SIMD_WIDTH, %rax
  js ReduceUnalignedLast
  mov %rax, ReduceUnalignedLength
  mov ReduceUnalignedDataPointer, %rax
  add $SIMD_WIDTH, %rax
  mov %rax, ReduceUnalignedDataPointer
  jmp ReduceUnalignedLoopStart
ReduceUnalignedLast:
  leaq CALL_STACK4, %rsp # tear down fixed size crude callstack frame
  ret

ReduceUnalignedShortMask:
  # We are shoveling the last vector now,
  # whether that vector is full or not.
  leaq lengthMaskTableMiddle(%rip), %rax
  sub ReduceUnalignedLength, %rax
  movdqu (%rax), %xmm0
  _SIMDPush %xmm0
  mov ReduceUnalignedLambda, %rdx
  call *%rdx
  jmp ReduceUnalignedLast

.globl _start
_start:
  EndAlienCallStackFrame

  getMemoryMacro messageLocation=inputBuffer(%rip),length=$BUFFER_LENGTH
  # "
  # Return (%rax) between -4095 and -1 indicates an error, it is -errno.
  # For right now I'm ignoring that possibility.
  # Otherwise, more pertinent to us it equals the length of the read string.
  # "
  _Scalar64BroadcastToSIMD128 %rax %xmm0
  movdqu %xmm0, inputBufferByteLength(%rip)
  PrintStackMessage "Sanity check: stack is empty, right?"
  Bitfield64Immediate -1 # Accumulator starts at "not found" state.
  _Bitfield64DataStackPushAddress inputBufferByteLength(%rip)
  _Bitfield64DataStackPushAddress lambda(%rip)
  call ReduceUnaligned # iterate over inputBuffer using lambda
  _RAMDataStackPush inputBuffer(%rip)
  Duplicate
  _Bitfield64DataStackPushAddress inputBufferByteLength(%rip)
  
  PrintStackMessage "very first 16 characters of input, how many whitespace to skip"

  Bitfield64Immediate 0
  systemExit

lambda:
  # Lambda Stack now has: Accumulator, current SIMD_WIDTH characters
  # from input buffer, and mask of valid bytes.
  Exchange
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , and current SIMD_WIDTH characters from input buffer.
  _RAMDataStackPush characterSpace(%rip)
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , current SIMD_WIDTH characters from input buffer
  # , an array literal of ascii spaces
  SignedInteger8greaterThan
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , mask of which of the first
  # SIMD_WIDTH of input characters is ascii 33-127 (due to "signed" comp)
  _RAMDataStackPush inputBuffer(%rip)
  _RAMDataStackPush characterDelete(%rip)
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , mask of which of the first
  # SIMD_WIDTH of input characters is ascii 33-127 (due to "signed" comp)
  # , current SIMD_WIDTH input chars, array literal of ascii deletes (/u127).
  Bitfield8equal
  BooleanNot
  BooleanAnd
  BooleanAnd
  # Lambda Stack now has: Accumulator
  # , mask of which of the current SIMD_WIDTH of input characters
  # that is both valid AND is ascii 33-126 (eg: printable)
  movdqa DATA_STACK0, %xmm0
  ptest %xmm0, %xmm0
  jne lambdaBail
  DataStackRetreat
  # Lambda Stack now has: Accumulator (same -1 I got originally passed)
  # I never read it, and I only ever write it on bail.
  LoopNext
lambdaBail:
  # Lambda Stack now has: (old) Accumulator
  # , mask of which of the current SIMD_WIDTH of input characters
  # that is both valid AND is ascii 33-126 (eg: printable)
  DataStackRetreatTwice
  pmovmskb %xmm0, %eax
  # _Bitfield64DataStackPushGeneral %rax
  bsf %ax, %ax
  _Bitfield64DataStackPushGeneral %rax
  LoopBail