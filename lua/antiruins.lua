--[[
Main antiruin engine file.
This should be platform independant.
For the Dreamcast version, this should handles loading the game as well.
]]--

platform  = ""  -- current platform
game      = nil -- loaded gameworld
config    = {}  -- engine configuration
deltaTime = 0
cFrame    = 0
delayExit = 300


local libs = {
  lume        =  "lib.lume",
  --csv         =  "lib.csv",
  --flux        =  "lib.flux",
  --xml         =  "lib.xml",
  --json        =  "lib.json",
  maf         =  "lib.maf",
  --tableToFile =  "lib.tableToFile",
  --bit         =  "lib.bit",
  hump_signal =  "lib.hump_signal",
  hump_timer  =  "lib.hump_timer",

  --[[LANTERN]]--
  graphics    =  "graphicsLove",
  input       =  "input",
  audio       =  "audio",
  gameworld   =  "gameworld",
  gameObject  =  "gameobject",
  sprite      =  "sprite",
  --console     =  "console",
  --log         =  "log",
  --saveload    =  "saveload",
  --collision   =  "collision",
  --video       =  "video",
  vmu         =  "vmu",
  --player      =  "player",
  --script      =  "script",
  --map         =  "map",
  --dialog      =  "dialog2",
  --quest       =  "quest",

}

-- ROOT_PATH is the folder containing the dc and lua folder and all the game_*** folders.
ROOT_PATH   = "" -- root of the engine -> pc/ cd/ sd/
GAME_PATH   = "" -- game_**** folder containing the assets and .lua files
LOVE2D_PATH = "" -- require path for love 2D
LUA_PATH    = "" -- require path for lua

function initAntiruins(_platform)
  platform = _platform or "DC"
  print("antiruins.lua> Init Antiruins on " .. platform .. " platform.")

  LUA_PATH = package.path

  initDreamcast()
  initLove2D()

  loadLibs()
  initLibs()

  if config.loader then 
    GAME_PATH = "default"
  end

  --terrible name
  loadNewGame()

  return 0
end

function updateAntiruins(dt)
  deltaTime = dt
  cFrame    = cFrame + 1
  if input.getButton("START") then
    delayExit = delayExit - dt
    if delayExit < 0 then
      --exit()
    end
  else 
    delayExit = 300
  end
end

-- Process the data found in the config files.
function processConfig(configFile)
  print("=== Games in Config File ===")      
  for i, v in ipairs(configFile.games) do
      print("Found game: ", v.name, " at ", v.dir)
  end

  if configFile.loader == false then
    for k, v in pairs(configFile.games) do
      if v.name == configFile.defaultGame then
        GAME_PATH   = v.dir
      end
    end
  end

  return confData
end

function initDreamcast()
  if platform ~= "DC" then return end

  -- Init the DC specific fast maths
  initDCMath = function()
    --math.sin    = sh4_sin
    --math.cos    = sh4_cos
    --math.sqrt   = sh4_sqrt
    --math.sum_sq = sh4_sum_sq
    --math.lerp   = sh4_lerp
    --math.abs    = sh4_abs
  end

  mountRomdisk    = C_mountRomdisk
  unmountRomdisk  = C_unmountRomdisk

  libs.graphics = "graphics" -- switch from graphicsLove
  updatePathsDC()
  -- DC fast maths
  --initDCMath()
  _config, err = loadfile(ROOT_PATH .. "config.lua")
  if err then 
    print(err)
  else
    confData = _config()
    config    = processConfig(confData)
  end
end

function initLove2D()
  if platform ~= "LOVE" then return end

  ROOT_PATH = ""
  confData  = require "config"
  config    = processConfig(confData)

  if config.fullscreen then
    love.window.setFullscreen(true)
  end
  -- add the path added by the config file
  love.filesystem.setRequirePath(config.reqPath)
  -- grab the original LOVE2D path, in case we change game later on.
  LOVE2D_PATH = love.filesystem.getRequirePath()
  --print("LOVE2D_PATH = " .. LOVE2D_PATH)
end

function loadNewGame(newGamePath, gameFile)
  if game ~= nil then
    game.free()
  end
  -- secure this
  GAME_PATH = newGamePath or GAME_PATH

  -- update paths
  updatePathsDC()

  if gameFile then
    game, status = gameworld.loadfile(gameFile)
  else
    game, status = gameworld.load(GAME_PATH)
  end
  if game == nil then 
    print(status)
  else
    game.create()
  end
end

-- Find a file in multiple standard location
function findFile(filename)
  local dest = { "/rd/", "/cd/", "/sd/", "/pc/"}
  local f
  local wGame = ""

  if filename == nil then goto nofile end

  -- perfect filename without search
  f = io.open(filename, "r")
  if f then io.close(f) return filename end

  -- perfect filename without search
  f = io.open(ROOT_PATH .. filename, "r")
  if f then io.close(f) return ROOT_PATH .. filename end

  -- adding game for LOVE2d loading
  wGame = GAME_PATH .. "/" .. filename
  f = io.open(wGame, "r")
  if f then io.close(f) return wGame end

  -- adding the dreamcast paths
  for _, v in ipairs(dest) do
    f = v .. wGame
    --print("Trying file " .. f)
    file = io.open(f, "r")
    if file ~= nil then
      io.close(file)
      --print("Found " .. filename .. " at " .. v)
      return f
    end
  end

  ::nofile::
  print("antiruins.lua> Cannot find file " .. tostring(filename))
  return nil
end

-- Print how much memory lua is using
function printLuaMemory()
  local mem = collectgarbage("count") * 1024 / 1000
  print("MEM> " .. math.floor(mem) .. "kB")
end

-- Load all the libraries
function loadLibs()
  print("=== Loading Libraries ===")    
  local r = true;
  for k, v in pairs(libs) do
    local status, result = pcall(require, v)
    if status then
      --Assign the required table to the global lib name. eg: graphics / audio
      _G[k] = result --IMPORTANT
      if graphics ~= nil then
        local debug = 1
        print("lua libs > " .. k .. " loaded.")
      end
    else
      print( k .. " lib ERROR !!!! <----------- ")
      print(result)
      r = false;
    end
  end
  return r
end

-- Initialize all the libraries
function initLibs()
  print("=== Initialize Libraries ===")
    graphics.init(640, 480)
    audio.init(".mp3")
    input.init()
    --collision.init()
    vmu.init()
    --saveload.init()
end

-- THIS IS BROKEN (Libs names opackage)
function freeLibs()
  for k, v in pairs(package.loaded) do
    local moduleName = k
    if lantern.names[k] ~=  nil then
      print("Trying to delete " .. moduleName .. " module")
      package.loaded[moduleName] = nil
      v = nil
      if package.loaded[moduleName] ~= nil then
        print("Deleting the module " .. moduleName .." failed.")
      end
    end
  end
  lantern.loaded = false
  print(">> LANTERN IS DARK <<")
end

-- Add the proper path for Dreamcast
function updatePathsDC()
  if platform ~= "DC" then return end 
  -- root of are game, useful for DC dev
  ROOT_PATH = "cd/"

  -- check if PC path is present -- FOR DEVELOPPEMENT
  local pc = io.open("pc/lua/antiruins.lua", "r")
  if pc then
    ROOT_PATH = "pc/"
  end

  print("Antimeres.lua > Root path : " .. ROOT_PATH)
  -- adding different forlder to the lua search path
  local addToPath = {"assets", "lua", GAME_PATH}
  package.path = LUA_PATH

  for _, v in ipairs(addToPath) do
    package.path = package.path .. ";" .. ROOT_PATH .. v .. "/?.lua"
  end

end

-- Sleep function for Dreamcast
function sleep(s)
  local ntime = os.clock() + s/100
  repeat until os.clock() > ntime
end

function exit(status)
  local status = status or 0
  if platform == "DC" then
    C_exit(status)
  else
    love.event.quit(status)
  end
end

-- DC safe?
-- this function does create 2 different table.
function copy(t)
  if t == nil then print("PLATFORM> Trying to copy a nil table") end
  local u = {}
  for k, v in pairs(t) do u[k] = v end
  --return setmetatable(u, getmetatable(t))
  return u
end


return 1
