globals     = require "globals"
gameworld   = require "gameworld"
player      = require "player"
hardware    = require "hardware"
signal      = require "signal"
weather     = require "weather"
itemList    = require "item_list"
--local profiler    = require "lib.profile"

local obj = {}
local saved, loaded = false, false

function gameworld.create(startMap)
  p1 = player:new()
  return 1
end

function gameworld.update(dt)
  --input.update()
  --p1:updatePlayer()


  realTime = realTime + dt
  --print(realTime)

  if realTime > 31 and saved == false then
    saveload:save_test()
    saved = true
  end

  if realTime > 32 and saved == true and loaded == false then
    saveload:load_test()
    saved = true
    loaded = true
  end

  --]]
  --if p1:getButton("B") then

  --end
  return 1
end

function gameworld.render()
  return 1
end

function gameworld.free()

  return 1
end

return gameworld
