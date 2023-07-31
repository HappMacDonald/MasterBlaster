#!/usr/bin/awk -f

############################
##  Function definitions  ##
############################

function error(message)
{ print("ERROR: " message) > "/dev/stderr"
; print("At line " NR ": " $0) > "/dev/stderr"
; print("Comments stripped: " commentStripped) > "/dev/stderr"
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

# This accepts one numeric field index such as "2"
# It then deletes that field ($2), shifting all higher-index fields to the left.
# $0 and NF ARE both updated properly, and this SHOULD be POSIX compliant.
# Function returns the value of the single field that got deleted as well.
# Results undefined if `field` passed in is outside range from 1..NF
function shiftParseField(field,    fieldIndex, returnField)
{ returnField = $(field)
; for(fieldIndex=field; fieldIndex<NF; fieldIndex++)
  { #print "$" fieldIndex "=$" (fieldIndex+1) "\n[" $(fieldIndex) "]=[" $(fieldIndex+1) "]"
  ; $(fieldIndex)=$(fieldIndex+1)
  }
; $(NF)=""
; $0=$0
; return returnField
}

# Searches `subject` for `find`.
# If and only if found, the first found occurence is replaced with `replace`.
# The resulting modified string is returned.
function replaceStringFirst(subject, find, replace,    startPosition)
{ startPosition = index($0, constantName)
; return \
  ( substr(subject, 0, startPosition-1) \
    replace \
    substr(subject, startPosition + length(find)) \
  )
}

# This accepts one string value, and shifts the first block of non-whitespace
# off of the beginning. It returns an array result *through the second argument*
# with [0] being the block of nonwhitespace at the beginning
# , and [1] being the remainder of the string.
# Both return value are outer-trimmed of any whitespace as well.
# Example: shiftStringFirstField(" \thello \t \t\tthere,  how\tdo you do today?\n")
# -> [0] = "hello" & [1] = "there,  how\tdo you do today?"
# Example: shiftStringFirstField("HI!!")
# -> [0] = "HI!!" & [1] = ""
# Example: shiftStringFirstField("")
# -> [0] = "" & [1] = ""
function shiftStringFirstField(string, returnArray)
{ gsub(/(^[[:blank:]]+|[[:blank:]]+$)/, "", string)
; returnArray[0] = string
; returnArray[1] = string
; sub(/[[:blank:]].*/, "", returnArray[0])
; sub(/^[^[:blank:]]+[[:blank:]]+/, "", returnArray[1])
}

# Does what it says on the tin
function emptyArray(array,      arrayIndex)
{ delete array[0] # in case was not already defined as an array
; for(arrayIndex in array)
  { delete array[arrayIndex]
  }
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
; emptyArray(includeFileStack)
; emptyArray(includeOnceDone)
; emptyArray(constantTable)
; emptyArray(constantsAlreadyExpanded)

; for(argvIndex in ARGV)
  { if(ARGV[argvIndex] ~ /^--?(\?|h|he|hel|help)$/)
    { usage()
    }
  }

  ############################################
  ##  Manually Executed Input Parsing Loop  ##
  ############################################

; repeatInput = FALSE
  # We will manually exit loop after exhausting all possible lines to parse
  # or upon any showstopping error
; while(TRUE)
  { if(!repeatInput)
    { emptyArray(constantsAlreadyExpanded)
    ; if(includeFileIndex>=0) # If there exists an include stack
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
      else # only while the include stack is completely empty
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
    }
    # else — because we are repating input — constantsAlreadyExpanded survives.
  ; repeatInput = FALSE


    # If we get this far then $0 should be set as next line to parse

    # Mock up a cleaner version of the line to further process
  ; commentStripped = commentStrip($0)

    ##########################################
    ##  Manually Executed Match Conditions  ##
    ##########################################

    # this might be a C-preprocessor directive, we can skip further processing here.
  ; if(match($0, /^[[:blank:]]*#/))
    { print # do pass it through to output
    ; continue # prevent any later rule from matching
    }

  ; shiftStringFirstField(commentStripped, pieces)
  ; possibleDirective = pieces[0]
  ; directiveContents = pieces[1]

    # if(sub(/^[[:blank:]]*\.crudeIncludeOnce([[:blank:]]+|$)/, "", commentStripped))
  ; if(possibleDirective == ".crudeIncludeOnce")
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

    ; print "#Processed: " $0
    ; includeFile=directiveContents
    ; if(includeFile in includeOnceDone)
      { print "# " includeFile " was already included before, so skipping."
      ; continue;
      }
    ; includeFileStack[++includeFileIndex] = includeFile
    ; includeOnceDone[includeFile] = 1
    ; continue # prevent any later rule from matching
    }

    # if(sub(/^[[:blank:]]*\.crudeIncludeEveryTime([[:blank:]]+|$)/, "", commentStripped))
  ; if(possibleDirective==".crudeIncludeEveryTime")
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

    ; includeFile=directiveContents
    ; includeFileStack[++includeFileIndex] = includeFile
    ; print "#Processed: " $0
    ; continue # prevent any later rule from matching
    }

    # if(sub(/^[[:blank:]]*\.crudeDefine([[:blank:]]+|$)/, "", commentStripped))
  ; if(possibleDirective==".crudeDefine")
    { if(NF<2)
      { error \
        ( ".crudeDefine directive requires both a constant to define, and a" \
          " value to define it to." \
          "\nSyntax:" \
          "\n.crudeDefine <constant> <value>" \
          "\n.crudeDefine <constant> <value> # comment not included in value" \
        )
      }

    ; print "#Processed: " $0
    ; shiftStringFirstField(directiveContents, pieces)
    ; constantName = pieces[0]
    ; constantValue = pieces[1]
    ; if(constantName in constantTable)
      { error \
        ( "Attempt to .crudeDefine constant name '"\
          constantName\
          "' despite that name already being set to value '"\
          constantTable[constantName]\
          "' earlier in this session."\
          "\nPlease .crudeUndefine a constant before trying to set it again."\
        )
      }
    ; constantTable[constantName] = constantValue
    ; continue # prevent any later rule from matching
    }


  ; if(/^[[:blank:]]*\.crudeMemoryBlock([[:blank:]]|$)/)
    { if(NF<2)
      { error(".crudeMemoryBlock directive requires 1 field to name the memory block.")
      }
    ; if(NF>2)
      { error(".crudeMemoryBlock directive requires ONLY 1 field to name the memory block.")
      }
    ; if(readMode == READMODE_MEMORY_BLOCK)
      { error(".crudeMemoryBlock directive encountered while already inside of a memory block")
      }
    ; print "#Processed: " $0
    ; memoryBlockHandle = $2
    ; hereToken = NR
    ; print "  jmp crudePreprocessorEndMemoryBlock" hereToken
    ; print ".balign SIMD_WIDTH"
    ; print memoryBlockHandle ":"

    ; readMode = READMODE_MEMORY_BLOCK

    ; continue # prevent any later rule from matching
    }

  ; if(/^[[:blank:]]*\.crudeEndMemoryBlock/)
    { if(readMode != READMODE_MEMORY_BLOCK)
      { error(".crudeEndMemoryBlock directive encountered outside of a memory block")
      }
    ; if(!/^[[:blank:]]*\.crudeEndMemoryBlock[[:blank:]]*$/)
      { error(".crudeEndMemoryBlock directive must not include any arguments")
      }

    ; print "#Processed: " $0
    ; print "crudePreprocessorEndMemoryBlock" hereToken ":"
    ; hereToken = -1
    ; readMode = READMODE_NONE

    ; continue # prevent any later rule from matching
    }

  ; if(/^[[:blank:]]*\.crude/)
    { error("Unidentified crude preprocessor directive encountered")
    ; continue # prevent any later rule from matching
    }

    # Check for constants and macros to expand:
    for(constantName in constantTable)
    { # Bail unless *stripped* text has match...
    ; if \
      ( constantName in constantsAlreadyExpanded \
      ||index(commentStripped, constantName)<1 \
      )
      { continue; # search for next constant name
      }
      # We must have hit a constant name!
    ; print "#Processed: " $0
    ; repeatInput = TRUE
    ; constantsAlreadyExpanded[constantName] = 1

    # ... but then perform replace on *unstripped* text.
    ; $0 = replaceStringFirst($0, constantName, constantTable[constantName])
    }

    # Above constant and macro scanning WILL alter $0 and set `repeatInput`
    # if work done, so here we catch that condition and restart
    # the parsing loop.
    if(repeatInput)
    { continue
    }

  ; if(readMode == READMODE_MEMORY_BLOCK)
    { hexData = normalizeInputToHexadecimalDigits(commentStripped)
      # If odd number of hex digits, prepend a single zero digit.
    ; if(length(hexData) % 2 != 0)
      { hexData = "0" hexData
      }
    ; numberOfBytes = int(length(hexData)/2)

    ; print "#Processed: " $0
    ; printf ".byte"
    ; for(byteIndex=0; byteIndex<numberOfBytes; byteIndex++)
      { if(byteIndex!=0)
        { printf ","
        }
      ; printf " 0x" substr(hexData, byteIndex*2+1, 2)
      }
    ; printf "\n"
    ; continue # prevent any later rule from matching
    }

  ; if(readMode == READMODE_NONE)
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

; exit 0
}
