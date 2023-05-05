#ifndef __UTILS_H__
#define __UTILS_H__

#include <stdio.h>
#include <stdint.h>

void      startTimer();
float     getDelta();
float     getAverageDelta();

int     bin_exec(char* binary);
int     bin_exec2(char* binary);

int     checkCDContent();
char*   findFile(char* filename);
void    debugMess(char *message);
int     unmount_romdisk();
int     mount_romdisk(char *filename, char *mountpoint);
int     loadFile(char *filename);

uint64  getTimeMS();
uint64  getTimeUS();

void    quitGame();
//MATH//////////////
double distance(float x1,float y1,float x2,float y2);


#endif
