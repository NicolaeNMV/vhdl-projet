
#include <stdio.h>

#include "ttyS.h"

#define TTY_NAME "/dev/ttyS0"
//#define TTY_BAUD B300
#define TTY_BAUD B9600

int main(int argc, char**argv)
{
    int vt100;
    int nb=0;
    unsigned char c=0;

	printf("%s %s\n",argv[0],TTY_NAME);

	vt100 = ttyS_open(TTY_NAME,O_WRONLY,TTY_BAUD);

	while (1) {
        //c= (nb&0xf) + 'A';
        printf("entrer en hexa: ");
        scanf("%x",&nb);
        c= nb&0xff ;
	    printf("write %3dth : %08x\n",nb,c); fflush(stdout);
	    ttyS_write(vt100,c);
        usleep(100000);
	    nb++;
    }

    return 0;
}
