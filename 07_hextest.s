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


unsignedIntegerToString:
  # copy argument two (buffer location) to return register.
  # return register will represent start of buffer, arg2 represent end FTTB.
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
  movb %r8b, (%rsi) # .. then put it into current end of buffer.
  inc %rsi # March end of buffer forward by one byte.
  shrq $4, %rdi # demote all nibbles of arg1 by one nibble position
  jnz .loop
.endLoop:
  subq %rax, %rsi # change arg2 from "end of buffer" to "length of buffer".
  ret

	.text
StringLiteral0:
	.string	"Hello\n"
  StringLiteral0Length = . - StringLiteral0
HexAlphabet:
  .string "0123456789ABCDEF"
	.globl _start

  .data
Digit: 
  .byte 0x3F
numberPrintBuffer:
  .skip 16

.text
_start:
  movq $0x3F, %rdi
  leaq numberPrintBuffer(%rip), %rsi
  call unsignedIntegerToString
#  putMemoryMacro messageLocation=(%rax), length=%rsi
  mov %rax, %rdi # move memory location from first return integer into arg1
  # Length at second return integer already is arg2
  mov $STDOUT, %rdx # define arg3
  call putMemoryProcedure
  putNewlineMacro
  # movq $sys_write, %rax
  # movq $STDOUT, %rdi
  # mov Digit(%rip), %rbx
  # leaq HexAlphabet(%rip), %rsi
  # addq %rbx,%rsi
  # movq $singleCharacterLength, %rdx
  # syscall
  # putNewlineMacro
  # putLiteralMacro "Testing\n\n"
  # putMemoryMacro StringLiteral0(%rip), $StringLiteral0Length
  systemExitMacro 69
