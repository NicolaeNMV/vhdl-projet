
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
    unsigned int  code=0;
    int a;

	printf("%s %s\n",argv[0],TTY_NAME);

	vt100 = ttyS_open(TTY_NAME,O_WRONLY,TTY_BAUD);

	while (1) {
        printf("entrer A : ");
        scanf("%d",&a);
        code = (4<<27) | (0<<24) | (a & 0xFFFFFF) ;
        printf("%3dth bus=%08x\n",nb,code);
	    ttyS_write(vt100,((code)>>24)&0xff);
	    ttyS_write(vt100,((code)>>16)&0xff);
	    ttyS_write(vt100,((code)>>8)&0xff);
	    ttyS_write(vt100,((code)>>0)&0xff);
        nb+=1;
    }
    return 0;
}
