#!/usr/bin/awk -f

############################
##  Function definitions  ##
############################

function error(message)
{ print("ERROR: " message) > "/dev/stderr"
; print("At line " NR ": " $0) > "/dev/stderr"
; RETURN_VALUE = 1
; exit 1
}

function usage()
{ print "Usage:"
  print "\tcat source_file.ext | " SCRIPTNAME " > preprocessed_source_file.ext"
  print "\t" SCRIPTNAME " source_file.ext > preprocessed_source_file.ext"
  print "\t" SCRIPTNAME " source_file.ext | gcc --flags"

; RETURN_VALUE = 2
; exit 2
}

function normalizeInputToHexadecimalDigits(input)
{ result = ""
; for(characterIndex=1; characterIndex<=length(input); characterIndex++)
  { character = \
      toupper \
      ( substr( input, characterIndex, 1 ) \
      )
  ; if(character ~ /[0-9A-F]/)
    { result = result character
    }
  }
; return(result)
}

#####################
##  BEGIN section  ##
#####################

BEGIN \
{ # These constants represent values which can be relied on to evaluate
  # to either true or false. They must NOT be compared to directly,
  # as many other values may also evaluate to true or false despite not
  # being strictly equal to these canonical example r-values.
; TRUE = 1
; FALSE = 0
; SCRIPTNAME = ENVIRON["_"]
; READMODE_NONE = 0
; READMODE_MEMORY_BLOCK = 1
; RETURN_VALUE = 0 # assume happy return until proven otherwise

; readMode = READMODE_NONE
; hereToken = -1 # like \@ in GAS preprocessor
; memoryBlockHandle = ""

; for(argvIndex in ARGV)
  { if(ARGV[argvIndex] ~ /^--?(\?|h|he|hel|help)$/)
    { usage()
    }
  }
}

############################################
##  Match input lines against conditions  ##
############################################

################################################
##  Match conditions are `.crude` directives  ##
################################################

/^[ \t]*\.crudeMemoryBlock([ \t]|$)/ \
{ if(NF<2)
  { error(".crudeMemoryBlock directive requires 1 field to name the memory block.")
  }
; if(NF>2)
  { error(".crudeMemoryBlock directive requires ONLY 1 field to name the memory block.")
  }
; if(readMode == READMODE_MEMORY_BLOCK)
  { error(".crudeMemoryBlock directive encountered while already inside of a memory block")
  }
; memoryBlockHandle = $2
; hereToken = NR
; print "  jmp crudePreprocessorEndMemoryBlock" hereToken
; print ".balign SIMD_WIDTH"
; print memoryBlockHandle ":"

; readMode = READMODE_MEMORY_BLOCK

; next # prevent any later rule from matching
}

/^[ \t]*\.crudeEndMemoryBlock/ \
{ if(readMode != READMODE_MEMORY_BLOCK)
  { error(".crudeEndMemoryBlock directive encountered outside of a memory block")
  }
; if(!/^[ \t]*\.crudeEndMemoryBlock[ \t]*$/)
  { error(".crudeEndMemoryBlock directive must not include any arguments")
  }

; print "crudePreprocessorEndMemoryBlock" hereToken ":"
; hereToken = -1
; readMode = READMODE_NONE

; next # prevent any later rule from matching
}

/^[ \t]*\.crude/ \
{ error("Unidentified crude preprocessor directive encountered")
; next # prevent any later rule from matching
}

######################################
##  Match conditions are readModes  ##
######################################

(readMode == READMODE_MEMORY_BLOCK) \
{ hexData = normalizeInputToHexadecimalDigits($0)
  # If odd number of hex digits, prepend a single zero digit.
; if(length(hexData) % 2 != 0)
  { hexData = "0" hexData
  }
; numberOfBytes = int(length(hexData)/2)

; printf ".byte"
; for(byteIndex=0; byteIndex<numberOfBytes; byteIndex++)
  { if(byteIndex!=0)
    { printf ","
    }
    printf " 0x" substr(hexData, byteIndex*2+1, 2)
  }
  printf "\n"
; next # prevent any later rule from matching
}

(readMode == READMODE_NONE) \
{ print
; next # prevent any later rule from matching
}

{ error("Internal error: somehow got to unrecognized read mode (" readMode ")")
; next # prevent any later rule from matching
}

###################
##  END Section  ##
###################

END \
{ if(RETURN_VALUE!=0)
  { exit RETURN_VALUE
  }

  if(readMode == READMODE_MEMORY_BLOCK)
  { print "Source code ended in an unresolved .crudeMemoryBlock" > "/dev/stderr"
  ; exit 1
  }

  exit 0
}
