globals   = require "globals"
local gw  = require "gameworld"
local player = require "player"

local vmuAnim
local saveInfo
local mIndex = 1

function gameworld.create()
  p1 = player.new()
  saveload.updateSaveInfo()
  saveInfo = saveload.getSaveInfo()
  vmuAnim = vmu.createAnimation("radio", 3, 0.25, 1)

  map.init()
  currentMap = map:load("crash", false)
  return 1
end

function gameworld.update(dt)
  input.update()
  vmu.update(dt)

  if input.getButton("DOWN") then mIndex = math.min(mIndex + 1, 3) end
  if input.getButton("UP")   then mIndex = math.max(mIndex - 1, 1) end
  if input.getButton("A")    then
    saveload:save(mIndex)
    saveload.updateSaveInfo()
    saveInfo = saveload.getSaveInfo()
  end

  vmu.playAnimation(vmuAnim)

  return 1
end

function gameworld.render()
  graphics.print("Summoning Signals VMU Tester", 20, 20)
  printVmuData()
  return 1
end

function printVmuData()
  local c, c1, c2 = {1,1,1,1}, 20, 100
  local s = "No game file."

  for i, v in ipairs(saveInfo) do
    if v.map == "" then

    else
      c = color.WHITE
      if mIndex == i then
        --graphics.label("<< Load.", 480,   80 + (i-1) * 30, color.ACTIVE)
        c = color.ACTIVE
      end
      s = "G" .. i .. " > " .. v.map .. " " .. math.floor(v.time/60) .. " mins"
    end
    graphics.print(s, c1, 40 + (i * 20), c)
  end

end


return gw
