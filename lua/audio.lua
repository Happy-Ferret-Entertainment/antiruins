local audio = {
  load = function() end,
  play = function() end,
  stop = function() end,
  free = function() end,
}

local source = {
  loaded    = false,
  id        = 0,
  channel   = -1,
  volume    = 220, --0, 254
  isPlaying = false,
  type      = "stream",
  duration  = 0,
  playUntil = 0,
}

local s1, s2
local effect = {
  source = nil,
  action = "fadein", -- "fadeout"
  lenght = 0,
  start = 0
}

local actions = {}

function audio.init(_format)
  audio.sfx = {}
  print("AUDIO> Init done")
end

function audio.update(dt)
end

-- type are "static/SFX" or "stream"
function audio.load(filename, sfxType, duration)
  local sfx = copy(source)
  local sfxType = sfxType or "stream"
  sfxType = string.lower(sfxType)

  if      sfxType == "stream" then
    --filename    = string.sub(filename, 1, #filename-4)
    --filename    = audio_path ..filename .. audio_format
    sfx.id      = tonumber(filename)
    sfx.loaded  = true
    sfx.type    = sfxType
  elseif  sfxType == "sfx" then
    sfx.id        = C_loadSFX(filename, "SFX")
    sfx.loaded   = true
    sfx.type     = sfxType
    sfx.duration = duration or 0
  end
  return sfx
end

function audio.free(source)
  if source.loaded == false then source = nil return end
  
  if source.type == "sfx" then
    C_freeSFX(source.id)
  end

  source = nil
end

function audio.play(source, volume, loop)
  if source == nil then return end  
  local volume  = volume or source.volume
  local loop    = loop or false
  local sfxType = source.type

  source.volume = lume.clamp(volume, 0, 254)

  if        sfxType == "sfx" then 
    source.channel = C_playSFX(source.id, source.volume)
    return source.channel

  elseif    sfxType == "stream" then
    if source.isPlaying == false then
      if loop then
        C_playCDDA(source.id, source.volume, 1)
      else
        C_playCDDA(source.id, source.volume, 0)
      end
      source.isPlaying = true
    end
  end
end

function audio.stop(source)
  if source == nil then return end

  if source.isPlaying then
      C_pauseCDDA()
      source.isPlaying = false
  end
end

function audio.pause(source)
  audio.stop(source)
end

function audio.resume(source)
  if source == nil then return end

  if source.isPlaying == false then
      C_resumeCDDA()
      source.isPlaying = true
  end
end

function audio.setVolume(source, volume)
  if source.loaded == false then return end
  source.volume = lume.clamp(volume, 0, 254)


  if source.type == "sfx" then
    C_setChannelVolume(source.channel, source.volume)
  else
    C_setCDDAVolume(source.volume)
  end
end

function audio.pan(source, pan)
  if source == nil then return end
  if platform == "LOVE" then
    --source.setVolume(volume)
  end
end

function audio.setLoop(source, loop)
  if source.loaded == false then return end
  local loop = loop or false
  if platform == "LOVE" then
    source.id:setLooping(loop)
  end
end

function audio.isPlaying(source)
  if source == nil            then return false end
  if source.type ~= "stream"  then return false end

  -- Currently only work with CDDA tracks
  --source.isPlaying = C_isPlaying(source.id)

  return source.isPlaying
end

return audio
