#include "crude_compiler.h"

# Definitions

STDIN = 0
STDOUT = 1
STDERR = 2
sys_read = 0
sys_write = 1
sys_exit = 60
# crusade against magic numbers: Explicit Intent Edition
singleCharacterLength = 1

CFunctionReturn1 = rax
CFunctionReturn2 = rdx

CFunctionArgument1 = rdi
CFunctionArgument2 = rsi
CFunctionArgument3 = rdx
CFunctionArgument4 = rcx
CFunctionArgument5 = r8
CFunctionArgument6 = r9
CFunctionReturn1 = rax
CFunctionReturn2 = rdx


# Macros

// Does not return.. yields control back to the calling shell.
.macro systemExitMacro returnValue=0
  putNewlineMacro
  mov $sys_exit, %rax
  mov $\returnValue, %rdi
  syscall
.endm

// Clobbers child-owned values
.macro putNewlineMacro fileDescriptor=$STDOUT
  mov $sys_write, %rax
  mov \fileDescriptor, %rdi
  lea aNewLine\@(%rip), %rsi
  mov $singleCharacterLength, %rdx
  syscall
	jmp putNewlineMacroEnd\@
aNewLine\@:
  .string "\n"
putNewlineMacroEnd\@:
.endm

// Clobbers child-owned values
.macro getMemoryMacro messageLocation:req length:req fileDescriptor=$STDIN
  mov \fileDescriptor, %rdi
  leaq \messageLocation, %rsi
  mov \length, %rdx
  mov $sys_read, %rax # define syscall arg0
  syscall
.endm

// Clobbers child-owned values
.macro putMemoryMacro messageLocation:req length:req fileDescriptor=$STDOUT
  mov \fileDescriptor, %rdi
  lea \messageLocation, %rsi
  mov \length, %rdx
  mov $sys_write, %rax
  syscall
.endm

// Clobbers child-owned values
.macro putLiteralMacro message:req fileDescriptor=$STDOUT
  putMemoryMacro messageLocation=putsMessage\@(%rip),length=$putsMessage\@Length,fileDescriptor=\fileDescriptor
	jmp putsEnd\@
putsMessage\@:
  .string "\message"
  putsMessage\@Length = . - putsMessage\@ - 1
  .align 8
putsEnd\@:
.endm

.macro SSE42_InkStamp0xFF stamp=%xmm15
  pcmpeqd	\stamp, \stamp
.endm

.macro SSE42_InkStamp0x00 stamp=%xmm14
  pxor	\stamp, \stamp
.endm

//destinationAddress must be a naked rip relative integer.
// eg 123 gets interpreted as 123(%rip)
//Uses stamp(xmm register), clobbers r11.
.macro SSE42_memset128BitBlocks stamp=%xmm15 destinationAddress:req repeat=1 currentIndex=0
  // .if \currentIndex-\repeat
da16 = destinationAddress + 16
  movaps \stamp, \destinationAddress(%rip)
  movaps \stamp, \da16(%rip)
  // SSE42_memset128BitBlocks stamp=\stamp,destinationAddress=\destinationAddress,repeat=\repeat,currentIndex="(\currentIndex+1)"
  // .endif
.endm

// This is an alias: alternate name
.macro SSE42_memset16ByteBlocks stamp=%xmm15 destinationAddress:req repeat=1 currentIndex=0
  SSE42_memset128BitBlocks stamp=\stamp,destinationAddress=\destinationAddress,repeat=\repeat,currentIndex=currentIndex
.endm

#define IterableRAMParentCallStackAddress CALL_STACK5
#define IterableRAMLambda CALL_STACK4
#define IterableRAMLength CALL_STACK3
#define IterableRAMDataPointer CALL_STACK2
#define IterableRAMByteCounter CALL_STACK1
#define IterableRAMLastClause CALL_STACK0

#define IterableRAMForeignLambda CALL_STACK5
#define IterableRAMForeignLength CALL_STACK4
#define IterableRAMForeignDataPointer CALL_STACK3
#define IterableRAMForeignByteCounter CALL_STACK2
#define IterableRAMForeignLastClause CALL_STACK1


#define LoopNext ret

.macro LoopBail
  add $SCALAR_NATIVE_WIDTH_IN_BYTES, %rsp # silently pop caller address
  jmp *IterableRAMLastClause # go to last clause instead of returning there.
.endm

# Pushes byte counter for beginning of current vector onto the stack
.macro LoopGetByteCount
  _Bitfield64DataStackPushRAM IterableRAMForeignByteCounter  
.endm