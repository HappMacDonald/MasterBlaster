STDIN = 0
STDOUT = 1
STDERR = 2
sys_write = 1
# crusade against magic numbers: Explicit Intent Edition
singleCharacterLength = 1

.macro systemExitMacro returnValue=0
  putNewlineMacro
  mov $60, %rax
  mov $\returnValue, %rdi
  syscall
.endm

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

.macro putMemoryMacro messageLocation:req length:req fileDescriptor=$STDOUT
  mov $sys_write, %rax
  mov \fileDescriptor, %rdi
  lea \messageLocation, %rsi
  mov \length, %rdx
  syscall
.endm

# arg1 %rdi = memory location
# arg2 %rsi = length
# arg3 %rdx = file descriptor
putMemoryProcedure:
  mov %rdx, %rax # put file descriptor into temporary place
  mov %rsi, %rdx # put length into newly vacated syscall arg2
  mov %rdi, %rsi # put memory location into newly freed syscall arg1
  mov %rax, %rdi # dig fd from temporary location and put into newly vacated syscall arg3
  mov $sys_write, %rax # define syscall arg0
  syscall
  ret

.macro putLiteralMacro message:req fileDescriptor=$STDOUT
  putMemoryMacro messageLocation=putsMessage\@(%rip),length=$putsMessage\@Length,fileDescriptor=\fileDescriptor
	jmp putsEnd\@
putsMessage\@:
  .string "\message"
  putsMessage\@Length = . - putsMessage\@
  .align 8
putsEnd\@:
.endm

# Accepts arg1(%rdi)=number to convert to hex string, and arg2(%rsi)=16 byte buffer space.
# Returns ret1(%rax)=pointer to inside of buffer where RIGHT-ALIGNED answer sits,
# and ret2(%rdx)=total length of the answer string. That is not null-terminated.
unsignedIntegerToString:
  addq $0x10, %rsi # skip arg2 to end of buffer
  # copy arg2 to ret1, which will track the left side of answer.
  # arg2 will stay at the right side of answer.
  movq %rsi, %rax
.loop:
  movq %rdi, %rdx # copy arg1 (number to cast) into arg3
  andq $0x0F, %rdx  # mask out all but the last four bits of arg3, leaving LSnibble.
  leaq HexAlphabet(%rip), %rcx # Load hex alphabet address into arg4
  # addq %rdx, %rcx
  #####
  # ( Add digit to base of hex alphabet
  # , pull digit at that location
  # , put into arg5(LSB)
  # )
  movb (%rcx,%rdx,1), %r8b
  movb %r8b, (%rax) # .. then put it into current end of buffer.
  dec %rax # March left side of buffer further elft by one byte.
  shrq $4, %rdi # demote all nibbles of arg1 by one nibble position
  jnz .loop
.endLoop:
  inc %rax # step back forward to last written digit
  inc %rsi # step right side one past final digit
  subq %rax, %rsi # change arg2 from "end of buffer" to "length of buffer"
  movq %rsi, %rdx # .. and then copy that to proper ret2.
  # ret1(%rax) still holds left side of buffer
  ret

	.data
HexAlphabet:
  .string "0123456789ABCDEF"
	.globl _start

  .data
numberPrintBuffer:
  .skip 16

.text
_start:
  movq $65535, %rdi
  leaq numberPrintBuffer(%rip), %rsi
  call unsignedIntegerToString
  mov %rax, %rdi # move memory location from ret1 into arg1
  mov %rdx, %rsi # move length from ret2 into arg2
  mov $STDOUT, %rdx # define recently vacated arg3
  call putMemoryProcedure
  putNewlineMacro
  systemExitMacro 69
