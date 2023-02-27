#include <kos.h>
#include <math.h>
#include <png/png.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <GL/gl.h>
#include <GL/glkos.h>
#include <GL/glext.h>
#include <GL/glu.h>
#include "extra/sh4_math.h"
//#include <dreamroq/dreamroqlib.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "graphics.h"
#include "antiruins.h"

//#include "extra/obj_loader.h"

#define M_PI 3.1415926535
#define MAX_TEXTURE     256
#define MAX_BATCH_VERT  4096
#define PACK_PIXEL(r, g, b) ( ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3) )
#define PACK_BGRA8888(b, g, r, a) ((uint32_t)(((uint8_t)(b) << 24) + ((uint8_t)(g) << 16) + ((uint8_t)(r) << 8) + (uint8_t)(a)))


GLfloat       global_ambient[4] = {1.0, 1.0, 1.0, 1.0};
GLfloat       global_diffuse[4] = {1.0, 1.0, 1.0, 1.0};
GLfloat       drawColor[4]      = {1.0f, 1.0f, 1.0f, 1.0f};
GLint         drawColori[4]     = {255, 255, 255, 255};
GLfloat       clearColor[4]     = {1.0f, 1.0f, 1.0f, 1.0f};
int           blendFlag         = 0;

// GLdc has a maximum of 32 textureID
texture       *tex[MAX_TEXTURE];
char          *filename[64];

// FONT
texture       *font[4];

// MATRIX
int           _push   = 1;
float         _rotate = 0.0f;

glvert        drawVert[2048];
int           vBatch = 0;
int           drawBatchSize = 0;

glvert        textVert[2048];
int           textBatchSize = 0;
GLfloat       zdepth = 0.00f;
GLfloat       z_inc    = -0.01f;

//GLfloat   textVert[4096];
int           batchActive   = 1;
float         uvSpacing[2];
float         glyphSize[2];
float         cellSize      = 16;
float         fontSize      = 16;
int           xSpacing      = 7;
float         glyphScale    = 1;

//Current texture data
GLfloat vertex_data[18];  // X/Y/Z * TRI * 2
GLfloat uv_data[18];      // X/Y/Z * TRI * 2
GLfloat normal_data[18];  // X/Y/Z * TRI * 2


int   png_to_gl_texture(texture *tex, char *filename);
int   dtex_to_gl_texture(texture *tex, char* filename);

void  initGL() { // We call this right after our OpenGL window is created.
  //pvr_init_defaults();
  //pvr_init();
  glKosInit();

  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);		// This Will Clear The Background Color To Black
  glClearDepth(1.0);				// Enables Clearing Of The Depth Buffer
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  //glDepthFunc(GL_LEQUAL);				// The Type Of Depth Test To Do
  //glEnable(GL_DEPTH_TEST);
  //glEnable(GL_ALPHA_TEST);
  glDisable(GL_NEARZ_CLIPPING_KOS);
  glShadeModel(GL_SMOOTH);			// Enables Smooth Color Shading
  glEnable(GL_NORMALIZE);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();				// Reset The Projection Matrix
  glOrtho(0.0, 640.0, 0.0, 480.0, -1.0, 1.0);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  GLfloat modelAmbient[4] = {0.8, 0.8, 0.8, 1.0};
  GLfloat ambient[4] = {0.2, 0.2, 0.2, 1.0};
  GLfloat diffuse[4] = {1.0, 1.0, 1.0, 1.0};
  GLfloat specular[4] = {0.0, 0.0, 0.0, 1.0};
  GLfloat position[4] = {320.0, 240.0, -5.0, 1.0};

  /*
  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glLightfv(GL_LIGHT0, GL_AMBIENT, modelAmbient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
  glLightfv(GL_LIGHT0, GL_SPECULAR, specular);
  glLightfv(GL_LIGHT0, GL_POSITION, position);
  */

  setGLbinds();
  initTexture(font[0]);
  glLoadIdentity();
  printf("L2D-Graphics> Init GLdc (struct Texture size: %d)\n", sizeof(texture));
}

void  setGLbinds() {
  lua_pushcfunction(luaData, LUA_swapBuffer);
  lua_setglobal(luaData, "C_swapBuffer");

  lua_pushcfunction(luaData, LUA_matrixOperation);
  lua_setglobal(luaData, "C_matrixOperation");

  lua_pushcfunction(luaData, LUA_setClearColor);
  lua_setglobal(luaData, "C_setClearColor");

  lua_pushcfunction(luaData, LUA_setDrawColor);
  lua_setglobal(luaData, "C_setDrawColor");

  lua_pushcfunction(luaData, LUA_setTransparency);
  lua_setglobal(luaData, "C_setTransparency");

  lua_pushcfunction(luaData, LUA_loadTexture);
  lua_setglobal(luaData, "C_loadTexture");

  lua_pushcfunction(luaData, LUA_setTextureUV);
  lua_setglobal(luaData, "C_setTextureUV");

  lua_pushcfunction(luaData, LUA_getTextureInfo);
  lua_setglobal(luaData, "C_getTextureInfo");

  lua_pushcfunction(luaData, LUA_newTextureFromID);
  lua_setglobal(luaData, "C_newTextureFromID");

  lua_pushcfunction(luaData, LUA_drawTexture);
  lua_setglobal(luaData, "C_drawTexture");

  lua_pushcfunction(luaData, LUA_freeTexture);
  lua_setglobal(luaData, "C_freeTexture");

  lua_pushcfunction(luaData, LUA_loadFont);
  lua_setglobal(luaData, "C_loadFont");

  lua_pushcfunction(luaData, LUA_writeFont);
  lua_setglobal(luaData, "C_writeFont");

  lua_pushcfunction(luaData, LUA_drawQuad);
  lua_setglobal(luaData, "C_drawQuad");

  lua_pushcfunction(luaData, LUA_drawTri);
  lua_setglobal(luaData, "C_drawTri");

  lua_pushcfunction(luaData, LUA_drawMultiTexture);
  lua_setglobal(luaData, "C_drawMultiTexture");

  lua_pushcfunction(luaData, LUA_startBatch);
  lua_setglobal(luaData, "C_startBatch");

  lua_pushcfunction(luaData, LUA_addToBatch);
  lua_setglobal(luaData, "C_addToBatch");

  lua_pushcfunction(luaData, LUA_endBatch);
  lua_setglobal(luaData, "C_endBatch");

  lua_pushcfunction(luaData, LUA_startBatch2);
  lua_setglobal(luaData, "C_startBatch2");

  lua_pushcfunction(luaData, LUA_endBatch2);
  lua_setglobal(luaData, "C_endBatch2");

  lua_pushcfunction(luaData, LUA_addToBatch2);
  lua_setglobal(luaData, "C_addToBatch2");

}

void  basicLight() {
  GLfloat modelAmbient[4] = {0.8, 0.8, 0.8, 1.0};
  GLfloat ambient[4] = {0.2, 0.2, 0.2, 1.0};
  GLfloat diffuse[4] = {1.0, 1.0, 1.0, 1.0};
  GLfloat specular[4] = {0.0, 0.0, 0.0, 1.0};

  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);
  glLightfv(GL_LIGHT0, GL_AMBIENT, modelAmbient);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
  glLightfv(GL_LIGHT0, GL_SPECULAR, specular);
  glDisable(GL_COLOR_MATERIAL);
}

void  endFrame() {
  zdepth = 15.0f;
}

int   LUA_setClearColor(lua_State *L) {
  clearColor[0] = (float)lua_tonumber(L, 1);
  clearColor[1] = (float)lua_tonumber(L, 2);
  clearColor[2] = (float)lua_tonumber(L, 3);
	glClearColor(clearColor[0], clearColor[1], clearColor[2], 1.0f);

	return 1;
}

int   LUA_setDrawColor(lua_State *L) {

  // BGRA Ordering
  drawColor[2] = (float)lua_tonumber(L, 1);
  drawColor[1] = (float)lua_tonumber(L, 2);
  drawColor[0] = (float)lua_tonumber(L, 3);
  drawColor[3] = (float)lua_tonumber(L, 4);

  drawColori[0] = drawColor[0] * 254;
  drawColori[1] = drawColor[1] * 254;
  drawColori[2] = drawColor[2] * 254;
  drawColori[3] = drawColor[3] * 254;

  if(drawColori[3] >= 254){
    blendFlag = 0;
  } else {
    blendFlag = 1;
  }

	return 1;
}

int   LUA_setTransparency(lua_State *L) {

  drawColor[3] = (float)lua_tonumber(L, 1);
  drawColori[3] = drawColor[3] * 254;

  if(drawColori[3] >= 254){
    blendFlag = 0;
  } else {
    blendFlag = 1;
  }

  //printf("ALPHA> %i - FLAG - %i\n", drawColori[3], blendFlag);

  return 1;
}

int   LUA_loadTexture(lua_State *L) {
  const char* filename = lua_tostring(L, 1);

  char* path = findFile(filename);
  if(path == NULL) return(NULL);

  texture *t = malloc(sizeof(texture) * 1);
  initTexture(t);
  t->filename = malloc(strlen(path) + 1);
  strcpy(t->filename, path);
  //t->filename[strlen(path) + 1] = '\0';

  char* type = strstr(t->filename, ".dtex");
  int r = 0;
  if(type != NULL) {
    r = dtex_to_gl_texture(t, t->filename);
  } else {
    r = png_to_gl_texture(t, t->filename);
  }


  if(r == 1 && debugActive) {

  }

  if(r == 1) {
    int index = getNextTexture();
    tex[index] = t;
    lua_pushnumber(L, index);
    lua_pushnumber(L, t->width);
    lua_pushnumber(L, t->height);
    //fprintf(stderr, "GRAPHICS.C> File %s loaded in texture slot #%d\n", t->filename, index);
    return 3;
  } else {
    lua_pushnumber(L, -1);
    return 1;
  }
}

int   LUA_newTextureFromID(lua_State *L) {
  int id = lua_tonumber(L, 1);

  if(&tex[id] != NULL) {
    int newID = getNextTexture();
    //printf("GRAPHICS.C>Copying %d into %d\n", id, newID);

    tex[newID] = malloc(sizeof(texture) * 1);
    *tex[newID] = *tex[id];
    lua_pushnumber(L, newID);
    return(1);
  }

  return(0);
}

int   LUA_setTextureUV(lua_State *L) {
  int id = lua_tonumber(L, 1);

  if(&tex[id] != NULL) {
    tex[id]->u = lua_tonumber(L, 2);
    tex[id]->v = lua_tonumber(L, 3);
    tex[id]->us = lua_tonumber(L, 4);
    tex[id]->vs = lua_tonumber(L, 5);
    //printf("New Texture %d W:%d H:%d\n", id, tex[id]->width, tex[id]->height);
    //printf("U:%0.2f, V:%0.2f, US:%0.2f, VS:%0.2f\n", tex[id]->u, tex[id]->v ,tex[id]->us ,tex[id]->vs);
  }
  lua_settop(L, 0);
  return(1);
}

int   LUA_getTextureInfo(lua_State *L) {
  int id = lua_tonumber(L, 1);

  if(&tex[id] != NULL) {
    lua_pushnumber(L, tex[id]->width);
    lua_pushnumber(L, tex[id]->height);
    lua_pushnumber(L, tex[id]->u);
    lua_pushnumber(L, tex[id]->v);
    lua_pushnumber(L, tex[id]->us);
    lua_pushnumber(L, tex[id]->vs);
  }
  return(6);
}

int   LUA_freeTexture(lua_State *L) {
  int id = lua_tonumber(L, 1);
  int type = lua_tonumber(L, 2);

  texture *t;

  // a full texture
  if        (type == 1) {
    t = tex[id];
  // a gameObject ID - WORKS
  } else if (type == 2) {
    if(&tex[id] != NULL) {
      free(tex[id]);
      tex[id] = NULL;
    }
    return 1;
  // a font
  } else if (type == 3) {
    t = font[id];
  }

  if(&t->filename != NULL)
    free(t->filename);

  printf("GRAPHICS.C > Freeing texture #%d | GL ID: %d\n", id, t->id);
  if (type != 2) {
    if(glIsTexture(t->id) == GL_TRUE) {
      glDeleteTextures(1, &t->id);
      printf("DELETED! | Mem left %d.\n", pvr_mem_available());

      // FEB 2020 - does free the texture ID and doesn't crash anything
      // !!! WONT WORK ON FONT!
      if(&tex[id] != NULL) {
        free(tex[id]);
        tex[id] = NULL;
      }

    } else {
      printf("Invalid GL texture\n");
      return 0;
    }
  }
  return 1;
}

int   png_to_gl_texture(texture *tex, char *filename) {
	int          ret     = 0;
	FILE         *file   = 0;
	uint8_t      *data   = 0;
	png_structp  parser  = 0;
	png_infop    info    = 0;
	png_bytep    *row_pointers = 0;

	png_uint_32 w, h;
	int bit_depth;
	int color_type;

	if(!tex) {
		printf("No pointer for texture\n");
		return(0);
	}

	file = fopen(filename, "rb");
	if(!file) {
		printf("Couldn't find %s\n", filename);
		fclose(file);
	}

	parser = png_create_read_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
	if(!parser) {
	}

	info = png_create_info_struct(parser);
	if(!info) {
	}

	if(setjmp(png_jmpbuf(parser))) {
	}

	png_init_io(parser, file);
	png_read_info(parser, info);
	png_get_IHDR(parser, info, &w, &h, &bit_depth, &color_type, 0, 0, 0);

	if((w & (w-1)) || (h & (h-1)) || w < 8 || h < 8) {
	}

	if(png_get_valid(parser, info, PNG_INFO_tRNS) || (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) || color_type == PNG_COLOR_TYPE_PALETTE) {
		png_set_expand(parser);
	}
	if(bit_depth == 16) {
		png_set_strip_16(parser);
	}
	if(color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_GRAY_ALPHA) {
		png_set_gray_to_rgb(parser);
	}
	png_read_update_info(parser, info);

	int rowbytes = png_get_rowbytes(parser, info);
	rowbytes += 3 - ((rowbytes-1) % 4); // align to 4 bytes

	int data_size = rowbytes * h * sizeof(png_byte) + 15;
	data = malloc(rowbytes * h * sizeof(png_byte) + 15);
	if(!data) {
		printf("No space for .PNG texture");
		return(0);
	}

	row_pointers = malloc(h * sizeof(png_bytep));
	if(!row_pointers) {
		printf("No rowpointers for .PNG texture");
		return(0);
  }

	// set the individual row_pointers to point at the correct offsets of data
	for(png_uint_32 i = 0; i < h; ++i) {
		row_pointers[h - 1 - i] = data + i * rowbytes;
	}

	png_read_image(parser, row_pointers);

	// Generate the OpenGL texture object
	glGenTextures(1, &tex->id);
	glBindTexture(GL_TEXTURE_2D, tex->id);
	GLenum texture_format = (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;
	//GLenum texture_format = GL_RGB;
	glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h, 0, texture_format,   GL_UNSIGNED_BYTE, data);

	tex->width = w;
	tex->height = h;
	tex->format = texture_format;
	ret = 1;

	if(debugActive)
		printf("GRAPHICS.C> Loaded %s ID:%d | Mem left:%d\n", tex->filename, tex->id, pvr_mem_available());

	fclose(file);
	png_destroy_read_struct(&parser, info ? &info : 0, 0);
	free(row_pointers);
	free(data);
	return ret;
}

int   dtex_to_gl_texture(texture *tex, char* filename) {
    // Load Texture

    typedef struct Image {
        unsigned long sizeX;
        unsigned long sizeY;
        char          *data;
        GLenum        internalFormat;
        GLboolean     mipmapped;
        unsigned int  dataSize;
    } Image;

    Image *image;

    // allocate space for texture
    image = (Image *) malloc(sizeof(Image));
    if (image == NULL) {
				printf("No memory for .DTEX file\n");
				return(0);
    }

		FILE* file = NULL;

		// make sure the file is there.
		if ((file = fopen(filename, "rb")) == NULL)
		{
			printf("GRAPHICS.C> File not found : %s\n", filename);
				return 0;
		}

		struct {
				char	     id[4];	// 'DTEX'
				GLushort	 width;
				GLushort	 height;
				GLuint		 type;
				GLuint		 size;
		} header;

		fread(&header, sizeof(header), 1, file);

		GLboolean twiddled = (header.type & (1 << 26)) < 1;
		GLboolean compressed = (header.type & (1 << 30)) > 0;
		GLboolean mipmapped = (header.type & (1 << 31)) > 0;
		GLboolean strided = (header.type & (1 << 25)) > 0;
		GLuint 		format = (header.type >> 27) & 0b111;

		image->data = (char *) malloc (header.size);
		image->sizeX = header.width;
		image->sizeY = header.height;
		image->dataSize = header.size;

		GLuint expected = 2 * header.width * header.height;
		GLuint ratio = (GLuint) (((GLfloat) expected) / ((GLfloat) header.size));

    uint64_t t1 = getTime_MS();
    // i can use mutlple of 32 bytes
		fread(image->data, image->dataSize, 1, file);
    //memcpy(image->data, file, image->dataSize * 1);
    //*file += image->dataSize * 1;
    uint64_t t2 = getTime_MS() - t1;
    printf("GRAPHICS.C-DEBUG> fread speed %0.2f SEC\n", (double)t2 * 0.001f);

		fclose(file);

		if(compressed) {
				printf("Compressed - ");
				if(twiddled) {
					printf("Twiddled - ");
						switch(format) {
								case 0: {
										if(mipmapped) {
												image->internalFormat = GL_COMPRESSED_ARGB_1555_VQ_MIPMAP_TWID_KOS;
										} else {
												image->internalFormat = GL_COMPRESSED_ARGB_1555_VQ_TWID_KOS;
										}
								} break;
								case 1: {
										if(mipmapped) {
												image->internalFormat = GL_COMPRESSED_RGB_565_VQ_MIPMAP_TWID_KOS;
										} else {
												image->internalFormat = GL_COMPRESSED_RGB_565_VQ_TWID_KOS;
										}
								} break;
								case 2: {
										if(mipmapped) {
												image->internalFormat = GL_COMPRESSED_ARGB_4444_VQ_MIPMAP_TWID_KOS;
										} else {
												image->internalFormat = GL_COMPRESSED_ARGB_4444_VQ_TWID_KOS;
										}
								}
								break;
								default:
										fprintf(stderr, "Invalid texture format");
										return 0;
						}
				} else {
						switch(format) {
								case 0: {
										if(mipmapped) {
												image->internalFormat = GL_COMPRESSED_ARGB_1555_VQ_MIPMAP_KOS;
										} else {
												image->internalFormat = GL_COMPRESSED_ARGB_1555_VQ_KOS;
										}
								} break;
								case 1: {
										if(mipmapped) {
												image->internalFormat = GL_COMPRESSED_RGB_565_VQ_MIPMAP_KOS;
										} else {
												image->internalFormat = GL_COMPRESSED_RGB_565_VQ_KOS;
										}
								} break;
								case 2: {
										if(mipmapped) {
												image->internalFormat = GL_COMPRESSED_ARGB_4444_VQ_MIPMAP_KOS;
										} else {
												image->internalFormat = GL_COMPRESSED_ARGB_4444_VQ_KOS;
										}
								}
								break;
								default:
										fprintf(stderr, "Invalid texture format");
										return 0;
						}
				}
		} else {
			//printf("Uncompressed - ");
			//printf("Color:%u -", format);
				switch(format) {

						case 0:
								image->internalFormat = GL_UNSIGNED_SHORT_1_5_5_5_REV_TWID_KOS;
								//image->internalFormat = GL_UNSIGNED_SHORT_1_5_5_5_REV;
						break;
						case 1:
								image->internalFormat = GL_UNSIGNED_SHORT_5_6_5_REV;
						break;
						case 2:
								image->internalFormat = GL_UNSIGNED_SHORT_4_4_4_4_REV;
						break;
			}
		}

    printf("GRAPHICS.C> Mem before loading: %d\n", pvr_mem_available());

		// Create Texture
    glGenTextures(1, &tex->id);
  	glBindTexture(GL_TEXTURE_2D, tex->id);

		GLint newFormat = format;
		GLint colorType = GL_RGB;

		if (image->internalFormat == GL_UNSIGNED_SHORT_1_5_5_5_REV_TWID_KOS ||
				image->internalFormat == GL_UNSIGNED_SHORT_4_4_4_4_REV){
					 newFormat = GL_BGRA;
					 colorType = GL_RGBA;
					 //printf("Reversing RGBA\n");
			}

		if (image->internalFormat == GL_UNSIGNED_SHORT_5_6_5_REV){
					 newFormat = GL_RGB;
					 colorType = GL_RGB;
					 //printf("Reversing RGB\n");
			}

		glTexImage2D(GL_TEXTURE_2D, 0,
			colorType, image->sizeX, image->sizeY, 0,
			newFormat, image->internalFormat, image->data);

    tex->width  = image->sizeX;
  	tex->height = image->sizeY;
  	tex->format = image->internalFormat;

    free(image->data);

  	if(debugActive)
  		printf("GRAPHICS.C> Loaded %s GL_ID:%d | Mem after loading: %d\n", tex->filename, tex->id, pvr_mem_available());

		return(1);
};

int   getNextTexture() {
  for(int i = 1; i < MAX_TEXTURE; i++) {
    if(tex[i] == NULL){
      //if(debugActive)
        //printf("GRAPHICS.C> Texture slot %d is available.\n", i);
      return(i);
    }
  }
  return 0;
}

int   initTexture(texture *tex) {
  tex->filename = NULL;
  tex->height = 32;
  tex->width  = 32;
  tex->u  = tex->v = 0.0;
  tex->us = tex->vs = 1.0;
  tex->scale[0] = tex->scale[1] = 1.0;
  return(1);
}

int   freeTexture(texture *tex) {
	if(glIsTexture(tex->id)) {
		glDeleteTextures(1, &tex->id);
	}

  //this could be problematic
  if(tex->filename != NULL) {
    free(tex->filename);
    tex->filename = NULL;
  }
  return(1);
}

// DRAWING //////////////////////////////////////////////////////
int   LUA_addTri(lua_State *L) {

}

int   LUA_drawTriBatch(lua_State *L) {

}

int   LUA_drawTri(lua_State *L) {

  GLfloat x1 = (float)lua_tonumber(L, 1);
  GLfloat y1 = (float)lua_tonumber(L, 2);
  GLfloat x2 = (float)lua_tonumber(L, 3);
  GLfloat y2 = (float)lua_tonumber(L, 4);
  GLfloat x3 = (float)lua_tonumber(L, 5);
  GLfloat y3 = (float)lua_tonumber(L, 6);
  GLfloat angle = (float)lua_tonumber(L, 7);

  GLfloat vertex_data[] = {
		x1,  -y1,  5,
		x2,  -y2,  5,
		x3,  -y3,  5
	};

  setFastVert(&drawVert[0], x1,  -y1,  0, 0, 0);
  setFastVert(&drawVert[1], x2,  -y2,  0, 1, 1);
  setFastVert(&drawVert[2], x3,  -y3,  0, 1, 0);

  glEnableClientState  (GL_VERTEX_ARRAY);
  glEnableClientState  (GL_COLOR_ARRAY);

  glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &drawVert[0].vert);
  glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &drawVert[0].color.array);

  glPushMatrix();
  glTranslatef(0, 0, -zdepth);
  zdepth += z_inc;

  if(blendFlag == 1) {
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  } else {
    glDisable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.1f);
  }

  glDrawArrays(GL_TRIANGLES, 0, 3);
  glPopMatrix();

	glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);
	glDisable(GL_BLEND);
  //glPopMatrix();

  lua_settop(L, 0);
	return 1;
}

int   LUA_drawQuad(lua_State *L) {

	GLfloat x = (float)lua_tonumber(L, -4);
	GLfloat y = (float)lua_tonumber(L, -3);
	GLfloat	w = (float)lua_tonumber(L, -2)*0.5;
	GLfloat h = (float)lua_tonumber(L, -1)*0.5;

  setFastVert(&drawVert[0], -w, -h,   0, 0, 0);
  setFastVert(&drawVert[1], w,  h,    0, 1, 1);
  setFastVert(&drawVert[2], w,  -h,   0, 1, 0);
  setFastVert(&drawVert[3], -w,  -h,  0, 0, 0);
  setFastVert(&drawVert[4], w,  h,    0, 1, 1);
  setFastVert(&drawVert[5], -w,  h,   0, 0, 1);

  glPushMatrix();
  glTranslatef(x, -y, -zdepth);
  zdepth += z_inc;

  if(blendFlag == 1) {
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  } else {
    glDisable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.1f);
  }

	glEnableClientState  (GL_VERTEX_ARRAY);
  glEnableClientState  (GL_COLOR_ARRAY);

  glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &drawVert[0].vert);
  glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &drawVert[0].color.array);

  glDrawArrays(GL_TRIANGLES, 0, 6);

	glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);

  glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);
  glPopMatrix();

	return 1;
}

int   LUA_drawMultiTexture(lua_State *L) {
  // https://www.opengl.org/archives/resources/code/samples/sig99/advanced99/notes/node61.html


  int     id      = (int)lua_tonumber(L, 1);
  int     id2     = (int)lua_tonumber(L, 2);
  GLfloat x       = (float)lua_tonumber(L, 3);
  GLfloat y       = (float)lua_tonumber(L, 4);
  GLfloat a       = (float)lua_tonumber(L, 5);
  GLfloat xScale  = (float)lua_tonumber(L, 6);
  GLfloat yScale  = (float)lua_tonumber(L, 7);


  if(tex[id] == NULL || tex[id2] == NULL) {
    printf("GRAPHICS.C> Trying to print a NULL multi-texture (%d)\n", id);
    id = 0;
    return 0;
  } else {
    printf("GRAPHICS.C> MULTI T1:%d T2:%d at X:%d Y:%d\n", id, id2, x, y);
  }

  GLfloat u = tex[id]->u;
  GLfloat v = tex[id]->v;
  GLfloat us = tex[id]->us;
  GLfloat vs = tex[id]->vs;

  GLfloat w = (tex[id]->width * tex[id]->us * xScale) * 0.5f;
  GLfloat h = (tex[id]->height * tex[id]->vs * yScale) * 0.5f;


  GLfloat vertex_data[] = {
    -w, -h, 1,
    w, h, 1,
    w, -h, 1,
    -w, -h, 1,
    w, h, 1,
    -w, h, 1
  };

  GLfloat uv_data[] = {
    u, v,
    u + us, v + vs,
    u + us, v,
    u, v,
    u + us, v + vs,
    u, v + vs
  };

  /*
  printf("Drawing texture %d at X%.f Y%.f\n", id, (double)x, (double)y);
  printf("texW:%0.2f texH:%0.2f\n", (double)texW, (double)texH);
  printf("U:%0.2f V:%0.2f US:%0.2f VS:%0.2f\n", (double)u, (double)v, (double)us, (double)vs);
  */

  GLfloat normal_data[] = {
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0
  };

  glPushMatrix();
  glTranslatef(x, 480 - y, 0);
  glRotatef(a, 0, 0, -1);

  /* Enable Client States for OpenGL Arrays Submission */
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  //glEnableClientState(GL_COLOR_ARRAY);

  /* Bind texture to GL_TEXTURE0_ARB and set texture parameters */
  glActiveTextureARB(GL_TEXTURE0_ARB);
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex[id]->id);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  /* Bind multi-texture to GL_TEXTURE1_ARB and set texture parameters */
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex[id2]->id);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  //glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB_ARB, GL_ADD_SIGNED_ARB);

  //// UV //////////////////////////////////////////////////
  /* Bind texture coordinates to GL_TEXTURE0_ARB */
  //glTexCoordPointer(2, GL_FLOAT, 0, TEXCOORD_ARRAY);
  //glTexCoordPointer		(2, GL_FLOAT, 0, uv_data);


  /* Bind texture coordinates to GL_TEXTURE1_ARB */
  u = tex[id2]->u;
  v = tex[id2]->v;
  us = tex[id2]->us;
  vs = tex[id2]->vs;

  GLfloat uv_data2[] = {
    u, v,
    u + us, v + vs,
    u + us, v,
    u, v,
    u + us, v + vs,
    u, v + vs
  };

  glClientActiveTextureARB(GL_TEXTURE1_ARB);
  glTexCoordPointer		(2, GL_FLOAT, 0, uv_data2);

  glClientActiveTextureARB(GL_TEXTURE0_ARB);
  glTexCoordPointer		(2, GL_FLOAT, 0, uv_data);
  /* Bind the Color Array */
  //glColorPointer(GL_BGRA, GL_UNSIGNED_BYTE, 0, ARGB_ARRAY);
  //glMaterialfv				(GL_FRONT, GL_DIFFUSE, global_diffuse);
  //glMaterialfv				(GL_FRONT, GL_AMBIENT, global_ambient);

  /* Bind the Vertex Array */
  glVertexPointer(3, GL_FLOAT, 0, vertex_data);
  glNormalPointer(GL_FLOAT, 0, normal_data);

  /* Set Blending Mode */
  //glBlendFunc(GL_SRC_ALPHA, GL_DST_ALPHA);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  /* Render the Vertices as Indexed Arrays using glDrawArrays */
  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);


  /* Disable GL_TEXTURE1 */
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glBindTexture(GL_TEXTURE_2D, 0);
  glDisable(GL_TEXTURE_2D);

  /* Make sure to set glActiveTexture back to GL_TEXTURE0_ARB when finished */
  glActiveTextureARB(GL_TEXTURE0_ARB);
  glBindTexture(GL_TEXTURE_2D, 0);
  glDisable(GL_TEXTURE_2D);

  /* Disable Vertex, Color and Texture Coord Arrays */
  glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);

  glDisable(GL_TEXTURE_2D);
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);

  glPopMatrix();

  return(1);
}

int   LUA_drawTexture(lua_State *L) {
  // Need to optimize the hell out of this

  int     id = (int)lua_tonumber(L, 1);
	GLfloat x = (float)lua_tonumber(L, 2);
	GLfloat y = (float)lua_tonumber(L, 3);
  GLfloat a = (float)lua_tonumber(L, 4);
  GLfloat xScale = (float)lua_tonumber(L, 5);
  GLfloat yScale = (float)lua_tonumber(L, 6);

  if(tex[id] == NULL) {
    printf("GRAPHICS.C> Trying to print a NULL texture (%d)\n", id);
    id = 0;
    return 0;
  }

  GLfloat u = tex[id]->u;
  GLfloat v = tex[id]->v;
  GLfloat us = tex[id]->us;
  GLfloat vs = tex[id]->vs;

  GLfloat w = (tex[id]->width * tex[id]->us)  * (xScale * 0.5f);
  GLfloat h = (tex[id]->height * tex[id]->vs) * (yScale * 0.5f);

  /*
  // REGULAR 2 x TRI
  setFastVert(&drawVert[0], -w, -h,  5, u,  v);
  setFastVert(&drawVert[1], w,  h,  5, u + us, v + vs);
  setFastVert(&drawVert[2], w,  -h,  5, u + us, v);
  setFastVert(&drawVert[3], -w, -h,  5, u,   v);
  setFastVert(&drawVert[4], w,  h,  5, u + us, v + vs);
  setFastVert(&drawVert[5], -w, h,  5, u,   v + vs);
  */

  // TRIANGLE_FAN
  setFastVert(&drawVert[0], 0,  0,    0, u + us*0.5 , v + vs*0.5);
  setFastVert(&drawVert[1], -w, h,    0, u          , v + vs);
  setFastVert(&drawVert[2], 0,  h,    0, u + us*0.5 , v + vs);
  setFastVert(&drawVert[3], w,  h,    0, u + us     , v + vs);
  setFastVert(&drawVert[4], w,  0,    0, u + us     , v + vs*0.5);
  setFastVert(&drawVert[5], w,  -h,   0, u + us     , v);
  setFastVert(&drawVert[6], 0,  -h,   0, u + us*0.5 , v);
  setFastVert(&drawVert[7], -w, -h,   0, u          , v);
  setFastVert(&drawVert[8], -w, 0,    0, u           , v + vs*0.5);
  setFastVert(&drawVert[9], -w, h,    0, u          , v + vs);


  glPushMatrix();
  glTranslatef(x, -y, -zdepth);
  glRotatef(a, 0, 0, -1);
  zdepth += z_inc;

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex[id]->id);

  if(blendFlag == 1) {
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  } else {
    glDisable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.1f);
  }

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);

  glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &drawVert->vert);
  glTexCoordPointer		(2, GL_FLOAT, sizeof(glvert), &drawVert->texture);
  glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &drawVert->color.packed);

  glDrawArrays(GL_TRIANGLE_FAN, 0, 10); // Regular 2 x tri
  //glDrawArrays(GL_TRIANGLES, 0, 5); // Regular 2 x tri

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);

  glDisable(GL_ALPHA_TEST);
  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);

  glPopMatrix();

	return 1;
}

int   LUA_swapBuffer(lua_State *L) {
    //pvr_scene_finish();
    glKosSwapBuffers();
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    //pvr_wait_ready();
    //pvr_set_bg_color(0,0,0);
    //glClearColor(0.0f, 0.0f, 0.0f, 1.0f);		// This Will Clear The Background Color To Black
    //glClearDepth(1.0);				              // Enables Clearing Of The Depth Buffer


    return 1;
}

int   LUA_startBatch(lua_State *L) {
  int id = (int)lua_tonumber(L, 1);

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex[id]->id);

  if(blendFlag == 1) {
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  } else {
    glDisable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.1f);
  }

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);

  return(1);
}

int   LUA_startBatch2(lua_State *L) {
  vBatch = 0;
  return(1);
}

int   LUA_addToBatch(lua_State *L) {
  GLfloat w = (float)lua_tonumber(L, 4) * 0.5f;
  GLfloat h = (float)lua_tonumber(L, 5) * 0.5f;

  GLfloat u = (float)lua_tonumber(L, 6);
  GLfloat v = (float)lua_tonumber(L, 7);
  GLfloat us = (float)lua_tonumber(L, 8);
  GLfloat vs = (float)lua_tonumber(L, 9);

  glPushMatrix();
  glTranslatef((float)lua_tonumber(L, 1), -(float)lua_tonumber(L, 2), -zdepth);
  glRotatef((float)lua_tonumber(L, 3), 0, 0, -1);
  zdepth += z_inc;


  // 2x tri
  setFastVert(&drawVert[0], -w,  -h,  0, u,  v);
  setFastVert(&drawVert[1], w,  h,    0, u + us, v + vs);
  setFastVert(&drawVert[2], w,  -h,   0, u + us, v);
  setFastVert(&drawVert[3], -w,  -h,  0, u,   v);
  setFastVert(&drawVert[4], w,  h,    0, u + us, v + vs);
  setFastVert(&drawVert[5], -w,  h,   0, u,   v + vs);


  /*
  // TRIP STRIP
  setFastVert(&drawVert[0], -w,   -h,   0, u,  v);
  setFastVert(&drawVert[1], -w,   0,    0, u,  v+vs*0.5);
  setFastVert(&drawVert[2], 0,    -h,   0, u+us*0.5,  v);
  setFastVert(&drawVert[3], 0,    0,    0, u+us*0.5,  v+vs*0.5);
  setFastVert(&drawVert[4], w,    -h,   0, u+us,  v);
  setFastVert(&drawVert[5], w,    0,    0, u+us,  v+vs*0.5);

  setFastVert(&drawVert[6], -w,   0,   0, u,  v+vs*0.5);
  setFastVert(&drawVert[7], -w,   h,    0, u,  v+vs);
  setFastVert(&drawVert[8], 0,    0,   0, u+us*0.5,  v+vs*0.5);
  setFastVert(&drawVert[9], 0,    h,    0, u+us*0.5,  v+vs);
  setFastVert(&drawVert[10], w,    0,   0, u+us,  v+vs*0.5);
  setFastVert(&drawVert[11], w,    h,    0, u+us,  v+vs);
  */

  glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &drawVert[0].vert);
  glTexCoordPointer		(2, GL_FLOAT, sizeof(glvert), &drawVert[0].texture);
  glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &drawVert[0].color.array);

  //glDrawArrays(GL_TRIANGLE_STRIP, 0, 12);
  glDrawArrays(GL_TRIANGLES, 0, 6);

  glPopMatrix();

  return(1);
}

int   LUA_addToBatch2(lua_State *L) {
  float _w  = (float)lua_tonumber(L, 4) * 0.5f;
  float _h  = (float)lua_tonumber(L, 5) * 0.5f;
  float u   = (float)lua_tonumber(L, 6);
  float v   = (float)lua_tonumber(L, 7);
  float us  = (float)lua_tonumber(L, 8);
  float vs  = (float)lua_tonumber(L, 9);
  int x     =   (int)lua_tonumber(L, 1);
  int y     =   -(int)lua_tonumber(L, 2);

  // VERY IMPORTANT USAGE INFORMATION (sine and cosine functions):
  //
  // Due to the nature in which the fsca instruction behaves, you MUST do the
  // following in your code to get sine and cosine from these functions:
  //
  //  _Complex float sine_cosine = [Call the fsca function here]
  //  float sine_value = __real__ sine_cosine;
  //  float cosine_value = __imag__ sine_cosine;
  //  Your output is now in sine_value and cosine_value.

  //get sin/cos
  //RETURN_FSCA_STRUCT r = MATH_fsca_Float_Rad((float)lua_tonumber(L, 3));
  //RETURN_VECTOR_STRUCT r = MATH_fsca_Float_Rad((float)lua_tonumber(L, 3));
  
  
  
  //_Complex float sine_cosine = MATH_fsca_Float_Rad((float)lua_tonumber(L, 3));
  //float sine    = __real__ sine_cosine;
  //float cosine  = __imag__ sine_cosine;
  float sine = 1;
  float cosine = 1;

  float w = 0;
  float h = 0;
  //get the origin of the point
  w = -_w * cosine - -_h * sine;
  h = -_w * sine   + -_h * cosine;
  setFastVert(&drawVert[vBatch++], x + w, y + h, -zdepth, u, v);

  w = _w * cosine - _h * sine;
  h = _w * sine   + _h * cosine;
  setFastVert(&drawVert[vBatch++], x + w, y + h, -zdepth, u + us, v + vs);

  w = _w * cosine - -_h * sine;
  h = _w * sine   + -_h * cosine;
  setFastVert(&drawVert[vBatch++], x + w, y + h, -zdepth, u + us, v);

  w = -_w * cosine - -_h * sine;
  h = -_w * sine   + -_h * cosine;
  setFastVert(&drawVert[vBatch++], x + w, y + h, -zdepth, u, v);

  w = _w * cosine - _h * sine;
  h = _w * sine   + _h * cosine;
  setFastVert(&drawVert[vBatch++], x + w, y + h, -zdepth, u + us, v + vs);

  w = -_w * cosine - _h * sine;
  h = -_w * sine   + _h * cosine;
  setFastVert(&drawVert[vBatch++], x + w, y + h, -zdepth, u, v + vs);

  zdepth += z_inc;

  return(1);
}

int   LUA_endBatch(lua_State *L) {
  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);

  glDisable(GL_TEXTURE_2D);
  glDisable(GL_ALPHA_TEST);
  glDisable(GL_BLEND);
  drawBatchSize = 0;
  return(1);
}

int   LUA_endBatch2(lua_State *L) {

  int id        = (int)lua_tonumber(L, 1); // texture id
  if(!glIsTexture(tex[id]->id)) {
    printf("TRYING TO RENDER BATCH WITH INVALID TEXTURE\n");
    return(0);
  }

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex[id]->id);

  if(blendFlag == 1) {
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  } else {
    glDisable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.1f);
  }

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);

  /*
  //printf("--- END BATCH 2 ---\n");

  int batchSize = 0;

  // Check fo valid table
  if (!lua_istable(L, 1)) {
    printf("Can't find the actial batch table\n");
  } else {
    batchSize = lua_rawlen(L, 1);
    //printf("Valid batch (size %d)\n", batchSize);
  }


  float w, h, u, v, us, vs;
  int   t = 0;

  //this would get the table that is located that index
  for(int i = 1; i <= batchSize; i++) {
    lua_rawgeti(L, 1, i); // object data
    t = lua_gettop(L);
    for(int j = 1; j <= 9; j++) { lua_rawgeti(L, t, j); }
    //float x = lua_tonumber(L, -9);
    //float y = lua_tonumber(L, -8);
    //float a = lua_tonumber(L, -7);
    w = lua_tonumber(L, -6);
    h = lua_tonumber(L, -5);
    u = lua_tonumber(L, -4);
    v = lua_tonumber(L, -3);
    us = lua_tonumber(L, -2);
    vs = lua_tonumber(L, -1);

    glPushMatrix();
    glTranslatef(lua_tonumber(L, -9), -lua_tonumber(L, -8), -zdepth);
    glRotatef(lua_tonumber(L, -7), 0, 0, -1);
    zdepth += z_inc;

    // 2x tri
    setFastVert(&drawVert[0], -w,  -h,  0, u,  v);
    setFastVert(&drawVert[1], w,  h,    0, u + us, v + vs);
    setFastVert(&drawVert[2], w,  -h,   0, u + us, v);
    setFastVert(&drawVert[3], -w,  -h,  0, u,   v);
    setFastVert(&drawVert[4], w,  h,    0, u + us, v + vs);
    setFastVert(&drawVert[5], -w,  h,   0, u,   v + vs);

    glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &drawVert[0].vert);
    glTexCoordPointer		(2, GL_FLOAT, sizeof(glvert), &drawVert[0].texture);
    glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &drawVert[0].color.array);

    //glDrawArrays(GL_TRIANGLE_STRIP, 0, 12);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    glPopMatrix();
    //dumpstack(L);

    lua_pop(L, 9); // remove table data
    lua_pop(L, 1); // remove table
  }
  */

  glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &drawVert[0].vert);
  glTexCoordPointer		(2, GL_FLOAT, sizeof(glvert), &drawVert[0].texture);
  glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &drawVert[0].color.array);

  //glDrawArrays(GL_TRIANGLE_STRIP, 0, 12);
  glDrawArrays(GL_TRIANGLES, 0, vBatch);

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);

  glDisable(GL_TEXTURE_2D);
  glDisable(GL_ALPHA_TEST);
  glDisable(GL_BLEND);
  vBatch = 0;
  return(1);

  /*
  int index = 1;
  //this would get the table that is located that index
  lua_rawgeti(L, 1, index);
  if (!lua_istable(L, -1)) {
  printf("Didn't find table!\n");
  } else {
  int dataLen = lua_rawlen(L, -1);
  printf("Table len = %d\n", dataLen);
  for(int i = 1; i <= dataLen; i++) {
  lua_rawgeti(L, -1, i);
  float data = lua_tonumber(L, -1);
  printf("%d=%0.2f | ", i, data);
  lua_pop(L, 1);
  }
  printf("\n");
  }
  */
}

/*
int LUA_drawTexture(lua_State *L) {
  // Need to optimize the hell out of this

  int     id = (int)lua_tonumber(L, 1);
	GLfloat x = (float)lua_tonumber(L, 2);
	GLfloat y = (float)lua_tonumber(L, 3);

  if(tex[id] == NULL) {
    printf("GRAPHICS.C> Trying to print a NULL texture (%d)\n", id);
    id = 0;
    return 0;
  }

  GLfloat u = tex[id]->u;
  GLfloat v = tex[id]->v;
  GLfloat us = tex[id]->us;
  GLfloat vs = tex[id]->vs;

  GLfloat w = (tex[id]->width * tex[id]->us * tex[id]->scale[0]) * 0.5f;
  GLfloat h = (tex[id]->height * tex[id]->vs * tex[id]->scale[1]) * 0.5f;


  GLfloat vertex_data[] = {
		x-w, y-h, 1,
		x+w, y+h, 1,
		x+w, y-h, 1,
    x-w, y-h, 1,
    x+w, y+h, 1,
		x-w, y+h, 1
	};

	GLfloat uv_data[] = {
    u, v,
		u + us, v + vs,
		u + us, v,
    u, v,
		u + us, v + vs,
		u, v + vs
	};


	GLfloat normal_data[] = {
		0.0, 0.0, 1.0,
		0.0, 0.0, 1.0,
		0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
		0.0, 0.0, 1.0
	};

	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, tex[id]->id);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);

	glVertexPointer			(3, GL_FLOAT, 0, vertex_data);
	glTexCoordPointer		(2, GL_FLOAT, 0, uv_data);
	glNormalPointer			(GL_FLOAT, 0, normal_data);

	glMaterialfv				(GL_FRONT, GL_DIFFUSE, global_diffuse);
	glMaterialfv				(GL_FRONT, GL_AMBIENT, global_ambient);

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//glDrawArrays(GL_TR, 0, 4);
  glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);

	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_NORMAL_ARRAY);

  glDisable(GL_TEXTURE_2D);
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);

	return 1;
}
*/

int   LUA_matrixOperation(lua_State *L) {

  const char* type  = lua_tostring(L, 1);
  const float x     = (float)lua_tonumber(L, 2);
  const float y     = (float)lua_tonumber(L, 3);
  const float z     = (float)lua_tonumber(L, 4);

  if(strcmp(type, "rotate") == 0) {
    //x = angle, then rtation vector (0,0,-1)
    glRotatef(x, 0, 0, -1);
    return 1;
  }

  if(strcmp(type, "scale") == 0) {
    glScalef(x, y, 0);
    return 1;
  }

  if(strcmp(type, "translate") == 0) {
    glTranslatef(x, y, z);
    return 1;
  }

  if(strcmp(type, "push") == 0) {
    glPushMatrix();
    return 1;
  }

  if(strcmp(type, "pop") == 0) {
    glPopMatrix();
    return 1;
  }

  return 1;
}



int   drawTexture(texture *tex, int _x, int _y, int _a, float _w, float _h) {
  // Need to optimize the hell out of this


	GLfloat x = _x;
	GLfloat y = _y;
  GLfloat a = _a;
  GLfloat xScale = _w;
  GLfloat yScale = _h;

  if(tex == NULL) {
    //printf("GRAPHICS.C> Trying to print a NULL texture (%d)\n", id);
    //id = 0;
    return 0;
  }

  GLfloat u = tex->u;
  GLfloat v = tex->v;
  GLfloat us = tex->us;
  GLfloat vs = tex->vs;

  GLfloat w = (tex->width * tex->us)  * (xScale * 0.5f);
  GLfloat h = (tex->height * tex->vs) * (yScale * 0.5f);

  /*
  // REGULAR 2 x TRI
  setFastVert(&drawVert[0], -w, -h,  5, u,  v);
  setFastVert(&drawVert[1], w,  h,  5, u + us, v + vs);
  setFastVert(&drawVert[2], w,  -h,  5, u + us, v);
  setFastVert(&drawVert[3], -w, -h,  5, u,   v);
  setFastVert(&drawVert[4], w,  h,  5, u + us, v + vs);
  setFastVert(&drawVert[5], -w, h,  5, u,   v + vs);
  */

  // TRIANGLE_FAN
  setFastVert(&drawVert[0], 0,  0,    0, u + us*0.5 , v + vs*0.5);
  setFastVert(&drawVert[1], -w, h,    0, u          , v + vs);
  setFastVert(&drawVert[2], 0,  h,    0, u + us*0.5 , v + vs);
  setFastVert(&drawVert[3], w,  h,    0, u + us     , v + vs);
  setFastVert(&drawVert[4], w,  0,    0, u + us     , v + vs*0.5);
  setFastVert(&drawVert[5], w,  -h,   0, u + us     , v);
  setFastVert(&drawVert[6], 0,  -h,   0, u + us*0.5 , v);
  setFastVert(&drawVert[7], -w, -h,   0, u          , v);
  setFastVert(&drawVert[8], -w, 0,    0, u           , v + vs*0.5);
  setFastVert(&drawVert[9], -w, h,    0, u          , v + vs);


  glPushMatrix();
  glTranslatef(x, -y, -zdepth);
  glRotatef(a, 0, 0, -1);
  zdepth += z_inc;

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex->id);

  if(blendFlag == 1) {
    glDisable(GL_ALPHA_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  } else {
    glDisable(GL_BLEND);
    glEnable(GL_ALPHA_TEST);
    glAlphaFunc(GL_GREATER, 0.1f);
  }

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);

  glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &drawVert->vert);
  glTexCoordPointer		(2, GL_FLOAT, sizeof(glvert), &drawVert->texture);
  glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &drawVert->color.packed);

  glDrawArrays(GL_TRIANGLE_FAN, 0, 10); // Regular 2 x tri
  //glDrawArrays(GL_TRIANGLES, 0, 5); // Regular 2 x tri

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);

  glDisable(GL_ALPHA_TEST);
  glDisable(GL_BLEND);
  glDisable(GL_TEXTURE_2D);

  glPopMatrix();

	return 1;
}

// FONT STUF ///////////////////////////////
void setFastVert(glvert *vertex, float x, float y, float z, float u, float v) {
  vertex->vert.x = x; vertex->vert.y = y; vertex->vert.z = z;
  vertex->texture.u = u; vertex->texture.v = v;
  //BGRA
  //memcpy4(vertex->color.array, drawColori, sizeof(drawColori));
  vertex->color.array[0] = drawColori[0];
  vertex->color.array[1] = drawColori[1];
  vertex->color.array[2] = drawColori[2];
  vertex->color.array[3] = drawColori[3];
  //vertex->color.packed = PACK_BGRA8888(drawColori[0], drawColori[1], drawColori[2], drawColori[3]);
}

void startBatching(texture *tex) {

}

void closeBatching(texture *tex, int vertNum) {

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, tex->id);

  glDisable(GL_ALPHA_TEST);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);

  glVertexPointer			(3, GL_FLOAT, sizeof(glvert), &textVert->vert);
  glTexCoordPointer		(2, GL_FLOAT, sizeof(glvert), &textVert->texture);
  glColorPointer		  (GL_BGRA, GL_UNSIGNED_BYTE, sizeof(glvert), &textVert->color.array);

  glPushMatrix();
  //glLoadIdentity();
  glTranslatef(0, 0, -zdepth);
  zdepth += z_inc;

  glDrawArrays(GL_TRIANGLES, 0, textBatchSize);
  glPopMatrix();


	glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisableClientState(GL_COLOR_ARRAY);

	glDisable(GL_TEXTURE_2D);
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);

  // EMPTY verts
  textBatchSize = 0;
}

void addCharToBatch(int c, int i, float x, float y) {
    //if(c == 0) return;
    char letter = c;
    c -= 32; // <----- Ascii Offset in font texture

    int c1 = (int) (c % 16);
    int c2 = (int) (c / 16) + 1;
    float u  =      (float) c1 * uvSpacing[0];
    float v  = 1 -  (float) c2 * uvSpacing[1];
    //printf("%c = %u | %u | u = %0.4f | v =  %0.4f \n", letter, c1, c2, u, v);

    int vertNum = i * 6;
    setFastVert(&textVert[vertNum + 0], x,      -y,      0, u,  v);
    setFastVert(&textVert[vertNum + 1], x + fontSize,  -y + fontSize,  0, u + glyphSize[0], v + glyphSize[1]);
    setFastVert(&textVert[vertNum + 2], x + fontSize,  -y,      0, u + glyphSize[0], v);
    setFastVert(&textVert[vertNum + 3], x,      -y,      0, u,   v);
    setFastVert(&textVert[vertNum + 4], x + fontSize,  -y + fontSize,  0, u + glyphSize[0], v + glyphSize[1]);
    setFastVert(&textVert[vertNum + 5], x,      -y + fontSize,  0, u,   v + glyphSize[1]);
    textBatchSize += 6;

}

void batchString(const char* s, float x, float y) {
  if(batchActive) {
    int charNum = strlen(s);
    int line = 0;
    int pos = 0;
    for(int i = 0; i <= charNum; i++) {
      addCharToBatch(*s, i, x + (pos * xSpacing), y + (line * fontSize) + 6);
      if (*s == '\n') {
        line++;
        pos = 0;
      } else {
        pos++;
      }

      *s++;
      if (i == charNum) {
          closeBatching(font[0], i * 4);
          //printf("Closing batch with %d char.\n", i);
      }
    }
  }
  else {
    printf("Inactive batch or full or problem or something \n");
  }
}

int LUA_loadFont(lua_State *L){
  const char* filename  = lua_tostring(L, 1);
  float _fontSize       = lua_tonumber(L, 2);
  float _cellSize       = lua_tonumber(L, 3);

  char* path = findFile(filename);
  if(path == NULL) return(NULL);

  texture *t = malloc(sizeof(texture) * 1);
  initTexture(t);
  t->filename = malloc(strlen(path));
  strcpy(t->filename, path);

  char* type = strstr(t->filename, ".dtex");
  int r = 0;
  if(type != NULL)
    r = dtex_to_gl_texture(t, t->filename);
  else
    r = png_to_gl_texture(t, t->filename);

  float ratio = t->width / t->height;

  uvSpacing[0] = 1 /  (t->width / _cellSize);
  uvSpacing[1] = 1 /  (t->height / _cellSize);

  glyphSize[0] = 1 /  (t->width / _fontSize);
  glyphSize[1] = 1 /  (t->height / _fontSize);

  cellSize = _cellSize;
  fontSize = _fontSize;
  xSpacing = (int) _fontSize * 0.7;

  if(r == 1 && debugActive) {
    printf("GRAPHICS.C> %s W:%u H:%u \n", t->filename, t->width, t->height);
    printf("GRAPHICS.C> Font size : %0.4f | %0.4f | %0.4f | %0.4f\n", uvSpacing[0], uvSpacing[1], glyphSize[0], glyphSize[1]);
  }

  if(r == 1) {
    int index = 0;
    font[index] = t;

    lua_pushnumber(L, index);
    lua_pushnumber(L, t->width);
    lua_pushnumber(L, t->height);

    return 3;
  } else {
    lua_pushnumber(L, -1);
    return 1;
  }
}

int LUA_writeFont(lua_State *L) {
  const char* s = lua_tostring(L, 1);
  int x         = lua_tonumber(L, 2);
  int y         = lua_tonumber(L, 3);
  int type      = lua_tonumber(L, 4);
  //printf("trying to print %s\n", s);
  if(font[0] ==  NULL || type == 1) {
    int y = 440;
    bfont_draw_str(vram_s + ((y + 1) * 24 * 640) + (x * 12), 640, 0, s);
  } else {
    batchString(s, lua_tonumber(L, 2), lua_tonumber(L, 3) + fontSize);
  }
  return(1);
  lua_settop(L, 0);
}

// LINE STUFF ///////////////////////////////////
void drawLine(int x1, int y1, int x2, int y2) {
  vram_s[x1 + (y1 * 640)] = PACK_PIXEL(255,0,0);
}

/*
// VIDEO-DREAMROQ ////////////////////////////////////////
int LUA_startVideo(lua_State *L) {

  //roq_set_size(100, 100);

  const char* filename =  lua_tostring(L, 1);
  int roq_status = roq_play(filename,
            0, //loop
            roq_render_cb,
            roq_audio_cb,
            roq_quit_cb);


  printf("GRAPHICS.C> %s video playing status : %d\n", filename, roq_status);
  printf("GRAPHICS.C> AUDIO RESTART!\n");

  // THIS IS FREAKING BOOTLEG!!
  snd_init();
  snd_stream_init();
  mp3_init();

  lua_pushnumber(L, 1);
  return(1);
}
*/
