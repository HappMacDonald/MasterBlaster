#!/usr/bin/awk -f
#
# This script authored by Jesse Thompson <jesset@gmail.com>
# Contributed to the public domain via CC0 licence
#
# Example output from esr/tapview for me to try to emulate
# ................F.......
# not ok $0xDEADBEEF01234568 contents Part 3
#   ---
#   message: "$0xDEADBEEF01234568 contents Part 3 were wrong"
#   ...
# Expected 999 tests but only 24 ran.
# 24 tests, 1 failures.


############################
##  Function definitions  ##
############################


function bailout(message)
{ capPartialLine()
; print "BAILOUT Line " NR ": " $0 "\n" message
; PARSING_CONTEXT = "BAILED_OUT"
; exit 1
}

function debug(message)
{ capPartialLine()
; print "DEBUG Line " NR ": " $0 "\n" message
}

function rejectBodyFollowingPlanPostfix()
{ if(PARSING_CONTEXT == "PLAN_POSTFIX_ENCOUNTERED")
  { bailout("Plan must either appear before or after all test points")
  }
}

function capPartialLine()
{ if(TEST_RUN_TOTAL>TEST_RUN_TOTAL_SINCE_LAST_LINE_CLEAR)
  { print "" # Cap off partial line of test result characters
  ; TEST_RUN_TOTAL_SINCE_LAST_LINE_CLEAR = TEST_RUN_TOTAL
  }
}

#####################
##  BEGIN section  ##
#####################

BEGIN \
{ VALID_TAP_VERSIONS[13] = 1
; VALID_TAP_VERSIONS[14] = 1
; delete TAP_ERRORS[0] # This initializes TAP_ERRORS as an empty array
; TAP_ERROR_COUNT = 0
; PARSING_CONTEXT = "AWAITING_VALID_TAP_CONTENT"
  # PLAN_TOTAL < 0 means no total specified yet in parsing
  # PLAN_TOTAL == 0 instead means "0" validly specified in plan line
; PLAN_TOTAL = -1
; TEST_RUN_TOTAL = 0
; TEST_RUN_TOTAL_SINCE_LAST_LINE_CLEAR = 0
; TEST_FAIL_TOTAL = 0
; TEST_FAIL_LINES_TOTAL = 0
; EXPLICIT_BAIL_OUT = 0
}


############################################
##  Match input lines against conditions  ##
############################################

/^[^#]*Bail out!/ \
{ EXPLICIT_BAIL_OUT = 1
; bailout("TAP stream explicitly requested bailout")
  # Despite this line being impossible to actually reach....
; next # Force TAP input to only match one awk pattern
}

/^TAP version / \
{ if(PARSING_CONTEXT != "AWAITING_VALID_TAP_CONTENT")
  { bailout("Tap protocol header issued too late")
  }
; TAP_VERSION = substr($0, 13)
; if( !(TAP_VERSION in VALID_TAP_VERSIONS) )
  { bailout \
    ( "Invalid tap version specified, must be 13 or 14 not" \
      " '" TAP_VERSION "'" \
    )
  ; exit 1
  }
# ; debug("TAP Protocol Version set to " TAP_VERSION)
; PARSING_CONTEXT = "TAP_HEADER_PARSED"
; next # Force TAP input to only match one awk pattern
}

/^1\.\.[0-9]/ \
{ #debug("Matched /^1\.\.[0-9]/ " "(" (/^1\.\.[0-9]/) ")")
; if(!/^1\.\.[0-9]+([ \t]*#.*)?$/)
  { bailout("Invalid plan line " "(" (/^1\.\.[0-9]/) ")")
  }
  if \
  ( PARSING_CONTEXT == "AWAITING_VALID_TAP_CONTENT" \
  ||PARSING_CONTEXT == "TAP_HEADER_PARSED" \
  )
  { PARSING_CONTEXT = "PLAN_PREFIX_PARSED"
  }
  else if \
  ( PARSING_CONTEXT == "BODY_LINES_PARSED" \
  &&PLAN_TOTAL<0 \
  )
  { PARSING_CONTEXT = "PLAN_POSTFIX_PARSED"
  }
  else
  { bailout \
    ( "Plan line found at wrong place in TAP stream." \
      "\nContext = " PARSING_CONTEXT \
    )
  }
  # This expression can safely cast to a number given above syntax assertion
; PLAN_TOTAL = substr($0, 4)+0
# ; debug("PLAN COUNT set to " PLAN_TOTAL)
; next # Force TAP input to only match one awk pattern
}

/^ok/ \
{ rejectBodyFollowingPlanPostfix()
; printf(".")
; TEST_RUN_TOTAL++
; PARSING_CONTEXT = "BODY_LINES_PARSED"
; next # Force TAP input to only match one awk pattern
}

/^not ok/ \
{ rejectBodyFollowingPlanPostfix()
; printf("F")
; TEST_RUN_TOTAL++
; TEST_FAIL_TOTAL++
; TAP_ERRORS[++TEST_FAIL_LINES_TOTAL] = $0
; PARSING_CONTEXT = "TEST_FAILURE_BEING_PARSED"
; next # Force TAP input to only match one awk pattern
}

# Important that this rule follows all content pattern matches
# so that it only gets tested if those all failed to match
(PARSING_CONTEXT == "TEST_FAILURE_BEING_PARSED") \
{ TAP_ERRORS[++TEST_FAIL_LINES_TOTAL] = $0
; next # Force TAP input to only match one awk pattern
}


###################
##  END Section  ##
###################

END \
{ capPartialLine()
; if(TEST_FAIL_LINES_TOTAL>0)
  { print "== Failed test point details:"
  ; for(failLineIndex=1; failLineIndex<=TEST_FAIL_LINES_TOTAL; failLineIndex++)
    { print TAP_ERRORS[failLineIndex]
    }
  }
; if(PLAN_TOTAL<0)
  { print "Error: No plan specified at beginning or end of TAP stream"
  }
  else if(TEST_RUN_TOTAL<PLAN_TOTAL)
  { print "Expected " PLAN_TOTAL " tests but only " TEST_RUN_TOTAL " ran."
  }
; print TEST_RUN_TOTAL " tests, " TEST_FAIL_TOTAL " failures."

; if(EXPLICIT_BAIL_OUT)
  { exit 2
  }
; if(TEST_FAIL_TOTAL>0 || PLAN_TOTAL<0 || TEST_RUN_TOTAL<PLAN_TOTAL)
  { exit 1
  }
; exit 0
}
