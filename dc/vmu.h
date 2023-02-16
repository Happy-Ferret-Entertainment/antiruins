#ifndef __VMU_H__
#define __VMU_H__

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

//#define PURUPURU_EFFECT2_UINTENSITY(x) (x << 4)
//#define PURUPURU_EFFECT2_LINTENSITY(x) (x)

int initVMU(maple_device_t *cont);

// VMU Icons
int LUA_loadVMUIcon(lua_State *L);
int LUA_freeVMUIcon(lua_State *L);
int LUA_drawVMUIcon(lua_State *L);
int LUA_clearVMUIcon(lua_State *L);

// VMU Beeps
int LUA_setVMUTone(lua_State *L);

// Rumble
int LUA_setRumble(lua_State * L);

int vmu_program_beep();

#endif
