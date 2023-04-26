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
  volume    = 210, --0, 254
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
local audio_path = "game/"
local audio_format --from C

function audio.init(_format)
  if platform == "LOVE" then
    if love.audio.isEffectsSupported( ) then
      print("AUDIO> effect supported")
    end
  end
  audio_format = AUDIO_FORMAT or _format
  audio.sfx = {}
  --audio.loadDefault()
  print("AUDIO> Init done (format: " .. tostring(audio_format) .. ")")
end

function audio.update(dt)
  for i,v in ipairs(actions) do
    if      v.action == "fadein" then
      audio.fade(v, "fadein")
    elseif  v.action == "fadeout" then

    else

    end
  end
end

-- type are "static/SFX" or "stream"
function audio.load(filename, type, duration)
  local sfx = copy(source)
  local type = type or "stream"

  local f = findFile(filename)
  if f == nil then 
    print("AUDIO> Returning empty audio SFX table :")
    return sfx 
  end


  if platform == "LOVE" then
    type    = type or "static"
    if type == "SFX" or type == "sfx" then
      type = "static"
    end

    sfx.type      = type
    sfx.id        = love.audio.newSource(f, type)
    sfx.loaded    = true
    sfx.duration  = duration or 0
    print("AUDIO> Loaded file " .. f)
    return sfx
  end

  if platform == "DC" then
    if type == "stream" then
      filename    = string.sub(filename, 1, #filename-4)
      filename    = audio_path ..filename .. audio_format
      sfx.id      = findFile(filename)
      if sfx.id ~= nil then
        sfx.loaded  = true
        sfx.type    = type
      end
      return sfx
    end
    if type == "SFX" or type == "sfx" or type == "static" then
      filename    = string.sub(filename, 1, #filename-4)
      filename    = audio_path .. filename .. ".wav"
      filename    = findFile(filename)
      sfx.id      = C_loadSFX(filename, "SFX")
      sfx.loaded   = true
      sfx.type     = type
      sfx.duration = duration or 0
    end
    return sfx
  end
end

function audio.free(source)
  if source.loaded == false then source = {} return end

  if platform == "LOVE" then
    source.id = nil
    source = nil
  end

  if platform == "DC" then
    C_freeSFX(source.id)
  end
end

function audio.play(source, volume, loop, type)
  if source == nil or source.loaded == false then return end
  local volume = volume or source.volume
  local loop = loop or false
  local type = type or source.type

  if platform == "LOVE" then
    source.id:setVolume(volume)
    love.audio.play(source.id)
    --source.isPlaying = true
    --if source.type == "stream" then source.isPlaying = true end
    if loop then source.id:setLooping(true) end
  end

  if platform == "DC" then
    volume = math.min(volume, 254)
    if type == "stream" then
      if source.isPlaying == false then
        if loop then
          C_streamFile(source.id, volume, 1)
        else
          C_streamFile(source.id, volume, 0)
        end
        source.isPlaying = true
      end

    else -- SFX
      if source.playUntil > realTime then return end
      source.channel = C_playSFX(source.id, volume, 127)
      source.isPlaying = true
    end
  end

  source.playUntil = realTime + source.duration
end

function audio.stop(source)
  if source == nil then return end
  if platform == "LOVE" then
    if audio.isPlaying(source) then
      print("Stopping a source")
      love.audio.stop(source.id)
    end
  else
    if audio.isPlaying(source) then
      C_stopStream();
      source.isPlaying = false
    end
  end
end

function audio.addEffect(source, type, lenght)
  if source == nil then return end

  local effect = effect
  local type = type or "none"
  local lenght = lenght or 1.0

  effect.source = source
  effect.type = type
  effect.lenght = lenght
  effect.start = realTime

  table.insert(actions, effect)
end

function audio.fade(effectSource, type)
  if source == nil then return end
  local s = effectSource
end

function audio.crossfade(source1, source2, length)
  --local
end

function audio.setVolume(source, volume)
  if source.loaded == false then return end

  if platform == "LOVE" then
    volume = volume / 256
    --print("Setting volume to " .. volume)
    source.id:setVolume(volume)
  else --DC
    volume = math.min(volume, 254)
    C_setChannelVolume(source.channel, volume)
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
  if source == nil then return end
  if source.loaded == false then return nil end
  if platform == "LOVE" then
    source.isPlaying = source.id:isPlaying()
    return source.isPlaying
  else
    C_isPlaying(source.id)
    return source.isPlaying
  end
end

function audio.getVolume(source)
  if ssource.loaded == false then return end
  if platform == "LOVE" then
    return source.id:getVolume()
  end
end

function audio.getDuration(source)
  if source.loaded == false then return end
  if platform == "LOVE" then
    return source.id:getDuration("seconds")
  end
end


return audio
