#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include<stdio.h>
#include<stdint.h>
#include"libmb_c.h"

// Note: printing uint64_t values requires the following specifier:
// %" PRIX64 "
// Yes.. percent sign, then break out of string and have whitespace around macro thingy.

int main()
{ char resultBuffer[20];
  struct MasterBlasterString actualResults;
  printf("Before\n");
  putMemoryProcedure("Hello", 4, STDOUT);
  printf("(%c)\n", *TrigentasenaryUppercaseDigits+1);
  printf("(%.*s)\n", 10, (&TrigentasenaryUppercaseDigits));
  actualResults = unsignedIntegerToStringBase16(0xdeadbeef, resultBuffer);
  printf("a=%" PRIX64 ", b=%" PRIX64 "\n", actualResults.a, actualResults.b);
  printf("(%.*s)\n", actualResults.b, actualResults.a);
  actualResults = unsignedIntegerToStringBase10(0xdeadbeef, resultBuffer);
  printf("a=%" PRIX64 ", b=%" PRIX64 "\n", actualResults.a, actualResults.b);
  printf("(%.*s)\n", actualResults.b, actualResults.a);
  printf("After\n");
  return(0); // All clear
}