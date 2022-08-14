#include "../libmb_s.h"

// 2022-05-30T11:16-07:00 Current Status:
// Yeah I don't have to rush to vectorization, though it might
// be nice to build down the road. For now it's basically
// "Test if this entire vector on the stack is what it's
// supposed to be or not".
// 
// One thing I *do* need to figure out eventually is fuzzers, though.
//
// 2022-05-30T07:45-07:00 Current Status:
// Setting up this file as a library to standardize automated tests.
// 1. I think I need to rename my "ScalarBranch*" and "BranchSIMD*"
// to instead be "Bitfield64Branch*" and "VectorBranch*".
// The latter is called from only one place, which is easy.
// The former is called from one or two places.. but also has a test file,
// so I'm torn about *when* to make that change since I'd be opening
// up a can of upgrading a test. :P
// All of them might be in the Tokenizer Vocabulary as well, I'unno.
// 
// 2. I need to work out a possible vectorization of my TAP macros, natch! ;P

TAP_BUFFER_LENGTH=4096

.data
.balign CACHE_LINE_WIDTH, 0
// inputBufferByteLength:
// .skip SIMD_WIDTH, 0
// inputBuffer:
// .skip TAP_BUFFER_LENGTH
// .balign SIMD_WIDTH, 0
constantYAMLPreamble:
.ascii "\n  ---\n  message: \""
constantYAMLPreambleLength = . - constantYAMLPreamble
.balign SIMD_WIDTH, 0
constantYAMLPost:
.ascii "\"\n  ...\n"
constantYAMLPostLength = . - constantYAMLPost
.balign SIMD_WIDTH, 0
outputBuffer:
sadNoises:
.ascii "not "
sadNoisesPreambleLength = . - sadNoises
happyNoises:
.ascii "ok "
happyNoisesPreambleLength = . - happyNoises
outputBufferTestName:
.skip TAP_BUFFER_LENGTH-6, 0


// This is a quick and dirty memcopy that makes the following
// assumptions on behalf of the caller:
// * source address must be aligned to SIMD_WIDTH
// * destination addresses may be unaligned
// * space after source address is padded with zeros to
//   align to SIMD_WIDTH (or free-to-copy garbage, Irdk)
// * said zeros or garbage WILL be copied along with the
//   valid data, despite the high likelihood of extending beyond the
//   bytelength specified.
// * 
.macro ok1MemCopy sourceAddress:req \
  destinationAddress:req \
  byteLength:req \
  SIMDRegister=%xmm0 \
  scalarRegisterLength=%ecx \
  scalarRegisterSource=%eax \
  scalarRegisterDestination=%edx
ok1MemCopy\@:
  mov $\byteLength, \scalarRegisterLength
  mov $\sourceAddress, \scalarRegisterSource
  mov $\destinationAddress, \scalarRegisterDestination
ok1MemCopyLoop\@:
  movdqa [\scalarRegisterSource], \sIMDRegister
  movdqu \SIMDRegister, [\scalarRegisterDestination]
  sub $SIMD_WIDTH, \scalarRegisterLength
  ja ok1MemCopyLoop\@
  add $byteLength, \scalarRegisterDestination
.endm

// Step 1: describe (testcase pseudocode?) what behavior we want from
// this macro.
// 1. takes 2 messages as macro parameters, and consumes 1 test result
// from data stack.
// 2. Spits out happy noises or sad noises via outputBuffer
// based upon whether Test argument is VectorTrue.
//
// General: TestPoint := ("not ")? "ok " Description "\n" (YAMLBlock)?
// Below is responsibility of caller:
// Description (testName) := (Number " ")? "- " words
// Happy: "ok " testName "\n"
// Not happy:
//   "not ok " testName "\n"
//   "  ---\n"
//   "  message: \"" testFailMessage "\"\n"
//   "  severity: fail\n"
//   (?: eventually:
//   "  data:\n"
//   "    got: " testGot(?)
//   "    expected: " testExpected(?)
//   )?
//   "  ...\n"

#define ok1StringBuilder %edx
#define ok1AndCrucible %eax
// #define ok1OutputLength %edx
#define ok1OutputStart %ecx


.macro ok1 testName:req testFailMessage:req
  Bitfield64castToBoolean // Make sure top of stack is a pure boolean
  mov outputBufferTestName(%rip), ok1StringBuilder
  ok1MemCopy testName\@(%rip), ok1StringBuilder, $testName\@Length
  ok1MemCopy constantYAMLPreamble(%rip), ok1StringBuilder, $constantYAMLPreambleLength
  ok1MemCopy testFailMessage\@(%rip), ok1StringBuilder, $testFailMessage\@Length
  ok1MemCopy constantYAMLPost(%rip), ok1StringBuilder, $constantYAMLPostLength
  // .. not really necessary, but just in case I feel
  // like endcapping the output buffer at some point.
  // movb $0, ok1StringBuilder

  // because of Bitfield64castToBoolean, must be a valid and mask
  mov DATA_STACK0, %eax
  ptest %eax, %eax
  jz okFail

okSucceed:
  putMemoryMacro happyNoises(%rip), happyNoises\@Length
  jmp ok1End

okFail:
  putMemoryMacro sadNoises(%rip), ok1StringBuilder
  jmp ok1End
  
testName\@:
  .ascii "\testName"
  testName\@Length = . - testName\@
  happyNoises\@Length = happyNoisesPreambleLength + testName\@Length + 1
  .align SIMD_WIDTH
testFailMessage\@:
  .ascii "\testFailMessage"
  testFailMessage\@Length = . - testFailMessage\@
  .align SIMD_WIDTH
ok1End\@:
  DataStackRetreat
.endm


.text
.globl _start
_start:
  EndAlienCallStackFrame
  BooleanPushFalse
  BooleanPushTrue
  ok1 "Test true should be OK" "Test true.. isn't OK?"
  ok1 "Test false should be not OK # todo" "Err.. false succeeded I guess?"
  Bitfield64Count
  ok1 "Tests should consume stack input # todo" "Huh.. stack isn't empty.."
