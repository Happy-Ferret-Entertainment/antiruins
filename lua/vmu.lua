local vmu = {}

local logo

function vmu.init()
  if platform == "LOVE" then
    -- make all the function empty lol
  end
  vmu.timer = hump_timer.new()
  vmu.currentAnim = nil
  vmu.animTimer   = nil
  vmu.defaultIcon = nil
  vmu.isPlaying   = false

  --local repair = vmu.createAnimation("repair", 3, 0.25, 1)
  logo = vmu.createAnimation("logo", 1, 0, 0)
  vmu.playAnimation(logo, 1)

end

-- LCD Icons -----------------------------
function vmu.createAnimation(filename, frames, speed, priority)
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
    path = "asset/VMU/" .. filename .. ".bin"
    table.insert(a.icon, C_loadVMUIcon(path))
  else
    for i=1, frames do
      path = "asset/VMU/" .. filename .. i .. ".bin"
      print(path)
      table.insert(a.icon, C_loadVMUIcon(path))
    end
  end

  return a
end

function vmu.deleteAnimation(anim)

end

function vmu.setAnimation(anim, force)
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
  if vmu.isPlaying then
    return
  end

  if vmu.currentAnim ~= nil then
    if force or anim.priority > vmu.currentAnim.priority then
      vmu.timer:cancel(vmu.animTimer)
    else
      return
    end
  end

  local a = anim
  local repeats = repeats or 1
  local clearAfter = clearAfter

  vmu.isPlaying = true

  vmu.animTimer = vmu.timer:script(
    function(wait)
      for r=1, repeats do
        for i=1, a.length do
          C_drawVMUIcon(a.icon[i])
          wait(a.speed)
        end
      end

      -- AFTER PLAYING THE ANIMATION
      -- clears the current animation
      --vmu.currentAnim = nil
      vmu.isPlaying = false

      --[[
      if vmu.nextAnim ~= nil then
        vmu.playAnimation(vmu.nextAnim)
        vmu.nextAnim = nil
        return
      end
      --]]

      if clearAfter then
        vmu.playAnimation(logo)
        return
      end
    end)
end

function vmu.queueAnimation(anim)
  vmu.nextAnim = anim
end

function vmu.clearScreen()
  --vmu.playAnimation(logo)
  --C_clearVMUIcon()
end

-- Beeps -------------------------------------------
function vmu.playBeeps(beep, repeats)
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
