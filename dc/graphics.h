#ifndef __GRAPHICS_H__
#define __GRAPHICS_H__

#include <GL/gl.h>
#include <GL/glkos.h>
#include <GL/glext.h>
#include <GL/glu.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

typedef struct _texture {
  char*         filename;
  GLuint        id;
  int           width, height;
  GLfloat       scale[2];
  GLfloat       u, v, us, vs;
	GLenum 		    format;
	GLenum 		    min_filter;
	GLenum 		    mag_filter;
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

void  initGL();
void  setGLbinds();
int   getNextTexture();
int   initTexture(texture *t);
void  endFrame();

int LUA_setDrawColor(lua_State *L);
int LUA_setClearColor(lua_State *L);
int LUA_swapBuffer(lua_State *L);
int LUA_setTransparency(lua_State *L);

int LUA_loadTexture(lua_State *L);
int LUA_newTextureFromID(lua_State *L);
int LUA_setTextureUV(lua_State *L);
int LUA_getTextureInfo(lua_State *L);
int LUA_freeTexture(lua_State *L);
int LUA_drawTexture(lua_State *L);
int LUA_drawMultiTexture(lua_State *L);

int LUA_startBatch(lua_State *L);
int LUA_addToBatch(lua_State *L);
int LUA_endBatch(lua_State *L);

int LUA_startBatch2(lua_State *L);
int LUA_addToBatch2(lua_State *L);
int LUA_endBatch2(lua_State *L);

int LUA_matrixOperation(lua_State *L);

int LUA_drawQuad(lua_State *L);
int LUA_drawTri(lua_State *L);

int LUA_loadFont(lua_State *L);
int LUA_writeFont(lua_State *L);

// DREAMROQ /////////////////////////
//int LUA_startVideo(lua_State *L);


// LINE - VECTORS ///////////////////////
void drawLine(int x1, int y1, int x2, int y2);
int  drawTexture(texture *tex, int x, int y, int a, float w, float h);
void setFastVert(glvert *vertex, float x, float y, float z, float u, float v);

#endif
