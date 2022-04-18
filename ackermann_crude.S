#include "libmb_s.h"

.text

// In Push order we have `N M`.
Ackermann:
//PrintStackMessage "[A1"
  Duplicate
  Immediate 0
  ScalarBranchNotEqual Ackermann2 forceBranchCallerToReturn=TRUE // M!=0?
  DataStackRetreat // If M==0, then pop M
  Immediate 1
  UnsignedInteger63add // M+=1
//PrintStackMessage "/A1]"
  ret // Consumed `N M` returning just M+1

// In Push order we have `N M`.
Ackermann2:
//PrintStackMessage "(A2"
  pop %rax // Skip caller's frame
  Exchange // `M N`
  Duplicate
  Immediate 0
  ScalarBranchNotEqual Ackermann3 forceBranchCallerToReturn=TRUE // N!=0?
  DataStackRetreat // If N==0, then pop N
  Immediate 1 // `M 1`
  Exchange // `1 M`
  Immediate -1 // `1 M -1`
  UnsignedInteger63add // `1 (M-1)`
  BranchUnconditional Ackermann // Calculate Ackermann(M=M-1, N=1)
//PrintStackMessage "/A2)"
  ret // return Ackermann M=M-1, N=1

// In Push order we have `M N`. (STACK0 == N)
Ackermann3:
//PrintStackMessage "{A3"
  Immediate -1 // `M N -1`
  UnsignedInteger63add // `M (N-1)`
  Immediate 2 // `M (N-1) 2`
  Index // `M (N-1) M`
//PrintStackMessage "{{A3 interior call"
  BranchUnconditional Ackermann // Calculate Ackermann(M=M, N=N-1) => `A`
//PrintStackMessage "/A3 interior call}}"
  // `M A`
  Exchange // `A M`
  Immediate -1 // `A M -1`
  UnsignedInteger63add // `A (M-1)`
//PrintStackMessage "{{A3 exterior call"
  BranchUnconditional Ackermann // Calculate Ackermann(M=M-1, N=A=Ackerman(M=M, N=N-1))
//PrintStackMessage "}}/A3}"
  ret

.globl _start
_start:
  // Treating inbound rbp=0 as parent's stack frame.
  EndAlienCallStackFrame

  putLiteralMacro "Starting.."
  Immediate 1
  Immediate 4
  call Ackermann
  PrintStackMessage "Output:"
  systemExit
