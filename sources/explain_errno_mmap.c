#include<stdio.h>
#include<stdlib.h>
#include<sys/mman.h>
#include<stdint.h>
#include<inttypes.h>
#include<errno.h>

void main()
// { void *result = mmap(0, 0x1000000, 6, 0x20102, -1, 0);
{ void *result = mmap(0, 0x1000000, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);

printf
( "%X, %X, (%X)\n"
, PROT_READ
, PROT_WRITE
, PROT_READ|PROT_WRITE
);
printf
( "%X, %X, (%X)\n"
, MAP_PRIVATE
, MAP_ANONYMOUS
, MAP_PRIVATE|MAP_ANONYMOUS
);


  if(result<0 || (uint64_t)result>0xEFFFFFFFFFFFFFFF)
  // { fprintf(stderr, "%s\n", explain_mmap(0, 0x1000000, 6, 0x20102, -1, 0));
  { fprintf(stderr, "ERRNO: %" PRIXPTR "\n", errno);
    exit(EXIT_FAILURE);
  }
  else
  { fprintf(stderr, "SUCCESS?: %" PRIXPTR "\n", errno);
    exit(EXIT_SUCCESS);
  }
}