local flux  = require "lib.flux"

local graphics = {
  width,
  height,
  scene, -- for SS3D
  canvas,
  scaleRatio = 1,
  xOffset, yOffset = 0, 0,
  lights = {
    init = nil
  },
  fontTexture,
  fontSize = 12,
  fontScale = 1;
  drawCall = 0,
  fillrate = 0,
  _label = function() end,
  tooltips = {}
}

--this will be shallow copied, so not nested tables
local TEXTURE = {
  texture   = {}, -- actual texture data
  filename  = "",
  w, h      = 0, 0, 
}

local font = {}
local fontReg = {}
local fontBig = {}
local _font_size  = 1
local platform = platform

local dColor = {1,1,1,1} --save the last draw color

function graphics.init(width, height)
  graphics.width, graphics.height = width, height
  graphics.camera = gameObject:new()
  graphics.camera.size:set(width, heigth)
  --graphics.noTexture = gameObject:createFromFile("assets/default/temp_asset.png", 0, 0)

  graphics.canvas = love.graphics.newCanvas(640, 480)
  graphics.drawCall = 0

  graphics.loadFont("default/MathJax.otf", 16, 20)

  print("GRAPHICS> Init done.")
end

function graphics.shutdown()
  graphics.freeTexture(graphics.fontTexture, "font")
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

function graphics.loadFont(filename, size, cellSize)
  local size = 20
  local scaling = 1.0

  graphics.fontSize   = size
  graphics.fontScale  = scaling

  filename = "default/SpaceMono-Regular.ttf"
  local filename = findFile(filename)
  if filename == nil then
    filename = "default/SpaceMono-Regular.ttf"
    --filename = "default/MathJax.otf"
  end

  if filename then
    fontBig  = love.graphics.newFont(filename, size * 2)
    fontReg  = love.graphics.newFont(filename, size)
    
    love.graphics.setFont(fontReg)
    font     = fontReg

    graphics.fontSize = font:getHeight()
    
  end

end

function graphics.getTextWidth(str)
  if str == nil then return end
  if platform == "LOVE" then return font:getWidth(str) end
  if platform == "DC" then
     local ll = str:find("\n")
     if ll then
       local m = math.max(ll, #str - ll) * 10
       return m
     else
       return #str * 10
     end
  end
end

function graphics.setFontScale(size)
  local size = size or 1
  graphics.fontScale = size
end

function graphics.getFontSize()
  return graphics.fontSize
end

function graphics.setFont(name)
  if name == "big" then
    love.graphics.setFont(fontBig)
    font = fontBig
    graphics.fontSize = font:getHeight()
  end

  if name == nil then
    love.graphics.setFont(fontReg)
    font = fontReg
    graphics.fontSize = font:getHeight()
  end
end

function graphics.print(string, x, y, mode, color, debug)
  local x       = math.floor(x) --makes the texts way sharper
  local y       = math.floor(y)
  local align   = "left"
  local string  = string or ""
  local debug   = debug or 0
  local w       = 1
  local boxW    = math.max(font:getWidth(string), 1)

  if mode ~= nil then
    align = "center"
    w = font:getWidth(string)
    --x = x - (#string/2) * graphics.fontSize/2
  end

  if color ~= nil then
    graphics.setDrawColor(color)
  end
    
  love.graphics.printf(string, x, y, boxW, align, 0, graphics.fontScale, graphics.fontScale, w/2)

  graphics.drawCall = graphics.drawCall + 1
  graphics.setDrawColor()
end

function graphics.printDebug(string, color)
  local x       = 20 --makes the texts way sharper
  local y       = 440
  local string  = string or ""

  if color ~= nil then
    graphics.setDrawColor(color)
  end

  if platform == "LOVE" then
    love.graphics.printf(string, x, y, 640, "left", 0, graphics.fontScale)
  else
    C_writeFont(string, x, y, 1);
  end
  graphics.setDrawColor()
end

-- Generic way to write description
function graphics.label(str, x, y, col, mode)
  if str == nil then  return end
  local x, y = math.ceil(x), math.ceil(y)
  local w = graphics.getTextWidth(str)
  local h = graphics.fontSize + 3
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

-- Loading info
function graphics.printInfo(string, _color, renderNow)
  local color = _color or color.LGREY

  graphics.setDrawColor(color)
  if platform == "LOVE" then
    love.graphics.print(string, 20, 440, 0, graphics.fontScale)
  else
    C_writeFont(string, 20, 440);
  end
  graphics.setDrawColor()

  if renderNow == nil then
    graphics.renderFrame()
  end
end

function graphics.getFPS()
  return love.timer.getFPS()
end
-----------------------------------------------


function graphics.getDelta()
  return love.timer.getAverageDelta()
end
-- TEXTURE -------------------------------------
function graphics.loadTexture(filename)
  if type(filename) == "table" then
    print("GRAPHICS> Trying to load a table as texture -> returning same table")
    return filename
  end


  local originalName = filename
  filename = findFile(filename)
  if not filename then 
    print("GRAPHICS> Texture not found: "..originalName)
    return 
  end 

  local nTex = copy(TEXTURE)

  nTex.texture    = love.graphics.newImage(filename)
  nTex.w, nTex.h  = nTex.texture:getDimensions()
  nTex.filename   = originalName
  print("GRAPHICS> Texture loaded: "..filename)
  return nTex
end

function graphics.freeTexture(texture, type)
  local type = type or 1

  if texture == nil then
    print("GRAPHICS.LUA>Trying to free empty texture")
    return nil
  end

  if platform == "LOVE" then
    texture = nil
  end

  if platform == "DC" then
    if      type == "font" then
      C_freeTexture(texture, 3)
    elseif  type == "gameobject" then
      C_freeTexture(texture, 2)
    else
      C_freeTexture(texture, 1)
    end
    texture = nil
  end
  return true
end

function graphics.getTextureInfo(texture)
  local w, h = 0, 0
  local u, v, us, vs = 0, 0, 1, 1

  if platform == "LOVE" then
    w, h = texture.texture:getDimensions()
  else
    w, h, u, v, us, vs = C_getTextureInfo(texture.texture)
  end

  -- sprite width / height
  local sW, sH = (us-u)*w, (vs-v)*h
  return u, v, us, vs, sW, sH, w, h
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

function graphics.setTextureUV(texture, u, v, us, vs)
  C_setTextureUV(texture, u, v, us, vs)
end

---------------------------------------------------

-- 3D ---------------------------------------------
function graphics.loadObj(path, texture)
  if platform == "LOVE" then
    local t = graphics.loadTexture(texture)
    print("Graphics> texture for model loaded" .. tostring(t))
    return ss3d:newModel(ss3d.loadObj(path), t)
  end
end

function graphics.addModel(model)
  if model == nil then return nil end

  if platform == "LOVE" then
    local r = graphics.ss3dscene:addModel(model)
    print("Graphics> Model added -> " .. tostring(r))
  end
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

  love.graphics.clear(_r, _g, _b, _a)
  --graphics.drawRect(0, 0, 640, 480, _r, _g, _b, _a)

end


function graphics.setDrawColor(r,g,b,a)
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

  love.graphics.setColor(_r, _g, _b, _a)
  dColor = {_r, _g, _b, _a}
end
graphics.setColor = graphics.setDrawColor

function graphics.setTransparency(a)
  local a = a or 1.0
  love.graphics.setColor(dColor[1], dColor[2], dColor[3], a)
end
-------------------------------------------------

-- Drawing 2D -----------------------------------
function graphics.startBatch(tex)
end


function graphics.addToBatch(obj)
  if platform == "LOVE" then
    if obj.quad ~= nil then
      love.graphics.draw(obj.texture.texture, obj.quad, obj.pos.x, obj.pos.y, math.rad(obj.angle), obj.scale.x, obj.scale.y, obj.size.x/2, obj.size.y/2)
    else
      love.graphics.draw(obj.texture.texture, obj.pos.x, obj.pos.y, math.rad(obj.angle), obj.scale.x, obj.scale.y, obj.size.x/2, obj.size.y/2)
    end
  end
end

function graphics.addToBatch2(obj)
end

function graphics.endBatch(tex)
end

function graphics.drawTexture(texture, x, y, mode)
  local mode = mode or "center"
  local xOff = 0
  local yOff = 0

  if texture == nil then return nil end
  
  if mode == "center" then 
    xOff = texture.w/2
    yOff = texture.h/2
  end

 
  love.graphics.draw(texture.texture, x, y, 0, 1, 1, xOff, yOff)
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

-- top-left
function graphics.drawRect(x, y, w, h, r, g, b, a)
  local coord = {
    x + w, y,
    x + w, y + h,
    x, y + h,
    x, y,
  }

  --graphics.setDrawColor(r, g, b, a)
  love.graphics.polygon("fill", coord)
  --graphics.setDrawColor()

  graphics.drawCall = graphics.drawCall + 1
end

function graphics.drawMask(vertex)
  --[[
  local x, y = obj.pos.x, obj.pos.y
  local w, h = obj.size.x * obj.scale.x, obj.size.y * obj.scale.y
  local coord = {
    x, y,
    x + w, y,
    x + w, y + h,
    x, y + h,
  }
  --]]
  graphics.setDrawColor(0,0,0,1)
  love.graphics.polygon("fill", vertex)
  graphics.setDrawColor()
  graphics.drawCall = graphics.drawCall + 1 -- ???? it's a mask?
end

function graphics.drawPoly(vert, r, g, b, a, angle)
  if platform == "DC" then
    local angle = angle or 0.0
    if r then graphics.setDrawColor(r,g,b,a) end
    C_drawTri(vert[1], vert[2], vert[3], vert[4], vert[5], vert[6], angle)
    graphics.setDrawColor()
    return
  end

  if platform == "LOVE" then
    love.graphics.push()
    if r then graphics.setDrawColor(r,g,b,a) end
    if angle then love.graphics.rotate(angle) end
    love.graphics.polygon("fill", vert)
    love.graphics.pop()
    graphics.setDrawColor()
  end

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

function graphics.endFrame(debug)
  if debug == true then
    local info = {}
    info[1] = "drawcall: " .. graphics.drawCall
    info[2] = "fillrate: " .. graphics.fillrate
    info[3] = "deltaTime: " .. deltaTime
    info[4] = string.format("mem: %0.2f", collectgarbage("count"))

    s = table.concat(info, "\n")
    graphics.print(s, 10, 10, color.WHITE)
  end

  if platform == "DC" then
    --C_swapBuffer()
  end
  graphics.fillrate = 0
  graphics.drawCall = 0
end

function graphics.renderFrame()
  if platform == "DC" then
    C_swapBuffer()
  end
end

function graphics.translateCamera()
  local camera = graphics.camera
  graphics.translate(-camera.pos.x, -camera.pos.y, 0)
end

-- LIGHT STUFF ---------------------------------------------
function graphics.lights.initLight(gameCanvas)
  if platform == "LOVE" then
    local w, h = graphics.getNativeSize()
    luven.init(w, h, false, gameCanvas)
    --luven.camera:init(w, h, false)
    --luven.camera:setScale(graphics.scaleRatio, graphics.scaleRatio)
    --luven.camera:setPosition(-320, -240)
    --luven.camera:setScale(0.5, 0.5)
    luven.setAmbientLightColor({0.1, 0.1, 0.1})
    graphics.lights.available = true
    graphics.lights.init = 1
    return graphics.lights.init
  end
end

function graphics.lights.addLight(x, y, power, color)
  local power = power or 10

  if graphics.lights.init == nil then return 0 end
  if platform == "LOVE" then
    local id = -1
    id = luven.addNormalLight(x, y, color, power)
    --print("LUVEN> added light " .. id)
    return id
  end
end

function graphics.lights.setLight(lightID, setting, p1, p2, p3, p4)
  if graphics.lights.init == nil then return 0 end
  if lightID > luven.getLightCount()  then print("LUVEN> invalid ID") return 0 end

  local p1 = p1 or 1
  local p2 = p2 or 1
  local p3 = p3 or 1
  local p4 = p4 or 1

  if setting == "position" then luven.setLightPosition(lightID, p1, p2) end
  if setting == "color"    then luven.setLightColor(lightID, {p1, p2, p3, p4}) end
  if setting == "scale"    then luven.setLightScale(lightID, p1, p2) end
  if setting == "ambient"  then luven.setAmbientLightColor({p1, p2, p3 , p4}) end

end

function graphics.lights.remove(lightID)
  if graphics.lights.init == nil then return 0 end
  luven.removeLight(lightID)
end

function graphics.lights.clearLights()
  if graphics.lights.init == nil then return 0 end
  for i=1, luven.getLightCount() do
    luven.removeLight(i)
  end
  print("GRAPHICS> Removed ALL lights")
end

function graphics.lights.update(dt)
  if graphics.lights.init == nil then return 0 end
  local camera = graphics.camera
  local w, h   = graphics.getWindowSize()
  gx, gy = love.graphics.inverseTransformPoint(camera.pos.x, camera.pos.y)
  luven.camera.x, luven.camera.y = gx, gy

  luven.camera:setPosition(-2000, camera.pos.y)
  luven.update(dt)
end

function graphics.lights.begin()
  if graphics.lights.init == nil then return 0 end
  luven.drawBegin()
end

function graphics.lights.done()
  if graphics.lights.init == nil then return 0 end
  luven.drawEnd()
end

function graphics.lights.render()
  if graphics.lights.init == nil then return 0 end
  if platform == "LOVE" then

    luven.drawBegin()
    graphics.push()
    graphics.translateCamera()
    currentMap:render()
    --graphics.setDrawColor({1, 1, 1, 1})
    --p1:render()
    currentMap:renderOverlay()
    graphics.pop()
    luven.drawEnd()
  end
end

return graphics
