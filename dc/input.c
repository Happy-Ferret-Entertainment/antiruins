#include <kos.h>
#include "input.h"
#include "antiruins.h"

char* playerName = "";
int   delayToExit = 30;
input *controller[4];

uint16_t  mask[9]   = {4, 2, 1024, 512, 16, 32, 64, 128, 8};
char*     bName[9]  = {"A", "B", "X", "Y", "UP", "DOWN", "LEFT", "RIGHT", "START"};

int     initInput() {
  for(int i = 0; i < 4; i++) {
    controller[i] = NULL;
  }
  //lua_pushcfunction(luaData, LUA_getController);
  //lua_setglobal(luaData, "C_getController");
  return(1);
}

input   *newController(int controllerNum) {
  if(controllerNum > 4 || controllerNum < 0) {
    printf("input.c> Controller %d out of range!! \n", controllerNum);
    return(NULL);
  }
  input *temp = malloc(sizeof(input));

  temp->contNum    = controllerNum;
  temp->cont       = maple_enum_type(controllerNum, MAPLE_FUNC_CONTROLLER);
  temp->state      = (cont_state_t *)maple_dev_status(temp->cont);
  temp->pstate     = *temp->state;
  temp->pbuttons   = temp->buttons = 0;
  temp->update     = update;

  printf("input.c> Controller %d added. \n", controllerNum);
  controller[controllerNum] = temp;
  return temp;
}

void    update(input *self, int controllerNum) {
  char c = controllerNum;

  self->cont = maple_enum_type(self->contNum, MAPLE_FUNC_CONTROLLER);
  self->state = (cont_state_t *)maple_dev_status(self->cont);
  self->buttons = self->state->buttons;

  //get global table for DC controller Data
  lua_getglobal(luaData, "cont");
  //get correct index in the table (4 player)
  lua_rawgeti(luaData, -1, controllerNum + 1); // lua offset array

  //sets the data

  lua_pushnumber(luaData, self->state->joyx);
  lua_setfield(luaData, -2, "joyx");
  lua_pushnumber(luaData, self->state->joyy);
  lua_setfield(luaData, -2, "joyy");
  lua_pushnumber(luaData, self->state->ltrig);
  lua_setfield(luaData, -2, "ltrig");
  lua_pushnumber(luaData, self->state->rtrig);
  lua_setfield(luaData, -2, "rtrig");

  // BUTTONS AFTER AXIS
  lua_getfield(luaData, -1, "buttonPressed");
  uint32 _button = self->state->buttons;
  //A,B,X,Y,UP,DOWN,LEFT,RIGHT,START
  uint16 _bState = 0;
  for(int i = 0; i < 9; i++) {
    lua_pushboolean(luaData, (_button & mask[i]));
    lua_setfield(luaData, -2, bName[i]);  
  }

  //fancy process in the lua space
  lua_getglobal(luaData, "_processController");
  lua_pushnumber(luaData, controllerNum + 1);
  int result = lua_pcall(luaData, 1, 1, 0);

  lua_settop(luaData, 0);
}

//char isSet(unsigned char b, unsigned char n) { return b & ( 1 << n); }

int     pushControllerData(int controllerNum) {
  int c = controllerNum;

  //get global table for DC controller Data
  lua_getglobal(luaData, "DCcont");
  //get correct index in the table (4 player)
  lua_rawgeti(luaData, -1, controllerNum + 1); // lua offset array

  //sets the data
  lua_pushnumber(luaData, controller[c]->state->buttons);
  lua_setfield(luaData, -2, "buttons");
  lua_pushnumber(luaData, controller[c]->state->joyx);
  lua_setfield(luaData, -2, "joyx");
  lua_pushnumber(luaData, controller[c]->state->joyy);
  lua_setfield(luaData, -2, "joyy");
  lua_pushnumber(luaData, controller[c]->state->ltrig);
  lua_setfield(luaData, -2, "ltrig");
  lua_pushnumber(luaData, controller[c]->state->rtrig);
  lua_setfield(luaData, -2, "rtrig");

  //fancy process in the lua space
  lua_getglobal(luaData, "_processController");
  lua_pushnumber(luaData, controllerNum + 1);
  int result = lua_pcall(luaData, 1, 1, 0);

  lua_settop(luaData, 0);
  return(1);
}

// update all the controllers?
void    updateControllers() {
  for(int i = 0; i < 4; i++) {
    if(controller[i] != NULL) {
      update(controller[i], i);
    }
  }
}
/*
int     LUA_getController(lua_State *L) {
  input *p;
  int   controllerNum = lua_tonumber(L, 1) - 1; // -1 is lua offset

  if(controllerNum < 0 || controllerNum > 4) {
    printf("input.c> Controller out of range (%d)\n", controllerNum);
    return(1);
  } else {
    p = controller[controllerNum];
  }

  lua_pushnumber(L, p->state->buttons);
  lua_pushnumber(L, p->state->joyx);
  lua_pushnumber(L, p->state->joyy);
  lua_pushnumber(L, p->state->ltrig);
  lua_pushnumber(L, p->state->rtrig);
  return(5);
}
*/

/*
void    LUA_updateInput(input *self) {
  if(GW_status == GW_READY) {
    lua_getglobal(luaData, "_updateDreamcastController");
    lua_pushnumber(luaData, self->state->buttons);
    lua_pushnumber(luaData, self->state->joyx);
    lua_pushnumber(luaData, self->state->joyy);
    lua_pushnumber(luaData, self->state->ltrig);
    lua_pushnumber(luaData, self->state->rtrig);
    lua_pcall(luaData, 5, 1, 0);
  }
  //const char* r = lua_tostring(luaData, 1);
  //printf(r);

  lua_settop(luaData, 0);
  return(1);
}
*/
