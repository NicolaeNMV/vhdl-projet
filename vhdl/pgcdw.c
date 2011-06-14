
#include <stdio.h>

#include "iar-prj/rs232/ttyS.h"

#define TTY_NAME "/dev/ttyS0"
//#define TTY_BAUD B300
#define TTY_BAUD B9600

int main(int argc, char**argv)
{
    int vt100;
    int i,nb=0;
    unsigned char c=0;
    unsigned int  codeA=0,codeB=0;
    int a,b;

	printf("%s %s\n",argv[0],TTY_NAME);

	vt100 = ttyS_open(TTY_NAME,O_WRONLY,TTY_BAUD);

	while (1) {
        //c= (nb&0xf) + 'A';
        printf("entrer en A et B (%d %d) : ", 0xFF800000, 0x007FFFFF);
        scanf("%d%d",&a,&b);
        codeA = (3<<27) | (0<<24) | ((a<<0)&0xFFFFFF);
	codeB = (3<<27) | (0<<24) | ((b<<0)&0xFFFFFF);

        printf("send A: %3dth bus=%08x\n",nb,codeA);
	    ttyS_write(vt100,((codeA)>>24)&0xff);
	    ttyS_write(vt100,((codeA)>>16)&0xff);
	    ttyS_write(vt100,((codeA)>>8)&0xff);
	    ttyS_write(vt100,((codeA)>>0)&0xff);

       printf("send B: %3dth bus=%08x\n",nb,codeA);
	    ttyS_write(vt100,((codeB)>>24)&0xff);
	    ttyS_write(vt100,((codeB)>>16)&0xff);
	    ttyS_write(vt100,((codeB)>>8)&0xff);
	    ttyS_write(vt100,((codeB)>>0)&0xff);


        nb+=1;
    }
    return 0;
}
