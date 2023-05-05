#include <kos.h>
#include <dc/cdrom.h>
#include <assert.h>
#include <string.h>
#include <dirent.h>
#include <zlib/zlib.h>
#include <errno.h>

#include "antiruins.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"


uint64  start_time = 0;
float   deltaTimes[100];
int     deltaIndex = 0;

char*   new_path[256];

void      startTimer() {
  //timer_ms_gettime(secs, msecs);
  //start_time = (*secs + *msecs/1000.0f);
  start_time = timer_us_gettime64()/1000.0f;
}

float     getDelta() {
  float new_time = timer_us_gettime64()/1000.0f;
  float delta = new_time - start_time;
  
  deltaTimes[deltaIndex] = delta;
  deltaIndex ++;
  if (deltaIndex == 100) deltaIndex = 0;

  return delta;
}

float     getAverageDelta() {
  float total = 0;
  float min = 1000000;
  float max = 0;
  for (int i = 0; i < 100; i ++) {
    total += deltaTimes[i];
    if (deltaTimes[i] > max) max = deltaTimes[i];
    if (deltaTimes[i] < min) min = deltaTimes[i];
  }

  float avgDelta = total / 100.0f;

  printf("Average dt over the last 100 frames: %0.2f\n", (double)avgDelta);
  printf("Min dt: %2.2f || Max dt:%2.2f\n", (float)min, (float)max);

  return avgDelta;
}

int       checkCDContent() {
  /*
  CDROM_TOC toc;

  printf("Checking CD content... Current Session: %d\n", CMD_GETSES);
  int result = cdrom_read_toc(&toc, CMD_GETSES);
  if(result != ERR_OK) {
    printf("Error reading TOC: %d\n", result);
    return 0;
  }

  for(int i = 0; i < 99; i++) {
    if(toc.entry[i] != 0) {
      printf("Found a data track %d - size %d\n", i, toc.entry[i]);
    }
  }
  fflush(stdout);
  */
  return 1;
}

int       bin_exec2(char* filename) {
    printf("Trying to execute %s\n", filename);
    
    /* Map the sub-elf */
    file_t f;
    void *subelf;

    f = fs_open(filename, O_RDONLY);
    if (f == -1) {
      printf("Failed to load %s - %s \n", filename, strerror(errno));
      return(0);
    }
    
    subelf = fs_mmap(f);
    if (subelf == NULL) {
      printf("Failed to map %s - %s \n", filename, strerror(errno));
      return(0);
    }

    //assert(subelf);

    /* Tell exec to replace us */
    printf("sub.bin mapped at %08x, jumping to it!\n\n\n", subelf);
    arch_exec(subelf, fs_total(f));
    return(1);
}

int       bin_exec(char * binary) {
  /* execute a binary (c) 2002 Dan Potter, (c) 2011 PH3NOM */

  /* Open the input bin file */
  FILE * bin_file = fopen( binary,"rb" );
  assert( bin_file);

  /* obtain the bin file size using fseek */
  fseek ( bin_file , 0, SEEK_END );
  int lSize = ftell   ( bin_file );
  fseek ( bin_file , 0, SEEK_SET );

  /* allocate the buffer, then read the file into it */
  unsigned int * bin_buffer = malloc( lSize );
  assert( bin_buffer );
  fread ( bin_buffer, 1, lSize, bin_file );
  fclose( bin_file );

  /* Tell exec to replace us */
  arch_exec( bin_buffer, lSize );
  return(1);
}

char*     findFile(char *filename) {
  file_t  file;
  char*   dest[5];

  dest[0] = "";
  dest[1] = "cd";
  dest[2] = "pc";
  dest[3] = "rd";
  dest[4] = "sd";

  for(int i = 0; i < 5; i ++){
    sprintf(new_path, "%s/%s", dest[i], filename);
    if ((file = fs_open(new_path, O_RDONLY)) != -1){
      //if (debugActive) printf("Found file %s at %s > %s\n", filename, dest[i], new_path);
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

uint64_t  getTimeMS() {
    return timer_ms_gettime64();
}

uint64_t  getTimeUS() {
    return timer_us_gettime64();
}
