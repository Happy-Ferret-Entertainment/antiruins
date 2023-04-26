#ifndef __GAMEWORLD_H__
#define __GAMEWORLD_H__

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

int LUA_createGameworld();
int LUA_freeGameworld();

int LUA_updateGameworld(uint64_t deltaTime);
int LUA_renderGameworld(uint64_t deltaTime);


#endif
