#ifndef __ANTIRUINS_H__
#define __ANTIRUINS_H__

#include <stdint.h>

#include "lua/lua.h"
#include "lua/lauxlib.h"
#include "lua/lualib.h"

#define GW_ERROR    0 //Something went wrong
#define GW_READY    1 //Gameworld loaded
#define GW_EMPTY    2 //No gameworld loaded
#define GW_RELOAD   3 //Empty then reload
#define GW_FREE     4 //Free the current gameworld

#define MP3         1
#define OGG         2
#define WAV         3

extern int        debugActive;
extern int        gameActive;
extern int        GW_status;
extern lua_State  *luaData;

extern uint64_t   game_time;
extern uint32_t   delta_time;

#include "graphics.h"
#include "audio.h"
#include "input.h"
#include "utils.h"
#include "gameworld.h"
#include "saveload.h"
#include "vmu.h"
#include "profiler.h"

#endif
