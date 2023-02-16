globals   = require "globals"
local gw  = require "gameworld"
local puzzle    = require "puzzle"

local puz1
local init = {
  0,0,1,0,0,
  1,1,0,0,1,
  1,0,0,1,0,
  0,1,2,3,1,
  0,0,1,1,0,
}
local solution = {
  0,0,1,0,0,
  1,1,0,0,1,
  1,0,3,1,0,
  0,1,2,0,1,
  0,0,1,1,0,
}


function gameworld.create()
  puzzle.init()
  puz1 = puzzle:new(5, 5, init, solution)

  return 1
end

function gameworld.update()
  input.update()
  puz1:update()

  return 1
end

function gameworld.render()
  puz1:render()

  return 1
end


return gw
