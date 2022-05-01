.balign CACHE_LINE_WIDTH, 0
tokenLiteralLengthInBytes:
.long endOfTokenLiterals-tokenLiterals
.balign SIMD_WIDTH, 0
tokenLiterals:
.asciz "boolean"
.balign SIMD_WIDTH, 0
.asciz "signed"
.balign SIMD_WIDTH, 0
.asciz "unsigned"
.balign SIMD_WIDTH, 0
.asciz "integer64"
.balign SIMD_WIDTH, 0
.asciz "integer8"
.balign SIMD_WIDTH, 0
.asciz "0x"
.balign SIMD_WIDTH, 0
.asciz "0d"
.balign SIMD_WIDTH, 0
.asciz "0b"
.balign SIMD_WIDTH, 0
.asciz "pop"
.balign SIMD_WIDTH, 0
.asciz "pop2"
.balign SIMD_WIDTH, 0
.asciz "systemExit"
.balign SIMD_WIDTH, 0
.asciz "clearStack"
.balign SIMD_WIDTH, 0
.asciz "count"
.balign SIMD_WIDTH, 0
.asciz "duplicate"
.balign SIMD_WIDTH, 0
.asciz "exchange"
.balign SIMD_WIDTH, 0
.asciz "index"
.balign SIMD_WIDTH, 0
.asciz "negate"
.balign SIMD_WIDTH, 0
.asciz "add"
.balign SIMD_WIDTH, 0
.asciz "multiply"
.balign SIMD_WIDTH, 0
.asciz "equal"
.balign SIMD_WIDTH, 0
.asciz "greaterThan"
.balign SIMD_WIDTH, 0
.asciz "bitShiftDown"
.balign SIMD_WIDTH, 0
.asciz "bitShiftUp"
.balign SIMD_WIDTH, 0
.asciz "bitRotateDown"
.balign SIMD_WIDTH, 0
.asciz "bitRotateUp"
.balign SIMD_WIDTH, 0
.asciz "toBoolean"
.balign SIMD_WIDTH, 0
.asciz "TRUE"
.balign SIMD_WIDTH, 0
.asciz "FALSE"
.balign SIMD_WIDTH, 0
.asciz "not"
.balign SIMD_WIDTH, 0
.asciz "and"
.balign SIMD_WIDTH, 0
.asciz "or"
.balign SIMD_WIDTH, 0
.asciz "xor"
.balign SIMD_WIDTH, 0
.asciz "maskBlend"
.balign SIMD_WIDTH, 0
.asciz "callMaskBlend"
.balign SIMD_WIDTH, 0
.asciz "call"
.balign SIMD_WIDTH, 0
.asciz "callLess"
.balign SIMD_WIDTH, 0
.asciz "callGreater"
.balign SIMD_WIDTH, 0
.asciz "callEqual"
.balign SIMD_WIDTH, 0
.asciz "callAnd"
.balign SIMD_WIDTH, 0
.asciz "callNotLess"
.balign SIMD_WIDTH, 0
.asciz "callNotGreater"
.balign SIMD_WIDTH, 0
.asciz "callNotEqual"
.balign SIMD_WIDTH, 0
.asciz "callNand"
.balign SIMD_WIDTH, 0
.asciz "printStack"
.balign SIMD_WIDTH, 0
endOfTokenLiterals: