#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>

#include "libmb_c.h"
#include "libmb_test_c.h"
#include <CUnit/Basic.h>

// Note: printing uint64_t values requires the following specifier:
// %" PRIX64 "
// Yes.. percent sign, then break out of string and have whitespace around macro thingy.

int main()
{ CU_pSuite pSuite = NULL;

  /* initialize the CUnit test registry */
  if (CU_initialize_registry() != CUE_SUCCESS)
  { return CU_get_error();
  }

  /* add a suite to the registry */
  pSuite = CU_add_suite("Experimental Test Suite", NULL, NULL);
  if (pSuite == NULL)
  { CU_cleanup_registry();
    exit(CU_get_error());
  }

  /* Add the tests to the suite */
  /* These if statements DO NOT RUN the tests, */
  /* they only prepare the tests to be run later */
  /* and we check for failures even getting */
  /* the tests added to to the queue. :P */
  if
  ( CU_add_test
    ( pSuite
    , "Buffer Tainting Test for unsignedIntegerToStringBase16"
    , runBufferTaintingTestForUnsignedIntegerToStringBase16
    )
  ==NULL
  )
  { CU_cleanup_registry();
    return CU_get_error();
  }

  if
  ( CU_add_test
    ( pSuite
    , "Buffer Tainting Test for unsignedIntegerToStringBase10"
    , runBufferTaintingTestForUnsignedIntegerToStringBase10
    )
  ==NULL
  )
  { CU_cleanup_registry();
    return CU_get_error();
  }

  // -- The most verbose thing this framework outputs is its horific Run Summary..
  // -- but no setting here seems to make a difference to that. ;P
  // CU_basic_set_mode(CU_BRM_SILENT);
  // CU_basic_set_mode(CU_BRM_NORMAL);
  CU_basic_set_mode(CU_BRM_VERBOSE);

  /* Run all tests using the CUnit Basic interface */
  CU_basic_run_tests();

  int failures = CU_get_number_of_failures();
  CU_cleanup_registry();
  return CU_get_error() || failures;
}

void runBufferTaintingTestForUnsignedIntegerToStringBase16()
{ char comparison[17];
  uint64_t testValue = randomSeedFromClock();

  sprintf(comparison, "%" PRIX64, testValue);

  runBufferTaintingTest
  ( unsignedIntegerToStringBase16
  , 16
  , testValue
  , comparison
  );
}

void runBufferTaintingTestForUnsignedIntegerToStringBase10()
{ char comparison[21];
  uint64_t testValue = randomSeedFromClock();

  sprintf(comparison, "%" PRIu64, testValue);

  runBufferTaintingTest
  ( unsignedIntegerToStringBase10
  , 20
  , testValue
  , comparison
  );
}

void runBufferTaintingTest
( struct MasterBlasterString testFunction(uint64_t, char*)
, int byteLength
, uint64_t testValue
, char *comparison
)
{ uint64_t seed = randomSeedFromClock();
  uint64_t offset = (randomSeedFromClock() & 0x1FF) + 256; // 256-767
  int comparisonLength = strlen(comparison);
  struct MasterBlasterString results;
  // uint64_t testValue = 8888;

  /*******************************************
  **  Positive test with randomized buffer  **
  *******************************************/
  PrepMasterBlasterBuffer1k(seed, true);

  results = testFunction(testValue, (char *)(MasterBlasterBuffer1k) + offset);

  CU_ASSERT_EQUAL(results.length, comparisonLength);
  CU_ASSERT_NSTRING_EQUAL(results.string, comparison, results.length);

// MasterBlasterBuffer1k[3] = 7;
// printf("obstacle: MasterBlasterBuffer1k[3] == %016" PRIX64 "\n", MasterBlasterBuffer1k[3]);

  CU_ASSERT(MatchMasterBlasterBuffer1k(seed, offset, byteLength, true));


  /********************************************************
  **  Negative test against value shifted one byte left  **
  ********************************************************/
  // filling buffer with sixty four one bits should work here,
  // because all string generating functions that I am testing
  // should never generate non-ASCII characters to begin with,
  // and 0xFF is not a valid ascii character so would not
  // be confused for legitimate output.
  PrepMasterBlasterBuffer1k(SixtyFourOneBits, false);

  results = testFunction(testValue, (char *)(MasterBlasterBuffer1k) + offset - 1);

  CU_ASSERT_EQUAL(results.length, comparisonLength);
  CU_ASSERT_NSTRING_EQUAL(results.string, comparison, results.length);

  CU_ASSERT_FALSE
  ( MatchMasterBlasterBuffer1k(SixtyFourOneBits, offset-1, byteLength, false)
  );


  /*********************************************************
  **  Negative test against value shifted one byte right  **
  *********************************************************/
  PrepMasterBlasterBuffer1k(SixtyFourOneBits, false);

  results = testFunction(testValue, (char *)(MasterBlasterBuffer1k) + offset + 1);

  CU_ASSERT_EQUAL(results.length, comparisonLength);
  CU_ASSERT_NSTRING_EQUAL(results.string, comparison, results.length);

  CU_ASSERT_FALSE
  ( MatchMasterBlasterBuffer1k(SixtyFourOneBits, offset+1, byteLength, false)
  );

  return;
}

void PrepMasterBlasterBuffer1k(uint64_t bouncingBall, bool randomized)
{ int index;
  for(index=0; index<KiBin64bit; index++)
  { if(randomized) { bouncingBall = fasthash(bouncingBall); }
    MasterBlasterBuffer1k[index] = bouncingBall;
  }
}

bool MatchMasterBlasterBuffer1k
( uint64_t seed
, int startSkip
, int lengthSkip
, bool randomized
)
{ int index;
  int oldChunk = -1;
  union Bytefield64 bouncingBall = { .d64 = seed };
  union Bytefield64 *inMemory;

  for(index=0; index<KiB; index++)
  { 
// printf("index=%d\n", index);
    int chunk = index/8;
    int offset = index%8;
    char *errorMaskBackground = "                ";
    char *errorMaskForeground = "^^";

    // printf(".");
    if(chunk!=oldChunk)
    {
// printf("Before: %016" PRIX64 "\n", bouncingBall.d64);
      if(randomized) { bouncingBall.d64 = fasthash(bouncingBall.d64); }
// printf("After: %016" PRIX64 " (%d %d %d)\n", bouncingBall.d64, index, chunk, offset);
      inMemory = (union Bytefield64 *)(MasterBlasterBuffer1k + chunk);
      oldChunk = chunk;
// if(chunk==3)
// { printf("%016" PRIX64 " ?= %016" PRIX64 "\n", bouncingBall.d64, MasterBlasterBuffer1k[chunk]);
// }
    }

    if
    ( ( index<startSkip || index>=(startSkip + lengthSkip) )
    &&bouncingBall.d8[offset] != (*inMemory).d8[offset]
    )
    { printf
      ( "\nTest failed! startSkip=%d, lengthSkip=%d, offending byte=%d:\n"
      , startSkip
      , lengthSkip
      , index
      );
      printf("%016" PRIX64 " != \n", bouncingBall.d64);
      printf("%016" PRIX64 "\n", MasterBlasterBuffer1k[chunk]);
      printf("%.*s%s%.*s\n\n", 14-2*offset, errorMaskBackground, errorMaskForeground, 2*offset, errorMaskBackground);
      return(false);
    }
  }
  return(true);
}

// void assemblyExternInvocationExampleCode()
// { char resultBuffer[20];
//   struct MasterBlasterString actualResults;
//   printf("Before\n");
//   putMemoryProcedure("Hello", 4, STDOUT);
//   printf("(%c)\n", *TrigentasenaryUppercaseDigits+1);
//   printf("(%.*s)\n", 10, (&TrigentasenaryUppercaseDigits));
//   actualResults = unsignedIntegerToStringBase16(0xdeadbeef, resultBuffer);
//   printf("a=%016" PRIX64 ", b=%016" PRIX64 "\n", actualResults.a, actualResults.b);
//   printf("(%.*s)\n", actualResults.b, actualResults.a);
//   actualResults = unsignedIntegerToStringBase10(0xdeadbeef, resultBuffer);
//   printf("a=%016" PRIX64 ", b=%016" PRIX64 "\n", actualResults.a, actualResults.b);
//   printf("(%.*s)\n", actualResults.b, actualResults.a);
//   printf("After\n");
// }
