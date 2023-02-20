 #ifndef __LUADC_H__
#define __LUADC_H__

#include <kos.h>
#include "lua.h"

void    initLua(lua_State **L_state);
int     initAntiruins(lua_State **L_state);

int     reloadGameworld(lua_State **L_state, const char* gameWorld);
int     reloadEngine(lua_State **L_state);

int     loadLuaFile(lua_State *L_state, char *filename);
void    setLuaState(lua_State *L_state);
int     garbageCollectStep(int stepSize);
void    dumpstack(lua_State *L);
void    reportError(int result);

#endif
