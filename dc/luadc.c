#include <stdio.h>
#include <stdlib.h>

#include "luadc.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "antiruins.h"
#include "utils.h"

int       LUA_clock(lua_State *L) {
  lua_pushnumber(L, getTime_MS());
  return 1;
}

int       LUA_clockUS(lua_State *L) {
  lua_pushnumber(L, getTime_US());
  return 1;
}

int       LUA_mountRomdisk(lua_State *L) {
    const char* filename = lua_tostring(L, 1);
    const char* mountpoint = lua_tostring(L, 2);

    char* f = findFile(filename);
    if(f == NULL) return(NULL);

    int result = mount_romdisk(filename, mountpoint);

    lua_pushnumber(L, result);
    return(1);
}

int       LUA_unmountRomdisk(lua_State *L) {
    unmount_romdisk();

    return(1);
}

void      initLua(lua_State **L_state) {
  *L_state = luaL_newstate();

  // Open LUA library
  luaL_openlibs(*L_state);
  luaL_requiref( *L_state, "_G", luaopen_base, 1 );
  luaL_requiref( *L_state, "_G", luaopen_math, 1 );
  luaL_requiref( *L_state, "_G", luaopen_string, 1 );
  luaL_requiref( *L_state, "_G", luaopen_table, 1 );
  luaL_requiref( *L_state, "_G", luaopen_os, 1 );
  luaL_requiref( *L_state, "_G", luaopen_io, 1 );

  lua_pushcfunction(*L_state, LUA_clock);
  lua_setglobal(*L_state, "C_clock");

  lua_pushcfunction(*L_state, LUA_clockUS);
  lua_setglobal(*L_state, "C_clockUS");

  lua_pushcfunction(*L_state, profiler_start);
  lua_setglobal(*L_state, "DCprof_start");
  lua_pushcfunction(*L_state, profiler_stop);
  lua_setglobal(*L_state, "DCprof_stop");
  lua_pushcfunction(*L_state, profiler_clean_up);
  lua_setglobal(*L_state, "DCprof_cleanup");

  lua_pushcfunction(*L_state, LUA_mountRomdisk);
  lua_setglobal(luaData, "C_mountRomdisk");

  lua_pushcfunction(*L_state, LUA_unmountRomdisk);
  lua_setglobal(luaData, "C_unmountRomdisk");

}

int       initAntiruins(lua_State **L_state) {
  lua_pushstring(*L_state, "DC");
  lua_setglobal(*L_state,  "platform");
  char *path = findFile("lua/antiruins.lua");
  int r = loadLuaFile(*L_state,    path);

  if(r == 1)
    printf("luadc.c> Loaded Antiruins.lua\n");
  else
    printf("luadc.c> FAIL Antiruins.lua !!!\n");

  lua_settop(*L_state, 0);

  lua_getglobal(*L_state, "initAntiruins");
  lua_pcall(*L_state, 0, 0, 0);
  int result = lua_tonumber(*L_state, 1);
  if (result != 0) reportError(result);
}

void reportError(int result) {
    switch (result) {
      case LUA_ERRRUN:
        printf("Lua Error ----> %s\n", lua_tostring(luaData, -1));
        break;
      case LUA_ERRMEM:
        printf("Lua Error (memory)----> %s\n", lua_tostring(luaData, -1));
        break;
      case LUA_ERRERR:
        printf("Lua Error (error) ----> %s\n", lua_tostring(luaData, -1));
        break;
    }
}

/*
int       reloadGameworld(lua_State **L_state, const char* gameWorld) {
  lua_getglobal(*L_state, "platformInit");
  lua_pushstring(*L_state, gameWorld);
  lua_pcall(*L_state, 1, 1, 0);
  int status = lua_tonumber(*L_state, 1);
  lua_settop(*L_state, 0);

  LUA_createGameworld();
  return(1);
}

int       reloadEngine(lua_State **L_state) {
  int result = 0;
  int r = loadLuaFile(*L_state,    findFile("/platform.lua"));
  lua_settop(*L_state, 0);

  lua_getglobal(*L_state, "platformInit");
  lua_pcall(*L_state, 0, 0, 0);
  lua_settop(*L_state, 0);

  LUA_createGameworld();
  r = GW_READY;
  return(r);
}
*/
int       loadLuaFile(lua_State *L_state, char *filename) {
  if(luaL_loadfile(L_state, filename) || lua_pcall(L_state, 0, 0, 0)) {
    printf(lua_tostring(L_state, -1));
    return(0);
  }
  return (1);
}

int       doLuaFile(lua_State *L_state, char *filename) {
  if(luaL_loadfile(L_state, filename) || lua_pcall(L_state, 0, 0, 0)) {
    return(0);
  }
  return (1);
}

int       garbageCollectStep(int stepSize) {
  uint32_t s = getTime_US();
  int mem1 = lua_gc(luaData, LUA_GCCOUNT, 0);
  int completedCycle = lua_gc(luaData, LUA_GCSTEP, stepSize);
  int mem2 = lua_gc(luaData, LUA_GCCOUNT, 0);
  printf("GC > %dkb collected in %d us.(completed:%d)\n", mem1-mem2, getTime_US() - s,completedCycle);
  //lua_gc(luaData, LUA_GCCOLLECT, 0);
  return lua_gc(luaData, LUA_GCCOUNT, 0);
}

void      dumpstack (lua_State *L) {
  int top=lua_gettop(L);
  for (int i=1; i <= top; i++) {
    printf("%d\t%s\t", i, luaL_typename(L,i));
    switch (lua_type(L, i)) {
      case LUA_TNUMBER:
        printf("%0.0f\n",lua_tonumber(L,i));
        break;
      case LUA_TSTRING:
        printf("%s\n",lua_tostring(L,i));
        break;
      case LUA_TBOOLEAN:
        printf("%s\n", (lua_toboolean(L, i) ? "true" : "false"));
        break;
      case LUA_TNIL:
        printf("%s\n", "nil");
        break;
      default:
        printf("%p\n",lua_topointer(L,i));
        break;
    }
  }
}
