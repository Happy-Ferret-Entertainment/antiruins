#include <kos.h>
#include <stdint.h>
#include <stdio.h>
#include <GL/gl.h>
#include "antiruins.h"
#include "utils.h"
#include "graphics.h"
#include "luadc.h"

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

int displayAntiruins() {
  for (int i = 0; i < 100; i++) {
    newSprite(logoTex, rand() % 640, rand() % 480, 0, 0, 0);
  }
  //newSprite(logoTex, 320, 240, 0, 0, 0);
}


int __exit(int status) {
  thd_sleep(250);
  getAverageDelta();
  printf("Antiruins > Clean Exiting :%d\n", status);
  fflush(stdout);
  exit(status);
}

int main() {
  //profiler_init("/pc/gmon.out");
  //profiler_init("");
  //profiler_start();
  
  //initLua(&luaData);

  //initInput();
  //p1 = newController(0);
  //initVMU(p1->cont);
  //initSaveload();

  //initMath();
  //initGL();
  initPVR();
  logoTex = loadDTEX(findFile("default/logo.dtex"));
  //initSound(MP3);

  // C antiruin Logo
  //
  //initAntiruins(&luaData);
 
  // CLear Logo
  //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  //glLoadIdentity();
  //glKosSwapBuffers();




  int exitTime = 7 * 1000;
  while(gameActive && game_time < exitTime)
  {
    startTimer();
    //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //glLoadIdentity();
    //glTranslatef(0, 480, 0);

    //updateControllers();
    //LUA_updateAntiruins(delta_time);
    //LUA_updateGameworld(delta_time);
    //LUA_renderGameworld(delta_time);

    displayAntiruins();
    renderFrame();

    //endFrame();
    //glKosSwapBuffers();

    delta_time = getDelta();
    game_time += delta_time;
    cFrame++;

    if (cFrame % 100 == 0) getAverageDelta();

    // Send anything stuck in the buffer
  }
  // If there is a VMU, make it stop beeping
  //vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), 0);

  //profiler_stop();
  //profiler_clean_up();

  __exit(0);
  
  return(0);
}
