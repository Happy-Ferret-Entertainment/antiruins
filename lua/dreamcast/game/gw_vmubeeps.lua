local globals     = require "globals"
local gameworld   = require "gameworld"

realTime = 0
local t1 = 0
local v1, v2, v3 = 1, 1, 1

--[[
V1 = 5 // V2 = 2 --- smooth subtle rumble




]]

function gameworld.create(startMap)
  return 1
end

function gameworld.update(dt)
  realTime = realTime + dt
  input.update()


  if input.getButton("START") then
    C_setRumble(0, 0, 0)
  end

  if input.getButton("A") then
    C_setRumble(v1, v2, v3)
  end

  if input.getButton("X") then
    v1 = v1 + 1
    if v1 > 7 then v1 = 1 end
  end

  if input.getButton("Y") then
    v2 = v2 + 1
    if v2 > 7 then v2 = 1 end
  end

  if input.getButton("B") then
    v3 = v3 + 3
    if v3 > 50 then v3 = 1 end
  end

  return 1
end

function gameworld.render()
  graphics.setClearColor(0, 0, 1, 1)

  graphics.print("PURUPURU TESTER:", 20, 20)
  graphics.print("v1: " .. v1, 20, 40)
  graphics.print("v2: " .. v2, 20, 60)
  graphics.print("duration: " .. v3, 20, 80)
  return 1
end

function gameworld.free()
  return 1
end

return gameworld
