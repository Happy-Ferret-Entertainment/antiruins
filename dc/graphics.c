#include <kos.h>
#include <math.h>
#include <dc/pvr.h>
#include <png/png.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include "extra/sh4_math.h"

#include "lua.h"

#include "graphics.h"
#include "antiruins.h"

/*
currently uses GLdc
-> best way to draw in GLdc is Triangle Strip

PVR
-> could beinsteresting to do straight PVR because we do not need zclipping.
*/

pvr_poly_hdr_t hdr;

#define MAX_TEXTURE     256
#define MAX_SPRITES     2048

typedef struct _sprite {
  int   texID;
  float x, y;
  float w, h;
  float a;
  float u0, v0, u1, v1;
} sprite;

sprite    sprites[MAX_SPRITES];
texture*  tex[MAX_TEXTURE];
int       texCount = 0;
int       spriteCount = 0;


int totalPvrMem = 0; //total pvr memory in kb       

void  initPVR() { // We call this right after our OpenGL window is created.
  int result = pvr_init_defaults();
  totalPvrMem = pvr_mem_available()/1000;
  if (result != 0) {
    printf("Graphics-PVR> Error initializing PVR: %d", result);
  }

  for(int i = 0; i < MAX_SPRITES; i++) {
    sprites[i].texID = -1;
    sprites[i].u0 = 0;
    sprites[i].v0 = 0;
    sprites[i].u1 = 1;
    sprites[i].v1 = 1;
  }

  //setPVRbinds(luaData);

  //loadPNG("pc/default/grid_256.png");
  //int tex = loadDTEX("pc/default/logo.dtex");


  pvr_set_bg_color(1.0f, 0.0f, 0.0f);
  printf("Graphics-PVR> PVR initialized.\n");
  printf("Graphics-PVR> Memory for sprites: %d bytes\n", sizeof(sprites));
}

// TEXTURES ////////////////////////////////////////////////////////
int   getNextTextureID() {
  for(int i = 0; i < MAX_TEXTURE; i++) {
    if(tex[i] == NULL) {
      printf("Graphics-PVR> Found empty texture #%d.\n", i);
      return i;
    }
  }
}

int   freeTexture(int id) {
  if(id < 0 || id > MAX_TEXTURE) {
    printf("Graphics-PVR> Texture ID out of range: %d\n", id);
    return 0;
  } 
  //free the PVR memory
  prv_mem_free(tex[id]->data);
  //free the texture data
  free(tex[id]);
  // Set to null just incase
  tex[id] = NULL;
  return 1;
}

/* Loads a .dtex texture and returnds a texID.*/
/* Works well with ARGB1555*/
int   loadDTEX(char* filename) {
  int id            = getNextTextureID();
  int pvrMemBefore  = pvr_mem_available()/1000;

  tex[id]           = malloc(sizeof(texture));
  tex[id]->id       = id;
  tex[id]->filename = filename;

  FILE* file = NULL;
  // make sure the file is there.
  if ((file = fopen(filename, "rb")) == NULL) {
    printf("GRAPHICS.C> File not found : %s\n", filename);
      return 0;
  }

  struct {
    uint8_t  magic[4]; // 'DTEX'
	  uint16_t width;
	  uint16_t height;
	  uint32_t type;
	  uint32_t size;
  } header;

  fread(&header, sizeof(header), 1, file);

  tex[id]->width    = header.width;
  tex[id]->height   = header.height;
  uint dataSize      = header.size;

  int twiddled    = (header.type & (1 << 26)) < 1;
  int compressed  = (header.type & (1 << 30)) > 0;
  int mipmapped   = (header.type & (1 << 31)) > 0;
  int strided     = (header.type & (1 << 25)) > 0;

  tex[id]->format = (header.type >> 27) & 0b111;
  tex[id]->data   = pvr_mem_malloc(header.size);

  if (tex[id]->data) {
    printf("Graphics-PVR> Texture #%d: %s loaded into PVR memory.\n", id, filename);
  } else {
    printf("Graphics-PVR> Texture #%d: %s failed to load into PVR memory.\n", id, filename);
    id = 0;
  }
  // Multiple of 32 bites
  fread(tex[id]->data, header.size, 1, file);

  int pvrMem = pvr_mem_available()/1000;
  printf("Graphics-PVR> Loaded texture #%d: %s size:%d/%d kb\n", id, filename, pvrMemBefore - pvrMem, totalPvrMem);
  printf("Graphics-PVR> Width:%d Height:%d\n", tex[id]->width, tex[id]->height);

  cleanup:
  fclose(file);
  free(tex[id]->data);
  return(id);
};

/*
int pngToTexture(texture *tex, char *filename) {
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
	//glGenTextures(1, &tex->id);
	//glBindTexture(GL_TEXTURE_2D, tex->id);
	GLenum texture_format = (color_type & PNG_COLOR_MASK_ALPHA) ? GL_RGBA : GL_RGB;
	//GLenum texture_format = GL_RGB;
	//glTexImage2D(GL_TEXTURE_2D, 0, texture_format, w, h, 0, texture_format,   GL_UNSIGNED_BYTE, data);

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
*/
int   loadPNG(char* filename) {
  int id            = getNextTextureID();
  int pvrMemBefore  = pvr_mem_available()/1000;

  tex[id]           = malloc(sizeof(texture));
  tex[id]->id       = id;
  tex[id]->filename = filename;
  tex[id]->format   = PVR_TXRFMT_ARGB4444;

  png_load_texture(filename, tex[id]->data, PNG_FULL_ALPHA, &tex[id]->width, &tex[id]->height); 
  
  int pvrMem = pvr_mem_available()/1000;
  printf("Graphics-PVR> Loaded texture #%d: %s size:%d/%d kb\n", id, filename, pvrMemBefore - pvrMem, totalPvrMem);
  printf("Graphics-PVR> Width:%d Height:%d\n", tex[id]->width, tex[id]->height);
  //texCount++;
  return(id);
}

/*  Renders a full texture -- NO UV COORD
    Currently in the OP list (no transparency)
*/
void  renderTexture(int id, uint16_t x, uint16_t y, uint16_t w, uint16_t h) {
  int z = 1;
	pvr_poly_cxt_t cxt;
	pvr_poly_hdr_t hdr;
	pvr_vertex_t vert;

  if (w == 0) w = tex[id]->width;
  if (h == 0) h = tex[id]->height;

  //ctx, pvr list, texture format, tex width, tex height, texture data, filtering
	pvr_poly_cxt_txr(&cxt, PVR_LIST_TR_POLY, tex[id]->format, 
                  tex[id]->width, tex[id]->height, 
                  tex[id]->data, PVR_FILTER_NONE);
	pvr_poly_compile(&hdr, &cxt);
	pvr_prim(&hdr, sizeof(hdr));

  vert.argb   = PVR_PACK_COLOR(1.0f, 1.0f, 1.0f, 1.0f);
	vert.flags  = PVR_CMD_VERTEX;    //I think this is used to define the start of a new polygon

  //Center the texture
  x = x - w*0.5f;
  y = y - h*0.5f;

	//These define the verticies of the triangles "strips" (One triangle uses verticies of other triangle)
	vert.x = x;
	vert.y = y;
	vert.z = z;
	vert.u = 0.0;
	vert.v = 0.0;
	pvr_prim(&vert, sizeof(vert));

	vert.x = x + w;
	vert.y = y;
	vert.z = z;
	vert.u = 1;
	vert.v = 0.0;
	pvr_prim(&vert, sizeof(vert));

	vert.x = x;
	vert.y = y + h;
	vert.z = z;
	vert.u = 0.0;
	vert.v = 1;
	pvr_prim(&vert, sizeof(vert));

	vert.x = x + w;
	vert.y = y + h;
	vert.z = z;
	vert.u = 1;
	vert.v = 1;
	vert.flags = PVR_CMD_VERTEX_EOL;
	pvr_prim(&vert, sizeof(vert));
}

// SPRITES ///////////////////////////////////////////////////////
int   getNextSpriteID() {
  /*
  for(int i = 0; i < MAX_SPRITES; i++) {
    if(sprites[i].texID == -1) {
      printf("Graphics-PVR> Found empty sprite #%d.\n", i);
      return i;
    }
  }
  */
 return spriteCount++;
}

int   freeSprite(int id) {
  if(id < 0 || id > MAX_SPRITES) {
    printf("Graphics-PVR> Sprite ID out of range: %d\n", id);
    return 0;
  }
  // Reserts the sprite UV
  sprites[id].u0 = 0;
  sprites[id].v0 = 0;
  sprites[id].u1 = 1;
  sprites[id].v1 = 1;
  sprites[id].texID = -1;
  return 1;
}

/* Create a new sprite using a texture and return sprite ID*/
int   newSprite(int texID, float x, float y, float w, float h, float a) {
  int id = getNextSpriteID();
  sprites[id].texID = texID;

  if (w == 0) w = tex[texID]->width;
  if (h == 0) h = tex[texID]->height;
  sprites[id].w = w;
  sprites[id].h = h;

    // Centered sprites
  sprites[id].x = x - w*0.5f;
  sprites[id].y = y - h*0.5f;

  sprites[id].a = a;
  return id;
}

/* Set the sprite UV using the sprite ID*/
int   setSpriteUV(int id, float u0, float v0, float u1, float v1) {
  if(id < 0 || id > MAX_SPRITES) {
    printf("Graphics-PVR> Sprite ID out of range: %d\n", id);
    return 0;
  }
  sprites[id].u0 = u0;
  sprites[id].v0 = v0;
  sprites[id].u1 = u1;
  sprites[id].v1 = v1;
  return 1;
}

int   renderSprite(sprite* spr){
  int texID = spr->texID;
  if(texID < 0 || texID > MAX_TEXTURE) {
    printf("Graphics-PVR> Texture ID out of range: %d\n", texID);
    return 0;
  }
  int z = 1; // <--- will have to verify this with depth checking
  pvr_poly_cxt_t cxt;
  pvr_poly_hdr_t hdr;
  pvr_vertex_t vert;

  //ctx, pvr list, texture format, tex width, tex height, texture data, filtering
  pvr_poly_cxt_txr(&cxt, PVR_LIST_TR_POLY, tex[texID]->format, 
                  tex[texID]->width, tex[texID]->height, 
                  tex[texID]->data, PVR_FILTER_NONE);
  pvr_poly_compile(&hdr, &cxt);
  pvr_prim(&hdr, sizeof(hdr));

  vert.argb   = PVR_PACK_COLOR(1.0f, 1.0f, 1.0f, 1.0f);
  vert.flags  = PVR_CMD_VERTEX;    //I think this is used to define the start of a new polygon

  //These define the verticies of the triangles "strips" (One triangle uses verticies of other triangle)
  vert.x = spr->x;
  vert.y = spr->y;
  vert.z = z;
  vert.u = spr->u0;
  vert.v = spr->v0;
  pvr_prim(&vert, sizeof(vert));

  vert.x = spr->x + spr->w;
  vert.y = spr->y;
  vert.z = z;
  vert.u = spr->u1;
  vert.v = spr->v0;
  pvr_prim(&vert, sizeof(vert));

  vert.x = spr->x;
  vert.y = spr->y + spr->h;
  vert.z = z;
  vert.u = spr->u0;
  vert.v = spr->v1;
  pvr_prim(&vert, sizeof(vert));

  vert.x = spr->x + spr->w;
  vert.y = spr->y + spr->h;
  vert.z = z;
  vert.u = spr->u1;
  vert.v = spr->v1;
  vert.flags = PVR_CMD_VERTEX_EOL;
  pvr_prim(&vert, sizeof(vert));

}

/* Renders a rectangle from the center (might be a bad idea)*/
void  renderRect(float x, float y, float w, float h, float r, float g, float b, float a) {
  pvr_poly_hdr_t hdr;
  pvr_poly_cxt_t cxt;
  pvr_vertex_t vert;

  pvr_poly_cxt_col(&cxt, PVR_LIST_TR_POLY);
  pvr_poly_compile(&hdr, &cxt);
  pvr_prim(&hdr, sizeof(hdr));

  x = x - w*0.5f;
  y = y - h*0.5f;

  vert.flags = PVR_CMD_VERTEX;
  vert.x = x;
  vert.y = y;
  vert.z = 1;
  vert.u = vert.v = 0.0f;
  vert.argb = PVR_PACK_COLOR(a, r, g, b);
  vert.oargb = 0;
  pvr_prim(&vert, sizeof(vert));

  vert.x = x + w;
  vert.y = y;
  vert.u = 1.0f;
  vert.v = 0.0f;
  pvr_prim(&vert, sizeof(vert));

  vert.x = x;
  vert.y = y + h;
  vert.u = 0.0f;
  vert.v = 1.0f;
  pvr_prim(&vert, sizeof(vert));

  vert.flags = PVR_CMD_VERTEX_EOL;
  vert.x = x + w;
  vert.y = y + h;
  vert.u = vert.v = 1.0f;
  pvr_prim(&vert, sizeof(vert));
}

/* Render the actual frame */
void  renderFrame() {
  pvr_wait_ready();
  pvr_scene_begin();
  
  pvr_list_begin(PVR_LIST_OP_POLY);
  pvr_list_finish();
  
  
  pvr_list_begin(PVR_LIST_TR_POLY);
  for (int i = 0; i < spriteCount; i++) {
      renderSprite(&sprites[i]);
  }
  pvr_list_finish();
  
  pvr_scene_finish();
  spriteCount = 0;
}

// TEXT ON SCREEN ///////////////////////////////////
/*
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
*/
// LUA BINDINGS ///////////////////////////////////////
int LUA_renderTexture(lua_State *L) {
  int id   = (int)lua_tonumber(L, 1);
  float x  = lua_tonumber(L, 2);
  float y  = lua_tonumber(L, 3);
  float w  = lua_tonumber(L, 4);
  float h  = lua_tonumber(L, 5);
  renderTexture(id, x, y, w, h);
  lua_settop(L, 0);
  return 0;
}

int setPVRbinds(lua_State *L) {
  lua_register(L, "renderTexture", LUA_renderTexture);
  return 0;
}