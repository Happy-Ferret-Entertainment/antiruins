
#include "saveload.h"
//#include "DreamHAL/startup/memfuncs.h"

#include "crayonVMU/savefile.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "antiruins.h"

#define SAVE_SIZE 4096
crayon_savefile_details_t savefile[3];

// Structure to keep track of the stuff I want to save in the game.
typedef struct _ss_data {
  char lua_table[SAVE_SIZE];
} ss_savefile;

ss_savefile save_package;
int         inv_index = 0;

int initSaveload() {

  // Intialize the savefiles
  for (int i = 0; i < 3; i++) {
    crayon_savefile_init_savefile_details(
      &savefile[i],
      (uint8_t *)&save_package,
      sizeof(ss_savefile),
      0,
      0,
      "Summoning Signals\0", // LONG
      "FM RADIO\0", // SHORT
      "SomeID\0", // ID
      "SAVE 00\0" //Save number?
    );
    sprintf(savefile[i].save_name, "SAVE 0%d", i);

    int r = checkForSavefile(i);
    if(r == 0) {
      printf("VMU> no savefile #%d\n", i);
    } else {
      printf("VMU> found savefile #%d\n", i);
    }
  }

  // Intialize the data
  char *empty = "return {}\0";
  memcpy(save_package.lua_table, empty, strlen(empty));

  // Lua binds
  lua_pushcfunction(luaData, LUA_saveSavefile);
  lua_setglobal(luaData, "C_saveSavefile");

  lua_pushcfunction(luaData, LUA_setSaveValue);
  lua_setglobal(luaData, "C_setSaveValue");

  lua_pushcfunction(luaData, LUA_loadSavefile);
  lua_setglobal(luaData, "C_loadSavefile");

  lua_pushcfunction(luaData, LUA_getSaveValue);
  lua_setglobal(luaData, "C_getSaveValue");
  return(1);
}

// Check if a file exists, return 1 on success
int checkForSavefile(int saveNum) {
  //Find the first savefile (if it exists)
    for(int iter = 0; iter <= 3; iter++){
      for(int jiter = 1; jiter <= 2; jiter++){
        if(crayon_savefile_get_vmu_bit(savefile[saveNum].valid_saves, iter, jiter)){	//Use the left most VMU
          savefile[saveNum].savefile_port = iter;
          savefile[saveNum].savefile_slot = jiter;
          goto Exit_loop_1;
        }
      }
    }
    Exit_loop_1: ;

  int savefileExist = 0;
  //Try and load savefile
  int load_result = crayon_savefile_check_for_save(&savefile[saveNum], savefile[saveNum].savefile_port, savefile[saveNum].savefile_slot);
  if(load_result == 0) {
      printf("SAVELOAD> Found a savefile on CONT%d-VMU%d\n", savefile[saveNum].savefile_port, savefile[saveNum].savefile_slot);
      savefileExist = 1;
  } else {
    printf("SAVELOAD> No file found\n");
  }
  return(savefileExist);
}

// Create a new empty savefile
int createNewSavefile(int saveNum) {
  //No savefile yet
  if(savefile[saveNum].valid_memcards && savefile[saveNum].savefile_port == -1 &&
  		savefile[saveNum].savefile_slot == -1){
  		//If we don't already have a savefile, choose a VMU
  		if(savefile[saveNum].valid_memcards){
  			for(int iter = 0; iter <= 3; iter++){
  				for(int jiter = 1; jiter <= 2; jiter++){
  					if(crayon_savefile_get_vmu_bit(savefile[saveNum].valid_memcards, iter, jiter)){	//Use the left most VMU
  						savefile[saveNum].savefile_port = iter;
  						savefile[saveNum].savefile_slot = jiter;
  						goto Exit_loop_2;
  					}
  				}
  			}
  		}
  		Exit_loop_2:
  		;
  	}

  //If one exists, try to save on it
  int save_res = 0;
  if(savefile[saveNum].valid_memcards){
    save_res = crayon_savefile_save(&savefile[saveNum]);
  }

  if(save_res == 0) {
    printf("SAVELOAD.C> Created new file success on CONT %d VMU %d\n", savefile[saveNum].savefile_port, savefile[saveNum].savefile_slot);
  } else {
    printf("SAVELOAD.C> File creation error : %d\n", save_res);
  }
}

// Update a valid savefile with the new result
int updateSavefile(int saveNum) {

  int save_res = crayon_savefile_save(&savefile[saveNum]);

  // if no valid save found
  if (save_res != 0) {
    createNewSavefile(saveNum);
    save_res = crayon_savefile_save(&savefile[saveNum]);
  }

  if(save_res == 0) {
    printf("SAVELOAD.C> Saved file updated CONT%d-VMU%d size:%u\n",
    savefile[saveNum].savefile_port,
    savefile[saveNum].savefile_slot,
    crayon_savefile_get_save_block_count(&savefile[saveNum]));
  } else {
    printf("SAVELOAD.C> Saved file error : %d\n", save_res);
  }
  return(save_res);
}

int LUA_createSavefile(lua_State *L) {


  return(1);
}

// LOAD ////////////////////////////////////

int LUA_loadSavefile(lua_State *L) {
  // -1 for the lua index offset
  int saveNum = (int)lua_tonumber(L, 1);
  int r = checkForSavefile(saveNum);

  //lua_settop(L, 0);
  // If true load the values
  if(r) {
    crayon_savefile_load(&savefile[saveNum]);
    ss_savefile *t = (ss_savefile*)savefile[saveNum].savefile_data;
    printf("=== RAW VMU LOAD %d ===\n%s\n", saveNum, t->lua_table);
    lua_pushnumber(L, 1);
    lua_pushlstring(L, t->lua_table, strlen(t->lua_table));
    return(2);
  } else {
    lua_pushnumber(L, 0);
  }
  return(1);
}

// Get a single value
int LUA_getSaveValue(lua_State *L) {
  const char* key = lua_tostring(L, 1);
  /*
  if(strcmp(key, "currentQuest") == 0) {
    lua_pushnumber(L, save_package.currentQuest);
    return(1);
  }

  if(strcmp(key, "currentMap") == 0) {
    lua_pushnumber(L, save_package.currentMap);
    return(1);
  }

  if(strcmp(key, "inventorySize") == 0) {
    lua_pushnumber(L, save_package.inventorySize);
    return(1);
  }

  if(strcmp(key, "itemID") == 0) {
    int itemNumber = lua_tonumber(L, 2);
    //printf("Sedngin item %u\n", save_package.inventory[itemNumber]);
    lua_pushnumber(L, save_package.inventory[itemNumber]);
    inv_index++;
    return(1);
  }
  */
  printf("SAVELOAD.C> Trying to get invalid key :%s\n", key);
  lua_pushnumber(L, -1);
  return(1);
}

// SAVE //////////////////////////////////

int LUA_saveSavefile(lua_State *L) {
  const char* raw = lua_tostring(L, 1);
  int saveNum     = (int)lua_tonumber(L, 2);
  int l = strlen(raw) + 1;
  memcpy(&save_package.lua_table, raw, l);
  printf("=== RAW VMU SAVE %d ===\n%s\n", saveNum, save_package.lua_table);
  updateSavefile(saveNum);

  return(1);
}

// Set a singla value
int LUA_setSaveValue(lua_State *L) {
  /*
  const char* key         = lua_tostring(L, 1);
  uint8_t     int_value   = 0;

  // For int value (WILL PROBABLY BE THIS ALL THE TIME)
  if      (lua_isinteger(L, 2)) {
      int_value = (uint8_t)lua_tonumber(L, 2);
      //printf("SAVELOAD> set INT %s to %u\n", key, int_value);
  }

  // Assigning the value to the save_package
  if(strcmp(key, "currentQuest") == 0) {
    save_package.currentQuest = int_value;
    //printf("Updated currentQuest : %u\n", int_value);
  }

  if(strcmp(key, "currentMap") == 0) {
    save_package.currentMap =  int_value;
    //printf("Updated currentMap : %u\n", int_value);
  }

  if(strcmp(key, "inventorySize") == 0) {
    save_package.inventorySize = int_value;
  }

  if(strcmp(key, "itemID") == 0) {
    save_package.inventory[inv_index] = int_value;
    inv_index++;
  }

  */
  return(1);
}
