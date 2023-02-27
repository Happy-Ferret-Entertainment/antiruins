local globals     = require "globals"
local gameworld   = require "gameworld"

local moodel

function gameworld.create(startMap)
  --[[
  model = graphics.loadObj(
  "asset/models/fountain/fountain.obj",
  "asset/models/fountain/Fonstaine-Ana-RAW.png"
  )
  ]]--

  model = graphics.loadObj(
  "asset/models/cube.obj",
  "asset/models/fountain/Fonstaine-Ana-RAW.png"
  )


  graphics.addModel(model)
  --model:setTransform({0, 0, -3})


  return 1
end

function gameworld.update(dt)
  return 1
end

function gameworld.render()
  graphics.setClearColor(0, 0, 1, 1)
  graphics.setDrawColor(0,0,0,1)
  graphics.endFrame()
  return 1
end

function gameworld.free()
  return 1
end

return gameworld
