#################
##  Constants  ##
#################

KiB = 1024

###################
##  DATA BLOCKS  ##
###################

# Large-ish buffer used in tests
# libmb_testhelper will not use this directly, but offers it to libmb_test.c
# as reusable memory fodder.
#
# Buffer will get filled with some pseudorandom sequence based on a certain seed.
# Then smaller buffer will get carved out of the MIDDLE of this buffer.
# function gets called with smaller buffer.
# Finally, after return large buffer will get checked from 0 to beginning of small buffer,
# and from end of small buffer to end of large buffer against the repeatable
# PRNG sequence to ensure no other bytes were changed.
# This will be used in short-fuzz scenarios so that multiple passes with different
# PRNG sequences will get tested, to help catch situations where a function might
# have coincidentally written a contraban value out of range that just happened
# to already be there.
	.data

.global MasterBlasterBuffer1k
MasterBlasterBuffer1k:
  .space KiB, 0


# This is the area where libmb_testhelper will store all parent-owned registers.
# upon return from tested function, each register will be compared with it's
# previously saved state to ensure that no parent-owned registers get
# clobbered by function.
.global MBTestRegisterSave
MBTestRegisterSave:
  .space 8*7, 0

####################
##  PROGRAM CODE  ##
####################
.text
