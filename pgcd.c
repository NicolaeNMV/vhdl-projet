#include<stdio.h>

int pgcd (int a, int b)
{
	if (b > a)
		return pgcd (b, a);
	if (b == 0)
		return a;
	return pgcd (b, a - b);
}

int main(void) {
    printf("%d\n", pgcd(1071,1029) );
    
    return 0;
}
