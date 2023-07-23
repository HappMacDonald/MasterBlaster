#!/usr/bin/awk -f

############################
##  Function definitions  ##
############################

function error(message)
{ print("ERROR: " message) > "/dev/stderr"
; print("At line " NR ": " $0) > "/dev/stderr"
; returnValue = 1
; exit 1
}

function usage()
{ print "Usage:"
  print "\tcat source_file.ext | " SCRIPTNAME " > preprocessed_source_file.ext"
  print "\t" SCRIPTNAME " source_file.ext > preprocessed_source_file.ext"
  print "\t" SCRIPTNAME " source_file.ext | gcc --flags"

; returnValue = 2
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

function commentStrip(input)
{ sub(/[[:blank:]]*(\/\/|#).*/, "", input) # strip comments
; sub(/[[:blank:]]+$/, "", input) # also strip all trailing whitespace
; return input
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
; returnValue = 0 # assume happy return until proven otherwise

; readMode = READMODE_NONE
; hereToken = -1 # like \@ in GAS preprocessor
; memoryBlockHandle = ""

; includeFileIndex = -1 # start with empty lifo stack of include files to parse
; delete includeFileStack[0] # This initializes includeFileStack as an empty array
; delete includeOnceDone[0] # This initializes includeOnceDone as an empty array

; for(argvIndex in ARGV)
  { if(ARGV[argvIndex] ~ /^--?(\?|h|he|hel|help)$/)
    { usage()
    }
  }

  ############################################
  ##  Manually Executed Input Parsing Loop  ##
  ############################################

  # We will manually exit loop after exhausting all possible lines to parse
  # or upon any showstopping error
  while(TRUE)
  { if(includeFileIndex>=0) # If there exists an include stack
    { result = getline < includeFileStack[includeFileIndex]
    ; if(result<0)
      { error \
        ( "Error trying to read from " \
          "'" includeFileStack[includeFileIndex] "'" \
          " out of the include stack" \
        )
      }
      else if(result==0) # EOF
      { close(includeFileStack[includeFileIndex])
      ; delete includeFileStack[includeFileIndex--] # pop this file from stack
      ; continue # retry read on whatever is left on stack or on primary input stream
      }
      # Else result>0 and our read succeeded so we may proceed
    }
    else # only if the include stack is 💯 empty
    { result = getline
    ; if(result<0)
      { error \
        ( "Error trying to read from " \
          "'" FILENAME "'" \
          " out of the primary input stream" \
        )
      }
      else if(result==0) # EOF
      { # if primary input stream is exhausted,
        # then ultimate parsing loop is also complete
      ; break
      }
      # Else result>0 and our read succeeded so we may proceed
    }

    # If we get this far then $0 should be set as next line to parse

    ##########################################
    ##  Manually Executed Match Conditions  ##
    ##########################################

    # Early skip lines that are 100% number sign comments.
    # There is a chance that instead of an actual comment
    # this is a C-preprocessor directive.
    if(match($0, /^[[:blank:]]*#/))
    { print # do pass it through to output
    ; continue # prevent any later rule from matching
    }

    # only strip comments not already parsed above
    $0 = commentStrip($0)

    if(sub(/^[[:blank:]]*\.crudeIncludeOnce([[:blank:]]+|$)/, "", $0))
    { if(NF<1)
      { error \
        ( ".crudeIncludeOnce directive requires a filename to include." \
          "\nSyntax:" \
          "\n.crudeIncludeOnce filename.ext" \
          "\n.crudeIncludeOnce filename containing spaces\tand\ttabs.ext" \
          "\nNote: all whitespace *surrounding* filename is ignored." \
          "\nFilename is also only parsed after comments are stripped from line:" \
          "\n.crudeIncludeOnce ordinaryFile.ext # comment not confused with filename" \
        )
      }

      if($0 in includeOnceDone)
      { continue; # File has already been included before, so silently ignore.
      }
    ; includeFileStack[++includeFileIndex] = $0
    ; includeOnceDone[$0] = 1
    }

    if(sub(/^[[:blank:]]*\.crudeIncludeEveryTime([[:blank:]]+|$)/, "", $0))
    { if(NF<1)
      { error \
        ( ".crudeIncludeEveryTime directive requires a filename to include." \
          "\nSyntax:" \
          "\n.crudeIncludeEveryTime filename.ext" \
          "\n.crudeIncludeEveryTime filename containing spaces\tand\ttabs.ext" \
          "\nNote: all whitespace *surrounding* filename is ignored." \
          "\nFilename is also only parsed after comments are stripped from line:" \
          "\n.crudeIncludeEveryTime ordinaryFile.ext # comment not confused with filename" \
        )
      }

    ; includeFileStack[++includeFileIndex] = $0
    }

    if(/^[ \t]*\.crudeMemoryBlock([ \t]|$)/)
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

    ; continue # prevent any later rule from matching
    }

    if(/^[ \t]*\.crudeEndMemoryBlock/)
    { if(readMode != READMODE_MEMORY_BLOCK)
      { error(".crudeEndMemoryBlock directive encountered outside of a memory block")
      }
    ; if(!/^[ \t]*\.crudeEndMemoryBlock[ \t]*$/)
      { error(".crudeEndMemoryBlock directive must not include any arguments")
      }

    ; print "crudePreprocessorEndMemoryBlock" hereToken ":"
    ; hereToken = -1
    ; readMode = READMODE_NONE

    ; continue # prevent any later rule from matching
    }

    if(/^[ \t]*\.crude/)
    { error("Unidentified crude preprocessor directive encountered")
    ; continue # prevent any later rule from matching
    }

    if(readMode == READMODE_MEMORY_BLOCK)
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
    ; continue # prevent any later rule from matching
    }

    if(readMode == READMODE_NONE)
    { print
    ; continue # prevent any later rule from matching
    }

    ; error("Internal error: somehow got to unrecognized read mode (" readMode ")")
  }
}

###############################################################################
##  Match conditions -- empty                                                ##
##  They have been "project-forked" into manual while loop in BEGIN instead  ##
###############################################################################

###################
##  END Section  ##
###################

END \
{ if(returnValue!=0)
  { exit returnValue
  }

  if(readMode == READMODE_MEMORY_BLOCK)
  { print "Source code ended in an unresolved .crudeMemoryBlock" > "/dev/stderr"
  ; exit 1
  }

  exit 0
}
