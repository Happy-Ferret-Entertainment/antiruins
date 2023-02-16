#ifndef __SAVELOAD_H__
#define __SAVELOAD_H__

#include "lua/lua.h"

// Inits a savefile
int initSaveload();

// Checks if a savefile already exists on vmu
int checkForSavefile(int saveNum);
int createNewSavefile(int saveNum);
int updateSavefile(int saveNum);

// Lua binds
int LUA_createSavefile(lua_State *L);
// Save
int LUA_saveSavefile(lua_State *L);
int LUA_setSaveValue(lua_State *L);
// Load
int LUA_loadSavefile(lua_State *L);
int LUA_getSaveValue(lua_State *L);

#endif
