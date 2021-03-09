#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include<stdio.h>
#include<stdint.h>
#include"libmb_c.h"

// Note: printing uint64_t values requires the following specifier:
// %" PRIX64 "
// Yes.. percent sign, then break out of string and have whitespace around macro thingy.

int main()
{ printf("Before\n");
  putMemoryProcedure("Hello", 4, STDOUT);
  printf("(%c)\n", *TrigentasenaryUppercaseDigits+1);
  printf("(%.*s)\n", 10, (&TrigentasenaryUppercaseDigits));
  printf("After\n");
  return(0); // All clear
}