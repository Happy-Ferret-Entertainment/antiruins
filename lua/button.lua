local button = {}

button.__index = button
setmetatable(button, {__call = function(cls, ...) return csl.new(...) end,})

local DELTA = 1e-10
local function rect_containsPoint(x,y,w,h, px,py)
  return px - x > DELTA      and py - y > DELTA and
         x + w - px > DELTA  and y + h - py > DELTA
end

function button:new(x, y, w, h, img)
  local b       = {}
  b.x, b.y      = x, y
  b.w, b.h      = w, h
  b.color       = {1,1,1,1}
  b.hColor      = {1,0,0,1}
  b.tColor      = {0,0,0,1}
  b.thColor      = {1,1,1,1}
  b.mouseOver   = false
  b.label       = ""
  b.clickButton = "LEFT_MOUSE"
  --b.image       = graphics.loadTexture(findFile(img))
  local self = setmetatable(b, button)
  return self
end

function button:setLabel(label, hLabel)
  self.label  = label
  self.hLabel = hLabel
end

function button:setImage(image, hImage)
  if image then
    self.image = image
  end

  if hImage then
    self.hImage = hImage
  end
end

function button:setColor(color, tColor, hColor, thColor)
  if color then
    self.color = copy(color)
  else
    self.color = {1,1,1,1}
  end

  if hColor then 
    self.hColor = copy(hColor) 
  end

  if tColor then 
    self.tColor = copy(tColor) 
  end

  if thColor then 
    self.thColor = copy(thColor) 
  end

end

-- user rewrittable callback
function button:onHover()
end

-- user rewritable callback
function button:onClick()
  print("Click on button!")
end

function button:render()
  local textColor = self.tColor
  if self.mouseOver then
    graphics.setDrawColor(self.hColor)
    textColor = self.thColor
    -- this is a bit strange, but to allow onHover visual effect?
    self:onHover()
  else 
    graphics.setDrawColor(self.color)
  end

  graphics.drawRect(self.x, self.y, self.w, self.h)
  graphics.setDrawColor(self.tColor)
  graphics.print(self.label, self.x + self.w/2, self.y, textColor, "center")
  graphics.setDrawColor()
end

-- hard coded to mouse right now
function button:update()
  if input.hasMouse then self:checkMouse() end
end

function button:checkMouse()
  local mouse = input.getMouse()
  local inside = rect_containsPoint(self.x, self.y, self.w, self.h, mouse.x, mouse.y)
  if inside then 
    self.mouseOver = true
    if input.getButton(self.clickButton) then
      self:onClick()
    end
  else
    self.mouseOver = false
  end
end

return button