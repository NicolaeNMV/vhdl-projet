
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#include <termios.h>
 
extern int ttyS_open(const char* base, int flag, int baud);
extern int ttyS_read(int vt100);
extern void ttyS_write(int vt100, unsigned char x);
