#ifndef __GRAPHICS_H__
#define __GRAPHICS_H__

#include <dc/pvr.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"


typedef struct _texture {
  char      filename;
  uint      id;
  pvr_ptr_t data;
  int       width, height;
  int       format;
} texture;


typedef struct __attribute__((packed, aligned(4))) vec3f_gl
{
    float x, y, z;
} vec3f;

typedef struct __attribute__((packed, aligned(4))) uv_float
{
    float u, v;
} uv_float;

typedef union color_uc {
  unsigned char array[4];
  unsigned int packed;
} color_uc;

typedef struct __attribute__((packed, aligned(4))) glvert
{
    uint32_t flags;
    struct vec3f_gl vert;
    uv_float texture;
    color_uc color; //bgra
    union {
        float pad;
        unsigned int vertindex;
     } pad0;
} glvert;

void  initPVR();

/* Boths these return texID */
int loadPNG(char* filename);
int loadDTEX(char* filename);

void renderTexture(int texID, uint16_t x, uint16_t y, uint16_t w, uint16_t h);
void renderRect(float x, float y, float w, float h, float r, float g, float b, float a);

int newSprite(int texID, float x, float y, float w, float h, float a);
int freeSprite(int spriteID);


void renderFrame();

int setPVRbind(lua_State *L);
#endif
