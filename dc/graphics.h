#ifndef __GRAPHICS_H__
#define __GRAPHICS_H__

#include <dc/pvr.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

typedef struct  __attribute__((packed, aligned(4))) _sprite{
  uint8   texID;
  uint     x, y;
  uint     w, h;
  float   a;
  float   u0, v0, u1, v1;
} sprite;

typedef struct __attribute__((packed, aligned(4))) _texture {
  char        filename;
  uint        id;
  pvr_ptr_t   data;
  uint        width, height;
  uint        format;
} texture;

typedef struct __attribute__((packed, aligned(4))) _font {
  uint     texID;
  uint     width, height;
  float    cellSize, gridSize;
  float    xSpacing, ySpacing;
  float    uS, vS;
} font;

void  initPVR();
// Bios print
void  biosprint(char* s, int x, int y);
void  batchString(const char* s, int x, int y);
void  loadFont();


int   freeTexture(int texID);

/* Boths these return texID */
int   loadPNG(char* filename);
int   loadDTEX(char* filename);

void  renderTexture(int texID, uint16_t x, uint16_t y, uint16_t w, uint16_t h);
void  renderRect(float x, float y, float w, float h, float r, float g, float b, float a);

int   newSprite(int texID, float x, float y, float w, float h, float a);
int   freeSprite(int spriteID);

void  startFrame();
void  renderFrame();

int   setPVRbind(lua_State *L);
#endif
