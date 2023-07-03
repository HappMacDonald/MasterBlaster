#define SCALAR_LESS_THAN 0
#define SCALAR_BELOW 0
#define SCALAR_GREATER_THAN 1
#define SCALAR_ABOVE 1
#define SCALAR_EQUAL 2
#define SCALAR_ZERO 2
#define SCALAR_XNOR 2
#define SCALAR_AND 3
#define SCALAR_GREATER_THAN_OR_EQUAL 4
#define SCALAR_ABOVE_OR_EQUAL 4
#define SCALAR_LESS_THAN_OR_EQUAL 5
#define SCALAR_BELOW_OR_EQUAL 5
#define SCALAR_NOT_EQUAL 6
#define SCALAR_NONZERO 6
#define SCALAR_XOR 6
#define SCALAR_NAND 7
#define SCALAR_ALWAYS 8
#define SCALAR_TRUE 8
#define SCALAR_UNCONDITIONAL 8

#define SCALAR_MASK_OUTPUT_NOT 4
#define SCALAR_MASK_BITWISE 2
#define SCALAR_MASK_BIGGER 1
#define SCALAR_MASK_AND 1

.macro ScalarBranch mode=SCALAR_UNCONDITIONAL
  .if \mode & SCALAR_MASK_BIGGER
    mov $2, %ax
  .endif
.endm

.text

.globl _start
_start:
  mov $1, %ax
  ScalarBranch mode=SCALAR_GREATER_THAN
  mov $1, %ax