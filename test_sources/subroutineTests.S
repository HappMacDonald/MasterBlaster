#include "TestAnythingProtocolProducer_s.h"

.text

MEMORY_SCRATCHPAD_PART2 = MEMORY_SCRATCHPAD + 8
MEMORY_SCRATCHPAD_BYTE_15 = MEMORY_SCRATCHPAD + 15


.globl _start
_start:
  EndAlienCallStackFrame


/****************************************************************************
** _unsignedIntegerToStringBase16 Test hex rendering of 0x1111111111111111 **
****************************************************************************/

.memoryBlock Expected_0x1111111111111111
31313131 31313131 31313131 31313131
.endMemoryBlock
  Expected_0x1111111111111111_Part2 = Expected_0x1111111111111111 + 8

  plan1 999 "subroutine tests"

  movq $0x1111111111111111, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq MEMORY_SCRATCHPAD(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase16

  // Test that ALIEN_INTEGER64_RETURN1 == MEMORY_SCRATCHPAD(%rip)
  leaq MEMORY_SCRATCHPAD(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $16
  sub $16, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that first 8 bytes at Expected_0x1111111111111111 matches MEMORY_SCRATCHPAD(%rip)
  _DataStackPushFromRAM Expected_0x1111111111111111(%rip)
  _DataStackPushFromRAM MEMORY_SCRATCHPAD(%rip)
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that last 8 bytes at Expected_0x1111111111111111 matches MEMORY_SCRATCHPAD(%rip)
  _DataStackPushFromRAM Expected_0x1111111111111111_Part2(%rip), aligned=FALSE
  _DataStackPushFromRAM MEMORY_SCRATCHPAD_PART2(%rip), aligned=FALSE
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
  Expected_0xDEADBEEF01234567_Part2 = Expected_0xDEADBEEF01234567 + 8

  movq $0xDEADBEEF01234567, %ALIEN_INTEGER64_ARGUMENT1 // numeric value to render into hex
  leaq MEMORY_SCRATCHPAD(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase16

  // Test that ALIEN_INTEGER64_RETURN1 == MEMORY_SCRATCHPAD(%rip)
  leaq MEMORY_SCRATCHPAD(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $16
  sub $16, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that first 8 bytes at Expected_0xDEADBEEF01234567 matches MEMORY_SCRATCHPAD(%rip)
  _DataStackPushFromRAM Expected_0xDEADBEEF01234567(%rip)
  _DataStackPushFromRAM MEMORY_SCRATCHPAD(%rip)
  BooleanXor
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that last 8 bytes at Expected_0xDEADBEEF01234567 matches MEMORY_SCRATCHPAD(%rip)
  _DataStackPushFromRAM Expected_0xDEADBEEF01234567_Part2(%rip), aligned=FALSE
  _DataStackPushFromRAM MEMORY_SCRATCHPAD_PART2(%rip), aligned=FALSE
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
  leaq MEMORY_SCRATCHPAD(%rip), %ALIEN_INTEGER64_ARGUMENT2 // place to print it
  call _unsignedIntegerToStringBase16

  // Test that ALIEN_INTEGER64_RETURN1 == MEMORY_SCRATCHPAD(%rip) + 15
  leaq MEMORY_SCRATCHPAD(%rip), %r9
  sub %r9, %ALIEN_INTEGER64_RETURN1
  sub $15, %ALIEN_INTEGER64_RETURN1
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN1
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that ALIEN_INTEGER64_RETURN2 == $1
  sub $1, %ALIEN_INTEGER64_RETURN2
  _Bitfield64DataStackPushGeneral register=%ALIEN_INTEGER64_RETURN2
  Bitfield64BooleanNot // we want 0 to mean true

  // Test that the only byte at Expected_0x7 matches MEMORY_SCRATCHPAD(%rip)
  movq $0, %rax
  movb Expected_0x7(%rip), %al
  movq $0, %rdi
  movb MEMORY_SCRATCHPAD_BYTE_15(%rip), %dil
  xor %rdi, %rax
  _Bitfield64DataStackPushGeneral register=%rax
  Bitfield64BooleanNot // we want 0 to mean true

  // process pushed test results in reverse/pop order
  ok1 "$0x7 contents", "$0x7 contents were wrong"
  ok1 "$0x7 length", "$0x7 length was wrong"
  ok1 "$0x7 buffer start", "$0x7 buffer start was wrong"

  systemExit
