.data
StringLiteral0:
	.string	"Hello\n"
  StringLiteral0Length = . - StringLiteral0
	.text
	.globl	main

main:
  movq  $1, %rax
  movq  $1, %rdi
  leaq  StringLiteral0(%rip), %rsi
  movq  $StringLiteral0Length, %rdx
  syscall
	ret
