local globals     = require "globals"
--local profiler    = require "lib.profile"

local frameCount = 0
local song
local path

local titles = {
  "mountainpath", "reine", "roches_keys",
  "echelles_explo", "crash", "title_screen"
}

function gameworld.create(startMap)
  path = "bgm/" .. lume.randomchoice(titles) .. ".mp3"
  song = audio.load(path, "stream")
  audio.play(song)
  return 1
end

function gameworld.update(dt)
  deltaTime = dt
  input.update()

  if input.getButton("A") then
    audio.stop(song)
    path = "bgm/" .. lume.randomchoice(titles) .. ".mp3"
    song = audio.load(path, "stream")
    audio.play(song)
  end

  return 1
end

function gameworld.render(dt)
  graphics.print(path, 20, 240, {1,0,0,1})
  graphics.endFrame(true)
  return 1
end

function gameworld.free()

  return 1
end

return gameworld
