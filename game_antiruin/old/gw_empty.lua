local globals     = require "globals"
local gameworld   = require "gameworld"

function gameworld.create(startMap)
  return 1
end

function gameworld.update(dt)
  input.update()
  return 1
end

function gameworld.render()
  graphics.setClearColor(0, 0, 1, 1)
  return 1
end

function gameworld.free()
  return 1
end

return gameworld
