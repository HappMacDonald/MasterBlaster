#include "TestAnythingProtocolProducer_s.h"

#define ARBITRARY_DATA_STACK_BOOKEND 0x666

.memoryBlock Expected_TRUE
FFFFFFFFFFFFFFFF FFFFFFFFFFFFFFFF
6606000000000000 6606000000000000
.endMemoryBlock

.memoryBlock Expected_FALSE
0000000000000000 0000000000000000
6606000000000000 6606000000000000
.endMemoryBlock

.macro TestRun operandA:req operandB:req operatorFullName:req operator:req expectation:req
  ClearDataStack
  Bitfield64Immediate ARBITRARY_DATA_STACK_BOOKEND
  // PrintStackMessage \operatorFullName
  Bitfield64Immediate FALSE
  Bitfield64Immediate \operandA
  Bitfield64Immediate \operandB
  PrintStackMessage "\operandA \operator\() \operandB"
  \operatorFullName doingStuff
  // .if !\expectation
  //   Bitfield64BooleanNot
  // .endif

  PrintStackMessage "\operandA \operator\() \operandB result"
  stackFullTest \expectation(%rip), 2
  ok1 "\operandA \operator\() \operandB", "oof"
  ClearDataStack

.endm

.text
doingStuff:
  PrintStackMessage "About to do stuff:"
  DataStackRetreat
  Bitfield64Immediate TRUE
  ret

.globl _start
_start:
  // Treating inbound rbp=0 as parent's stack frame.
  EndAlienCallStackFrame

  plan1 41 "Scalar Branch Tests"

  Bitfield64Immediate ARBITRARY_DATA_STACK_BOOKEND
  PrintStackMessage "Starting test: Unconditional"
  Bitfield64Immediate FALSE
  BranchUnconditional doingStuff
  PrintStackMessage "Starting test: Unconditional result"
  stackFullTest Expected_TRUE(%rip), 2
  ok1 "Starting test: Unconditional", "oof"
  ClearDataStack

  TestRun 5, 1,   "Bitfield64BranchLessThan", "<", Expected_FALSE
  TestRun 1, 4,   "Bitfield64BranchLessThan", "<", Expected_TRUE
  TestRun 8, 8,   "Bitfield64BranchLessThan", "<", Expected_FALSE
  TestRun -16, 7, "Bitfield64BranchLessThan", "<", Expected_FALSE
  TestRun 7, -3,  "Bitfield64BranchLessThan", "<", Expected_TRUE
  PutNewlineMacro

  TestRun 5, 1,   "Bitfield64BranchGreaterThan", ">", Expected_TRUE
  TestRun 1, 4,   "Bitfield64BranchGreaterThan", ">", Expected_FALSE
  TestRun 8, 8,   "Bitfield64BranchGreaterThan", ">", Expected_FALSE
  TestRun -16, 7, "Bitfield64BranchGreaterThan", ">", Expected_TRUE
  TestRun 7, -3,  "Bitfield64BranchGreaterThan", ">", Expected_FALSE
  PutNewlineMacro

  TestRun 5, 1,   "Bitfield64BranchEqual", "==", Expected_FALSE
  TestRun 1, 4,   "Bitfield64BranchEqual", "==", Expected_FALSE
  TestRun 8, 8,   "Bitfield64BranchEqual", "==", Expected_TRUE
  TestRun -16, 7, "Bitfield64BranchEqual", "==", Expected_FALSE
  TestRun 7, -3,  "Bitfield64BranchEqual", "==", Expected_FALSE
  PutNewlineMacro

  TestRun 5, 1,   "Bitfield64BranchAnd", "&", Expected_TRUE
  TestRun 1, 4,   "Bitfield64BranchAnd", "&", Expected_FALSE
  TestRun 8, 8,   "Bitfield64BranchAnd", "&", Expected_TRUE
  TestRun -16, 7, "Bitfield64BranchAnd", "&", Expected_FALSE
  TestRun 7, -3,  "Bitfield64BranchAnd", "&", Expected_TRUE
  PutNewlineMacro

  TestRun 5, 1,   "Bitfield64BranchGreaterThanOrEqual", ">=", Expected_TRUE
  TestRun 1, 4,   "Bitfield64BranchGreaterThanOrEqual", ">=", Expected_FALSE
  TestRun 8, 8,   "Bitfield64BranchGreaterThanOrEqual", ">=", Expected_TRUE
  TestRun -16, 7, "Bitfield64BranchGreaterThanOrEqual", ">=", Expected_TRUE
  TestRun 7, -3,  "Bitfield64BranchGreaterThanOrEqual", ">=", Expected_FALSE
  PutNewlineMacro

  TestRun 5, 1,   "Bitfield64BranchLessThanOrEqual", "<=", Expected_FALSE
  TestRun 1, 4,   "Bitfield64BranchLessThanOrEqual", "<=", Expected_TRUE
  TestRun 8, 8,   "Bitfield64BranchLessThanOrEqual", "<=", Expected_TRUE
  TestRun -16, 7, "Bitfield64BranchLessThanOrEqual", "<=", Expected_FALSE
  TestRun 7, -3,  "Bitfield64BranchLessThanOrEqual", "<=", Expected_TRUE
  PutNewlineMacro

  TestRun 5, 1,   "Bitfield64BranchNotEqual", "!=", Expected_TRUE
  TestRun 1, 4,   "Bitfield64BranchNotEqual", "!=", Expected_TRUE
  TestRun 8, 8,   "Bitfield64BranchNotEqual", "!=", Expected_FALSE
  TestRun -16, 7, "Bitfield64BranchNotEqual", "!=", Expected_TRUE
  TestRun 7, -3,  "Bitfield64BranchNotEqual", "!=", Expected_TRUE
  PutNewlineMacro

  TestRun 5, 1,   "Bitfield64BranchNand", "NAND", Expected_FALSE
  TestRun 1, 4,   "Bitfield64BranchNand", "NAND", Expected_TRUE
  TestRun 8, 8,   "Bitfield64BranchNand", "NAND", Expected_FALSE
  TestRun -16, 7, "Bitfield64BranchNand", "NAND", Expected_TRUE
  TestRun 7, -3,  "Bitfield64BranchNand", "NAND", Expected_FALSE
  PutNewlineMacro

  Bitfield64Immediate 0
  systemExit
