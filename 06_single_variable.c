#include<stdio.h>

int main()
{ short q;
  short *qq = &q;
  *qq = 7;
  return q;
}
