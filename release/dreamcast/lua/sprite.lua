local lume = require "lib.lume"
local sprite = {}


sprite.__index = sprite
setmetatable(sprite, {__call = function(cls, ...) return csl.new(...) end,})

function sprite.new(spritefile, texture, col, row)
  local spritesheet  = {
    frames    = {},
    cFrame    = 1,
    maxFrame  = 1,
    direction = 1,
    texture   = {},
    timer     = {}, --timer handle
    stopAnimation = false,
  }

  -- Load the spritesheet data
  if spritefile then
    sprite_data         = loadfile(spritefile)()
    if sprite_data == nil then
      print("Error loading spritesheet data " .. spritefile)
      return nil
    end
    spritesheet.frames    = sprite_data.frames
    spritesheet.maxFrame  = #spritesheet.frames
  end

  if col and row then
    print("Sprite.lua> Using Col&Row for sprite")
    spritesheet.uv = {
      w = texture.w / col,
      h = texture.h / row,
    }

    for i = 0, row - 1 do
      for j = 0, col - 1 do
        local frame = {
          x = j * spritesheet.uv.w,
          y = i * spritesheet.uv.h,
          w = spritesheet.uv.w,
          h = spritesheet.uv.h,
          center = {
            x = 0,
            y = 0,
          }
        }
        table.insert(spritesheet.frames, frame)
      end
    end
    spritesheet.maxFrame = #spritesheet.frames
  end

  -- This is a full texture object
  spritesheet.texture = texture

  local self = setmetatable(spritesheet, sprite)
  return self
end

function sprite.setTimer(newTimer)
  timer = newTimer
end

function sprite:getCopy()
  local new = copy(self)
  
  new.texture = copy(self.texture)
  new.frames  = copy(self.frames)

  print("Copied frames " .. #new.frames)

  local spritecopy = setmetatable(new, sprite)
  return spritecopy

end

function sprite:draw(x, y, frame)
  local f = self.frames[frame] or self.frames[self.cFrame]
  --print(self.cFrame)
  if f == nil then return end
  local spriteID = graphics.drawTexture(self.texture, x + f.center.x, y - f.center.y)
  graphics.setSpriteUV(spriteID, f)
end

function sprite:nextFrame()
  local direction = self.direction or 1
  self.cFrame = lume.clamp(self.cFrame + direction, 1, self.maxFrame)
  return self.cFrame
end

function sprite:loop(speed, startFrom, endFrame)
  local startFrom = startFrom or 1
  local endFrame  = endFrame  or self.maxFrame
  local speed     = speed     or 0.1
  local direction = 1

  if startFrom > endFrame then
    direction = -1
  end

  if timer then
    -- delete previous animation
    if self.timer then
      timer.cancel(self.timer)
    end

    -- set new animation
    self.timer = timer.every(speed, function()
      self.cFrame = self.cFrame + self.direction
      if self.cFrame > endFrame then
        self.cFrame = startFrom
        if self.stopAnimation then
          --self.stopAnimation = false
          --return false
        end
      end
      if self.cFrame < startFrom then
        self.cFrame = endFrame
        if self.stopAnimation then
          --self.stopAnimation = false
          --return false
        end
      end
    end)

  else
    print("Error: timer not loaded")
  end
end

function sprite:play(speed, startFrom, endFrame)
  local endFrame  = endFrame or self.maxFrame
  local startFrom = startFrom or 1
  
  self.cFrame     = startFrom
  if endFrame < startFrom then
    self.direction = -1
  else
    self.direction = 1
  end

  if timer then
    timer.every(speed, function()
      local frame = self:nextFrame()
      --print("Sprite frame:" .. self.cFrame)
      if frame == endFrame then
        --print("Animation ended")
        return false
      end
    end, math.abs(endFrame - startFrom))
  else
    print("Error: timer not loaded")
  end
end

function sprite:stop()
  if self.timer then
    timer.cancel(self.timer)
  end
end

function sprite:getFrame()
  return self.cFrame
end

function sprite:free()
  graphics.freeTexture(self.texture)
  self.frames = nil
end

function sprite:getSize()
  return self.frames[self.cFrame].w, self.frames[self.cFrame].h
end

return sprite