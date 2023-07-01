	.globl	main
main:
	mov	$2, %rax
	cmp	$0, %rax
	mov	$0, %rax
	sete	%al
	cmp	$0, %rax
	mov	$0, %rax
	sete	%al
	ret

