#!/usr/bin/awk -f

# This is meant to transform the output from ./compile_test.sh into a single TAP test point
# Example input:
# Running test "test_binaries/bitfield8tests.elf64":
# ..........
# 10 tests, 0 failures.
# Tapsummary return value was: 0

BEGIN \
{ TestName = "Unknown"
; Failed = 0 # until ANY evidence of failure
; TestSummaryFound = 0
}

/^Running test "/ \
{ sub(/^Running test "/, "", $0)
; sub(/":$/, "", $0)
  # syntax highlighter reboot-> "
; TestName = $0
# ; print "Setting TestName to '" TestName "'"
}

/ failures.$/ \
{ TestSummaryFound = 1
  if(Failed == 0 && /, 0 failures/)
  { Failed = 0
  }
  else
  { Failed = 1
  }
}

/return value was: / \
{ if(Failed == 0 && /return value was: 0$/)
  { Failed = 0
  }
  else
  { Failed = 1
  }
}

END \
{ if(!TestSummaryFound)
  { print "not ok " TestName " -- No Test Summary Found"
  }
  else
  { if(Failed)
    { print "not ok " TestName
    }
    else
    { print "ok " TestName
    }
  }
}
