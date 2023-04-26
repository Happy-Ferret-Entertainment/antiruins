local maf = require "lib.maf"
local graphics = require "graphics"

local gameObject = {}
gameObject.__index = gameObject
setmetatable(gameObject, {__call = function(cls, ...) return csl.new(...) end,})

function gameObject:new(_npcID, x, y)
  objectData = {
    pos     = maf.vector(x or 0, y or 0),
    accel   = maf.vector(0,0),
    vel     = maf.vector(0,0),
    size    = maf.vector(1,1),
    scale   = maf.vector(1,1),
    hitSize = 0.0,
    color   = {1.0, 1.0, 1.0, 1.0},
    angle   = 0,
    display = true, -- for render
    active  = true, -- for scrips
    npcID   = _npcID or nil,
    file    = "nofile",

    -- texture
    textureName = "",
    texture     = nil,
    uv          = {0,0,1,1,1,1,1,1},

    -- description
    desc_file       = nil,
    desc_position   = 0,

    quad        = nil,
    canRepair   = 0, -- 0 impossible, 1 can repair, 2 is repaired
    canReceive  = nil,
  }
  local self = setmetatable(objectData, gameObject)
  return self
end

--USES COPY!!
function gameObject:copy(obj)
  local new = gameObject:new()

  new = copy(obj)
  --new:setTexture(obj)

  new.pos       = maf.vector(obj.pos.x,     obj.pos.y)
  new.accel     = maf.vector(obj.accel.x,   obj.accel.y)
  new.vel       = maf.vector(obj.vel.x,     obj.vel.y)
  new.size      = maf.vector(obj.size.x,    obj.size.y)
  new.scale     = maf.vector(obj.scale.x,   obj.scale.y)
  new.color     = {1.0, 1.0, 1.0, 1.0}

  return new
end

function gameObject:createFromXML(xml_data, sprite_data, map, textureID, debug)
  --local xml_data = xml_data
  local obj = gameObject:new()
  --get name---------------
  if xml_data["@href"] ~= nil then
    obj.file        = xml_data["@href"]
    obj.textureName = "spritesheet.png"
    obj.desc        = xml_data["@desc"] or nil
    obj.npcID       = xml_data["@npcID"] or nil
    --get size---------------
    obj.size.x      = tonumber(xml_data["@width"])
    obj.size.y      = tonumber(xml_data["@height"])
  else
    print("Object not found")
  end

  -- Get sprite info.
  if xml_data["@href"] ~= nil then
    --get UV-----------------
    obj.uv = {getTextureData(sprite_data, obj.file)}
    --print(table.unpack(obj.uv))
    if obj.uv[1] == nil then
      obj = gameObject:new(obj.npcID, 0, 0)
      obj:setTexture(graphics.noTexture)
      obj.textureName = "temp_asset.png"
    else
      --print(table.unpack(obj.uv))
      local scaleX = obj.size.x / obj.uv[7]
      local scaleY = obj.size.y / obj.uv[8]
      obj.scale:set(scaleX, scaleY)
      obj.size.x = obj.uv[7]
      obj.size.y = obj.uv[8]
        --print(tostring(obj.npcID) .. "-" .. tostring(obj.scale))
      if textureID ~= nil then
        if platform == "LOVE" then
          obj.quad = love.graphics.newQuad(obj.uv[1], obj.uv[2], obj.uv[3], obj.uv[4], obj.uv[5], obj.uv[6])
          obj.texture = textureID
        else
          obj.texture = C_newTextureFromID(textureID)
          C_setTextureUV(obj.texture, obj.uv[1], obj.uv[2], obj.uv[3], obj.uv[4])
        end
      end
    end


    --lights
    if xml_data["@light"] then
      obj.type = "light"
      local c = {}
      for token in string.gmatch(xml_data["@light"], "[^%s]+") do table.insert(c, token) end
      obj.lightActive = 1.0
      obj.color = c
    end
  end

  --get position-----------
  if platform == "LOVE" then
    -- FROM CENTER
    obj.pos.x = (tonumber(xml_data["@x"]) + (obj.size.x * obj.scale.x) * 0.5)
    obj.pos.y = (tonumber(xml_data["@y"]) + (obj.size.y * obj.scale.y) * 0.5)

  elseif platform == "DC" then
    obj.pos.x = (tonumber(xml_data["@x"]) + (obj.size.x * obj.scale.x) * 0.5)
    obj.pos.y = (tonumber(xml_data["@y"]) + (obj.size.y * obj.scale.y) * 0.5)
  end

  --get transforms(scale/angle)
  if xml_data["@transform"] ~= nil then
    if string.find(xml_data["@transform"], "rotate") ~= nil then
      obj.angle = tonumber(string.match(xml_data["@transform"], "(%-?%d+)"))
    end
    if string.find(xml_data["@transform"], "scale") ~= nil then
      local xScale, yScale = string.match(xml_data["@transform"], "(%-?%d+),(%-?%d+)")
      obj.scale:set(tonumber(xScale) * obj.scale.x, tonumber(yScale) * obj.scale.y)
    end
  end

  obj.hitSize = obj.size:length() * obj.scale:length() * 0.5
  obj.hitSize = math.min(obj.size.x * obj.scale.x, obj.size.y * obj.scale.y) * 0.7
  -- Get absolute center position post all angle/scale/bullshit
  obj.pos = obj:getPosition("abs")
  return obj
end

function gameObject:createFromFile(filename, x, y)
  local x = x or 0
  local y = y or 0
  local obj = gameObject:new()
  print("GameObject> Creating from file: " .. filename)
  obj.texture = graphics.loadTexture(filename)

  if obj.texture ~= nil then
    obj.textureName = filename
    obj.uv = {graphics.getTextureInfo(obj.texture)}
    obj.size:set(obj.uv[5], obj.uv[6])
    obj.hitSize = obj.size:length() * obj.scale:length() * 0.5
  end

  obj.pos:set(x, y)
  return obj
end

function gameObject:setNpc(npcID, desc_file)
  local desc_file = desc_file or "asset/npc/" .. npcID .. ".txt"
  self.npcID      = npcID
  self.name       = npcID:gsub("^%l", string.upper)
  self.desc_file  = checkFile(desc_file)

  if self.desc_file == nil then
    print("GameObject> Couldn't find desc_file for " .. self.npcID)
  else
    print("GameObject> " .. self.npcID .. " set as a NPC. > " .. self.desc_file)
  end
end

function gameObject:delete(tag)
  if tag ~= "NOASSET" then
    graphics.freeTexture(self.texture)
  end
  self.pos     = nil
  self.force   = nil
  self.vel     = nil
  self.size    = nil
  self.scale   = nil
  self = {}
end

function gameObject:setPosition(x, y)
  if type(x) == "cdata" then
    self.pos:set(x.x, x.y)
  else
    self.pos.x = x
    self.pos.y = y
  end
end

function gameObject:getPosition(type)
  if type == nil then
    return maf.vector(self.pos.x, self.pos.y)
  end

  if type == "abs" or type == "absolute" then
    local a = self.angle
    local s = math.sin(math.rad(a))
    local c = math.cos(math.rad(a))

    local _x, _y = self.pos.x, self.pos.y




    local x =  math.abs(_x * c - _y * s)
    local y =  math.abs(_x * s + _y * c)
    return maf.vector(x, y)
  elseif type == "center" then
    return maf.vector(self.pos.x + self.size.x/2, self.pos.y + self.size.y/2)
  else
    return maf.vector(self.pos.x, self.pos.y)
  end
end

-- PHYSICS -------------------------------
function gameObject:addForce(force, speed, noMaxSpeed)
  local maxSpeed = 1
  local f = force:scale(speed)
  self.accel:add(f)
  if noMaxSpeed == nil and self.accel:length() > 1 then
    self.accel:normalize():scale(maxSpeed)
  end
end

function gameObject:updatePosition()
  self.vel      :add(self.accel)
  self.pos      :add(self.vel)
  self.vel      :scale(0.85)
  self.accel    :scale(0)
end

function gameObject:moveTo(position, speed)
  local dir = position - self.pos
  local dist = #dir
  local speed = speed or 0.1

  dir = dir:normalize()
  dist = math.min(dist, 1)
  self:addForce(dir, speed * dist)

  if dist < 0.1 then return true end
end

function gameObject:follow(target, speed)
  local diff = target.pos - self.pos
  local t = target.pos + target.size/2
  local s = self.pos + self.size/2
  diff = t - s
  if speed == nil then self.pos = target.pos:clone() end
  if speed then diff:normalize():scale(speed) self:addForce(diff, 0.5) end
end
-------------------------------------------

-- TEXTURE / UV ---------------------------
function gameObject:getDataForEngine()
  return self.pos.x, self.pos.y, self.uv[1], self.uv[2], self.uv[3], self.uv[4], self.scale.x, self.desc, self.file, self.npcID
end

function gameObject:setTexture(target)
  self.uv         = {table.unpack(target.uv)}
  self.texture    = target.texture

  self.size:set(self.uv[7], self.uv[8])

  if platform == "LOVE" then
    self.quad = target.quad
  else
    self.texture = C_newTextureFromID(target.texture)
    C_setTextureUV(self.texture, self.uv[1], self.uv[2], self.uv[3], self.uv[4])
  end
end

function gameObject:freeTexture()
  return graphics.freeTexture(self.texture, "gameobject")
end

function gameObject:setSprite(spriteName, texture, spritesheet, trim)
  self.uv = {getTextureData(spritesheet, spriteName, trim)}
  if platform == "LOVE" then
    self.quad = love.graphics.newQuad(self.uv[1], self.uv[2], self.uv[3], self.uv[4], self.uv[5], self.uv[6])
    self.texture = texture
  else
    self.texture = C_newTextureFromID(texture)
    C_setTextureUV(self.texture, self.uv[1], self.uv[2], self.uv[3], self.uv[4])
  end
end

function gameObject:setUV(u, v, us, vs)
  if platform == "LOVE" then
    self.uv = {u, v, us, vs, self.uv[5], self.uv[6], self.uv[7], self.uv[8]}
    self.quad = love.graphics.newQuad(u, v, us, vs, self.uv[5], self.uv[6])
    --self.size:set(us, vs)
    --self.texture = texture
  else
    self.uv[1] = u
    self.uv[2] = v
    self.uv[3] = us
    self.uv[4] = vs
    C_setTextureUV(self.texture, u, v, us, uv)
  end
end

function gameObject:addAnimation(spriteName, frameNum, type)
  self.anim   = {
    type        = type or "normal",
    cFrame      = 1,
    spriteName  = spriteName,
    frameNum    = frameNum, -- this is a table containing the numbers
    mFrame      = #frameNum,
    timer       = 0,
    delay       = delay or 10,
    direction   = 1,
  }
end

function gameObject:updateAnimation(speed)
  if self.anim == nil then return nil end
  local a = self.anim
  local speed = speed or a.delay


  if frameCount % speed == 0 then
    -- prevent rolling over
    if a.cFrame > a.mFrame or a.cFrame == 0 then
      if a.type == "pingpong" then
        a.direction = -a.direction
        a.cFrame = a.cFrame + a.direction
        --print(a.cFrame)
      else
       a.cFrame = 1
     end
    end

    local file = a.spriteName .. tostring(a.frameNum[a.cFrame] .. ".png")
    self:setSprite(file, self.texture, currentMap.spriteData)
    a.cFrame = a.cFrame + a.direction
  end
end


--uses copy!! watchout for DC
function gameObject:isOver(target, precision)
  if target == nil then return nil end
  local a = {}
  local b = {}
  local precision = precision or target.size.x * 0.5

  b.pos     = maf.vector(target.pos.x, target.pos.y)
  a.pos     = maf.vector(self.pos.x, self.pos.y)

  if precision ~= nil then
    local d = math.abs(a.pos:distance(b.pos))
    --print(d)
    if d < precision then
      return true
    else
      return false
    end
    b.size = maf.vector(precision, precision)
  end
end

function gameObject:draw(x, y, static)
  local x = x or self.pos.x
  local y = y or self.pos.y

  if self.display == false then return nil end
  if self.texture == nil then return nil end

  print("draedid")
  graphics.drawTexture(self.texture, self, x, y)
end

function gameObject:drawBox(r, g, b, a, offset)
  local offset = offset or 0
  local r = r or 1.0
  local g = r or 1.0
  local b = r or 1.0
  local a = r or 1.0
  local c = {r,g,b,a}
  graphics.drawQuad(self, c)
  --C_drawQuad(r, g, b, a, self.pos.x, self.pos.y, self.size.x + offset, self.size.y + offset)
end

function gameObject:printData()
  for k, v in pairs(self) do
    print(k .. " > " .. v)
  end
end

--Loaders--
function getTextureData(sprite_data, filename, trim)
  local trim  = trim or 0
  local img_w = sprite_data.meta.size.w
  local img_h = sprite_data.meta.size.h

  for i, v in ipairs(sprite_data["frames"]) do
    local f = sprite_data["frames"][i]
    if f.filename == filename then
      if platform == "LOVE" then
        local uS  = f.frame.w
        local vS  = f.frame.h
        local u   = f.frame.x
        local _v  = f.frame.y
        --print(uS + u .. " " .. vS + _v)
        return u, _v, uS, vS, img_w, img_h, f.sourceSize.w, f.sourceSize.h
      elseif platform == "DC" then
        local uS = f.frame.w / img_w
        local vS = f.frame.h / img_h
        local u = f.frame.x / img_w
        local _v = ((img_h - f.frame.y) / img_h) - vS
        --print(img_w .. " " .. img_h)
        return u, _v, uS, vS, img_w, img_h, f.sourceSize.w, f.sourceSize.h
      end
    end
  end
  return nil
end

return gameObject
