STDIN = 0
STDOUT = 1
STDERR = 2
sys_write = 1
 / crusade against magic numbers: Explicit Intent Edition
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

.macro putLiteralMacro message:req fileDescriptor=$STDOUT
  putMemoryMacro messageLocation=putsMessage\@(%rip),length=$putsMessage\@Length,fileDescriptor=\fileDescriptor
	jmp putsEnd\@
putsMessage\@:
  .string "\message"
  putsMessage\@Length = . - putsMessage\@
  .align 8
putsEnd\@:
.endm

// .macro putLiteralMacro message:req
//   mov $1, %rax
//   mov $1, %rdi
//   lea putsMessage\@(%rip), %rsi
//   mov $putsMessage\@Length, %rdx
//   syscall
// 	jmp putsEnd\@
// putsMessage\@:
//   .string "\message"
//   putsMessage\@Length = . - putsMessage\@
//   .align 8
// putsEnd\@:
// .endm



	.text
StringLiteral0:
	.string	"Hello\n"
HexAlphabet:
  .string "0123456789ABCDEF"
  StringLiteral0Length = . - StringLiteral0
	.globl _start

  .data
Digit: 
  .byte 5

.text
_start:
  movq $sys_write, %rax
  movq $STDOUT, %rdi
  mov Digit(%rip), %rbx
  leaq HexAlphabet(%rip), %rsi
  addq %rbx,%rsi
  movq $singleCharacterLength, %rdx
  syscall

  putNewlineMacro
  putLiteralMacro "Testing\n\n"
  systemExitMacro 69
