

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
    int rac_min=0;

	printf("%s %s\n",argv[0],TTY_NAME);

	vt100 = ttyS_open(TTY_NAME,O_RDONLY,TTY_BAUD);

	while (1) {
        unsigned int  addr,status,code=0;
        code  = 0;
	    code |= (ttyS_read(vt100)&0xff)<<24;
	    code |= (ttyS_read(vt100)&0xff)<<16;
	    code |= (ttyS_read(vt100)&0xff)<< 8;
	    code |= (ttyS_read(vt100)&0xff)<< 0;
        printf("%3dth bus=%08x\n",nb,code);

        addr   = (code>>27)&0x1F;
        status = (code>>24)&0x7;
        if ( addr==ADDR_ADD ) {
            printf("ADD    : S=%5d addr=%2d status=%1d C=%d V=%d Z=%d\n",
                code&0xFFF, (code>>27)&0x1F, status, 
                (code&0x1000)>>12, (status&2)!=0, (status&1)!=0);
        } else if ( addr==ADDR_PGCD ) {
            printf("PGCD   : V=%5d addr=%2d status=%1d\n", code&0xFFFFFF, addr, status);
        } else if ( addr==ADDR_RAC ) {
            printf("RAC %s: V=%5d addr=%2d status=%1d\n",
                    (rac_min&1)==0 ? "MIN" : "MAX",        code&0xFFFFFF, addr, status);
            rac_min+=1;
        } else {
            printf("????   : V=%5d addr=%2d status=%1d\n", code&0xFFFFFF, addr, status);
        }
            nb+=1;
    }
    return 0;
}
