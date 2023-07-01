


int (*q)(int);

int a(int in)
{ return q(in);
}

int b(int in)
{ return q(in);
}

int main(int argc)
{ int (*functions[2])(int) = {a, b};
  q = (functions)[argc];
  return (((functions)[argc])(argc));
}