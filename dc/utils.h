#ifndef __UTILS_H__
#define __UTILS_H__

#include <stdio.h>
#include <stdint.h>

char*   findFile(char* filename);
void    debugMess(char *message);
int     unmount_romdisk();
int     mount_romdisk(char *filename, char *mountpoint);
int     loadFile(char *filename);

uint64_t  getTime_MS();
float     getTime_SEC();
void    quitGame();
//MATH//////////////
double distance(float x1,float y1,float x2,float y2);


#endif
