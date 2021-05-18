# Definitions

STDIN = 0
STDOUT = 1
STDERR = 2
sys_write = 1
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

