#ifndef __INPUT_H__
#define __INPUT_H__

#include <kos.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

typedef struct _input {
  maple_device_t  *cont;      //controller adress
  cont_state_t    *state;     //current state
  cont_state_t    pstate;     //previous state
  uint32_t        pbuttons;
  uint32_t        buttons;
  int             contNum;

  void (*update)(struct _input *self);
} input;

int   initInput();
input *newController(int controllerNum);
void  update(input *self, int controllerNum);
void  updateControllers();

int   LUA_getController(lua_State *L);
void  LUA_updateInput();

#endif
