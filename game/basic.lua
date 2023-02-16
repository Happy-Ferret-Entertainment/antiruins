--local globals     = require "globals"
local gameworld   = require "gameworld"

local x, y = 320 ,240
local sfx1
local image

function gameworld.create()
  sfx1  = audio.load("sfx/login.wav", "SFX")
  image = graphics.loadTexture("assets/cat.png")
  return 1
end

function gameworld.update(dt)
  local axis  = input.getAxis(1)
  x = x + axis.x/100.0
  y = y + axis.y/100.0

  if input.getButton("A", 1) then
    x, y = 320, 240
  end
  return 1
end

function gameworld.render()
  graphics.setClearColor(0, 0, 1, 1)
  graphics.print("Anti<------------->ruins", 20, 20)
  graphics.drawTexture(image, nil, x, y)  
  return 1
end

function gameworld.free()
  return 1
end

return gameworld
