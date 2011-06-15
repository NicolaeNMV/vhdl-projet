
#include <stdio.h>

#include "iar-prj/rs232/ttyS.h"

#define TTY_NAME "/dev/ttyS0"
//#define TTY_BAUD B300
#define TTY_BAUD B9600

#define ADDR_ADD  1
#define ADDR_PGCD 3
#define ADDR_RAC  4

int main(int argc, char**argv)
{
    int vt100;
    int i,nb=0;
    unsigned char c=0;
    unsigned int  code=0;
    int a,b;

	printf("%s %s\n",argv[0],TTY_NAME);

	vt100 = ttyS_open(TTY_NAME,O_WRONLY,TTY_BAUD);

	while (1) {
        //c= (nb&0xf) + 'A';
        printf("ADD12: entrer en A et B (%d %d) : ", 0xFFFFF800, 0x000007FF);
        scanf("%d%d",&a,&b);
        code = (ADDR_ADD<<27) | (0<<24) | ((b<<12)&0xFFF000) | ((a<<0)&0xFFF) ;
        printf("%3dth bus=%08x\n",nb,code);
	    ttyS_write(vt100,((code)>>24)&0xff);
	    ttyS_write(vt100,((code)>>16)&0xff);
	    ttyS_write(vt100,((code)>>8)&0xff);
	    ttyS_write(vt100,((code)>>0)&0xff);
        nb+=1;

        printf("PGCD: entrer en A et B (%d %d) : ", 0x00000001, 0x00FFFFFF);
        scanf("%d%d",&a,&b);
        code = (ADDR_PGCD<<27) | (0<<24) | (a&0xFFFFFF) ;
        printf("%3dth bus=%08x\n",nb,code);
	    ttyS_write(vt100,((code)>>24)&0xff);
	    ttyS_write(vt100,((code)>>16)&0xff);
	    ttyS_write(vt100,((code)>>8)&0xff);
	    ttyS_write(vt100,((code)>>0)&0xff);
        code = (ADDR_PGCD<<27) | (0<<24) | (b&0xFFFFFF) ;
        printf("%3dth bus=%08x\n",nb,code);
	    ttyS_write(vt100,((code)>>24)&0xff);
	    ttyS_write(vt100,((code)>>16)&0xff);
	    ttyS_write(vt100,((code)>>8)&0xff);
	    ttyS_write(vt100,((code)>>0)&0xff);
        nb+=1;

        printf("RACINE: entrer en A (%d %d) : ", 0x00000001, 0x00FFFFFF);
        scanf("%d",&a);
        code = (ADDR_RAC<<27) | (0<<24) | (a&0xFFFFFF) ;
        printf("%3dth bus=%08x\n",nb,code);
	    ttyS_write(vt100,((code)>>24)&0xff);
	    ttyS_write(vt100,((code)>>16)&0xff);
	    ttyS_write(vt100,((code)>>8)&0xff);
	    ttyS_write(vt100,((code)>>0)&0xff);
        nb+=1;

        printf("UNKNOWN: entrer en A (%d %d) : ", 0x00000001, 0x00FFFFFF);
        scanf("%d",&a);
        code = (0<<27) | (0<<24) | (a&0xFFFFFF) ;
        printf("%3dth bus=%08x\n",nb,code);
	    ttyS_write(vt100,((code)>>24)&0xff);
	    ttyS_write(vt100,((code)>>16)&0xff);
	    ttyS_write(vt100,((code)>>8)&0xff);
	    ttyS_write(vt100,((code)>>0)&0xff);
        nb+=1;
    }
    return 0;
}
