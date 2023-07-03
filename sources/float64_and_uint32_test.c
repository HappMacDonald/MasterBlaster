#define __STDC_FORMAT_MACROS
#include <inttypes.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>


void printDoubleFloat(double n)
{ unsigned char *buffer = (unsigned char *)&n;
  int index;

  printf(" "); // leading space
  for(index=0; index<8; index++)
  { printf("%02X", buffer[index]);
  }
}

void printUint32(uint32_t n)
{ unsigned char *buffer = (unsigned char *)&n;
  int index;

  printf(" "); // leading space
  for(index=0; index<4; index++)
  { printf("%02X", buffer[index]);
  }
}

int main()
{ printDoubleFloat(-3.0001);
  printDoubleFloat(1);
  printDoubleFloat(-1e100);
  printDoubleFloat(9999999999);

  printUint32(5488077);
  printUint32(0xDEADBEEF);
}
