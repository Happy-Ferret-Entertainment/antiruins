#include <kos.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <zlib/zlib.h>
#include <GL/gl.h>
#include <GL/glkos.h>
#include <GL/glext.h>
#include <GL/glu.h>

#include "antiruins.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

time_t  master_time;
char  *new_path[256];

char*     findFile(char *filename) {
  file_t  file;
  char  *dest[5];

  dest[0] = "";
  dest[1] = "cd";
  dest[2] = "pc";
  dest[3] = "/rd";
  dest[4] = "/sd";

  for(int i = 0; i < 5; i ++){
    sprintf(new_path, "%s/%s", dest[i], filename);
    if ((file = fs_open(new_path, O_RDONLY)) != -1){
      if (debugActive) printf("Found file %s at %s > %s\n", filename, dest[i], new_path);
      fs_close(file);
      return(new_path);
    } else {
      //printf("No file %s at %s > %s%s\n", filename, dest[i], dest[i], filename);
    }
  }
  if (debugActive) printf("No file %s \n", filename);
  return(NULL);
}

void      debugMess(char *message) {
  if(debugActive){
    printf(message);
  }
}

int       mount_romdisk(char *filename, char *mountpoint){
  void  *buffer;
  char  path[100];
  int   length = 0;
  char  *dest[3];
  file_t f;

  dest[0] = "/pc";
  dest[1] = "/cd";
  dest[2] = "/sd";

  for(int i = 0; i < 3; i ++){
    sprintf(path, "%s/%s", dest[i], filename);
    f = fs_open(path, O_RDONLY);
    if(f != -1) {
      length = fs_total(f);
      printf("Found romdisk at %s -> size : %u\n", dest[i], length);
      break;
    } else {
      printf("Looking for romdisk at %s/%s\n", dest[i], filename);
    }
  }
  fs_close(f);

  ssize_t size = fs_load(path, &buffer);
  // Successfully read romdisk image
  if(size != -1)
  {
    fs_romdisk_mount(mountpoint, buffer, 1);
    return(1);
  }
  return(0);
}

int       unmount_romdisk() {
  if (fs_romdisk_unmount("/rd") == 0) {
    return(1);
  }
  else {
    printf("Failed to unmount romdisk\n");
    return(0);
  }
  return 0;
}

int       loadFile(char *filename) {
  void *buffer;
  int size = fs_load(filename, &buffer);

  // Successfully read romdisk image
  if(size != -1)
  {
      //fs_romdisk_mount(mountpoint, buffer, 1);
      return size;
  }
  else
      return 0;
}

uint64_t  getTime_MS() {
    uint32 s_s, s_ms;
    timer_ms_gettime(&s_s, &s_ms);
    return s_s*1000 + s_ms;
}

uint64_t  getTime_US() {
    uint64 us;
    us = timer_us_gettime64();
    return us;
}

void      quitGame(){
    exit(1);
}
