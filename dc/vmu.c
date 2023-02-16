#include <kos.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "vmu.h"
#include "antiruins.h"

#include "crayonVMU/savefile.h"
#include "crayonVMU/setup.h"

uint8_t                   *vmu_icons[256] = { NULL };
crayon_savefile_details_t vmu_details;
uint8_t                   vmu_data; //we don't store anything here for real.'
maple_device_t            *vmu_cont;
maple_device_t            *jump_cont;
purupuru_effect_t         effect;

int initVMU(maple_device_t *cont) {
  unsigned int r = 1;
  crayon_savefile_init_savefile_details(&vmu_details, (uint8_t)&vmu_data, 1, 0, 0, "", "", "", "");
  printf("VMU> Init done: %u\n", r);

  char* logo  = findFile("asset/VMU/logo.bin");
  int   index = getEmptyIcon();
  setup_vmu_icon_load(  &vmu_icons[index], logo);
  crayon_vmu_display_icon(vmu_details.valid_vmu_screens,  vmu_icons[index]);


  jump_cont = maple_enum_type(0, MAPLE_FUNC_PURUPURU);
  if(jump_cont) {
    printf("------------->>>>>>> FOUND JUMP PACK!\n");
  }

  lua_pushcfunction(luaData, LUA_loadVMUIcon);
  lua_setglobal(luaData, "C_loadVMUIcon");

  lua_pushcfunction(luaData, LUA_freeVMUIcon);
  lua_setglobal(luaData, "C_freeVMUIcon");

  lua_pushcfunction(luaData, LUA_drawVMUIcon);
  lua_setglobal(luaData, "C_drawVMUIcon");

  lua_pushcfunction(luaData, LUA_clearVMUIcon);
  lua_setglobal(luaData, "C_clearVMUIcon");

  lua_pushcfunction(luaData, LUA_setVMUTone);
  lua_setglobal(luaData, "C_setVMUTone");

  lua_pushcfunction(luaData, LUA_setRumble);
  lua_setglobal(luaData, "C_setRumble");


  return(r);
}

int LUA_loadVMUIcon(lua_State *L) {
  const char* logo  = lua_tostring(L, 1);
  int         index = getEmptyIcon();

  char* path = findFile(logo);
  int r = setup_vmu_icon_load( &vmu_icons[index], path);
  printf("VMU> Loading icon %s at ID:%u\n", path, index);

  lua_pushnumber(L, index);
  return 1;
}

int LUA_freeVMUIcon(lua_State *L) {
  int index = (int)lua_tonumber(L, 1);

  if(vmu_icons[index] != NULL) {

  }
  return 1;
}

int LUA_drawVMUIcon(lua_State *L) {
  int index = (int)lua_tonumber(L, 1);

  if (vmu_icons[index] != NULL) {
    //printf("VMU> drawing ID:%u\n", index);
    crayon_vmu_display_icon(vmu_details.valid_vmu_screens,  vmu_icons[index]);
  }
  return 1;
}

int LUA_clearVMUIcon(lua_State *L) {
  return 1;
}

int LUA_setVMUTone(lua_State * L) {
  if (maple_enum_type(0, MAPLE_FUNC_CLOCK) == NULL) {
    return(0);
  }
  int tone = (int)lua_tonumber(L, 1);

  if(tone < 100 && tone != 0) tone = 100;
  if(tone > 255) tone = 255;

  uint32_t first = tone/4;
  first = first << 8;
  uint32_t beep = first + tone;

  vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), beep);

  return(0);
}

int LUA_setRumble(lua_State * L) {
  if(jump_cont == NULL) { return(1); }

  if(1 ==1 ) {return(1);}


  int v1 = (int)lua_tonumber(L, 1);
  int v2 = (int)lua_tonumber(L, 2);
  int v3 = (int)lua_tonumber(L, 3);

  if(v1 == 0) {
    purupuru_rumble_raw(jump_cont, 0x00000000);
    return(0);
  }
  //if(intensity < 0 )intensity = 0;
  //if(intensity > 7) intensity = 7;


  effect.duration = v3;
  effect.effect2 = PURUPURU_EFFECT2_LINTENSITY(v1)
                | PURUPURU_EFFECT2_PULSE;
  effect.effect1 = PURUPURU_EFFECT1_INTENSITY(v2)
                | PURUPURU_EFFECT1_PULSE;
                //PURUPURU_SPECIAL_MOTOR1;// |
  //effect.special = PURUPURU_SPECIAL_MOTOR1 | PURUPURU_SPECIAL_PULSE;
  effect.special = PURUPURU_SPECIAL_MOTOR1;

  purupuru_rumble(jump_cont, &effect);

  return(1);
}




int getEmptyIcon() {
  for(int i=0; i < 256; i++) {
    if(vmu_icons[i] == NULL){
      return(i);
    }
  }
  return(-1);
}

int vmu_program_beep() {
  uint32_t beep =  0x000065f0;
  vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), beep);
  timer_spin_sleep(250);
  vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), 0);
  timer_spin_sleep(100);

  /*
  uint32_t first = 100;
  uint32_t last  = 255;
  first = first << 16;
  last = last << 12;
  printf("First = %d | Last = %d | Beep = %d\n", first, last, beep);
  beep = first + last;
  printf("!!! New Beep = %d\n", beep);
  */


  uint32_t first = 100;
  uint32_t last  = 255;
  for(int i = 100; i < 255; i += 4) {
    first = i/4; last  = i;
    //printf("First = %d | Last = %d\n", first, last, beep);
    first = first << 8;
    beep = first + last;
    vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), beep);
    timer_spin_sleep(250);

    //vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), 0);
    //timer_spin_sleep(50);
  }


  vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), 0);
  timer_spin_sleep(50);

}
