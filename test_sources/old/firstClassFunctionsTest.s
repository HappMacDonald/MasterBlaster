	.file	"firstClassFunctionsTest.c"
	.text
	.globl	q
	.bss
	.align 8
	.type	q, @object
	.size	q, 8
q:
	.zero	8
	.text
	.globl	a
	.type	a, @function
a:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	movl	%edi, -4(%rbp)
	movq	q(%rip), %rdx
	movl	-4(%rbp), %eax
	movl	%eax, %edi
	call	*%rdx
	leave
	ret
	.size	a, .-a
	.globl	b
	.type	b, @function
b:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	movl	%edi, -4(%rbp)
	movq	q(%rip), %rdx
	movl	-4(%rbp), %eax
	movl	%eax, %edi
	call	*%rdx
	leave
	ret
	.size	b, .-b
	.globl	main
	.type	main, @function
main:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	movl	%edi, -20(%rbp)
	leaq	a(%rip), %rax
	movq	%rax, -16(%rbp)
	leaq	b(%rip), %rax
	movq	%rax, -8(%rbp)
	movl	-20(%rbp), %eax
	cltq
	movq	-16(%rbp,%rax,8), %rax
	movq	%rax, q(%rip)
	movl	-20(%rbp), %eax
	cltq
	movq	-16(%rbp,%rax,8), %rdx
	movl	-20(%rbp), %eax
	movl	%eax, %edi
	call	*%rdx
	leave
	ret
	.size	main, .-main
	.ident	"GCC: (Debian 10.2.1-6) 10.2.1 20210110"
	.section	.note.GNU-stack,"",@progbits
