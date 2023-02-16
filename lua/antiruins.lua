platform  = ""  -- current platform
game      = nil -- loaded gameworld

local libs = {
  lume        =  "lib.lume",
  flux        =  "lib.flux",
  xml         =  "lib.xml",
  json        =  "lib.json",
  maf         =  "lib.maf",
  tableToFile =  "lib.tableToFile",
  bit         =  "lib.bit",
  hump_signal =  "lib.hump_signal",
  hump_timer  =  "lib.hump_timer",

  --[[LANTERN]]--
  graphics    =  "graphicsLove",
  console     =  "console",
  input       =  "input",
  audio       =  "audio",
  gameworld   =  "gameworld",
  gameObject  =  "gameobject",

  --log         =  "log",
  --saveload    =  "saveload",
  --collision   =  "collision",
  --video       =  "video",
  --vmu         =  "vmu"
  --player      =  "player",
  --script      =  "script",
  --map         =  "map",
  --dialog      =  "dialog2",
  --quest       =  "quest",

}

-- Init all the main complnent and search for Paths, etc.
function initAntiruins(_platform)

  --[[
  very old platform argument
  i'm ok with doing platform check on init
  but not in function that are called over and over.
  ]]--
  platform = _platform or "DC"

  
  if platform == "DC" then
    libs.graphics = "graphics" -- switch from graphicsLove
    updatePathsDC()
    -- DC fast maths
    initDCMath()
  end


  -- load antiruins game libraries
  loadLibs()
  initLibs()
  print("antiruins.lua> Init Complete.")
  return 1
end

function updatePathsDC()
  -- root of are game, useful for DC dev
  local rootPath = "cd/"

  -- check if PC path is present -- FOR DEVELOPPEMENT
  local pc = io.open("pc/lua/antiruins.lua", "r")
  if pc then
    rootPath = "pc/"
  end

  print("Antimeres.lua > Root path : " .. rootPath)
  -- adding different forlder to the lua search path
  local addToPath = {"assets", "lua", "game"}
  for _, v in ipairs(addToPath) do
    local p = ";" .. rootPath .. v .. "/?.lua"
    package.path = package.path .. p
  end
end

function loadGameworld(file)
  local f         = findFile(file)
  local status    = 1

  if f then
    if platform == "LOVE" then
      local ok, chunk, err = pcall(love.filesystem.load, f)
      game = chunk()
    else
      game = dofile(f)
    end
  else
    print("antiruins.lua> Cannot find gameworld " .. file)
  end

  if game then
    print("antiruins.lua> Gameworld loaded.")
    status = 0
  end

  return status, game
end

-- Find a file in multiple standard location
function findFile(filename)
  local dest = { "/rd/", "/cd/", "/sd/", "/pc/"}
  local f

  -- perfect filename without search
  f = io.open(filename, "r")
  if f then io.close(f) return filename end

  -- adding game for LOVE2d loading
  local wGame = "game/" .. filename
  f = io.open(wGame, "r")
  if f then io.close(f) return wGame end

  for _, v in ipairs(dest) do
    f = v .. filename
    --print("Trying file " .. f)
    file = io.open(f, "r")
    if file ~= nil then
      io.close(file)
      --print("Found " .. filename .. " at " .. v)
      return f
    end
  end
end

-- Print how much memory lua is using
function printLuaMemory()
  local mem = collectgarbage("count") * 1024 / 1000
  print("MEM> " .. math.floor(mem) .. "kB")
end


function loadLibs()
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

function initLibs()
  print("== Initialize Systems ==")
    graphics.init(640, 480)
    local fontFile = findFile("game/assets/spacemono.png")
    graphics.loadFont(fontFile, 15, 16)
    audio.init(".mp3")
    input.init()
    --collision.init()
    --vmu.init()
    --saveload.init()
    print("== Initialize System Done ==")
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

function initDCMath()
  math.sin    = sh4_sin
  math.cos    = sh4_cos
  math.sqrt   = sh4_sqrt
  math.sum_sq = sh4_sum_sq
  math.lerp   = sh4_lerp
  math.abs    = sh4_abs
end

-- sleeps for
function sleep(s)
  local ntime = os.clock() + s/100
  repeat until os.clock() > ntime
end

-- DC safe?
-- this function does create 2 different table.
function copy(t)
  if t == nil then print("PLATFORM> Trying to copy a nil table") end
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end


return 1
