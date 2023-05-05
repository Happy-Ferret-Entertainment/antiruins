#include <kos.h>
#include <math.h>
#include <dc/pvr.h>
#include <png/png.h>
#include <dirent.h>


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

#define PVR_SPRITE_SZ   64
#define MAX_TEXTURE     256
#define MAX_SPRITES     2048
#define PVR_VERTEX_BUF_SIZE (MAX_SPRITES * PVR_SPRITE_SZ)

font      fonts[4];
sprite    sprites[MAX_SPRITES];
texture*  tex[MAX_TEXTURE];
int       texCount = 0;
int       spriteCount = 0;

uint32    bgColor   = 0;
uint32    drawColor = 0;

int totalPvrMem = 0; //total pvr memory in kb       


void  initPVR() { // We call this right after our OpenGL window is created.
  pvr_init_params_t pvr_params = {
    /* Enable opaque and translucent polygons with size 32 and 32 */
    {PVR_BINSIZE_32, PVR_BINSIZE_0, PVR_BINSIZE_32, PVR_BINSIZE_0, PVR_BINSIZE_32},
    PVR_VERTEX_BUF_SIZE, /* Vertex buffer size */
    0, /* No DMA */
    0, /* No FSAA */
    0 /* Disable translucent auto-sorting to match traditional GL */
  };

  int result = pvr_init(&pvr_params);
  totalPvrMem = pvr_mem_available()/1000;

  for(int i = 0; i < MAX_SPRITES; i++) {
    sprites[i].texID = -1;
    sprites[i].u0 = 0.0;
    sprites[i].v0 = 0.0;
    sprites[i].u1 = 1.0;
    sprites[i].v1 = 1.0;
  }

  setPVRbinds(luaData);
  bgColor   = PVR_PACK_COLOR(1.0,0.0,0.0,0.0);
  drawColor = PVR_PACK_COLOR(1.0,1.0,1.0,1.0);

  bfont_set_foreground_color(PVR_PACK_COLOR(1.0,1.0,1.0,1.0));
  pvr_set_bg_color(0,0,0);
  printf("Graphics-PVR> PVR initialized.\n");
  printf("Graphics-PVR> Memory for sprites: %d ea | total%d bytes\n", sizeof(sprite), sizeof(sprites));
}

void  loadFont() {
  // Load the font
  int id            = loadDTEX(findFile("default/spacemono.dtex"));
  int cellSize      = 16;
  fonts[0].texID    = id;
  fonts[0].cellSize = cellSize;
  fonts[0].width    = tex[id]->width;
  fonts[0].height   = tex[id]->height;
  fonts[0].xSpacing = cellSize * 0.7;
  fonts[0].ySpacing = cellSize;
  fonts[0].uS       = 1 / (fonts[0].width   / cellSize);
  fonts[0].vS       = 1 / (fonts[0].height  / cellSize);

  //printf("Font Specs: w %d h %d \n", fonts[0].width, fonts[0].height);
  //printf("Font Specs: uS %.3f vS %.3f   \n", fonts[0].uS, fonts[0].vS);

  return(1);
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

/* Free a texture using a TexID */
int   freeTexture(int id) {
  if(id < 0 || id > MAX_TEXTURE) {
    printf("Graphics-PVR> Texture ID out of range: %d\n", id);
    return 0;
  } 
  //free the PVR memory
  printf("Graphics-PVR> Attempt to free texture #%d from PVR memory.\n", id);
  pvr_mem_free(tex[id]->data);
  if (tex[id]->data == NULL) {
    printf("Graphics-PVR> Texture #%d freed from PVR memory.\n", id);
  }
  //free the texture data
  free(&tex[id]);
  // Set to null just incase
  //tex[id] = NULL;
  return 1;
}

/* Loads a .dtex texture and returns a texID.*/
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
      return -1;
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

  /*
  int twiddled    = (header.type & (1 << 26)) < 1;
  int compressed  = (header.type & (1 << 30)) > 0;
  int mipmapped   = (header.type & (1 << 31)) > 0;
  int strided     = (header.type & (1 << 25)) > 0;
  */

  tex[id]->format = (header.type >> 27) & 0b111;
  tex[id]->data   = pvr_mem_malloc(header.size);

  if (tex[id]->data) {
    printf("Graphics-PVR> Texture #%d: %s loaded into PVR memory.\n", id, filename);
  } else {
    printf("Graphics-PVR> Texture #%d: %s failed to load into PVR memory.\n", id, filename);
    id = -1;
    goto cleanup;
  }
  // Multiple of 32 bites
  fread(tex[id]->data, header.size, 1, file);

  int pvrMem = pvr_mem_available()/1000;
  printf("Graphics-PVR> Loaded texture #%d: %s size:%d/%d kb\n", id, filename, pvrMemBefore - pvrMem, totalPvrMem);
  printf("Graphics-PVR> Width:%d Height:%d\n", tex[id]->width, tex[id]->height);

  cleanup:
  fclose(file);
  //pvr_mem_free(tex[id]->data);
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
  int id = spriteCount++;
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

int   renderSprite3(int texID, int x, int y, float w, float h, float u0, float v0,float u1,float v1) {
  
  pvr_sprite_cxt_t sprite_context; 
	pvr_sprite_hdr_t sprite_header; 
	pvr_sprite_cxt_txr(&sprite_context, PVR_LIST_PT_POLY, tex[texID]->format, 
                  tex[texID]->width, tex[texID]->height, 
                  tex[texID]->data, PVR_FILTER_NONE);
	pvr_sprite_compile(&sprite_header, &sprite_context);

	pvr_prim(&sprite_header, sizeof(sprite_header)); 
  
  float z = 1;
  
	pvr_sprite_txr_t vert = {
		.flags = PVR_CMD_VERTEX_EOL,
		.ax = x,   .ay = y, .az = z,
 		.bx = x+w, .by = y, .bz = z,
 		.cx = x+w, .cy = y+h, .cz = z,
 		.dx = x,   .dy = y+h,
		.auv = PVR_PACK_16BIT_UV(u0, v0),
		.buv = PVR_PACK_16BIT_UV(u1, v0),
		.cuv = PVR_PACK_16BIT_UV(u1, v1),
	};
	pvr_prim(&vert, sizeof(vert));
  
}

int   renderSprite2(int texID, int x, int y, float w, float h, float u0, float v0,float u1,float v1) {
  if(texID < 0 || texID > MAX_TEXTURE) {
    printf("Graphics-PVR> Texture ID out of range: %d\n", texID);
    return 0;
  }
  float z = 1; // <--- will have to verify this with depth checking
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
  vert.x = x;
  vert.y = y;
  vert.z = z;
  vert.u = u0;
  vert.v = v0;
  pvr_prim(&vert, sizeof(vert));

  vert.x = x + w;
  vert.y = y;
  vert.u = u1;
  pvr_prim(&vert, sizeof(vert));

  vert.x = x;
  vert.y = y + h;
  vert.u = u0;
  vert.v = v1;
  pvr_prim(&vert, sizeof(vert));

  vert.x = x + w;
  vert.y = y + h;
  vert.u = u1;
  vert.flags = PVR_CMD_VERTEX_EOL;
  pvr_prim(&vert, sizeof(vert));
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

// TEXT ///////////////////////////////////////////////////////////

void  addCharToBatch(int c, float x, float y) {
  c -= 32; // <----- Ascii Offset in font texture

  int cell  = fonts[0].cellSize;
  int grid  = fonts[0].gridSize; // Magic number, should think about this.
  int c1    = (int) c % grid;
  int c2    = floor(c / grid);

  float u0  = c1 * fonts[0].uS;
  float v0  = c2 * fonts[0].vS;
  float u1  = u0 + fonts[0].uS;
  float v1  = v0 + fonts[0].vS;
  
  pvr_sprite_txr_t vert = {
    .flags = PVR_CMD_VERTEX_EOL,
    .ax = x,      .ay = y,      .az = 1,
    .bx = x+cell, .by = y,      .bz = 1,
    .cx = x+cell, .cy = y+cell, .cz = 1,
    .dx = x,      .dy = y+cell,
    .auv = PVR_PACK_16BIT_UV(u0, v0),
    .buv = PVR_PACK_16BIT_UV(u1, v0),
    .cuv = PVR_PACK_16BIT_UV(u1, v1),
  };
  pvr_prim(&vert, sizeof(vert));
  
}

void  batchString(const char* str, int x, int y) {
  float xSpacing = fonts[0].xSpacing;
  int   fontSize = fonts[0].ySpacing;

  texture t = *tex[fonts[0].texID];
  
  pvr_sprite_cxt_t sprite_context; 
	pvr_sprite_hdr_t sprite_header; 
	pvr_sprite_cxt_txr(&sprite_context, PVR_LIST_PT_POLY, t.format, 
                      t.width, t.height, 
                      t.data, PVR_FILTER_NONE);
	pvr_sprite_compile(&sprite_header, &sprite_context);

  sprite_header.argb = drawColor;

  pvr_prim(&sprite_header, sizeof(sprite_header)); 
  
  float z = 1;

  char  *s = str;
  int   charNum = strlen(str);
  int   line = 0;
  int   pos = 0;

  
  for(int i = 0; i <= charNum; i++) {    
    if (*s == '\0') break;

    addCharToBatch(*s, x + (pos * xSpacing), y + (line * fontSize) + 6);
    
    if (*s == '\n') {
      line++;
      pos = 0;
    } else {
      pos++;
    }
    *s++;
  }
}

void  biosprint(char* s, int x, int y) {
  bfont_draw_str(vram_s + ((y + 1) * 24 * 640) + (x * 12), 640, 1, s);
}

// RENDERER ///////////////////////////////////////////////////////
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

// FRAME //////////////////////////////////////////////////////////
void  startFrame() {
  pvr_wait_ready();
  pvr_scene_begin();

  pvr_list_begin(PVR_LIST_OP_POLY);
  pvr_list_finish();

  pvr_list_begin(PVR_LIST_TR_POLY);
  pvr_list_finish();

  pvr_list_begin(PVR_LIST_PT_POLY);
}
/* Render the actual frame */
void  renderFrame() {  
  
  
  sprite* spr = &sprites[0];
  for (int i = 0; i < spriteCount; i++) {
    //renderSprite(&sprites[i]);
    renderSprite3(spr->texID, spr->x, spr->y, spr->w, spr->h, spr->u0, spr->v0, spr->u1, spr->v1);
    spr++;
  }
  pvr_list_finish();
  pvr_scene_finish();
  spriteCount = 0;
}

// LUA BINDINGS ///////////////////////////////////////
int LUA_setClearColor(lua_State *L) {
  float r = lua_tonumber(L, 1);
  float g = lua_tonumber(L, 2);
  float b = lua_tonumber(L, 3);
  float a = lua_tonumber(L, 4);
  bgColor = PVR_PACK_COLOR(a,r,g,b);
  pvr_set_bg_color(r,g,b);
  lua_settop(L, 0);
  return 0;
}

int LUA_setColor2(lua_State *L) {
  float r = lua_tonumber(L, 1);
  float g = lua_tonumber(L, 2);
  float b = lua_tonumber(L, 3);
  float a = lua_tonumber(L, 4);
  bgColor = PVR_PACK_COLOR(a,r,g,b);
  pvr_set_bg_color(r,g,b);
  lua_settop(L, 0);
  return 0;
}

int LUA_setColor(lua_State *L) {

  
  float r = lua_tonumber(L, 1);
  float g = lua_tonumber(L, 2);
  float b = lua_tonumber(L, 3);
  float a = lua_tonumber(L, 4);
  drawColor = PVR_PACK_COLOR(a,r,g,b);
  lua_settop(L, 0);
  
  return 0;
}

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

int LUA_loadTexture(lua_State *L) {
  const char* filename  = lua_tostring(L, 1);
  int texID = loadDTEX(filename);
  if (texID == -1) {
    printf("Failed to load texture");
    return 0;
  }
  lua_pushnumber(L, texID);
  lua_pushnumber(L, tex[texID]->width);
  lua_pushnumber(L, tex[texID]->height);
  return (3);
}

int LUA_freeTexture(lua_State *L) {
  int texID = (int)lua_tonumber(L, 1);
  int type  = (int)lua_tonumber(L, 2);
  freeTexture(texID);
  lua_settop(L, 0);
  return 0;
}

int LUA_addSprite(lua_State *L) {
  int texID = (int)lua_tonumber(L, 1);
  float x  = lua_tonumber(L, 2);
  float y  = lua_tonumber(L, 3);
  float a  = lua_tonumber(L, 4);
  float w  = lua_tonumber(L, 5);
  float h  = lua_tonumber(L, 6);
  newSprite(texID, x, y, a, w, h);
  lua_settop(L, 0);
  return 0;
}

int LUA_loadFont(lua_State *L){
  const char* filename  = lua_tostring(L, 1);
  float gridSize        = lua_tonumber(L, 2);

  char* path = findFile(filename);
  if(path == NULL) return(NULL);

  int id = loadDTEX(path);

  fonts[0].texID    = id;
  fonts[0].gridSize = gridSize;                  // SIZE OF GRID
  fonts[0].cellSize = (int)((float)tex[id]->width / gridSize); // SIZE OF GRID
  fonts[0].width    = tex[id]->width;
  fonts[0].height   = tex[id]->height;
  fonts[0].xSpacing = fonts[0].cellSize/2;
  fonts[0].ySpacing = fonts[0].cellSize;

  fonts[0].uS       = 1.0/gridSize;
  fonts[0].vS       = 1.0/gridSize;

  //printf("GRAPHICS.C> W:%d H:%d CELL:%.3f\n", fonts[0].width, fonts[0].height, fonts[0].cellSize);
  //printf("GRAPHICS.C> Font size : %0.3f | %0.3f\n", fonts[0].uS, fonts[0].vS);

  if(id != -1) {
    lua_pushnumber(L, id);
    lua_pushnumber(L, fonts[0].xSpacing);
    lua_pushnumber(L, fonts[0].ySpacing);

    return 3;
  } else {
    lua_pushnumber(L, -1);
    return 1;
  }
}

int LUA_printString(lua_State *L) {
  const char* s = lua_tostring(L, 1);
  batchString(s, (int)lua_tonumber(L, 2), (int)lua_tonumber(L, 3));
  lua_settop(L, 0);
  return(1);
}

int setPVRbinds(lua_State *L) {
  
  lua_register(L, "C_setClearColor",  LUA_setClearColor);
  lua_register(L, "C_renderTexture",  LUA_renderTexture);
  
  lua_pushcfunction(L, LUA_setColor);
  lua_setglobal(L, "C_setColor");

  //lua_register(L," C_setColor",     LUA_setColor);
  lua_register(L, "C_loadTexture",  LUA_loadTexture);
  lua_register(L, "C_freeTexture",  LUA_freeTexture);
  lua_register(L, "C_addSprite",    LUA_addSprite);

  lua_register(L, "C_loadFont",     LUA_loadFont);
  lua_register(L, "C_printString",   LUA_printString);
  return 0;
}