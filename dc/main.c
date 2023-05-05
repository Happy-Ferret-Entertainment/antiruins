#include <kos.h>
#include "antiruins.h"
#include "utils.h"
#include "graphics.h"
#include "luadc.h"

KOS_INIT_FLAGS(INIT_DEFAULT);

char*             gameworld   = "lua/loader.lua";
uint64            game_time   = 0;
uint32            delta_time  = 0;
uint64            cFrame = 0;
int               debugActive = 0;
int               gameActive  = 1;
int               GW_status   = GW_EMPTY;
lua_State         *luaData;

input             *p1; //player 1

int               timeToExit = 200;
int               logoTex = -1;
float             _delta = 0;
char              str[16] = "";

int displayAntiruins() {
  for (int i = 0; i < 500; i++) {
    newSprite(logoTex, rand() % 640, rand() % 480, 256, 64, 0);
  }
}


int __exit(int status) {
  thd_sleep(2500);
  getAverageDelta();
  printf("Game Time : %f\n", game_time);
  printf("Antiruins > Clean Exiting :%d\n", status);
  fflush(stdout);
  exit(status);
}

int main() {
  //dbgio_dev_select("fb");
  //profiler_init("/pc/gmon.out");
  //profiler_init("");
  //profiler_start();
  checkCDContent();
  initLua(&luaData);
  initInput();
  p1 = newController(0);

  initPVR();
  initSound(MP3);
  initAntiruins(&luaData);
 
  int exitTime = 25 * 1000;
  while(gameActive)
  {
    startTimer(); 
    updateControllers();
    
    LUA_updateAntiruins(delta_time);
    LUA_updateGameworld(delta_time);

    startFrame();
    LUA_renderGameworld(delta_time);
    renderFrame();

    delta_time = getDelta();
    game_time += delta_time;
    cFrame++;
    //if (cFrame % 100 == 0) _delta = getAverageDelta();
  }
  // If there is a VMU, make it stop beeping
  //vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), 0);

  //profiler_stop();
  //profiler_clean_up();

  __exit(0);
  
  return(0);
}
