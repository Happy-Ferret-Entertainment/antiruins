local game = {}

local cdda_track_1, click_sound
local volume  = 255
local loop    = true

function game.create()
  graphics.loadFont(findFile("assets/MonofontSmall.dtex"), 16, 8, 0)

  cdda_track_1  = audio.load(6, "stream")
  click_sound   = audio.load(findFile("default/login.wav"), "sfx")

  -- source, volume, loop.
  audio.play(cdda_track_1, volume, loop)

end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end


  if input.getButton("A") then
    if audio.isPlaying(cdda_track_1) then
      audio.pause(cdda_track_1)
    else
      audio.resume(cdda_track_1)
    end
  end

  if input.getButton("X") then
    audio.play(click_sound, 240)
  end

  if input.getButton("DOWN")  then audio.setVolume(cdda_track_1, cdda_track_1.volume - 35) end
  if input.getButton("UP")    then audio.setVolume(cdda_track_1, cdda_track_1.volume + 35) end
  
end

function game.render()
  graphics.setClearColor(0.1,0.1,0.1,1.0)

  if audio.isPlaying(cdda_track_1) then
    graphics.print("Playing CDDA track.", 20, 20)
    graphics.print("Volume:" .. tostring(cdda_track_1.volume), 20, 40)
    graphics.print("Loop:" .. tostring(loop), 20, 60)
  else
    graphics.print("CDDA paused.", 20, 20)
  end

  graphics.print("Press A to pause/resume.", 20, 100)
  graphics.print("Press UP/DOWN to change volume.", 20, 120)
  graphics.print("Press X to play a SFX sound.", 20, 140)
end

return game