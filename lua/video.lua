local video = {}

local V_DONE    = 1
local V_PLAYING = 2

local skipDelay = 100
local videoStatus = 0

function video.load(filename)
  local filename = findFile(filename)

  local vid = {
    filename  = filename,
    source    = nil, -- for love.video
    length    = 0,
    isPlaying = false,
  }

  if platform == "LOVE" then
    vid.source = love.graphics.newVideo(filename)
    print(vid.source)
    if vid.source == nil then
      print("VIDEO> Invalid video file")
      return nil
    end
  end

  if platform == "DC" then
    local f = string.sub(vid.filename, 1, -4)
    vid.filename = findFile(f .. "roq")
    print(vid.filename)
  end

  return vid
end

function video.play(vid)
  if platform == "LOVE" then
    vid.source:play()
  else
    videoStatus = C_startVideo(vid.filename)
  end
end

function video.render(vid)
  if platform == "LOVE" then
    if vid.source:isPlaying() then
      love.graphics.draw(vid.source)
    else
    end
  else
  end
end

function video.isDone(vid)
  if platform == "LOVE" then
    return not vid.source:isPlaying()
  else
    if videoStatus == V_DONE then
      return true
    else
      return false
    end
  end
end


return video
