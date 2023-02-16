globals   = require "globals"
local gw  = require "gameworld"
local repair = require "repair"
local player = require "player"

function gameworld.create()
  p1 = player.new()
  repair:onLoad()
  repair:activate()
  return 1
end

function gameworld.update()
  input.update()
  repair:update()
  return 1
end

function gameworld.render()
  repair:render()
  return 1
end


return gw
