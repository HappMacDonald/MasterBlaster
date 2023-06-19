#include "libmb_s.h"

# "
# 2022-05-12T02:05-07:00 current status:
# Probably time to fall back to the tokenizer for the time being.
# Appears to work in the general case, but cannot
# handle more than 4kB input.
# I was using the following code to manually fuzz test:
# perl -e '$q = int(rand()*1024); CORE::say STDERR "$q/". ($q%16); CORE::say " "x$q . "OK";' | ( time ./trim_whitespace_left.elf64 )
# but increasing that "1024" value > 4kib naturally crashes.
# I have no clear path to improve that,
# as supporting streaming would have to wait for streaming generator iterable models.

# 2022-05-11T04:21-07:00 current status:
# OK, all of the min/max verbs have been created and tested.
# Next up: trim fails on 16+ WS. More research needed.
#
# 2022-05-06T23:40-07:00 current status:
# OK, I've now got IterableRAM generating a "valid mask" to offer along
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
inputBufferByteLength:
  .skip SIMD_WIDTH, 0
inputBuffer: # this area is considered unaligned
  .skip BUFFER_LENGTH



.text
.globl _start
_start:
  EndAlienCallStackFrame

  getMemoryMacro messageLocation=inputBuffer(%rip),length=$BUFFER_LENGTH
  # "
  # Return (%rax) between -4095 and -1 indicates an error, it is -errno.
  # For right now I'm ignoring that possibility.
  # Otherwise — more pertinent to us — it equals the length of the read string.
  # "
  _Scalar64BroadcastToSIMD128 %rax %xmm0
  movdqa %xmm0, inputBufferByteLength(%rip)
  // PrintStackMessage "Sanity check: stack is empty, right?"
  Bitfield64Immediate -1 # Accumulator starts at "not found" state.
  _Bitfield64DataStackPushAddress inputBufferByteLength(%rip)
  Bitfield64Immediate 0 # Start searching from beginning of buffer
  _Bitfield64DataStackPushAddress lambda(%rip)
  call IterableRAM # iterate over inputBuffer using lambda
  _RAMDataStackPush inputBuffer(%rip)
  
  PrintStackMessage "very first 16 characters of input, how many whitespace to skip"

  Bitfield64Immediate 0
  systemExit

lambda:
  # Lambda Stack now has: Accumulator, current SIMD_WIDTH characters
  # from input buffer, and mask of valid bytes.
  Exchange
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , and current SIMD_WIDTH characters from input buffer.
  _DataStackPushFromRAM characterSpace(%rip)
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , current SIMD_WIDTH characters from input buffer
  # , an array literal of ascii spaces
  Duplicate
  SignedInteger8greaterThan
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , current SIMD_WIDTH characters from input buffer
  # , mask of which of the first
  # SIMD_WIDTH of input characters is ascii 33-127 (due to "signed" comp)

  _DataStackPushFromRAM characterDelete(%rip)
  # Lambda Stack now has: Accumulator, mask of valid bytes
  # , mask of which of the first
  # SIMD_WIDTH of input characters is ascii 33-127 (due to "signed" comp)
  # , current SIMD_WIDTH input chars, array literal of ascii deletes (/u127).
  Bitfield8equal
  Bitfield8BooleanNot
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
