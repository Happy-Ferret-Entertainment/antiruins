
paths = {
  asset = "asset/",
  cd = "cd/",
  pc = "pc/",
  rd = "rd/",
  origin = nil
}

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
  graphics    =  "graphics",
  console     =  "console",
  input       =  "input",
  audio       =  "audio",
  gameworld   =  "gameworld"
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
  --gameObject  =  "gameobject",
}

function loadLibs()
  local r = true;
  for k, v in pairs(libs) do
    --package.loaded[v] = require("pc/LANTERN_ENGINE/" .. v)
    local status, result = pcall(require, v)
    if status then
      --print("LANTERN > " .. k .. " lib loaded.")
      --Assign the required table to the global lib name. eg: graphics / audio
      _G[k] = result --IMPORTANT
      if graphics ~= nil then
        local debug = 1
        print("lua libs > " .. k .. " loaded.")
        graphics.printDebug("lua libs > " .. k .. " loaded.")
        graphics.renderFrame()
      end
    else
      print( k .. " lib ERROR !!!! <----------- ")
      print(result)
      graphics.printDebug( k .. " lib ERROR !!!! <----------- ", color.RED)
      graphics.renderFrame()
      r = false;
    end
  end
  graphics.printDebug(">> lua libs loaded.")
  graphics.renderFrame()
  return r
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

function initPlatform()
  local status = 1

  platform = "DC"
  -- rewrite this bullshit into somwething more consize.
  package.path = package.path .. ";./asset/?.lua" .. ";/lua/?.lua"
  package.path = package.path .. ";cd/?.lua" .. ";pc/?.lua"
  package.path = package.path .. ";cd/asset/?.lua" .. ";pc/asset/?.lua"
  package.path = package.path .. ";cd/lua/?.lua" .. ";pc/lua/?.lua"

  paths.origin = findAssetLocation()

  local libraryLoaded = loadLibs()

  -- LUA 5.3 doesn't have loadstring. Must need this
  loadstring = load
  -- Clocks replace
  os.clock = C_clock

  -- Dreamcast Maths
  math.sin    = sh4_sin
  math.cos    = sh4_cos
  math.sqrt   = sh4_sqrt
  math.sum_sq = sh4_sum_sq
  math.lerp   = sh4_lerp
  math.abs    = sh4_abs

  love = require "love2dream"
  setLOVEfunctions()

  --collectgarbage("setpause", 75)
  --collectgarbage("setstepmul", 100) -- default 200
  --collectgarbage("stop", 100)

  print("PLATFORM> Dreamcast init sucess")
  return status
end

function loadGameworld(file)
  local f = findFile(file)
  local gameworld = {}

  if f then
    if platform == "LOVE" then
      --gameworld = dofile(f)
      gameworld = love.filesystem.load(f)()
    else
      gameworld = dofile(f)
    end
  else
    print("Platform.lua> Gameworld file error.")
  end

  if gameworld ~= nil then
    return gameworld
  else
    return 0
  end
end
-- Middle file class

function initMiddleFile()
  local _io = {}
  function _io:seek(mode, position)
    local cPos = self.pos
    if      mode == "set" then
      self.loveFile:seek(position)
      --self.pos = position
    elseif  mode == "cur" then
      self.loveFile:seek(cPos + position)
    elseif  mode == "end" then
      -- pas sur ca marche ça
      --self:seek(self:getSize() + position)
    end
    --print("Current seek = " .. self.loveFile:tell())
    return self.pos
  end

  function _io:read(mode)
    if mode == "*line" then
      return self.line()
    end
  end

  function _io.open(filename, mode)
    local file = {
      loveFile = nil,
    }
    file.loveFile = love.filesystem.newFile(filename)
    if file.loveFile == nil then
      print("PLATFORM> [filesystem] can't open : " .. filename)
      return nil
    else
      print("PLATFORM> [filesystem] open : " .. filename)
    end
    file.loveFile:open(mode)
    file.seek = _io.seek
    file.read = _io.read
    file.pos  = 0
    file.line = love.filesystem.lines(filename)
    return file
  end
  io = _io
end

-- LOVE --------------------------------
function disableDCFunctions()
  C_drawVMUIcon   = function() end
  C_loadVMUIcon   = function() return 1 end
  C_freeVMUIcon   = function() end
  C_clearVMUIcon  = function() end
  C_setVMUTone    = function() end
  C_setRumble     = function() end

  C_addToBatch  = function() end
  C_addToBatch2  = function() end
  C_startBatch  = function() end
  C_endBatch    = function() end
  C_endBatch2    = function() end

  sh4_distance = function(x1, y1, x2, y2)
    local x, y = x1 - x2, y1 - y2
    return math.sqrt(x * x + y * y)
  end

  sh4_vecLength = function(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
  end

  sh4_vecNormalize = function(x, y, z)
    local v = maf.vector(x, y, z)
    --return unpack(v:normalize())
  end
end


-- DC RELATED ---------------------------

function setDCFuntions()

end

function printLuaMemory()
  local mem = collectgarbage("count") * 1024 / 1000
  print("MEM> " .. math.floor(mem) .. "kB")
end

function setSourceDirectory()
  if love.filesystem.isFused() then
    local dir = love.filesystem.getSourceBaseDirectory()
    local success = love.filesystem.mount(dir, "source")
    print(dir)
    if success then
        -- If the game is fused and it's located in C:\Program Files\mycoolgame\,
        -- then we can now load files from that path.
        print("Platform> Fused directory ??? mounted the source dir")
    end
  end
end

function getScriptFolder()
    if      platform == "DC" then return paths.cd .. paths.script
    elseif  platform == "DC_PC" then return paths.cd .. paths.script
    else return paths.script end
  return ""
end

function getAssetFolder()
    if platform == "DC" then
      return paths.cd
    else
      return paths.asset
    end
  return nil
end

function findFile(filename)
 local dest = { "/rd/", "/cd/", "/sd/", "/pc/"}

 local f
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


-- peice of shit
function checkFile(og_filename)
  local filename = og_filename
  local file = nil

  if platform == "LOVE" then
    local info = {}
    info = love.filesystem.getInfo(filename, info)
    if info ~= nil then
      return filename
    else
      print("PLATFORM> Can't find " .. filename)
      return nil
    end
  end

  if platform == "DC" then
    -- Check with the original filename
    file = io.open(filename, "r")
    if file == nil then
      filename = paths.origin .. og_filename
      file = io.open(filename, "r")
    end

    if file ~= nil then
      --print("LUA > Found " .. og_filename)
      io.close(file)
      return filename
    else
      print("LUA > Can't find " .. og_filename)
      return nil
    end
  end
end

function findAssetLocation()
  local pc = io.open("/pc/gw_summoning.lua", "r")
  if pc then
    print("Location PC is available. Selected PC")
    paths.cd = paths.pc
    return "pc/"
  end

  local cd = io.open("/cd/gw_summoning.lua", "r")
  if cd then
    print("Location CD is available. Selected CD")
    paths.cd = paths.cd
    return "cd/"
  end
end

function reloadModule(name)
  local testModule = require(name)

  if testModule ~= nil then
    package.loaded[name] = nil
    return testModule
  else
    print("Tried to load module " .. name .. " but failed. !!!!!!!!!!!!!")
    return 0
  end
end

function sleep(s)
  local ntime = os.clock() + s/100
  repeat until os.clock() > ntime
end

-- DC safe?
function copy(t)
  if t == nil then print("PLATFORM> Trying to copy a nil table") end
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end

--[[
-- Save copied tables in `copies`, indexed by original table.
-- DANGEROUS ON DREAMCAST!!!!!!
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



function copy(obj, seen)
  -- Handle non-tables and previously-seen tables.
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end

  -- New table; mark it as seen an copy recursively.
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end
--]]


return 1
