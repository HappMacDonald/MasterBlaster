#include "../include/libmb_s.h"

// 2023-05-30T12:07-07:00 Current Status:
// Woohoo, found/resolved problem printing things in general. :)
// Lowdown: _crudeTestMemCopy is meant to update its dest address to the end of what it last copied.
// It was updating the register it uses to that effect internally
// , but *not* updating the register caller used to give it that data.
// Now it is.
//
// Current output is the following (with segfault at the end)
// ok Test true should be OK
// not ok Test false should be not OK # todo
//   ---
//   message: "Err.. false succeeded I guess?"
//   ...
// not ok Tests should consume stack input # todo
//   ---
//   message: "Huh.. stack isn't empty.."
//   ...
// Segmentation fault

// 2023-05-29T18:11-07:00 Current Status:
// lol! OK, in case I ever run into the below again...
// ...
// ... I was somehow compiling and gnu debugging the entire project in WINDOWS
// and it didn't crash or mess up any earlier than that specific dealeo.
// like.. WAT? Windows how are you running an elf64 I can't even xD
//
// I'm back properly doing this on Linux and get the same erroneous behavior
// now that I got two steps ago, back in 2022-08-17T03:31-07:00.


// 2023-05-28T04:45-07:00 Current Status:
// It looks like at the end of EndAlienCallStackFrame
// (very first line of macro-invoking code), $rbx (data stack pointer)
// is set to some garbage value?
// (gdb) p/x $rbx
// $2 = 0xffffffffc1000005


// 2022-08-17T03:31-07:00 Current Status:
// OK, as far as I can tell the first output attempt is trying to print
// 0x1a (26?) characters at mem location happyNoises(%rip) = 0x555555557034
// (gdb) x/16gx 0x555555557034
// 0x555555557034: 0x2e20200a22206b6f      0x00000000000a2e2e
// Decoding the above hex data, I get the same ascii output as I see on terminal,
// with spaces replaced by underscores and newlines by "\n" for readability here:
// ok_"\n
// __...\n
// I doubt this is what is really trying to be printed,
// I think perhaps the copy routines to fill in the output buffer
// are malfuntioning.

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
constantYAMLPreamble:
.ascii "\n  ---\n  message: \""
constantYAMLPreambleLength = . - constantYAMLPreamble
.balign SIMD_WIDTH, 0
constantYAMLPost:
.ascii "\"\n  ...\n"
constantYAMLPostLength = . - constantYAMLPost
.balign SIMD_WIDTH, 0
testPointBuffer:
sadNoises:
.ascii "not "
sadNoisesPreambleLength = . - sadNoises
happyNoises:
.ascii "ok "
happyNoisesPreambleLength = . - happyNoises
testPointName:
.skip TAP_BUFFER_LENGTH-6, 0
decimalIntegerBuffer:
.skip 20

// This is a rapid test that the top \count vectors in the stack
// all perfectly match the data at the literal address
// which caller is required to guarantee is exactly
// SIMD_WIDTH * \count bytes long.
// Success or failure is broadcast as a vector-wide boolean
// pushed to the top of the stack, intended for later consumption
// by the `ok1` macro.
// This macro will also yield test failure if the stack is shallower
// than \count entries deep.
// \literalAddress does NOT have to be aligned (win for PCMPEQD)
// , but Data Stack is obviously aligned by definition.
//
// `stackPartialTest` macro accepts as arguments:
// * macro "literalAddress"
// * macro "count" integer literal
// Side effect: none
// Data Stack: `stackPartialTest` pushes boolean scalar test result
// General Registers:
// * clobbers macro argument `stackIndex` defaults to %rax
// * clobbers macro argument `literalPointer` defaults to %rcx
// SIMD Registers:
// * clobbers macro argument `SIMDRegister` defaults to %xmm0
.macro stackPartialTest literalAddress:req count:req \
  SIMDRegister=%xmm0 \
  stackIndex=%rax \
  literalPointer=%rcx
stackPartialTest\@:
  mov BOTTOM_OF_CALL_STACK, \stackIndex
  sub %DATA_STACK_POINTER, \stackIndex // \stackIndex is now byte length of stack
  sar $SIMD_META_WIDTH, \stackIndex // \stackIndex is now vector length of stack
  cmp $\count, \stackIndex
  jb stackPartialTestCountTooLarge\@

  mov $\count, \stackIndex
  decq \stackIndex
  sal $SIMD_META_WIDTH, \stackIndex // \stackIndex is now $SIMD_WIDTH * (\count-1)
  lea \literalAddress, \literalPointer
  add \stackIndex, \literalPointer // Move \literalPointer to last item in literal
  add %DATA_STACK_POINTER, \stackIndex // Move \stackIndex to matching item in stack

stackPartialTestLoop\@:
  cmp %DATA_STACK_POINTER, \stackIndex
  jb stackPartialTestSuccess\@ // passed top of stack without failure yet 🎉

  movdqa (\stackIndex), \SIMDRegister
  // if unequal, set at least some bits to one.
  pxor (\literalPointer), \SIMDRegister

  // if any bits set, fail.
  ptest \SIMDRegister, \SIMDRegister
  jnz stackPartialTestFail\@

  // increment to next later memory vector
  // and to next deeper stack location
  sub $SIMD_WIDTH, \stackIndex
  sub $SIMD_WIDTH, \literalPointer
  jmp stackPartialTestLoop\@

stackPartialTestSuccess\@:
  BooleanPushTrue
  jmp stackPartialTestEnd\@

stackPartialTestCountTooLarge\@:
stackPartialTestFail\@:
  BooleanPushFalse

stackPartialTestEnd\@:
.endm

// Same as `stackPartialTest` except that
// test will ALSO fail if stack is *more* than \count entries deep.
//
// `stackFullTest` macro accepts as arguments:
// * macro "literalAddress"
// * macro "count" integer literal
// Side effect: none
// Data Stack: `stackFullTest` pushes boolean scalar test result
// General Registers:
// * clobbers macro argument `stackIndex` defaults to %rax
// * clobbers macro argument `literalPointer` defaults to %rcx
// SIMD Registers:
// * clobbers macro argument `SIMDRegister` defaults to %xmm0
.macro stackFullTest literalAddress:req count:req \
  SIMDRegister=%xmm0 \
  stackIndex=%rax \
  literalPointer=%rcx
stackFullTest\@:
  mov BOTTOM_OF_CALL_STACK, \stackIndex
  sub %DATA_STACK_POINTER, \stackIndex // \stackIndex is now byteLength of stack
  sar $SIMD_META_WIDTH, \stackIndex // \stackIndex is now vector length of stack
  cmp $\count, \stackIndex
  jne stackFullTestCountNoMatch\@

  stackPartialTest literalAddress=\literalAddress, count=\count \
    , SIMDRegister=\SIMDRegister \
    , stackIndex=\stackIndex \
    , literalPointer=\literalPointer

  jmp stackFullTestEnd\@

stackFullTestCountNoMatch\@:
  BooleanPushFalse

stackFullTestEnd\@:
.endm


// This is a quick and dirty memcopy that makes the following
// assumptions on behalf of the caller:
// * source address must be aligned to SIMD_WIDTH
// * destination addresses may be unaligned
// * space after source address is padded with null bytes to
//   align to SIMD_WIDTH (or free-to-copy garbage, Irdk)
// * said zeros or garbage WILL be copied along with the
//   valid data, despite the high likelihood of extending beyond the
//   bytelength specified.
// * Bytelength must be a literal constant integer
//
// `_crudeTestMemCopy` macro accepts as arguments:
// * macro "sourceAddress"
// * macro "destinationAddress"
// * macro "byteLength" integer
// Side effect: `_crudeTestMemCopy` macro copies ceil(byteLength/SIMD_WIDTH)
//   bytes from \sourceAddress to \destinationAddress
// Data Stack: `_crudeTestMemCopy` macro does not intentionally alter the Data Stack
// General Registers:
// * clobbers macro argument `scalarRegisterLength` defaults to %rcx
// * clobbers macro argument `scalarRegisterSource` defaults to %rax
// * clobbers macro argument `scalarRegisterDestination` defaults to %rdi
// SIMD Registers:
// * clobbers macro argument `SIMDRegister` defaults to %xmm0
.macro _crudeTestMemCopy \
  sourceAddress:req \
  destinationAddress:req \
  byteLength:req \
  SIMDRegister=%xmm0 \
  scalarRegisterLength=%rcx \
  scalarRegisterSource=%rax \
  scalarRegisterDestination=%rdi
_crudeTestMemCopy\@:
  mov $\byteLength, \scalarRegisterLength
  leaq \sourceAddress, \scalarRegisterSource
  mov \destinationAddress, \scalarRegisterDestination
_crudeTestMemCopyLoop\@:
  movdqu (\scalarRegisterSource), \SIMDRegister
  movdqu \SIMDRegister, (\scalarRegisterDestination)
  add $SIMD_WIDTH, \scalarRegisterSource
  add $SIMD_WIDTH, \scalarRegisterDestination
  sub $SIMD_WIDTH, \scalarRegisterLength
  ja _crudeTestMemCopyLoop\@
  mov \destinationAddress, \scalarRegisterDestination
  add $\byteLength, \scalarRegisterDestination
  mov \scalarRegisterDestination, \destinationAddress
.endm

// Step 1: describe (testcase pseudocode?) what behavior we want from
// this macro.
// 1. takes 2 messages as macro parameters, and consumes 1 test result
// from data stack.
// 2. Spits out happy noises or sad noises via testPointBuffer
// based upon whether Test argument is VectorTrue.
//
// General: TestPoint := ("not ")? "ok " Description "\n" (YAMLBlock)?
// Description format is responsibility of caller:
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



// `ok1` macro accepts as arguments:
// * macro "testName" string
// * macro "testFailMessage" string
// * Data Stack single full SIMD width boolean as test result
// Side effect: `ok1` macro emits to STDOUT a TAP protocol test point
// Data Stack: `ok1` macro consumes one input, creates no output.
// General Registers: Clobbers %rcx %rax %rdi
// * clobbers macro argument `ok1StringBuilder` defaults to %rdx
// * clobbers macro argument `ok1AndCrucible` defaults to %eax
// * clobbers macro argument `temporary` defaults to %r9
// SIMD Registers: clobbers %xmm0 %xmm1
.macro ok1 testName:req testFailMessage:req \
  ok1StringBuilder=%rdx \
  ok1AndCrucible=%eax \
  temporary=%r9
ok1\@:
  Bitfield64castToBoolean
  leaq testPointName(%rip), \ok1StringBuilder
  _crudeTestMemCopy testName\@(%rip), \ok1StringBuilder, testName\@Length
  _crudeTestMemCopy constantYAMLPreamble(%rip), \ok1StringBuilder, constantYAMLPreambleLength
  _crudeTestMemCopy testFailMessage\@(%rip), \ok1StringBuilder, testFailMessage\@Length
  _crudeTestMemCopy constantYAMLPost(%rip), \ok1StringBuilder, constantYAMLPostLength
  // .. not really necessary, but just in case I feel
  // like endcapping the output buffer at some point.
  // movb $0, \ok1StringBuilder

  // because of Bitfield64castToBoolean, must be a valid and mask
  mov DATA_STACK0, \ok1AndCrucible
  test \ok1AndCrucible, \ok1AndCrucible
  jz okFail\@

okSucceed\@:
  putMemoryMacro happyNoises(%rip), $happyNoises\@Length
  jmp ok1End\@

okFail\@:
  leaq sadNoises(%rip), \temporary
  sub \temporary, \ok1StringBuilder
  putMemoryMacro sadNoises(%rip), length=\ok1StringBuilder
  jmp ok1End\@

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

// `plan1` macro accepts as arguments:
// * macro `totalTestCount` literal constant unsigned integer
// ** Undefined results if totalTestCount is too large for its decimal string
//    expansion to fit within a single SIMD register.
// * macro `planReason` string
// Side effect: `plan1` macro emits to STDOUT a TAP protocol plan line
// General Registers:
// * clobbers %rdi %rsi %rdx %rcx (alien arguments 1-4)
// * clobbers %rax (alien return 1)
// SIMD Registers:
// * clobbers macro argument `SIMDRegister` defaults to %xmm0
.macro plan1 totalTestCount:req planReason:req \
  SIMDRegister=%xmm0
plan1\@:
  putLiteralMacro "1.."

// convert totalTestCount into a decimal string and print that
  mov $\totalTestCount, %ALIEN_INTEGER64_ARGUMENT1
  leaq decimalIntegerBuffer(%rip), %ALIEN_INTEGER64_ARGUMENT2
  call unsignedIntegerToStringBase10
  putMemoryMacro messageLocation=(%ALIEN_INTEGER64_RETURN1), length=%ALIEN_INTEGER64_RETURN2

// print reason
  putLiteralMacro " # "
  putLiteralMacro "\planReason"
  putNewlineMacro
.endm

// .text
// .globl _start
// _start:
//   EndAlienCallStackFrame
//   BooleanPushFalse
//   BooleanPushTrue
//   plan1 3, "Three tests .. though two of them are `todo` status. IDK"
//   ok1 "Test true should be OK", "Test true.. isn't OK?"
//   ok1 "Test false should be not OK # todo", "Err.. false succeeded I guess?"
//   Bitfield64Count
//   BooleanNot
//   ok1 "Tests should consume stack input # todo", "Huh.. stack isn't empty.."
//   Bitfield64PushZero
//   systemExit
