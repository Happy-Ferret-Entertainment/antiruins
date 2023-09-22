--[[
LOGIC:

lua_loadedSavefile = the file that was lua_loadedSavefile from the disk




]]--


local maf     = require "lib.maf"
local toFile  = require "lib.tableToFile"
local quest   = require "questlist"
local saveload = {}

local pathToSavefile = nil
local savefile = {}

-- THIS IS THE TABLE THAT GET UPDATED DURING THE GAME
local gamedata                = {}
local raw_gamedata            = ""

-- THIS IS THE CURRENTLY LOADED SAVEFILE
local lua_loadedSavefile      = {}
local raw_loadedSavefile      = ""

-- Info for saveload menu
local saveInfo = {}


function saveload.init()
  local status = false

  savefile = saveload.newSave()

  if platform == "DC" then
  end

  return status
end

function saveload.newSave()
  local savefile = {
    -- MAP
    mapInfo       = "",
    maps          = {},

    -- PLAYER
    inv           = {},
    quests        = {},

    -- HARDWARE
    emit          = {},
  }

  return savefile
end

function saveload:save(saveNum)
  local saveNum = saveNum or 1
  local result  = 0

  lua_gamedata = saveload:encode()

  if platform == "LOVE" then
    raw_gamedata = table.saveLove(gamedata, saveload.getPath(saveNum))
    local t = table.saveString(lua_gamedata)
    print(t)
    --result = love.filesystem.write()
  end

  if platform == "DC" then
    raw_gamedata = table.saveString(lua_gamedata)
    print(raw_gamedata)
    result = C_saveSavefile(raw_gamedata, saveNum - 1)
  end

  if result == 1 then
    audio.play(audio.sfx.success, 0.8, false)
    print("Saveload> Save done.")
  end
end

-- Loads and decodes if the fils is found
function saveload:load(saveNum)
  local result, data  = 0, ""
  local saveNum       = saveNum or 1
  raw_loadedSavefile  = ""

  -- LOADING THE SAVEFILE
  if platform == "LOVE" then
    local path = saveload.getPath(saveNum)
    local error
    raw_loadedSavefile, error = table.loadLove(path)
    if raw_loadedSavefile == nil then
      print("Error loading file : " .. error)
      return 0
    else
      --print("Loading file : " .. path)
    end
    result = 1
  end

  -- LOADING THE SAVEFILE
  if platform == "DC" then
    result, data = C_loadSavefile(saveNum - 1)
    if data ~= nil then
      raw_loadedSavefile = table.loadString(data)
    else
      return nil
    end
  end
  -- Set the new data to
  if result == 1 then
    lua_loadedSavefile = saveload:decode(raw_loadedSavefile)
    --audio.play(audio.sfx.success, 0.8, false)
    print("Saveload> Loaded save file ".. saveNum .. ".")
  end

  return lua_loadedSavefile
end

function saveload:encode()
  gamedata = saveload.newSave()
  -- map ID
  gamedata.mapInfo = saveload.encodeMapInfo()
  if gamedata.mapInfo == nil then

  end
  -- maps & npc
  local npc_data = {}
  for k, v in pairs(maps) do
    gamedata.maps[k] = {}
    for i, npc in ipairs(v.npcs) do
      local data = saveload.encodeNPC(npc)
      if data ~= nil then
        table.insert(gamedata.maps[k], data)
      end
    end
  end

  -- emit
  local emit_data = {}
  gamedata.emit = {}
  local raw_emit = hw.getEmitters()
  for k, emit in pairs(raw_emit) do
    local data = saveload.encodeEmit(emit)
    if data ~= nil then
      table.insert(gamedata.emit, data)
    end
  end

  -- quests
  local q = {}
  for k, v in pairs(p1.quests) do
    q = saveload.encodeQuest(v)
    table.insert(gamedata.quests, q)
  end

  -- items
  gamedata.inv = saveload.encodeItem(v)


  return gamedata
end

function saveload:decode(raw_data)
  local raw   = raw_data
  local data  = {}

  if raw == nil then
    data.mapInfo = {
      id = 1,
      realTime = 0,
      320,
      240,
    }
    print("==== EMPTY SAVEFILE ========")
    return data
  end

  print("===== DECODING ==========")
  data.mapInfo = saveload.decodeMapInfo(raw.mapInfo)
  if data.mapInfo == nil then
    return nil
  end
  print("CURRENT MAP : " .. data.mapInfo.id)

  for mapname, map in pairs(raw.maps) do
    print("decoded MAP : " .. mapname)
    data[mapname] = {}
    for i, npc in ipairs(map) do
      local new_npc = saveload.decodeNPC(npc)
      print("added NPC : " .. new_npc.npcID)
      table.insert(data[mapname], new_npc)
    end
  end

  data.emit = {}
  if raw.emit then
    for i, emit in ipairs(raw.emit) do
      local emit_data = saveload.decodeEmit(emit)
      print("emit : " .. emit_data.npcID)
      table.insert(data.emit, emit_data)
    end
  end

  data.quests = {}
  for i, quest in ipairs(raw.quests) do
    local quest_data = saveload.decodeQuest(quest)
    print("quest : " .. quest_data.id)
    table.insert(data.quests, quest_data)
  end

  data.inv = {}
  data.inv = saveload.decodeItem(raw.inv)
  print("items : " .. #data.inv .. " found")
  print("=========================")

  return data
end

function saveload.applyLoad()
  local data = lua_loadedSavefile

  -- DELETE ENTIRE STATE??? YES!
  for i, v in ipairs(maps) do
    v = nil
  end

  -- Maps
  saveload.restoreMapNpc(currentMap)

  -- Emitters
  saveload.restoreEmitters(hw.getEmitters())

  -- Quests
  p1.quests = {}
  for i, v in ipairs(data.quests) do
    p1:addQuest(v.id, v.progress)
  end

  -- Inventory
  p1.inventory = {}
  for i, v in ipairs(data.inv) do
    p1:pickItem(v, false)
  end

  realTime = data.mapInfo.time
  --switch to the player map
  if currentMap.id ~= data.mapInfo.id then
    local mapName = MAP_NAMES[data.mapInfo.id]
    print("Saveload> Moving to " .. mapName)
    currentMap:switch(mapName)
  end
  p1:setPosition(data.mapInfo.x, data.mapInfo.y)
  graphics.setCamPosition(data.mapInfo.x, data.mapInfo.y)

end

function saveload.updateSaveInfo(saveNum)
  local data = {}

  if saveNum == nil then
    for i=1, 3 do
      data = saveload:load(i)
      saveInfo[i]       = {}
      if data ~= nil then
        local mapName = MAP_NAMES[data.mapInfo.id] or "INVALID MAP"
        saveInfo[i].map   = mapName:gsub("^%l", string.upper)
        saveInfo[i].time  = data.mapInfo.time or 0
      else
        saveInfo[i].map   = "No savefile"
        saveInfo[i].time  = 0
      end
    end
  else
    local  i = saveNum
    data = saveload:load(i)
    saveInfo[i]       = {}
    if data ~= nil then
      local mapName = MAP_NAMES[data.mapInfo.id] or "INVALID MAP"
      saveInfo[i].map   = mapName:gsub("^%l", string.upper)
      saveInfo[i].time  = data.mapInfo.time or 0
    else
      saveInfo[i].map   = "No savefile"
      saveInfo[i].time  = 0
    end
  end
end

function saveload.getSaveInfo()
  return saveInfo
end
-----------------------------------------
function saveload.encodeMapInfo()
  -- ORDER : NPCID - DESC - REPAIR
  local mapInfo = {}
  if currentMap == nil then
    return nil
  else
    table.insert(mapInfo, currentMap.id)
    table.insert(mapInfo, math.floor(realTime))
    table.insert(mapInfo, math.ceil(p1.obj.pos.x))
    table.insert(mapInfo, math.ceil(p1.obj.pos.y))
  end
  return table.concat(mapInfo, "-")
end

function saveload.decodeMapInfo(raw_data)
  local mapInfo = {}
  if raw_data == "" or nil then return nil end

  for id, time, x, y in string.gmatch(raw_data, "(%d+)-(%d+)-(%d+)-(%d+)") do
    mapInfo.id    = tonumber(id)
    mapInfo.time  = tonumber(time)
    mapInfo.x   = tonumber(x)
    mapInfo.y   = tonumber(y)
  end
  return mapInfo
end

function saveload.encodeNPC(npc)
  -- ORDER : NPCID - DESC - REPAIR
  local data = {}

  -- Protection against non relevant NPC
  if npc.desc_position + npc.canRepair == 0 then
    return nil
  else
    table.insert(data, npc.npcID)
    table.insert(data, npc.desc_position)
    table.insert(data, npc.canRepair)
    return table.concat(data, "-")
  end
end

function saveload.decodeNPC(raw_data)
  local npc = {}
  for npcID, desc, repair in string.gmatch(raw_data, "([%w_]+)-(%d+)-(%d+)") do
    npc.npcID         = npcID
    npc.desc_position = tonumber(desc)
    npc.canRepair     = tonumber(repair)
  end
  return npc
end

function saveload.encodeEmit(emit)
  -- ORDER : NPCID - DESC - REPAIR
  local data = {}

  table.insert(data, emit.npcID)
  table.insert(data, emit.desc_position)
  return table.concat(data, "-")
end

function saveload.decodeEmit(raw_data)
  local emit = {}
  for npcID, desc in string.gmatch(raw_data, "([%w_]+)-(%d+)") do
    emit.npcID         = npcID
    emit.desc_position = tonumber(desc)
  end
  return emit
end

function saveload.encodeQuest(quest)
  -- ORDER : ID - progress
  local data = {}
  table.insert(data, quest.id)
  table.insert(data, quest.progress)
  return table.concat(data, "-")
end

function saveload.decodeQuest(raw_data)
  local quest = {}
  for id, progress in string.gmatch(raw_data, "(%d+)-(%-?%d+)") do
    quest.id        = tonumber(id)
    quest.progress  = tonumber(progress)
  end
  return quest
end

function saveload.encodeItem(item)
  -- ORDER : ID - progress
  local data = {}
  for k, v in pairs(p1.inventory) do
    --table.insert(data, v.name)
    table.insert(data, v.uuid)
  end
  --table.insert(data, quest.progress)
  return table.concat(data, "-")
end

function saveload.decodeItem(raw_data)
  local item = {}
  for uuid in string.gmatch(raw_data, "(%d+)") do
    table.insert(item, tonumber(uuid))
  end
  return item
end

--- TESTING ------------------------------
function saveload:save_test(saveNum)
  local saveNum = saveNum or 1
  local result  = 0

  test_data = saveload:newSave()
  test_data.mapInfo = "1-0-0-0"

  if platform == "DC" then
    raw_gamedata = table.saveString(test_data)
    result = C_saveSavefile(raw_gamedata, saveNum - 1)
  end

  if result == 1 then
    --audio.play(audio.sfx.success, 0.8, false)
    print("Saveload> Save done.")
  end
end

-- Loads and decodes if the fils is found
function saveload:load_test(saveNum)
  local result      = 0
  local saveNum     = saveNum or 1
  raw_loadedSavefile = ""

  -- LOADING THE SAVEFILE
  if platform == "DC" then
    result, data = C_loadSavefile(saveNum - 1)
    print("SAVELOAD.lua -> save " .. saveNum .. " = " .. result);
    if data ~= nil then
      raw_loadedSavefile = table.loadString(data)
      print("=== LUA TABLE ===")
      for k, v in pairs(raw_loadedSavefile) do
        print(tostring(k) .. "-" .. tostring(v))
      end
    else
      lua_loadedSavefile = nil
    end
  end
  -- Set the new data to
  if result == 1 then
    lua_loadedSavefile = saveload:decode(raw_loadedSavefile)
    --audio.play(audio.sfx.success, 0.8, false)
    print("Saveload> Loaded save file ".. saveNum .. ".")
  else
    lua_loadedSavefile = nil
  end

  return lua_loadedSavefile
end

-----------------------------------------

function saveload.restoreEmitters(emitters)
  local data = lua_loadedSavefile
  for i, v in ipairs(data.emit) do
    local name = string.lower(v.npcID)
    if emitters[name] then
      print("Restoring " .. name .. " at " .. v.desc_position)
      emitters[name].desc_position = v.desc_position
    else
      print("Creating " .. name .. " at " .. v.desc_position)
      hw.addEmitter(name, v.desc_position)
    end
  end

end

function saveload.restoreMapNpc(map)
  local data = lua_loadedSavefile
  local obj = {}

  if data == nil then
    print("SAVE> No loadfile data")
    return
  end

  if data[map.name] ~= nil then
    for i, v in ipairs(data[map.name]) do
      print(v.npcID)
      obj = map:getObject(v.npcID)
      if obj ~= nil then
        obj.canRepair     = v.canRepair
        obj.desc_position = v.desc_position
        print("updated " .. obj.npcID .. " from loaded file")
      end
    end
    -- THIS MIGHT BE A BIT ROUGH ??????????????
    data[map.name] = nil
  else
    print("SAVE> No loadfile data for this map")
  end
end

function saveload.getPath(saveNum)
  local saveNum = saveNum or 1
  local path = checkFile("savefile" .. saveNum .. ".txt")
  return path
end

function saveload.addNPC() end


return saveload
