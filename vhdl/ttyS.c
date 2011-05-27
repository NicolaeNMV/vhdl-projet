#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#include <termios.h>
#include <unistd.h>

#include "ttyS.h"
 
static struct termios satt(int fid, int br);
static void patt(struct termios att);
static char* pbaud(long x);

extern int ttyS_open(const char* base, int flag, int baud)
{
    int vt100;
    int flags;
	struct termios att;

    /* open with O_NONBLOCK avoid being blocked in open
     * sytem call. */
	vt100=open(base,flag|O_NONBLOCK);
	if (vt100<0) {
		fprintf(stderr,"can't open %s\n",base);
		exit(1);
	}
    /* now we must clear the NONBLOCK mode for making that 
     * the read system call waits data instead of returning
     * immediately. */
    if ( (flags=fcntl (vt100, F_GETFL)) == -1 ) {
        fprintf(stderr, "couldn't get the mode of the opened file %s\n", base);
        exit(1);
    }
    if ( fcntl(vt100, F_SETFL, flags & ~O_NONBLOCK) < 0) {
        fprintf(stderr, "couldn't reset non-blocking mode of opened file %s\n", base);
        exit(1);
    }

    /* well, all is ok, read & write must work fine now */
	att=satt(vt100,baud);
	patt(att);

    return vt100;
}

extern int ttyS_read(int vt100)
{
    int status;
	char c;
	while ( (status=read(vt100,&c,1))!=1) {
        if (status!=0) {
		    fprintf(stderr,"%s: read error status=%d errno=%d (%s)\n",
                __func__,status,errno,strerror(errno)
            );
            exit (1);
        } else if ( status==0 ) {
            usleep(50000);
        }
	}
	return c&0xff;
}

extern void ttyS_write(int vt100, unsigned char x)
{
    int status;
	char c=x;
	if ( (status=write(vt100,&c,1))!=1) {
		fprintf(stderr,"%s: write error status=%d errno=%d (%s)\n",
            __func__,status,errno,strerror(errno)
        );
		exit(1);
	}
}

struct termios gatt(int fid)
{
int ret;

struct termios att;
	ret= tcgetattr(fid,&att);
	if (ret<0) {
		fprintf(stderr,"tcgetattr failed for fid %d\n",fid);
		exit(1);
	}
	return att;
}

char* pbaud(long x)
{
  switch (x) {
    case B0     : return "0";
    case B50    : return "50";
    case B75    : return "75";
    case B150   : return "150";
    case B300   : return "300";
    case B600   : return "600";
    case B1200  : return "1200";
    case B2400  : return "2400";
    case B4800  : return "4800";
    case B9600  : return "9600";
    case B19200 : return "19200";
    case B115200 : return "115200";
    default     : return "????";
  }
}

void patt(struct termios att)
{
  printf("CRTSCTS = %c\n", att.c_cflag&CRTSCTS ? 'Y' : 'N');
  printf("parity  = %c\n", att.c_cflag&PARENB ? 
                               (att.c_cflag&PARODD ? 'O' : 'E') : 'N');
  printf("XON     = %c\n", att.c_iflag&IXON    ? 'Y' : 'N');
  printf("XOFF    = %c\n", att.c_iflag&IXOFF   ? 'Y' : 'N');
  printf("strip   = %c\n", att.c_iflag&ISTRIP  ? 'Y' : 'N');
  printf("nbbit   = %d\n", 
	(att.c_cflag&CSIZE)==CS5 ? 5 :
	(att.c_cflag&CSIZE)==CS6 ? 6 :
	(att.c_cflag&CSIZE)==CS7 ? 7 :
	(att.c_cflag&CSIZE)==CS8 ? 8 : -1);
  printf("stopbit = %c\n", att.c_cflag&CSTOPB  ? '2' : '1');
  printf("inbaud  = %s\n", pbaud(cfgetispeed(&att)));
  printf("outbaud = %s\n", pbaud(cfgetospeed(&att)));
  printf("echo    = %c\n", att.c_lflag&ECHO ? 'Y' : 'N' );
  printf("i=%08x o=%08x c=%08x l=%08x\n",
	att.c_iflag,att.c_oflag,att.c_cflag,att.c_lflag);
}

struct termios satt(int fid, int br)
{
int ret;

struct termios att;
	att= gatt(fid);
 
	att.c_iflag=0;
	att.c_iflag |= IGNBRK;
	// att.c_iflag |= BRKINT;
	att.c_iflag |= IGNPAR;
	// att.c_iflag |= PARMRK;
	// att.c_iflag |= INPCK;
	// att.c_iflag |= ISTRIP;
	// att.c_iflag |= INLCR;
	// att.c_iflag |= IGNCR;
	// att.c_iflag |= ICRNL;
	// att.c_iflag |= IXON;
	// att.c_iflag |= IXANY;
	// att.c_iflag |= IXOFF;
	// att.c_iflag |= IMAXBEL;

	att.c_oflag = 0;
	att.c_oflag |= OPOST;
	// att.c_oflag |= OLCUC;
	// att.c_oflag |= ONLCR;
	// att.c_oflag |= OCRNL;
	// att.c_oflag |= ONOCR;
	// att.c_oflag |= ONLRET;
	// att.c_oflag |= OFILL;

	att.c_cflag = 0;
	att.c_cflag |= CS8;
	att.c_cflag |= CSTOPB;
	att.c_cflag |= CREAD;
	// att.c_cflag |= PARENB;
	// att.c_cflag |= PARODD;
	// att.c_cflag |= HUPCL;
	// att.c_cflag |= CLOCAL;
	// att.c_cflag |= CIBAUD;
	// att.c_cflag |= CRTSCTS;

	att.c_lflag = 0;
	// att.c_lflag |= ISIG;
	// att.c_lflag |= ICANON;
	// att.c_lflag |= XCASE;
	// att.c_lflag |= ECHO;
	// att.c_lflag |= ECHOE;
	// att.c_lflag |= ECHOK;
	// att.c_lflag |= ECHONL;
	// att.c_lflag |= ECHOCTL;
	// att.c_lflag |= ECHOPRT;
	// att.c_lflag |= ECHOKE;
	att.c_lflag |= FLUSHO;
	// att.c_lflag |= NOFLSH;
	// att.c_lflag |= TOSTOP;
	// att.c_lflag |= PENDIN;
	// att.c_lflag |= IEXTEN;
	
	cfsetispeed(&att,br);
	cfsetospeed(&att,br);
	ret= tcsetattr(fid,TCSAFLUSH,&att);
	if (ret<0) {
		fprintf(stderr,"tcsetattr failed for fid %d\n",fid);
		exit(1);
	}
	return gatt(fid);
}

