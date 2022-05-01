#include "libmb_s.h"

// 2022-04-30T23:19-07:00 current status:
// This code is ready for first test.
// It is using an iterable metafunction as planned.
// Currently it will return `amount of whitespace to skip` mod 16,
// cleaning that out of a 16 loop will be my next task once I have this bit
// functioning properly.
// Yay! The following produces what might be valid output,
// I just have to vet it by eyeball and then work from there:
// $ echo "   Hello" | ./trim_whitespace_left.elf64
// Warning: before gdb'ing this thing, recompile it since my comment here screws
// with gdb's sense of source code line numbering. :P

// 2022-04-30T01:27-07:00 current status:
// revisiting the below, more importantly still I have to devise a method to 
// make the looping strategy modular. >.<

// 2022-04-22T20:54-07:00 current status:
// The masking strategy appears to be strictly functioning:
// I get a mask of whitespace vs. non-whitespace,
// and I boil that mask down to "how many WS bytes to skip",
// from 0 to 15.
// Now when we start with at least 16 WS characters spec says
// that the numeric output is "undefined" so we shouldn't rely on it.
// Also FWIW it gives back zero which is numerically indistinguishable
// from "no WS to skip", but we should not even rely on that.
// So I need to test for zero flag from bsf, and kick in a routine
// to test further bucketfuls in that circumstance.
// But I also need that routine to bail early if the end of the most
// recent bucket > total input length.

// #define BUFFER_LENGTH SIMD_WIDTH
#define BUFFER_LENGTH 4096

.data
.balign CACHE_LINE_WIDTH, 0
characterSpace:
  .skip SIMD_WIDTH, 32
characterDelete:
  .skip SIMD_WIDTH, 127

inputBufferByteLength:
.skip SIMD_WIDTH, 0
inputBuffer: // this area is considered unaligned
.skip BUFFER_LENGTH
.balign SIMD_WIDTH

.macro _RAMDataStackPush address:req SIMDClobber=%xmm0 aligned=TRUE
  .if \aligned
    movdqa \address, \SIMDClobber
  .else
    movdqu \address, \SIMDClobber
  .endif
  _SIMDPush \SIMDClobber
.endm

#define CrudeMapUnalignedLambda CALL_STACK3
#define CrudeMapUnalignedLength CALL_STACK2
#define CrudeMapUnalignedDataPointer CALL_STACK1
#define CrudeMapUnalignedLastClause CALL_STACK0
#define LoopNext ret

.macro LoopBail
  add $SCALAR_NATIVE_WIDTH_IN_BYTES, %rsp // silently pop caller address
  jmp *CrudeMapUnalignedLastClause // go to last clause instead of returning there.
.endm

// This metafunction consumes the following stack arguments:
// * Iterable Address (pointer to byteLength followed by data)
// * lambda address
// Then it repeatedly invokes the lambda.
// With each invocation, it leaves one vector-worth of data on the data stack
// for the lambda to work on.
// Said vector might not be completely packed by valid data, it's on the
// lambda to tolerate that. Lambda needs to process the valid lanes to
// get valid results, and not allow invalid lanes to complicate that..
// WITHOUT ANY WARNING about which lanes are valid or invalid!
.text
CrudeMapUnaligned:
  PrepareSimpleCallStackFrame
  _DataStackPopGeneral %rax // pop lambda address
  push %rax // set CrudeMapUnalignedLambda
  _DataStackPopGeneral %rax // pop iterable length pointer
  pushq (%rax) // set CrudeMapUnalignedLength
  add $SIMD_WIDTH, %rax // advance to where the data lives
  push %rax // set CrudeMapUnalignedDataPointer
//   push $0 // push vector index onto call stack frame
// #define CrudeMapUnalignedIndex CALL_STACK_NEGATIVE2
  leaq CrudeMapUnalignedLast(%rip), %rax
  push %rax // set CrudeMapUnalignedLastClause
  //Now Call Stack frame is set up,
  //and all inbound arguments have been popped from the Data Stack.
CrudeMapUnalignedLoopStart:
  mov CrudeMapUnalignedDataPointer, %rax
  _RAMDataStackPush address=(%rax),aligned=FALSE
  mov CrudeMapUnalignedLambda, %rdx
  call *%rdx
  mov CrudeMapUnalignedLength, %rax
  cmp $SIMD_WIDTH, %rax
  jbe CrudeMapUnalignedLast
CrudeMapUnalignedLoopFinish:
  // %rax still has CrudeMapUnalignedLength in it
  sub $SIMD_WIDTH, %rax
  mov %rax, CrudeMapUnalignedLength
  sub CrudeMapUnalignedDataPointer, %rax
  add $SIMD_WIDTH, %rax
  mov %rax, CrudeMapUnalignedDataPointer
CrudeMapUnalignedLast:
  DismantleSimpleCallStackFrame
  ret

.globl _start
_start:
  EndAlienCallStackFrame

  getMemoryMacro messageLocation=inputBuffer(%rip),length=$BUFFER_LENGTH
  // Return (%rax) between -4095 and -1 indicates an error, it is -errno.
  // For right now I'm ignoring that possibility.
  // Otherwise, more pertinent to us it equals the length of the read string.
  _Scalar64BroadcastToSIMD128 %rax %xmm0
  movdqa %xmm0, inputBufferByteLength(%rip)
  PrintStackMessage "Sanity check: stack is empty, right?"
  leaq inputBufferByteLength(%rip), %rax
  _Bitfield64DataStackPushGeneral %rax
  leaq lambda(%rip), %rax
  _Bitfield64DataStackPushGeneral %rax
  call CrudeMapUnaligned
  // call lambda
  PrintStackMessage "input length, printable characters mask, how many whitespace to skip, input prefix"

  Bitfield64Immediate 0
  systemExit

lambda:
  // Lambda Stack now has: first SIMD_WIDTH characters
  // from input buffer.
  _RAMDataStackPush characterSpace(%rip)
  // Lambda Stack now has: first SIMD_WIDTH input chars,
  // an array literal of ascii spaces.
  SignedInteger8greaterThan
  // Lambda Stack now has: mask of which of the first
  // SIMD_WIDTH of input characters is ascii 33-127 (due to "signed" comp)
  _RAMDataStackPush inputBuffer(%rip)
  _RAMDataStackPush characterDelete(%rip)
  // Lambda Stack now has: mask of which of the first
  // SIMD_WIDTH of input characters is ascii 33-127 (due to "signed" comp)
  // , first SIMD_WIDTH input chars, array literal of ascii deletes (/u127).
  Bitfield8equal
  BooleanNot
  BooleanAnd
  // Lambda Stack now has: mask of which of the first
  // SIMD_WIDTH of input characters is ascii 33-126 (eg: printable)
  movdqa DATA_STACK0, %xmm0
  ptest %xmm0, %xmm0
  jne lambdaSkip
  LoopNext
lambdaSkip:
  pmovmskb %xmm0, %eax
  _Bitfield64DataStackPushGeneral %rax
  bsf %ax, %ax
  _Bitfield64DataStackPushGeneral %rax
  _RAMDataStackPush inputBuffer(%rip)
  LoopBail