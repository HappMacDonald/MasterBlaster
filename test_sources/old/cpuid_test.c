#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>
#define cpuid(func,ax,bx,cx,dx)\
	__asm__ __volatile__ ("cpuid":\
	"=a" (ax), "=b" (bx), "=c" (cx), "=d" (dx) : "a" (func));

int main()
{ uint32_t func
    , a = 0x01234567
    , b = 0x01234567
    , c = 0x01234567
    , d = 0x01234567
    ;

  cpuid(1, a, b, c, d);
  printf
  ( "a=%08" PRIX32
    "\nb=%08" PRIX32
    "\nc=%08" PRIX32
    "\nd=%08" PRIX32
    "\n"
  , a
  , b
  , c
  , d
  );
}