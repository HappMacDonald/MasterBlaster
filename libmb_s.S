#include "libmb_s.h"

.text
# Procedures

# extern void putMemoryProcedure
# ( /*rdi*/ char *message
# , /*rsi*/ uint64_t length
# , /*rdx*/ uint64_t fileDescriptor
# );
.global putMemoryProcedure
putMemoryProcedure:
  mov %rdx, %rax # put file descriptor into temporary place
  mov %rsi, %rdx # put length into newly vacated syscall arg2
  mov %rdi, %rsi # put memory location into newly freed syscall arg1
  mov %rax, %rdi # dig fd from temporary location and put into newly vacated syscall arg3
  mov $sys_write, %rax # define syscall arg0
  syscall
  ret

# extern /*???*/ uint64_t getMemoryProcedure
# ( /*rdi*/ char *messageBuffer
# , /*rsi*/ uint64_t length
# , /*rdx*/ uint64_t fileDescriptor
# );
.global getMemoryProcedure
getMemoryProcedure:
  mov %rdx, %rax # put file descriptor into temporary place
  mov %rsi, %rdx # put length into newly vacated syscall arg2
  mov %rdi, %rsi # put memory location into newly freed syscall arg1
  mov %rax, %rdi # dig fd from temporary location and put into newly vacated syscall arg3
  mov $sys_read, %rax # define syscall arg0
  syscall
  ret

# Accepts arg1(%rdi)=number to convert to hex string, and arg2(%rsi)=16 byte buffer space.
# Returns ret1(%rax)=pointer to inside of buffer where RIGHT-ALIGNED answer sits,
# and ret2(%rdx)=total length of the answer string. That is not null-terminated.
# Unused portion of buffer left of ret1(%rax) is considered clobbered.
# extern struct MasterBlasterString unsignedIntegerToStringBase16
# ( /*rdi*/ uint64_t valueToConvert
# , /*rax*/ char resultBuffer[16] // Largest possible results are 16 digits
# );
.global unsignedIntegerToStringBase16
unsignedIntegerToStringBase16:
.bufferLength = 16
.bufferLast = .bufferLength-1
  addq $.bufferLast, %rsi # advance arg2 to end of buffer
  # copy new arg2 to ret1, which will track the left side of answer.
  # arg2 will stay at the right side of answer.
  movq %rsi, %rax
0: #.loop
  movq %rdi, %rdx # copy arg1 (number to cast) into arg3
  andq $0x0F, %rdx  # mask out all but the last four bits of arg3, leaving LSnibble.
  leaq TrigentasenaryUppercaseDigits(%rip), %rcx # Load digit list address into arg4
  #####
  # ( Add nibble digit (arg3) to base of digit list (arg4)
  # , pull ASCII digit character at that location
  # , put into arg5(LSB)
  # )
  movb (%rcx,%rdx,1), %r8b
  movb %r8b, (%rax) # .. then put it into current left end of result.
  dec %rax # March left side of result further left by one byte.
  shrq $4, %rdi # demote all nibbles of arg1 by one nibble position
  jnz 0b # .loop
# .endLoop
  inc %rax # backpedal left side (ret1) to point at most recently written HSdigit
  inc %rsi # step arg2 forward to one byte past end of result/buffer
  subq %rax, %rsi # transform arg2 from "end of result&buffer" to "length of result"
  movq %rsi, %rdx # .. and then copy that to proper ret2.
  # ret1(%rax) still holds left side of result
  ret


# Accepts arg1(%rdi)=number to convert to decimal string, and arg2(%rsi)=20 byte buffer space.
# Returns ret1(%rax)=pointer to inside of buffer where RIGHT-ALIGNED answer sits,
# and ret2(%rdx)=total length of the answer string. That is not null-terminated.
# Unused portion of buffer left of ret1(%rax) is considered clobbered.
# I'm doing division, so %rdx and %rax get locked down by that process until
# the end of the procedure.

# arg1(%rdi) number to convert to decimal string
# arg2(%rsi) 20 byte buffer space .. becomes right side of answer, then length of answer.
# arg3(%rdx) gets abused as division scratchpad
# arg4(%rcx) left side of answer, copies to ret1(%rax) at the end.
# extern struct MasterBlasterString unsignedIntegerToStringBase10
# ( /*rdi*/ uint64_t valueToConvert
# , /*rsi*/ char resultBuffer[20] // Largest possible results are 20 digits
# );
.global unsignedIntegerToStringBase10
unsignedIntegerToStringBase10:
.bufferLength = 20
.bufferLast = .bufferLength-1
  addq $.bufferLast, %rsi # skip arg2 to end of buffer
  # copy arg2 to arg5, which will track the left side of answer.
  # arg2 will stay at the right side of answer.
  movq %rsi, %rcx
  movq %rdi, %rax # copy arg1 (number to cast) into Division Numerator Low Register
0: #.loop
  xor %edx, %edx # zero out Division Numerator High Register RDX
  mov $10, %edi # load numeric base (10) into arg1
  divq %rdi # divide by base: RDX = remainder, RAX = quotient
  leaq TrigentasenaryUppercaseDigits(%rip), %rdi # Load digit list address into arg1
  #####
  # ( Add digit (remainder from division) to base of digit list
  # , pull ascii/UTF-8 digit character at that location
  # , put into arg5(LSB)
  # )
  movb (%rdi,%rdx,1), %r8b
  movb %r8b, (%rcx) # .. then put it into current left end of result.
  dec %rcx # March left side of result further left by one byte.
  test %rax, %rax
  jnz 0b # .loop
# .endLoop
  inc %rcx # backpedal left side to point at most recently written HSdigit
  inc %rsi # step forward to one byte past end of result/buffer
  subq %rcx, %rsi # change arg2 from "end of result&buffer" to "length of result"
  movq %rsi, %rdx # .. and then copy that to proper ret2.
  movq %rcx, %rax # copy left side of result from arg4 to ret1
  ret

# This prints each lane of each stack element.
# Bottom of stack first, lane 1 first.
# lanes delimited by colons, stack elements delimited by newlines.
.global PrintStack
PrintStack:
  mov %DATA_STACK_POINTER, %rcx
PrintStackLoop:
  cmp BOTTOM_OF_CALL_STACK, %rcx
  jae End

# Print Lane 1 of current stack top
  mov (%rcx), %rdi
  push %rcx
  leaq MEMORY_SCRATCHPAD(%rip), %rsi
  call unsignedIntegerToStringBase16
  //%rax has new pointer to string
  //%rdx has length of new string
  putMemoryMacro messageLocation=(%rax),length=%rdx

//Print a colon
  mov $STDOUT, %rdi
  lea COLON(%rip), %rsi
  mov $singleCharacterLength, %rdx
  mov $sys_write, %rax
  syscall

//Print Lane 2 of current stack top
  pop %rcx
  mov 8(%rcx), %rdi // DATA_STACK0 lane 2
  push %rcx
  // mov 24(%DATA_STACK_POINTER), %rdi // DATA_STACK0 lane 2
  leaq MEMORY_SCRATCHPAD(%rip), %rsi
  call unsignedIntegerToStringBase16
  //%rax has new pointer to string
  //%rdx has length of new string
  putMemoryMacro messageLocation=(%rax),length=%rdx

  pop %rcx
  add $SIMD_WIDTH, %rcx
  push %rcx
  putNewlineMacro
  pop %rcx
  jmp PrintStackLoop

End:
  ret


	.data
.global TrigentasenaryUppercaseDigits
TrigentasenaryUppercaseDigits:
  .string "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

.global MEMORY_SCRATCHPAD
MEMORY_SCRATCHPAD:
.skip 512

COLON:
  .string ":"

// Align to start of a cache line. (or center of a very large one perhaps?)
.balign 64
.global ALL_LANES_0x01
ALL_LANES_0x01:
  .quad 1,1
  .quad 1,1
  .quad 1,1
  .quad 1,1

.global ALL_LANES_0x3F
ALL_LANES_0x3F: // That's 63dec, or 0011 1111 binary
  .quad 0x3F,0x3F
  .quad 0x3F,0x3F
  .quad 0x3F,0x3F
  .quad 0x3F,0x3F

