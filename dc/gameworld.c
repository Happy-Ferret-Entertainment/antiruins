#include <kos.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "gameworld.h"
#include "antiruins.h"

int LUA_updateGameworld(uint64_t deltaTime) {
  lua_getglobal(luaData, "game");
  lua_getfield(luaData, -1, "update");
  float dt = deltaTime/1000.0f;
  lua_pushnumber(luaData, dt);
  int result = lua_pcall(luaData, 1, 0, 0);
  if (result != 0) reportError(result);
  lua_settop(luaData, 0);
  return 1;
}

int LUA_renderGameworld(uint64_t deltaTime) {
  lua_getglobal(luaData, "game");
  lua_getfield(luaData, -1, "render");
  float dt = deltaTime/1000.0f;
  lua_pushnumber(luaData, dt);
  int result = lua_pcall(luaData, 1, 0, 0);
  if (result != 0) reportError(result);
  /*
  if (result != 0) {
    if (result != 0){
      switch (result) {
        case LUA_ERRRUN:
          printf("!!! renderGameworld Error\n ----> %s\n", lua_tostring(luaData, -1));
          break;
        case LUA_ERRMEM:

          break;
        case LUA_ERRERR:

          break;
      }
    }
  }
  */
  lua_settop(luaData, 0);
  return 1;
}
