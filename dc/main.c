#include <kos.h>
#include <GL/gl.h>
#include "antiruins.h"
#include "utils.h"
#include "graphics.h"
#include "luadc.h"

char*             gameworld   = "lua/loader.lua";
uint64_t          end_time, start_time, delta_time, game_time = 0;
int               debugActive = 0;
int               gameActive  = 1;
int               GW_status   = GW_EMPTY;
lua_State         *luaData;

input             *p1; //player 1

int displayAntiruins() {
  texture *t;
  t = malloc(sizeof(texture));

  initTexture(t);
  int r = dtex_to_gl_texture(t, findFile("default/logo.dtex"));
  printf("Antiruins > Logo Loaded:%u\n", r);

  glClearColor(0.1 ,0.1, 0.1, 1);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  glTranslatef(320, 240, 0);

  drawTexture(t, 0, 0, 0, 1.0, 1.0);
  glKosSwapBuffers();
  thd_sleep(250);
  freeTexture(t);
}

int main() {
  //profiler_init("/pc/DCprof_output.gmon");

  initLua(&luaData);

  initInput();
  p1 = newController(0);
  //initVMU(p1->cont);
  //initSaveload();

  initMath();
  initGL();
  initSound(MP3);

  // C antiruin Logo
  displayAntiruins();
  initAntiruins(&luaData);

  //Load the game
  LUA_loadGameworld(gameworld);
  LUA_createGameworld();

  
  // CLear Logo
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glLoadIdentity();
  glKosSwapBuffers();
  //profiler_start();

  while(gameActive)
  {
    start_time = getTime_MS();
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glTranslatef(0, 480, 0);

    updateControllers();
    LUA_updateGameworld(delta_time);
    LUA_renderGameworld(delta_time);

    /*
    switch (GW_status) {
      case GW_READY:
        LUA_updateGameworld(delta_time);
        //glEnable(GL_LIGHTING);
        LUA_renderGameworld(delta_time);
        //glDisable(GL_LIGHTING);
        break;

      case GW_EMPTY: //If there's no world, create it
        LUA_createGameworld(startmap);
        //thd_sleep(200);
        break;

      case GW_FREE: //If the world need to be unloaded
        LUA_freeGameworld();
        //thd_sleep(200);
        printf("L2D> Gameworld free'd\n");
        GW_status = GW_ERROR;
        break;

      case GW_RELOAD: //If the world need to be unloaded
        printf("L2D> Attempt to restart\n");
        LUA_freeGameworld();
        thd_sleep(200);
        printf("L2D> Gameworld free'd\n");
        LUA_loadGameworld(gameworld);
        thd_sleep(200);
        LUA_createGameworld(startmap);
        GW_status = GW_READY;
        printf("L2D> Gameworld reloaded\n");
        break;
    }
    */

    uint64_t logic_time = getTime_MS() - start_time;
    //printf("DELTATIME : %d\n", logic_time);
    //garbageCollectStep(250);

    endFrame();
    glKosSwapBuffers();

    end_time    = getTime_MS();
    delta_time  = end_time - start_time;
    game_time  += delta_time;
    if(delta_time > 17) {
      //printf("SLOW -> LOGIC:%d DELTA:%d \n", logic_time, delta_time);
    } else {
      //int memLeft = garbageCollectStep(200);
    }
    //break;
  }
  //profiler_stop();

  //vmu_beep_raw(maple_enum_type(0, MAPLE_FUNC_CLOCK), 0);

  profiler_clean_up();
  printf("Exiting game.\n");
  return(0);
}
