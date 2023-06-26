#include "TestAnythingProtocolProducer_s.h"

.data
.global OUTPUT_BUFFER
OUTPUT_BUFFER:
.skip 20


OUTPUT_BUFFER_BYTE_1 = OUTPUT_BUFFER + 1
OUTPUT_BUFFER_BYTE_2 = OUTPUT_BUFFER + 2
OUTPUT_BUFFER_BYTE_3 = OUTPUT_BUFFER + 3
OUTPUT_BUFFER_BYTE_4 = OUTPUT_BUFFER + 4
OUTPUT_BUFFER_BYTE_5 = OUTPUT_BUFFER + 5
OUTPUT_BUFFER_BYTE_6 = OUTPUT_BUFFER + 6
OUTPUT_BUFFER_BYTE_7 = OUTPUT_BUFFER + 7
OUTPUT_BUFFER_BYTE_8 = OUTPUT_BUFFER + 8
OUTPUT_BUFFER_BYTE_9 = OUTPUT_BUFFER + 9
OUTPUT_BUFFER_BYTE_14 = OUTPUT_BUFFER + 14
OUTPUT_BUFFER_BYTE_15 = OUTPUT_BUFFER + 15
OUTPUT_BUFFER_BYTE_16 = OUTPUT_BUFFER + 16
OUTPUT_BUFFER_BYTE_17 = OUTPUT_BUFFER + 17
OUTPUT_BUFFER_BYTE_18 = OUTPUT_BUFFER + 18


.text
.globl _start
_start:
  EndAlienCallStackFrame


/****************************************************************************
** _unsignedIntegerToStringBase16 Test hex rendering of 0x1111111111111111 **
****************************************************************************/

.memoryBlock Expected_0x1111111111111111
31313131 31313131 31313131 31313131
.endMemoryBlock
  Expected_0x1111111111111111_BYTE_8 = Expected_0x1111111111111111 + 8

  plan1 24 "subroutine tests"

  movq $0x1111111111111111, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq OUTPUT_BUFFER(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase16

  // Test that ALIEN_INTEGER64_RETURN1 == OUTPUT_BUFFER(%rip)
  leaq OUTPUT_BUFFER(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $16
  sub $16, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that first 8 bytes at Expected_0x1111111111111111 matches OUTPUT_BUFFER(%rip)
  _DataStackPushFromRAM Expected_0x1111111111111111(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER(%rip), aligned=FALSE
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that last 8 bytes at Expected_0x1111111111111111 matches OUTPUT_BUFFER(%rip)
  _DataStackPushFromRAM Expected_0x1111111111111111_BYTE_8(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER_BYTE_8(%rip), aligned=FALSE
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // process pushed test results in reverse/pop order
  ok1 "$0x1111111111111111 contents Part 2", "$0x1111111111111111 contents Part 2 were wrong"
  ok1 "$0x1111111111111111 contents Part 1", "$0x1111111111111111 contents Part 1 were wrong"
  ok1 "$0x1111111111111111 length", "$0x1111111111111111 length was wrong"
  ok1 "$0x1111111111111111 buffer start", "$0x1111111111111111 buffer start was wrong"



/****************************************************************************
** _unsignedIntegerToStringBase16 Test hex rendering of 0xDEADBEEF01234567 **
****************************************************************************/

.memoryBlock Expected_0xDEADBEEF01234567
44454144 42454546 30313233 34353637
.endMemoryBlock
  Expected_0xDEADBEEF01234567_BYTE_8 = Expected_0xDEADBEEF01234567 + 8

  movq $0xDEADBEEF01234567, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq OUTPUT_BUFFER(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase16

  // Test that ALIEN_INTEGER64_RETURN1 == OUTPUT_BUFFER(%rip)
  leaq OUTPUT_BUFFER(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $16
  sub $16, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that first 8 bytes at Expected_0xDEADBEEF01234567 matches OUTPUT_BUFFER(%rip)
  _DataStackPushFromRAM Expected_0xDEADBEEF01234567(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER(%rip), aligned=FALSE
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that last 8 bytes at Expected_0xDEADBEEF01234567 matches OUTPUT_BUFFER(%rip)
  _DataStackPushFromRAM Expected_0xDEADBEEF01234567_BYTE_8(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER_BYTE_8(%rip), aligned=FALSE
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // process pushed test results in reverse/pop order
  ok1 "$0xDEADBEEF01234567 contents Part 2", "$0xDEADBEEF01234567 contents Part 2 were wrong"
  ok1 "$0xDEADBEEF01234567 contents Part 1", "$0xDEADBEEF01234567 contents Part 1 were wrong"
  ok1 "$0xDEADBEEF01234567 length", "$0xDEADBEEF01234567 length was wrong"
  ok1 "$0xDEADBEEF01234567 buffer start", "$0xDEADBEEF01234567 buffer start was wrong"



/*************************************************************
** _unsignedIntegerToStringBase16 Test hex rendering of 0x7 **
**************************************************************/

.memoryBlock Expected_0x7
37
.endMemoryBlock

  movq $0x7, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq OUTPUT_BUFFER(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase16

  // Test that ALIEN_INTEGER64_RETURN1 == OUTPUT_BUFFER(%rip) + 15
  leaq OUTPUT_BUFFER(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  sub $15, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $1
  sub $1, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that the only byte at Expected_0x7 matches OUTPUT_BUFFER(%rip)
  movq $0, %rax
  movb Expected_0x7(%rip), %al
  movq $0, %rdi
  movb OUTPUT_BUFFER_BYTE_15(%rip), %dil
  xor %rdi, %rax
  _Bitfield64DataStackPushGeneral register=%rax
  Bitfield64BooleanNot // we want 0 to mean true

  // process pushed test results in reverse/pop order
  ok1 "$0x7 contents", "$0x7 contents were wrong"
  ok1 "$0x7 length", "$0x7 length was wrong"
  ok1 "$0x7 buffer start", "$0x7 buffer start was wrong"



/****************************************************************************
****************************************************************************/



/****************************************************************************
** _unsignedIntegerToStringBase10 Test hex rendering of 0x1111111111111112 **
****************************************************************************/

// 1229782938247303441
.memoryBlock Expected_0x1111111111111112
31323239 37383239 33383234 37333033 343432
.endMemoryBlock
  Expected_0x1111111111111112_BYTE_8 = Expected_0x1111111111111112 + 8
  Expected_0x1111111111111112_BYTE_16 = Expected_0x1111111111111112 + 16

  movq $0x1111111111111112, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq OUTPUT_BUFFER(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase10

  // Test that ALIEN_INTEGER64_RETURN1 == OUTPUT_BUFFER(%rip)+1
  leaq OUTPUT_BUFFER(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  sub $1, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $19
  sub $19, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // putMemoryMacro messageLocation=OUTPUT_BUFFER_BYTE_1(%rip), length=$19
  putNewlineMacro
  // putMemoryMacro messageLocation=Expected_0x1111111111111112(%rip), length=$19
  putNewlineMacro

  // Test that first 8 bytes at Expected_0x1111111111111112 matches OUTPUT_BUFFER(%rip)
  // (the latter right-aligned)
  _DataStackPushFromRAM Expected_0x1111111111111112(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER_BYTE_1(%rip), aligned=FALSE
  // PrintStackMessage "$0x1111111111111112 contents Part 1"
  BooleanXor
  // PrintStackMessage "$0x1111111111111112 contents Part 1 after XOR"
  Bitfield64BooleanNot // we want 0 to mean true
  // PrintStackMessage "$0x1111111111111112 contents Part 1 after Not"

  // Test that second 8 bytes at Expected_0x1111111111111112 matches OUTPUT_BUFFER(%rip)
  // (the latter right-aligned)
  _DataStackPushFromRAM Expected_0x1111111111111112_BYTE_8(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER_BYTE_9(%rip), aligned=FALSE
  // PrintStackMessage "$0x1111111111111112 contents Part 2"
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that last 3 bytes at Expected_0x1111111111111112 matches OUTPUT_BUFFER(%rip)
  // (the latter right-aligned)
  _DataStackPushFromRAM Expected_0x1111111111111112_BYTE_16(%rip), aligned=FALSE
  movq $0xFFFFFF, %rax // mask for only first three bytes of this chunk
  _Bitfield64DataStackPushGeneral register=%rax
  BooleanAnd
  _DataStackPushFromRAM OUTPUT_BUFFER_BYTE_17(%rip), aligned=FALSE
  _Bitfield64DataStackPushGeneral register=%rax
  BooleanAnd
  // PrintStackMessage "$0x1111111111111112 contents Part 3"
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // process pushed test results in reverse/pop order
  ok1 "$0x1111111111111112 contents Part 3", "$0x1111111111111112 contents Part 3 were wrong"
  ok1 "$0x1111111111111112 contents Part 2", "$0x1111111111111112 contents Part 2 were wrong"
  ok1 "$0x1111111111111112 contents Part 1", "$0x1111111111111112 contents Part 1 were wrong"
  ok1 "$0x1111111111111112 length", "$0x1111111111111112 length was wrong"
  ok1 "$0x1111111111111112 buffer start", "$0x1111111111111112 buffer start was wrong"



/****************************************************************************
** _unsignedIntegerToStringBase10 Test hex rendering of 0xDEADBEEF01234568 **
****************************************************************************/

// 16045690981116495207
.memoryBlock Expected_0xDEADBEEF01234568
31363034 35363930 39383131 31363439 35323038
.endMemoryBlock
  Expected_0xDEADBEEF01234568_BYTE_8 = Expected_0xDEADBEEF01234568 + 8
  Expected_0xDEADBEEF01234568_BYTE_16 = Expected_0xDEADBEEF01234568 + 16

  movq $0xDEADBEEF01234568, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq OUTPUT_BUFFER(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase10

  // Test that ALIEN_INTEGER64_RETURN1 == OUTPUT_BUFFER(%rip)
  leaq OUTPUT_BUFFER(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $20
  sub $20, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // putMemoryMacro messageLocation=OUTPUT_BUFFER(%rip), length=$20
  putNewlineMacro
  // putMemoryMacro messageLocation=Expected_0xDEADBEEF01234568(%rip), length=$20
  putNewlineMacro

  // Test that first 8 bytes at Expected_0xDEADBEEF01234568 matches OUTPUT_BUFFER(%rip)
  // (the latter right-aligned)
  _DataStackPushFromRAM Expected_0xDEADBEEF01234568(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER(%rip), aligned=FALSE
  // PrintStackMessage "$0xDEADBEEF01234568 contents Part 1"
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that second 8 bytes at Expected_0xDEADBEEF01234568 matches OUTPUT_BUFFER(%rip)
  // (the latter right-aligned)
  _DataStackPushFromRAM Expected_0xDEADBEEF01234568_BYTE_8(%rip), aligned=FALSE
  _DataStackPushFromRAM OUTPUT_BUFFER_BYTE_8(%rip), aligned=FALSE
  // PrintStackMessage "$0xDEADBEEF01234568 contents Part 2"
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that last 3 bytes at Expected_0xDEADBEEF01234568 matches OUTPUT_BUFFER(%rip)
  // (the latter right-aligned)
  _DataStackPushFromRAM Expected_0xDEADBEEF01234568_BYTE_16(%rip), aligned=FALSE
  movq $0xFFFFFFFF, %rax // mask for only first four bytes of this chunk
  _Bitfield64DataStackPushGeneral register=%rax
  BooleanAnd
  _DataStackPushFromRAM OUTPUT_BUFFER_BYTE_16(%rip), aligned=FALSE
  _Bitfield64DataStackPushGeneral register=%rax
  BooleanAnd
  // PrintStackMessage "$0xDEADBEEF01234568 contents Part 3"
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // process pushed test results in reverse/pop order
  ok1 "$0xDEADBEEF01234568 contents Part 3", "$0xDEADBEEF01234568 contents Part 3 were wrong"
  ok1 "$0xDEADBEEF01234568 contents Part 2", "$0xDEADBEEF01234568 contents Part 2 were wrong"
  ok1 "$0xDEADBEEF01234568 contents Part 1", "$0xDEADBEEF01234568 contents Part 1 were wrong"
  ok1 "$0xDEADBEEF01234568 length", "$0xDEADBEEF01234568 length was wrong"
  ok1 "$0xDEADBEEF01234568 buffer start", "$0xDEADBEEF01234568 buffer start was wrong"



/*************************************************************
** _unsignedIntegerToStringBase10 Test hex rendering of 0xB **
**************************************************************/

// 11
.memoryBlock Expected_0xB
3131
.endMemoryBlock

  movq $0xB, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq OUTPUT_BUFFER(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase10

  // Test that ALIEN_INTEGER64_RETURN1 == OUTPUT_BUFFER(%rip) + 18
  leaq OUTPUT_BUFFER(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  sub $18, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $2
  sub $2, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // putMemoryMacro messageLocation=OUTPUT_BUFFER(%rip), length=$2
  putNewlineMacro
  // putMemoryMacro messageLocation=Expected_0xB(%rip), length=$2
  putNewlineMacro


  // Test that the two bytes at Expected_0xB match OUTPUT_BUFFER(%rip)
  // (the latter right-aligned)
  movq $0, %rax
  movw Expected_0xB(%rip), %ax
  movq $0, %rdi
  movw OUTPUT_BUFFER_BYTE_18(%rip), %di
  xor %rdi, %rax
  _Bitfield64DataStackPushGeneral register=%rax
  Bitfield64BooleanNot // we want 0 to mean true

  // process pushed test results in reverse/pop order
  ok1 "$0xB contents", "$0xB contents were wrong"
  ok1 "$0xB length", "$0xB length was wrong"
  ok1 "$0xB buffer start", "$0xB buffer start was wrong"

  systemExit
