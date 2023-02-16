#include <dc/sound/sound.h>
#include <dc/sound/stream.h>
#include <oggvorbis/sndoggvorbis.h>
#include <mp3_new/sndserver.h>
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

int        musicFormat = OGG;
char       *extension = ".ogg";
int        mp3isPlaying = 0;
int        currentChannel;
sfx        loadedSFX[MAX_SFX];
uint32_t   totalSoundMem = 0;
uint32_t   soundMem;
char       *bgmMusic;

void initSound(int format) {
  snd_init();
  snd_stream_init();
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

  lua_pushstring(luaData, extension);
  lua_setglobal(luaData, "AUDIO_FORMAT");
}

int startBGM(char* path, int volume, int loop){
    //make sure to stop the previous track?
    stopBGM();
    switch(musicFormat) {
      case WAV:

        break;
      case OGG:
        bgmMusic = findFile(path);
        sndoggvorbis_start(path, loop);
        sndoggvorbis_volume(volume);
        break;
      case MP3:
        bgmMusic = findFile(path);
        mp3_start(path, loop);
        mp3_volume(volume);
        mp3isPlaying = 1;
        printf("Starting music\n");
        break;
    }

    return 1;
}

int stopBGM(){
  switch(musicFormat) {
      case OGG:
        if(sndoggvorbis_isplaying()) {
          sndoggvorbis_stop();
          printf("Stopping OGG BGM\n");
        }
      break;
      case MP3:
        if(mp3isPlaying == 1) {
          mp3_stop();
          printf("Stopping MP3 BGM\n");
          mp3isPlaying = 0;
        }

      break;
  }

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
  const char* filename  = lua_tostring(L_state, 1);
  int volume            = lua_tonumber(L_state, 2);
  int loop              = lua_tonumber(L_state, 3);

  char *r = strstr(filename, extension);
  if(r == NULL) {
    printf("Source sound %s is not an %s\n", filename, extension);
    return(0);
  }
  printf("Starting sound %s \n", filename);
  startBGM(filename, volume, 1);

  return(0);
}

int LUA_stopStream(lua_State *L_state) {
  stopBGM();
}

int LUA_isPlaying(lua_State *L_state) {
  int result = 0;
  const char* id = lua_tostring(L_state, 1);

  if(strcmp(id, bgmMusic) == 0) {
    printf("AUDIO> Same source as BGM music!\n");
    switch(musicFormat) {
        case OGG:
          if(sndoggvorbis_isplaying()) {
            result = 1;
          }
        break;
        case MP3:
          if(mp3isPlaying == 1) {
            result = 1;
          }
        break;
    }
  }


  lua_pushboolean(L_state, result);
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
