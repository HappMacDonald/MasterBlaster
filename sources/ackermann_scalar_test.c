#include<stdio.h>

int Ackermann(int m, int n)
{ if(m==0)
  { return n+1;
  }
  else if(n==0)
  { return Ackermann(m-1, 1);
  }
  else
  { return Ackermann(m-1, Ackermann(m, n-1));
  }
}

void main()
{ printf("%d\n", Ackermann(4,1));
}