#define KiB 1024
#define KiBin64bit (KiB/8)
#define SixtyFourOneBits 0xFFFFFFFFFFFFFFFF

#define CUnitAssert(EXPR) ( if ((EXPR) == NULL) { CU_cleanup_registry(); exit(CU_get_error()); } )


extern uint64_t MasterBlasterBuffer1k[128];

static inline uint64_t fasthash(uint64_t i)
{ i += 1ULL; // This resists a 1-step loop at input=0
  i ^= i >> 33ULL;
  i *= 0xff51afd7ed558ccdULL;
  i ^= i >> 33ULL;
  i *= 0xc4ceb9fe1a85ec53ULL;
  i ^= i >> 33ULL;
  return i;
}

// Threat model limited to fuzz testing.
static inline uint64_t randomSeedFromClock()
{ struct timespec randomSeedClock;
  int error = clock_gettime(CLOCK_MONOTONIC, &randomSeedClock);

  if(error!=0)
  { printf("randomSeedFromClock() > clock_gettime error #%d", error);
    return(-1);
  }
  return(fasthash(randomSeedClock.tv_nsec));
}

/****
**  Dummy versions of the above functions for debugging, when you want
**  to try replacing the PRNG stream with a stream of all zeros.
static inline uint64_t fasthash(uint64_t i)
{ return 0;
}

static inline uint64_t randomSeedFromClock()
{ return 0;
}
*/

void runBufferTaintingTest
( struct MasterBlasterString testFunction(uint64_t, char*)
, int byteLength
, uint64_t testValue
, char *comparison
);
void PrepMasterBlasterBuffer1k(uint64_t bouncingBall, bool randomized);
bool MatchMasterBlasterBuffer1k
( uint64_t seed
, int startSkip
, int lengthSkip
, bool randomized
);
void runBufferTaintingTestForUnsignedIntegerToStringBase16();
void runBufferTaintingTestForUnsignedIntegerToStringBase10();
