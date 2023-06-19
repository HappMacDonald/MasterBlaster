#include "libmb_s.h"
#include "tokenizer_tokens.h"

// 2022-05-21T08:14-07:00 Current status:
// Pre-empt: I want an easy to use TDD solution!
// It doesn't have to focus on buffer overrun bs, but it will be nice
// for that to be an option in regression cases where it's clear that
// that wil be needed.
// Primary issue is: it needs to be easy for me to access/use/run, and
// it needs to be able to call my assembly routines (which at least
// tolerate being called C-style. :P
//
// Next idea: a new kind of iterator for the tokens.
// A "loose list of concatenated C-style strings" iterator.
// This would be a 2-levels-in-one iterator, so it would need
// loop verbs: LoopBail, LoopNextItem, and LoopNextChunk (of current item).
// This iterator WILL offer the guarantee that valid bytes will be
// packed left. It will not however offer the guarantee that presence of
// invalid bytes proves end of current item.

// 2022-05-20T16:50-07:00 Current status:
// I modified IterableRAM generator to additionally keep track of the 
// current byte-count within the iterable data, and I introduced macro
// `LoopGetByteCount` to allow caller's lambda to get a copy
// of that on demand.
// Thus, the whitespace counting appears to be working 100%.
// Next up: exploit the IterableRAM bytecount input feature
// to do token matching at the end of said whitespace. 👍

// 2022-05-18T22:34-07:00 Current status:
// Seems to give correct left-whitespace mod 16 answer for all tested inputs.
// Now how should I keep track of running byte offset, such that final result
// can be a combo of in-vector offset + combined length of all vectors that
// have come before?

// Problem 1: lambda doesn't know how big SIMD_WIDTH is, and I think it lacks
// any access to the generator's copy of running byte offset.

// Problem 2: (orthogonal to the above) How can I keep track of an offset in
// a way that allows LoopBail, "end of data", AND "never run" to all
// ensure a "not found" response — instead of getting the running byte offset
// confused with a "found here" indicator?
// I toyed with "keep byte offset negative, then flip sign on find" but one
// major problem there is that zero has no negative value.
// Solution might depend on having a 2-vector accumulator.
// But solution to problem 1 might change the playing field for problem 2,
// so I should focus on that one first.

// 2022-05-16T08:20-07:00 Current status:
// I have a lot of debug verbosity, ofc.
// echo "@" | ./compile_optimized.sh tokenizer_crude2
// gives 0 correctly, but
// echo " @" | ./compile_optimized.sh tokenizer_crude2
// gives 0 when it should give 1. Must pore over verbosity to debug.

BUFFER_LENGTH=4096

.data
.balign CACHE_LINE_WIDTH, 0
characterSpace:
  .skip SIMD_WIDTH, 32
.balign SIMD_WIDTH
characterDelete:
  .skip SIMD_WIDTH, 127
.balign SIMD_WIDTH
inputBufferByteLength:
.skip SIMD_WIDTH, 0
inputBuffer:
.skip BUFFER_LENGTH
.balign SIMD_WIDTH
outputBufferByteLength:
.skip SIMD_WIDTH, 0
outputBuffer:
.skip BUFFER_LENGTH



.text
.globl _start
_start:
  EndAlienCallStackFrame
  getMemoryMacro messageLocation=inputBuffer(%rip),length=$BUFFER_LENGTH
  // Return (%rax) between -4095 and -1 indicates an error, it is -errno.
  // For right now I'm ignoring that possibility.
  _Bitfield64DataStackPushGeneral %rax
  _DataStackCopyToRAM inputBufferByteLength(%rip)
  DataStackRetreat

  Bitfield64Immediate -1 # initial accumulator (-1 == not found)
  _Bitfield64DataStackPushAddress inputBufferByteLength(%rip) # RAM to iterate over
  Bitfield64Immediate 0 # Start reading from beginning of buffer
  _Bitfield64DataStackPushAddress CountLeftWhitespace(%rip) # lambda
  // PrintStackMessage "just before CountLeftWhitespace via IterableRAM"
  call IterableRAM
  PrintStackMessage "just after CountLeftWhitespace via IterableRAM"


  # return value 0x99 = "we hit bottom of _start, so maybe nothing found?"
  Bitfield64Immediate 0x99
  SystemExit

CountLeftWhitespace:
  # Data Stack now has, in push order:
  # * Accumulator
  # * current vector of characters from input buffer
  # * mask of valid bytes in said vector

  Exchange
  _DataStackPushFromRAM characterSpace(%rip)
  # Data Stack now has, in push order:
  # * Accumulator
  # * mask of valid bytes in said vector
  # * current vector of characters from input buffer
  # * A vector full of space characters


  Bitfield64Immediate 2
  Bitfield64Index
  # Data Stack now has, in push order:
  # * Accumulator
  # * mask of valid bytes in said vector
  # * current vector of characters from input buffer
  # * A vector full of space characters
  # * current vector of characters from input buffer

  // PrintStackMessage "Old accumulator, valid bytes, actual input vector, spaces, actual input vector"
  Exchange
  SignedInteger8greaterThan
  // Bitfield8BooleanNot
  // PrintStackMessage "Old accumulator, valid bytes, actual input vector, 33-127"
  # Data Stack now has, in push order:
  # * Accumulator
  # * mask of valid bytes in said vector
  # * current vector of characters from input buffer
  # * input character mask of ascii 33-127 (due to "signed" comp)

  Exchange
  _DataStackPushFromRAM characterDelete(%rip)
  # Data Stack now has, in push order:
  # * Accumulator
  # * mask of valid bytes in said vector
  # * input character mask of ascii 33-127 (due to "signed" comp)
  # * current vector of characters from input buffer
  # * A vector full of Delete characters

  // PrintStackMessage "Old accumulator, valid bytes, 33-127, actual input vector, 127?"

  Bitfield8equal
  Bitfield8BooleanNot
  BooleanAnd
  BooleanAnd
  # Data Stack now has, in push order:
  # * Accumulator
  # * mask of valid bytes that are ALSO ascii 33-126 (eg: printable)

  // PrintStackMessage "Old accumulator, and mask of valid printable chars?"

  movdqa DATA_STACK0, %xmm0
  ptest %xmm0, %xmm0
  jne CountLeftWhitespaceBail
  DataStackRetreat
  # I only get here if I had a whole vector full of WS or invalid bytes.
  # Data Stack now has: Accumulator (same -1 I got originally passed)
  # I never read it, and I only ever write it on bail.
  LoopNext

CountLeftWhitespaceBail:
  # Data Stack now has, in push order:
  # * (old) Accumulator
  # * mask of valid bytes that are ALSO ascii 33-126 (eg: printable)
  # %xmm0 also already has the latter.
  DataStackRetreatTwice # empty stack, including old accumulator
//vvvvvvvvvv
  pmovmskb %xmm0, %eax # get a bitmask version of our result from %xmm0
  bsf %ax, %ax # How many 0 bits before the first 1 bit?
//^^^^^^^^^^
  _Bitfield64DataStackPushGeneral %rax # Push that onto stack as offset into current vector
  LoopGetByteCount # get offset OF current vector in iterable
  Bitfield64add # Add them to get byte offset of first non-whitespace in iterable
  LoopBail

  # return value 0x98 = "we hit bottom of IterateOverInput, which is still being written."
  Bitfield64Immediate 0x98
  SystemExit

