#include<stdio.h>
#include<stdlib.h>

int isqrt(n)
register int n;
{
    register int a,b,c,as,bs;

    a = 1;
    b = 1;
    while (a<=n) {
        a = a << 2;
        b = b << 1;
    }
    as = 0;
    bs = 0;
    while ( (b>1) && (n>0) ) {
        a = a>>2;
        b = b>>1;
        c = n - (as|a);
        if ( c>=0 ) {
            n = c;
            as |= (a<<1);
            bs |= b;
        }
        as = as>>1;
    }

    return(bs);
}

int main(int argc, char** argv) {
  if(argc!=2) {
    printf("Usage: %s <integer>\n", argv[0]);
    return 1;
  }
  int n = atoi(argv[1]);
  printf("isqrt(%d)=%d\n", n, isqrt(n));
  return 0;
}
