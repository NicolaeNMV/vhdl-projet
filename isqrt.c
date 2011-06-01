#include<stdio.h>
#include<stdlib.h>

short racine_inf, racine_sup;
void isqrt(short num) {
    short op = num;
    short res = 0;
    short one = 1 << 14; // pour le vhdl, sur 24 bits => 22 bits 
    short tmp;

    while (one > op)
        one >>= 2;

    while (one != 0) {
        tmp = res + one;
        if (op >= tmp) {
            op -= tmp;
           res = (res>>1) + one; 
        }
        else
          res >>= 1;
        one >>= 2;
    }
    racine_inf = res;
    if(num == res*res)
      racine_sup = res;
    else
      racine_sup = res+1;
}

int main(int argc, char** argv) {
  if(argc!=2) {
    printf("Usage: %s <integer>\n", argv[0]);
    return 1;
  }
  int n = atoi(argv[1]);
  isqrt(n);
  printf("%d<isqrt(%d)<%d\n", racine_inf, n, racine_sup);
  return 0;
}
