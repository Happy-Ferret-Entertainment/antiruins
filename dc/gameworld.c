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

int LUA_initGameworld(){
  lua_getglobal(luaData, "game");
  lua_getfield(luaData, -1, "init");
  int status = lua_pcall(luaData, 0, 0, 0);
  printf("Gameworld> Init : %d\n", status);

  if(status)
    GW_status = GW_EMPTY;
  else
    GW_status = GW_ERROR;

  lua_settop(luaData, 0);
  return 1;
}

int LUA_loadGameworld(char* file){
  lua_getglobal(luaData, "loadGameworld");
  lua_pushstring(luaData, file);
  int status = lua_pcall(luaData, 1, 1, 0);

  if(status == 0)
    printf("Gameworld.c> Loading %s file as gameworld\n", file);
  else
    printf("Gameworld.c> ERROR Loading %s file as gameworld <---------------\n", file);

  lua_settop(luaData, 0);
  return(status);
}

int LUA_createGameworld(){
  lua_getglobal(luaData, "game");
  lua_getfield(luaData, -1, "create");
  int result = lua_pcall(luaData, 0, 0, 0);
  if (result != 0) reportError(result);
  /*
  lua_pcall(luaData, 0, 1, 0);
  int result = lua_tonumber(luaData, -1);

  if(result)
    GW_status = GW_READY;
  else
    GW_status = GW_ERROR;

  if (result != 0){
    switch (result) {
      case LUA_ERRRUN:
        printf("!!! createGameworld Error\n ----> %s\n", lua_tostring(luaData, -1));
        break;
      case LUA_ERRMEM:

        break;
      case LUA_ERRERR:

        break;
    }
  }
    printf("Gameworld> Create gameworld : %d\n", result);
  */
  printf("Gameworld> Create gameworld : %d\n", result);
  lua_settop(luaData, 0);
  return 1;
}

int LUA_freeGameworld(){
  lua_getglobal(luaData, "game");
  lua_getfield(luaData, -1, "free");
  int result = lua_pcall(luaData, 0, 1, 0);
  if (result != 0) reportError(result);
  lua_settop(luaData, 0);
  return 1;
}

int LUA_updateGameworld(uint64_t deltaTime) {
  lua_getglobal(luaData, "game");
  lua_getfield(luaData, -1, "update");
  float dt = deltaTime/1000.0f;
  lua_pushnumber(luaData, dt);
  int result = lua_pcall(luaData, 1, 0, 0);
  if (result != 0) reportError(result);
  /*
  if (result != 0){
    switch (result) {
      case LUA_ERRRUN:
        printf("!!! updateGameworld Error\n ----> %s\n", lua_tostring(luaData, -1));
        break;
      case LUA_ERRMEM:

        break;
      case LUA_ERRERR:

        break;
    }
  }
  */
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
