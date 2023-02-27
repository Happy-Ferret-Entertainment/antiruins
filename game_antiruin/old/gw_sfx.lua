local frameCount = 0
local song
local path

local sfx1, sfx2


realTime    = 0

function gameworld.create(startMap)
  sfx1 = audio.load("sfx/pick.wav", "SFX", 2.77)
  sfx2 = audio.load("sfx/login.wav", "SFX")
  return 1
end

function gameworld.update(dt)
  realTime = realTime + dt
  input.update()

  if input.getButton("A") then
    audio.play(sfx2, 127)
  end

  frameCount = frameCount + 1
  return 1
end

function gameworld.render(dt)
  graphics.endFrame()
  return 1
end

function gameworld.free()

  return 1
end

return gameworld
