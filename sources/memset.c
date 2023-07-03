/* memset example */
#include <stdio.h>
#include <string.h>

int main (int argv)
{
  char str[32];
  // memset (str,argv,16);
  int i=32;
  while(i-->16)
  { str[i] = (char)argv;
  }
  i=16;
  while(i-->0)
  { str[i] = (char)argv*2;
  }
  return str[argv];
}