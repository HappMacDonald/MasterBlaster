#include "libmb_s.h"
#include "tokenizer_tokens.h"

BUFFER_LENGTH=4096

.data
.balign SIMD_WIDTH
inputBufferByteLength:
.skip SIMD_WIDTH, 0
inputBuffer: // this area is considered unaligned
.skip BUFFER_LENGTH
.balign SIMD_WIDTH
outputBufferByteLength:
.skip SIMD_WIDTH, 0
outputBuffer: // this area is considered unaligned
.skip BUFFER_LENGTH
.text

scanVector:
  Bitfield64Immediate 0 // scalar64 index into list of tokens
  // Stack now contains (in push order, each value scalar64broadcast):
  // total number of bytes of input in our buffer
  // total number of valid tokens
  // current index into inputBuffer
  // index into list of tokens
scanTokenLoop:
  indexedRAMtoStack metaIndex=2 basePointer=inputBuffer(%rip)
  // now we have: inputIndex, tokenIndex, raw chunk of input bytes to scan.
  indexedRAMtoStack metaIndex=2 basePointer=tokenLiterals(%rip)
  // now we have: input length, token length
  // , inputIndex, tokenIndex
  // , raw chunk of input bytes to scan
  // , raw readout of first token to compare.

  Duplicate
  Bitfield64Immediate 0 // 0 to compare a copy of token against and get a mask
  Bitfield8Equal
  Bitfield8BooleanNot
  // now we have: input length, token length
  // , inputIndex, tokenIndex
  // , raw chunk of input bytes to scan
  // , raw readout of first token to compare.
  // , mask of valid bytes in first token to compare
  VectorBranchMaskEqual matchFound TRUE
  
  ret

matchFound:
  // now we have: input length, token length
  // , inputIndex, tokenIndex
  // , raw chunk of input bytes to scan
  // , all lanes TRUE if we have matched the token.
  PrintStackMessage "Token found .. er .. I think its index is on this stack somewhereplace?"
  Bitfield64Immediate 9
  systemExit


.globl _start
_start:
  EndAlienCallStackFrame
//vvvvvvvvvv
  getMemoryMacro messageLocation=inputBuffer(%rip),length=$BUFFER_LENGTH
  // Return (%rax) between -4095 and -1 indicates an error, it is -errno.
  // For right now I'm ignoring that possibility.
  _Bitfield64DataStackPushGeneral %rax
//^^^^^^^^^^
  Bitfield64ScalarBroadcast // groom scalar into all lanes
  _RAMDataStackPush tokenLiteralLengthInBytes(%rip) // number of token literals
  Bitfield64ScalarBroadcast // groom this scalar into all lanes as well

  Bitfield64Immediate 0 // scalar64 index into inputBuffer
  // Stack now contains (in push order, each value scalarbroadcast):
  // total number of bytes of input in our buffer
  // total number of valid tokens
  // current index into inputBuffer
scanInputLoop:
  BranchUnconditional scanVector

  Bitfield64Immediate 3
  systemExit

