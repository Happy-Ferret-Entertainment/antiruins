local vmu = {}
local logo
local platform = platform
local tableToString = require "lib.datadump"

function vmu.init()
  if platform == "LOVE" then return end
  vmu.timer = hump_timer.new()
  vmu.currentAnim = nil
  vmu.animTimer   = nil
  vmu.defaultIcon = nil
  vmu.isPlaying   = false

  --local repair = vmu.createAnimation("repair", 3, 0.25, 1)
  --logo = vmu.createAnimation("logo", 1, 0, 0)
  --vmu.playAnimation(logo, 1)
end

-- LCD Icons -----------------------------
function vmu.createAnimation(filename, frames, speed, priority)
  if platform == "LOVE" then return end
  local a = {
    icon      = {}, --image data
    cFrame    = 1,
    length    = frames,
    speed     = speed,
    priority  = priority or 1,
    active    = false,
    filename  = filename,
}

  local path = ""
  if frames == 1 then
    path = GAME_PATH .. "/assets/vmu/" .. filename .. ".bin"
    table.insert(a.icon, C_loadVMUIcon(path))
  else
    for i=1, frames do
      path = GAME_PATH .. "/assets/vmu/" .. filename .. i .. ".bin"
      table.insert(a.icon, C_loadVMUIcon(path))
    end
  end
  print("VMU> Animation ".. filename .. " created with " .. frames .. " frames.")
  return a
end

function vmu.deleteAnimation(anim)
  if platform == "LOVE" then return end

end

function vmu.setAnimation(anim, force)
  if platform == "LOVE" then return end
  local force = force or false

  if vmu.currentAnim ~= nil then
    if force or anim.priority > vmu.currentAnim.priority then
      print("VMU> Setting " .. anim.filename .. " as LCD anim over " .. vmu.currentAnim.filename)
      vmu.timer:cancel(vmu.animTimer)
    else
      print("VMU> " .. anim.filename .. " doesn't have priority.")
      return
    end
  end

  local a = anim
  if a.length > 1 then
    vmu.animTimer = vmu.timer:every(a.speed,
      function()
        C_drawVMUIcon(a.icon[a.cFrame])
        a.cFrame = a.cFrame + 1

        -- watch for turnover
        if a.cFrame > a.length then
          a.cFrame = 1
        end
      end)
  else
    C_drawVMUIcon(a.icon[1])
  end

  vmu.currentAnim = anim

end

function vmu.playAnimation(anim, repeats, clearAfter, force)
  local a = anim
  local repeats = repeats or 1
  local clearAfter = clearAfter

  vmu.isPlaying = true

  vmu.animTimer = vmu.timer:every(
    a.speed,
    function()
      -- -1 for C stuff
      C_drawVMUIcon(a.icon[a.cFrame])
      a.cFrame = a.cFrame + 1
      
      if a.cFrame > a.length then
        a.cFrame = 1
        repeats = repeats - 1
      end

      if repeats == 0 and clearAfter then
        C_clearVMUIcon()
        return false
      end
    end,
    a.length * repeats)
end

function vmu.queueAnimation(anim)
  if platform == "LOVE" then return end
  vmu.nextAnim = anim
end

function vmu.clearScreen()
  vmu.timer:cancel(vmu.animTimer)
  C_clearVMUIcon()
end

-- Saves --------------------------------
function vmu.initSavefile(gameName, saveName, descLong, descShort, saveID)
  saveID = saveID or -1
  local vmuID = C_initSavefile(gameName, saveName, descLong, descShort, saveID)
  return vmuID
end

function vmu.checkForVMU()
  return C_checkForVMU()
end

function vmu.checkForSave(vmuID)
  return C_checkForSave(vmuID)
end

function vmu.saveGame(vmuID, data)
  if type(data) == "table" then
    --local _d = {}
    --_d[1] = "return { "
    --_d[2] = table.saveString(data)
    --_d[3] = " }"
    data = DataDumper(data)
    --print(data)
  end
  return C_saveGame(data, vmuID)
end

function vmu.loadGame(vmuID)
  local rawSave = C_loadGame(vmuID) or "return {}"
  local saveData = {}

  local _t = load(rawSave)()
  if type(_t) == "table" then
    for _k, _v in pairs(_t) do
      saveData[_k] = _v
    end
  end

  return saveData
end

function vmu.addToSave(vmuData, newData)
  if type(vmuData) ~= "table" then return end

  for k, v in pairs(newData) do
    vmuData[k] = v
  end
end

function vmu.deleteGame(vmuID)
  return C_deleteGame(vmuID)
end


-- Beeps -------------------------------------------
function vmu.playBeeps(beep, repeats)
  if platform == "LOVE" then return end
  vmu.timer:script(function(wait)
    -- number of time to repeat the sequence
    for r=1, repeats do
      -- actual sequence
      for i=1, #beep, 2 do
        --print("VMU BEEP:" .. beep[i] .. " for " .. beep[i+1])
        C_setVMUTone(beep[i])
        wait(beep[i+1])
      end
    end
    C_setVMUTone(0)
  end)
end

function vmu.update(dt)
  vmu.timer:update(dt)
end




-------------------------------------


return vmu
