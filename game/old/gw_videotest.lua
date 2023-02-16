local globals     = require "globals"
--local profiler    = require "lib.profile"

local frameCount = 0
local videoPlayed = false
local queenVideo
local p1

function gameworld.create(startMap)
  queenVideo = video.load("asset/video/queensound.ogv")
  return 1
end

function gameworld.update(dt)
  if videoPlayed == false or input.getButton("A") then
    video.play(queenVideo)
    videoPlayed = true
  end
  --graphics.setClearColor(0,0,0,1)
  deltaTime = dt
  input.update()

  return 1
end

function gameworld.render(dt)
  graphics.setClearColor(0.3,0.3,0.3, 1)
  video.render(queenVideo)
  graphics.endFrame(true)
  return 1
end

function gameworld.free()

  return 1
end

return gameworld
