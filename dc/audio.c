#include <dc/sound/sound.h>
#include <dc/sound/stream.h>
#include <dc/cdrom.h>
#include <math.h>
#include <inttypes.h>
#include "aica.h"
#include "audio.h"
#include "antiruins.h"

/*////////////////////////////////////////
http://gamedev.allusion.net/docs/kos-2.0.0/stream_8h.html
MAX 4 CHANNEL OF STREAMING
MAC SOUND RAM = 2MB
2 CHANNEL FOR BGM
64 FOR SFX
/*//////////////////////////////////////////

#define MAX_VOLUME 254
#define MAX_SFX 64
#define MAX_CHANNEL 4

int        currentChannel;
sfx        loadedSFX[MAX_SFX];
uint32_t   totalSoundMem = 0;
uint32_t   soundMem;

int        activeCDDAtrack = -1;


void initSound(int format) {
  snd_init();
  snd_stream_init();

  // Volume 0 -> 15
  spu_cdda_volume(12, 12);
  // Pan 0 -> 31. 16 = center
  spu_cdda_pan(16, 16);
  /*
  musicFormat = format;
  switch(musicFormat) {
    case OGG:
      sndoggvorbis_init();
      extension = ".ogg";
      break;
    case MP3:
      mp3_init();
      extension = ".mp3";

      break;
  }
  */

  for(int i = 0; i < MAX_SFX; i++) {
    loadedSFX[i].loaded = 0;
    loadedSFX[i].path = NULL;
  }
  totalSoundMem = snd_mem_available();
  //bgmMusic = NULL;

  lua_pushcfunction(luaData, LUA_playSFX);
  lua_setglobal(luaData, "C_playSFX");

  lua_pushcfunction(luaData, LUA_loadSFX);
  lua_setglobal(luaData, "C_loadSFX");

  lua_pushcfunction(luaData, LUA_streamFile);
  lua_setglobal(luaData, "C_streamFile");

  lua_pushcfunction(luaData, LUA_stopStream);
  lua_setglobal(luaData, "C_stopStream");

  lua_pushcfunction(luaData, LUA_freeSFX);
  lua_setglobal(luaData, "C_freeSFX");

  lua_pushcfunction(luaData, LUA_isPlaying);
  lua_setglobal(luaData, "C_isPlaying");

  lua_pushcfunction(luaData, LUA_setChannelVolume);
  lua_setglobal(luaData, "C_setChannelVolume");

  lua_pushcfunction(luaData, LUA_setCDDAVolume);
  lua_setglobal(luaData, "C_setCDDAVolume");

}

int startBGM(int trackNumber, int volume, int loop){
  int status    = 0;
  int discType  = 0;
  
  if(cdrom_get_status(&status, &discType) != ERR_OK) {
    printf("CDROM NOT READY\n");
    return(0);
  }
  
  // It seems like the second trackNumber must be present on disc for it to work.
  // Playing the last tracks?
  cdrom_cdda_play(trackNumber, trackNumber, loop, CDDA_TRACKS);
  activeCDDAtrack = trackNumber;
  return(1);
}

int pauseBGM(){
  cdrom_cdda_pause();
  return(1);
}

int stopBGM(){
  cdrom_cdda_pause();
  activeCDDAtrack = -1;
  return(1);
}

int getSFXNumber() {
  for(int i = 1; i < MAX_SFX; i++) {
    if(loadedSFX[i].loaded == 0)
      return(i);
  }
  printf("SOUND_MIXER.C > No more valid SFX avail.\n");
  return(0);
}

int addSFX(char *path) {
  int c = getSFXNumber();

  path = findFile(path);
  loadedSFX[c].s = snd_sfx_load(path);
  if(loadedSFX[c].s == SFXHND_INVALID) {
    printf("Can't load SFX %s\n", path);
    //setParam(4, buf);
    return 0;
  }
  loadedSFX[c].loaded = 1;
  soundMem = snd_mem_available();
  printf("AUDIO.C> Loading SFX ID %d > %s | SOUND MEM : %d\n",c , path, soundMem);

  return c;
}

int freeSFX(int sfxID) {
  if(sfxID < 0 || sfxID > MAX_SFX) {
    printf("AUDIO.C> sfxID larger than 64 (or smaller than 0)\n");
    return 0;
  }

  if(loadedSFX[sfxID].loaded == 1) {
    snd_sfx_unload(loadedSFX[sfxID].s);
    loadedSFX[sfxID].loaded = 0;
  }
  return  0;
}

int playSFX(int sfxID, int volume, int pan) {
  char buf[64];
  int r = 0;

  //check for valid sound
  if(sfxID == 0 || loadedSFX[sfxID].loaded == 0)
    return 0;

  //data checking for volume
  if (volume > MAX_VOLUME)  volume = MAX_VOLUME;
  if (volume < 0)           volume = 0;

  //data chacing for pan

  if ((r = snd_sfx_play(loadedSFX[sfxID].s, volume, pan)) != -1)
    sprintf(buf, "Played %d on channel %d - volume: %d\n", sfxID, r, volume);
  else
    sprintf(buf, "Couldn't play sound\n");


  printf(buf);
  return r;
}

int LUA_playSFX(lua_State *L_state) {
    int id            = (int)lua_tonumber(L_state, 1);
    int vol           = (int)lua_tonumber(L_state, 2);
    int trig          = (int)lua_tonumber(L_state, 3);

    int channel = playSFX(id, vol, 127);

    lua_pushnumber(L_state, channel);
    return 1;
}

int LUA_streamFile(lua_State *L_state) {
  int trackID           = (int)lua_tonumber(L_state, 1);
  int volume            = (int)lua_tonumber(L_state, 2);
  int loop              = (int)lua_tonumber(L_state, 3);

  printf("AUDIO.C> Starting track %d \n", trackID);
  startBGM(trackID, volume, loop * 1000);

  return(0);
}

int LUA_stopStream(lua_State *L_state) {
  stopBGM();
}

int LUA_isPlaying(lua_State *L_state) {
  int result     = 0;
  const trackID  = lua_tonumber(L_state, 1);

  if(trackID == activeCDDAtrack) {
    //printf("AUDIO> Same source as BGM music!\n");
    result = 1;
  }


  lua_pushboolean(L_state, result);
  return(0);
}

int LUA_setCDDAVolume(lua_State *L_state) {
  int volume  = (int)lua_tonumber(L_state, 1);
  volume      = volume / 255 * 15;
  if(volume > 15) volume = 15;
  if(volume < 0)  volume = 0;
  

  spu_cdda_volume(volume, volume);
  return(0);
}

int LUA_setChannelVolume(lua_State *L_state) {

  int channel = (int)lua_tonumber(L_state, 1);
  int vol     = (int)lua_tonumber(L_state, 2);

  if(channel < 0) {
    printf("AUDIO> Invalid AICA channel %d (setVolume)\n", channel);
    return(1);
  }

  AICA_CMDSTR_CHANNEL(tmp, cmd, chan);

  cmd->cmd = AICA_CMD_CHAN;
  cmd->timestamp = 0;
  cmd->size = AICA_CMDSTR_CHANNEL_SIZE;
  cmd->cmd_id = channel;
  chan->cmd = AICA_CH_CMD_UPDATE | AICA_CH_UPDATE_SET_VOL;
  chan->vol = vol;
  snd_sh4_to_aica(tmp, cmd->size);
  //printf("Testing volume on chan %d to %d\n", channel, vol);
  return 1;
}

int LUA_loadSFX(lua_State *L_state) {
  const char* file  = lua_tostring(L_state, 1);
  int type          = lua_tonumber(L_state, 2);

  int id = addSFX(file);
  lua_pushnumber(L_state, id);

  return 1;
}

int LUA_freeSFX(lua_State *L_state) {
  int sfxID = lua_tonumber(L_state, 1);
  printf("AUSIO.C> Freeing SFX ID:%d\n", sfxID);
  freeSFX(sfxID);
  return 0;
}

char soundInfo[64];
char* getSoundInfo() {
  double avail = (float)soundMem / (float)totalSoundMem * 100.0f;
  sprintf(soundInfo, "SRAM:%2.2f/100", avail);
  return soundInfo;
}
