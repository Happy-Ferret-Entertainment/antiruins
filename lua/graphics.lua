local flux  = require "lib.flux"
local maf   = require "lib.maf"

local graphics = {
  width,
  height,
  scene, -- for SS3D
  canvas,
  scaleRatio = 1,
  xOffset, yOffset = 0, 0,

  font = nil,

  drawCall = 0,
  fillrate = 0,
  _label = function() end,
  tooltips = {}
}

drawQueue = {}

--this will be shallow copied, so not nested tables
local TEXTURE = {
  texture   = id, -- texture ID used by the C engine
  filename  = "",
  w, h      = 0, 0, 
}

local FONT = {
  texture = 0, 
  charW   = 0, --char width
  size    = 0,
  type    = "font",
}

local fonts = {}

local platform = platform
local perfInfo = {}
local dColor = {1,1,1,1} --save the last draw color

function graphics.init(width, height)
  graphics.width, graphics.height = width, height
  graphics.camera = gameObject:new()
  graphics.camera.size:set(width, heigth)

  perfInfo          = {}
  graphics.drawCall = 0

  -- global BG quad for transparent BG
  bgQuad = gameObject:new()

  print("GRAPHICS> Init done.")
end

function graphics.shutdown()
  --graphics.freeTexture(graphics.fontTexture, "font")
end

function graphics.getNativeSize()
  return graphics.width, graphics.height
end

function graphics.getWindowSize()
  if platform == "LOVE" then
    return love.graphics.getWidth(), love.graphics.getHeight()
  else
    return 640, 480
  end
end

function graphics.setCamPosition(x, y)
  graphics.camera.pos:set(x-320, y-240)
end

function graphics.setCamTarget(target, type)
  local type = type or "FIXED"

  graphics.camera.target = target
  graphics.camera.type = type
  if target ~= nil then
    if type == "JUMP" then
        graphics.setCamPosition(target.pos.x, target.pos.y)
    end
  else
    graphics.camera.pos:set(0, 0)
  end
end

function graphics.updateCamera()
  -- Last update Feb 2020 : Very smooth!!!!
  local cam = graphics.camera
  local farX, farY = currentMap.width - graphics.width, currentMap.height - graphics.height

  if cam.target ~= nil then
    local dx    = cam.pos.x - (cam.target.pos.x - 320)
    local dy    = cam.pos.y - (cam.target.pos.y - 240)

    local dist = sh4_vecLength(dx, dy, 0)
    if dist > 1000 then
      cam.pos = (cam.target.pos - maf.vector(320,240))
    end

    --local x, y, z = sh4_vecNormalize(dx, dy, 0)
    local dir = maf.vector(dx,dy)
    local f = dir:normalize() * (dist * 0.01)

    cam:addForce(-f, 1)
    cam:updatePosition()

    cam.pos.x = lume.round(cam.pos.x)
    cam.pos.y = lume.round(cam.pos.y)

    if cam.pos.x < 0 then cam.pos.x = 0 end
    if cam.pos.y < 0 then cam.pos.y = 0 end

    if cam.pos.x > farX then cam.pos.x = math.min(cam.pos.x, farX) end
    if cam.pos.y > farY then cam.pos.y = math.min(cam.pos.y, farY) end
  end
end

-- FONT & TEXT -------------------------

function graphics.loadFont(filename, gridX, gridY, fontSize)
  local filename = findFile(filename)
  if    filename == nil then return end

  local gridY     = gridY or gridX
  local fontSize  = fontSize or 0

  local f = copy(FONT)
  f.texture, f.charW, f.size = C_loadFont(filename, gridX, gridY, fontSize)

  print("GRAPHICS> Loaded font: "..filename.." charW: "..f.charW.." size: "..f.size)
  graphics.font = f
  return f
end

function graphics.freeFont(font)
  -- This is not using the argument, it's just freeing font 0 in graphics.c
  C_freeFont(font.texture)
  graphics.font = nil
end

function graphics.getTextWidth(str)
  if str == nil then return end
  if platform == "LOVE" then return font:getWidth(str) end

  local charW = graphics.font.charW
  if platform == "DC" then
     local ll = str:find("\n")
     if ll then
       local m = math.max(ll, #str - ll) * charW  
       return m
     else
       return #str * charW
     end
  end
end

function graphics.setFontSize(size)
end

function graphics.getFontSize(f)
  return graphics.font.size
end

function graphics.setFont(f)
  -- maybe some type checking here lol
  if f.type ~= "font" then print("Graphics.lua> invalid type of font")return end
  graphics.font = f
end

function graphics.print(string, x, y, mode, color, debug)
  local x       = math.floor(x) --makes the texts way sharper
  local y       = math.floor(y)
  local align   = "left"
  local string  = string or " "
  local debug   = debug or 0
  local w       = graphics.getTextWidth(string)
  --print("wow")

  if mode ~= nil then
    align = "center"
    --x = x - (#string/2) * graphics.fontSize/2
  end

  if color ~= nil then
    graphics.setDrawColor(color)
  end
  if align == "center" then x = x - (w/2) end
  
  C_printString(string, x, y, debug);
  graphics.drawCall = graphics.drawCall + 1
end

function graphics.printDebug(string, x, y)
  local x       = x or 20 --makes the texts way sharper
  local y       = y or 440
  local string  = string or ""

  for l in string.gmatch(string, "[^\r\n]+") do
    C_printBios(l, x, y);
    y = y + 24
  end

  --C_printBios(string, x, y);
end
--[[
-- Generic way to write description
function graphics.label(str, x, y, col, mode)
  if str == nil then  return end
  local x, y = math.ceil(x), math.ceil(y)
  local w = graphics.getTextWidth(str)
  local h = graphics.getFontSize()
  local c = col or color.WHITE
  local mode = mode or nil

  if mode == "STATIC" then
    x = x + graphics.camera.pos.x
    y = y + graphics.camera.pos.y
  end

  if platform == "LOVE" then
    for i = 1, #str do
      if str:byte(i) == 10 then
        h = h + 24
      end
    end

  elseif platform == "DC" then
    for i = 1, #str do
      if str:byte(i) == 10 then
        h = h + 20
      end
    end
  end

  graphics.drawRect(x, y + 3, w + 20, h, 0, 0, 0, 1)
  graphics.print(str, x + 10, y, c)
end

function graphics.label_delay(str, x, y, col, mode, delay)
  local text                = str
  local c, total, progress  = 0, #text, 1 --current char
  local isDone              = false -- check if the current desc is done
  local t                   = realTime + (delay or 2500) -- default is 25


  -- Generator --------------------
  graphics._label = function()
    if isDone == true then return end

    -- Delete after x second
    if realTime > t and c == total then
      isDone = true
      graphics._label = function() end
      return 1
    end

    -- Typing Effect
    if frameCount % 4 == 0 and c < total then
      c = c + 1
      if c == total then
        t = realTime + 2
      end
    end

    -- Actual string
    graphics.label(string.sub(text, 1, c), x, y, col, mode)
  end
end

function graphics.addTooltip(string, x, y, delay)
  local delay = delay or 3
  for i, v in ipairs(graphics.tooltips) do
    if string == v[1] then
      return i
    else

    end
  end
  local tooltip = {string, x, y, realTime + delay}
  table.insert(graphics.tooltips, tooltip)
  return tooltip
end

function graphics.clearTooltip(tooltip)
  for i, v in ipairs(graphics.tooltips) do
    if v == tooltip then
      table.remove(graphics.tooltips, i)
      print("tool removed")
    end
  end
end

-- Tooltip
function graphics.renderTooltip()
  for i, v in ipairs(graphics.tooltips) do
    if v[4] > realTime then
      graphics.label(v[1], v[2], v[3], nil, "center")
    else
      table.remove(graphics.tooltips, i)
    end
  end
end
--]]
-- Loading info
function graphics.printInfo(string, _color, renderNow)
  local color = _color or color.LGREY

  graphics.setDrawColor(color)
    C_writeFont(string, 20, 440);
  graphics.setDrawColor()

  if renderNow == nil then
    graphics.renderFrame()
  end
end

-----------------------------------------------

-- TEXTURE -------------------------------------
function graphics.loadTexture(filename)
  local t = copy(TEXTURE)
  local filename = findFile(filename)
  
  if filename == nil then 
    return nil 
  end
  
  local id, w, h = C_loadTexture(filename)

  t.texture   = id
  t.filename  = filename
  t.w, t.h    = w, h

  return t
end
-- Double check that everything is fine here (new texture table)
function graphics.freeTexture(texture, type)
  local type = type or 1

  if texture == nil then
    print("GRAPHICS.LUA>Trying to free empty texture")
    return nil
  end

  --some stuff to double check here
  if      type == "font" then
    C_freeTexture(texture.texture, 3)
  elseif  type == "gameobject" then
    C_freeTexture(texture.texture, 2)
  else
    C_freeTexture(texture.texture, 1)
  end
  texture = nil

  return true
end

function graphics.drawTexture(tex, x, y, w, h, angle)
  local w = w or tex.w
  local h = h or tex.h
  local spriteID = C_addSprite(tex.texture, x, y, angle, w, h)
  --table.insert(drawQueue, {tex.texture, x, y, 0, 1, 1})
  graphics.drawCall = graphics.drawCall + 1
  --graphics.fillrate = graphics.fillrate + (obj.size.x * obj.size.y * obj.scale.x * obj.scale.y)
  return spriteID
end

graphics.draw = graphics.drawTexture

function graphics.getTextureInfo(texture)
  local w, h = 0, 0
  local u, v, us, vs = 0, 0, 1, 1

  w, h, u, v, us, vs = C_getTextureInfo(texture.texture)

  -- sprite width / height
  local sW, sH = (us-u)*w, (vs-v)*h
  -- whole image width / height, sprite width / height, u, v, us, vs
  return w, h, sW, sH, u, v, us, vs
end

function graphics.setStencil(obj, x, y)
  if platform == "LOVE" then
    if obj ~= nil then
      local f = function()
        obj:drawObject()
        --love.graphics.circle("fill", 320, 240, 25)
      end
      --f()
      --love.graphics.stencil(f, "replace", 1)
      --love.graphics.setStencilTest("equal", 0)
      love.graphics.setColorMask(true, true, true, false)
    else
      love.graphics.setColorMask(true, true, true, true)
      --love.graphics.setStencilTest()
    end
  end
end

function graphics.setSpriteUV(spriteID, u, v, us, vs)
  -- this receives NON normalized (0-1) uv
  -- the x, y, w, h are the actual size of the sprite
  if type(u) == "table" then
    -- this is from the texturepacker antiruin exporter.
    u, v, us, vs = u.x, u.y, u.w, u.h
  end
  C_setSpriteUV(spriteID, u, v, us, vs)
end
---------------------------------------------------

-- Color --------------------------------------
function graphics.setClearColor(r, g, b, a)
  local _r, _g, _b, _a

  if type(r) == "table" then
    _r = r[1] or 1.0
    _g = r[2] or 1.0
    _b = r[3] or 1.0
    _a = r[4] or 1.0
  else
     _r = r or 1.0
     _g = g or 1.0
     _b = b or 1.0
     _a = a or 1.0
  end

  C_setClearColor(_r, _g, _b, 1.0)
end

function graphics.setDrawColor(r, g, b, a)
  local _r, _g, _b, _a = r or 1.0, g or 1.0, b or 1.0, a or 1.0
  if type(r) == "table" then
    _r = r[1] or 1.0
    _g = r[2] or 1.0
    _b = r[3] or 1.0
    _a = r[4] or 1.0
  end

  C_setColor(_r, _g, _b, _a)
end

graphics.setColor = graphics.setDrawColor

function graphics.setTransparency(a)
  local a = a or 1.0
  if platform == "LOVE" then
    love.graphics.setColor(dColor[1], dColor[2], dColor[3], a)
  else
    C_setTransparency(a)
  end
end
-------------------------------------------------

-- Drawing 2D -----------------------------------
function graphics.drawSprite(texture, spriteID, x, y)
  --graphics.drawTexture(texture, 320 - fr.center.x, yHand - fr.center.y)
  --graphics.setSpriteUV(spriteID, fr) 
end

function graphics.startBatch(tex)
  --C_startBatch(tex.texture)
end

function graphics.addToBatch(x, y, a, w, h, u, v, us, vs)

  --local w, h  = obj.scale.x * obj.size.x, obj.scale.y * obj.size.y
  C_addToBatch(x, y, a, w, h, u, v, us, vs)
  --C_drawTexture(x, y, a, w, h, u, v, us, vs)
  --graphics.fillrate = graphics.fillrate + math.abs(w * h)
  graphics.drawCall = graphics.drawCall + 1
end

function graphics.addToBatch2(obj)
  local obj   = obj
  C_addToBatch2(obj.pos.x, obj.pos.y, obj.angle,
                obj.scale.x * obj.size.x, obj.scale.y * obj.size.y,
                obj.uv[1],obj.uv[2],obj.uv[3],obj.uv[4])
end

function graphics.endBatch()
  --C_endBatch2()
end

function graphics.drawMultiTexture(texture, obj, texture2, obj2, x, y, mode)
  local mode = mode or nil

  if texture == nil then return nil end
  if obj ~= nil then end

  -- EVERYTHING NEED TO BE DRAWN FROM THE CENTER
  --[[
  if platform == "LOVE" then
    if obj.quad ~= nil then
      love.graphics.draw(texture, obj.quad, x, y, math.rad(obj.angle), obj.scale.x, obj.scale.y, obj.size.x/2, obj.size.y/2)
    else
      love.graphics.draw(texture, x, y, math.rad(obj.angle), obj.scale.x, obj.scale.y, obj.size.x/2, obj.size.y/2)
    end
  end
  --]]

  if platform == "DC" then
    C_drawMultiTexture(texture, texture2, x, y, obj.angle, obj.scale.x, obj.scale.y)
  end

  graphics.drawCall = graphics.drawCall + 1
end

function graphics.drawQuad(obj, r, g, b, a)
  local x, y = obj.pos.x, obj.pos.y
  local w, h = obj.size.x * obj.scale.x, obj.size.y * obj.scale.y
  local coord = {
    x - w/2, y - h/2,
    x + w/2, y - h/2,
    x + w/2, y + h/2,
    x - w/2, y + h/2,
  }
  graphics.setDrawColor(r,g,b,a)
  if platform == "LOVE" then
    love.graphics.polygon("fill", coord)
  else
    C_drawQuad(x, y, w, h)
  end
  graphics.setDrawColor()

  graphics.drawCall = graphics.drawCall + 1
end

function graphics.drawRect(x, y, w, h)
  C_drawRect(x, y, w, h)
  graphics.drawCall = graphics.drawCall + 1
end

function graphics.drawLine(x1, y1, x2, y2)
  C_drawLine(x1, y1, x2, y2)
end

function graphics.drawPoly(vert, r, g, b, a, angle)
  C_drawTri(vert[1], vert[2], vert[3], vert[4], vert[5], vert[6], angle)
end

function graphics.playVideo(filename, x, y, w, h)
  C_startVideo(filename, x, y, w, h)
end
-------------------------------------------------------

-- Matrix transfrom ------------------------------------
function graphics.scale(x, y)
  if platform == "DC" then
    C_matrixOperation("scale", x, y, 0)
    return 1
  elseif platform == "LOVE" then
    love.graphics.scale(x, y)
  end
end

function graphics.origin()
  if platform == "LOVE" then love.graphics.origin() end
end

function graphics.translate(x, y, z)
  if platform == "LOVE" then love.graphics.translate(x, y, z) end

  if platform == "DC" then
    C_matrixOperation("translate", x, -y, z)
  end
end

function graphics.push()
  if platform == "LOVE" then love.graphics.push() end

  if platform == "DC" then
    C_matrixOperation("push", 0, 0, 0)
  end
end

function graphics.pop()
  if platform == "LOVE" then love.graphics.pop() end

  if platform == "DC" then
    C_matrixOperation("pop", 0, 0, 0)
  end
end

function graphics.rotate(r)
  -- RADIANS

  if platform == "LOVE" then
    love.graphics.rotate(r)
  end

  if platform == "DC" then
    C_matrixOperation("rotate", math.deg(r), 0, 0)
  end
end
---------------------------------------------------------

function graphics.perfInfo(debug)

  perfInfo[1] = "drawcall: "  .. graphics.drawCall
  perfInfo[2] = "fillrate: "  .. graphics.fillrate
  perfInfo[3] = "deltaTime: " .. deltaTime
  perfInfo[4] = string.format("mem: %0.2f kb", collectgarbage("count"))

  local s = table.concat(perfInfo, "\n")
  graphics.print(s, 10, 10, {0,0,0,1})

  graphics.fillrate = 0
  graphics.drawCall = 0
end

function graphics.startFrame(renderTexture)
  C_startFrame(renderTexture)
end

function graphics.renderFrame()
  C_renderFrame()
end

function graphics.translateCamera()
  local camera = graphics.camera
  graphics.translate(-camera.pos.x, -camera.pos.y, 0)
end

return graphics
