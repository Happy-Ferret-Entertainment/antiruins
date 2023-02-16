#ifndef __AUDIO_H__
#define __AUDIO_H__

#include <kos.h>
#include "lua.h"

typedef struct _sfx {
  char      *path;
  int       loaded;
  sfxhnd_t  s;
} sfx;

void  initSound(int format);

int   addSFX(char *path);
int   playSFX(int sfxID, int volume, int pan);
int   freeSFX(int sfxID);

int   startBGM(char* path, int volume, int loop);
int   stopBGM();

int   getChannelNumber();
char* getSoundInfo();

int LUA_playSFX(lua_State *L_state);
int LUA_loadSFX(lua_State *L_state);
int LUA_freeSFX(lua_State *L_state);
int LUA_streamFile(lua_State *L_state);
int LUA_stopStream(lua_State *L_state);
int LUA_isPlaying(lua_State *L_state);
int LUA_setChannelVolume(lua_State *L_state);

#endif
