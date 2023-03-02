local graphics = require "graphics"
local profiler      = require "lib.profile"

local map = {}
map.__index = map
setmetatable(map, {__call = function(cls, ...) return csl.new(...) end,})


function map.init()
  map.arrow = gameObject:createFromFile("asset/icon/arrow.png")
  event:register("set_description", function(string)
    currentMap.currentDescription = currentMap:setDescription(string)
  end)
end

function map:new()
  mapData = {
    width           = 640,
    height          = 480,
    id              = 0,
    name            = "New Map",
    mode            = "basic",
    objects         = {}, -- the whole list
    npcs            = {}, -- list of object with npcID
    drawable        = {}, -- usually batched
    extra           = {}, -- non batched extra
    warps           = {}, -- warps
    canWarp         = true,
    trig            = {}, -- triggers
    colliders       = {},
    masks           = {},
    overlay         = {},

    -- GRAPHICS
    spritesheet     = nil, -- filename
    spriteData      = {},  -- spritesheet data
    texture         = nil, -- texture id
    drawDistance    = 750,
    drawObjectFlag  = true,

    -- SCRIPTS
    script          = {},

    -- SOUNDS
    sfx             = {},
    bgm             = nil,

    desc            = {},
    currentDescription = nil

    --activeObjects   = {},
    --lights          = {},
    --activeLights    = {},
    --dialog          = {},
  }
  local self = setmetatable(mapData, map)
  return self
end

function map:load_with_routine(mapName, withAsset)
  local withAsset = withAsset or false
  if mapName == nil then return nil end
  if maps[mapName] ~= nil then coroutine.yield("Map " .. mapName .. " already loaded.", maps[mapName]) return nil end
  coroutine.yield("Creating map [" .. mapName .. "].")

  local m = map:new()

  local path
  if      platform == "DC" then
    path = paths.origin .. paths.asset .. "map_" .. mapName .. "/"
  else
    path = paths.asset .. "map_" .. mapName .. "/"
  end

  -- BASIC DATA --------------------------------------------
  local xml_data  = loadXML(path .. "map_" .. mapName .. ".svg")
  m.spriteData    = loadSpritesheet(path .. "spritesheet.json")
  m.name          = mapName
  m.id            = map:getMapID(mapName)
  coroutine.yield("Basic data loaded.")

  -- TEXTURE ------------------------------------------------
  if platform == "DC" then
    -- Check for the file on the cd/pc path
    local f = nil
    f = findFile(path .. "spritesheet.dtex")
    if f == nil then f = findFile(path .. "spritesheet.png") end
    if f ~= nil then
      m.spritesheet = f
      if withAsset then
        m.texture = graphics.loadTexture(m.spritesheet)
      else
        m.texture = nil
      end
    end
  else
    m.spritesheet = paths.asset .. "map_" .. m.name .. "/spritesheet.png"
    m.texture     = graphics.loadTexture(m.spritesheet)
  end
  coroutine.yield("Texture loaded.")

  -- SPRITES ------------------------------------------------
  if xml_data ~= nil then
    local xml_object  = {}
    m.width           = tonumber(xml_data.svg["@width"])
    m.height          = tonumber(xml_data.svg["@height"])

    --LOAD IMAGES
    local layer_obj     = nil
    local layer_mask    = nil
    local layer_light   = nil
    local layer_coll    = nil
    local layer_overlay = nil
    local layer_trig    = nil

    -- Check for numbers of layer
    if #xml_data.svg.g == 0 then
      layer_obj = xml_data.svg.g
    elseif #xml_data.svg.g > 0 then
      for i, v in ipairs(xml_data.svg.g) do
        local v = xml_data.svg.g[i]["@label"]
        if v == "Layer 1"     then layer_obj  = xml_data.svg.g[i] end --old default shit
        if v == "Collision"   then layer_coll = xml_data.svg.g[i] end
        if v == "Trigger"     then layer_trig = xml_data.svg.g[i] end
      end
    end
    coroutine.yield("Layers loaded.")

  --OBJECTS --------------------------------------------------
    if layer_obj ~= nil and layer_obj.image ~= nil then
      for i=1, #layer_obj.image do --1 is floor?
      --for i, v in ipairs(layer_obj.image) do
        xml_object = layer_obj.image[i]
        if xml_object["@warp"] then
          local w = map.createWarp(layer_obj.image[i])
          table.insert(m.warps, w)
        else
          local o = gameObject:createFromXML(xml_object, sprite_data, m, m.texture)
          if o.textureName == "spritesheet.png" then
            table.insert(m.objects, o)
          else
            table.insert(m.extra, o)
            --print("EXTRAA!")
          end
          if o.npcID ~= nil then
            table.insert(m.npcs, o)
          end
        end
      end
    end

    --[[
    if layer_obj.circle ~= nil then
      for k, v in pairs(layer_obj.circle:properties()) do
        print(k)
      end

      for i=1, #layer_obj.circle do
        local xml_object = layer_obj.circle[i]
        for k, v in pairs(xml_object:properties()) do
          print(k)
        end
        local name = xml_object["@trigID"]
        local x, y = tonumber(xml_object["@cx"]), tonumber(xml_object["@cy"])
        local size = tonumber(xml_object["@r"])
        local trig = gameObject:new(name, x, y)
        trig.size:set(size, size)
        table.insert(m.trig, trig)
      end
    end
    --]]
    coroutine.yield("Objects (" .. #m.objects .. ") Trigs (" .. #m.trig .. ") and Warp (".. #m.warps .. ") loaded.")

    -- COLLISION ----------------------------------------------
    m.colliders = {}
    if layer_coll then
      m.colliders = collision.getTriangles(layer_coll)
    end
    coroutine.yield("Collision (" .. #m.colliders .. ") loaded.")

  end

  -- SCRIPTS ------------------------------------------------
  local scriptFile = path .. "script_" .. m.name .. ".lua"
  local r = attachScript(m, scriptFile)
  if r then
  else
  end
  coroutine.yield("Scripts loaded.")

  -- Descriptions --------------------------------------------
  m.desc = {}
  local desc_file = checkFile(path ..  "desc_" .. m.name .. ".txt")
  if desc_file then
    m.desc_file = desc_file
    coroutine.yield("Description file found.")
  end

  for i, npc in ipairs(m.objects) do
    --saveload.restoreNPC(m.id, npc)
  end
  --[[
  local desc_file = checkFile(path ..  "desc_" .. m.name .. ".lua")
  local desc_num = 0

  if desc_file then
    local f
    if platform == "LOVE" then
      f = love.filesystem.load(desc_file)
    else
      f = loadfile(desc_file)
    end

    -- if the have a file
    m.desc = {}

    if f then
      m.desc = f()
      --Cound number of description
      for k,v in pairs(m.desc) do
        desc_num = desc_num + 1
      end
    else
      print("MAP> Can't run the chunk from desc-loadfile")
    end

  end
  --]]
  --coroutine.yield("Descriptions (" .. desc_num .. ") done")


  -- EXTRA ------------------------------------------------------
  --[[
  if m.width > 640 or m.height > 480 then
    --print(self.width .. " " .. self.height)
    graphics.setCamTarget(p1.obj)
  else
    graphics.setCamTarget(nil)
  end
  --]]
  coroutine.yield("Loading done !", m)
end

function map:load(mapName, withAsset)
  if mapName == nil then return nil end
  -- Check if we're using a mapID
  if type(mapName) == "number" then
    mapName = MAP_NAMES[mapName]
  end

  local c1 = coroutine.create(map.load_with_routine)
  local status, message, map = nil
  print("MAP> --- Loading map " .. mapName .. " ---")
  while coroutine.status(c1) == "suspended" do
    status, message, map = coroutine.resume(c1, self, mapName, withAsset)
    if message then
      if platform == "LOVE" then
        --print("MAP> " .. message)
      else
        --print(message)
        graphics.setClearColor(0,0,0,1)
        graphics.printDebug(message, color.LGREY)
        graphics.renderFrame()
        if status == false then
          print("--ERROR--------------------------------")
          print("map:load() : " .. message)
        end
      end
    end
    if map then
      local t = "MAP> --- Map " .. mapName .. " done loading. ---"
      graphics.printDebug(t, color.LGREY)
      print(t)
      return map
    end
  end
  graphics.printDebug("ERROR LOADING " .. mapName .. " !!", color.ERROR)
end

function map:loadTexture(withAsset)
  local withAsset = withAsset or true

  if withAsset then
    self.texture = graphics.loadTexture(self.spritesheet)
    if      platform == "DC" then
      for i, obj in ipairs(self.objects) do
        if obj.textureName == "spritesheet.png" then
          obj.texture = C_newTextureFromID(self.texture)
          C_setTextureUV(obj.texture, obj.uv[1], obj.uv[2], obj.uv[3], obj.uv[4])
        end
      end

    elseif  platform == "LOVE" then
      for i, obj in ipairs(self.objects) do
        if obj.textureName == "spritesheet.png" then
          obj.texture = self.texture
        end
      end
    end
    graphics.printInfo("MAP> Loading " .. self.name .. " texture")
  else
    self.texture = nil
  end

end

function map.createWarp(xml_data)
    local obj = gameObject:copy(map.arrow)
    local r = xml_data["@warp"]:gmatch("%S+")

    obj.destination = xml_data["@warp"]
    --[[
    local x, y = string.match(xml_data["@warpPosition"], "(%-?%d+),(%-?%d+)")
    x = x or 0
    y = y or 0
    obj.spawnPosition = maf.vector(tonumber(x), tonumber(y))
    --]]

    --Position -----------
    if platform == "LOVE" then
      -- FROM CENTER
      obj.pos.x = (tonumber(xml_data["@x"]) + (obj.size.x * obj.scale.x) * 0.5)
      obj.pos.y = (tonumber(xml_data["@y"]) + (obj.size.y * obj.scale.y) * 0.5)

    elseif platform == "DC" then
      obj.pos.x = (tonumber(xml_data["@x"]) + (obj.size.x * obj.scale.x) * 0.5)
      obj.pos.y = (tonumber(xml_data["@y"]) + (obj.size.y * obj.scale.y) * 0.5)
    end

    -- Transforms(scale/angle)
    if xml_data["@transform"] ~= nil then
      if string.find(xml_data["@transform"], "rotate") ~= nil then
        obj.angle = tonumber(string.match(xml_data["@transform"], "(%-?%d+)"))
      end
      if string.find(xml_data["@transform"], "scale") ~= nil then
        local xScale, yScale = string.match(xml_data["@transform"], "(%-?%d+),(%-?%d+)")
        obj.scale:set(tonumber(xScale) * obj.scale.x, tonumber(yScale) * obj.scale.y)
      end
    end

    -- Get absolute center position post all angle/scale/bullshit
    obj.pos = obj:getPosition("abs")
    --print("MAP> Adding a warp going to " .. obj.destination)
    return obj
end

-- Trigger when the map is activated
function map:activate()
  if self.texture == nil and self.name ~= "overworld" then
    self:loadTexture()
  else
    print("MAP> No texture switch for " .. self.name .. " texture")
  end

  if self.width > 640 or self.height > 480 then
    graphics.setCamTarget(p1.obj)
  else
    graphics.setCamTarget(nil)
  end

  -- Scripts activate
  for i,v in ipairs(self.script) do
    v:activate()
  end

  -- This need to be after the scripts activates...
  saveload.restoreMapNpc(self)


  if self.bgm then audio.play(self.bgm, 127, true) end
end

-- Trigger before map is desactivate
function map:desactivate()
  if self.texture ~= nil and self.name ~= "overworld" then
    print("MAP> Desactivate -> Freeing " .. self.name .. " texture")
    for i, v in ipairs(self.objects) do
      v:freeTexture()
    end
    graphics.freeTexture(self.texture)
    self.texture = nil
  end

  graphics._label = function() end
  self.currentDescription = nil
  p1.obj.display = true

  -- scripts desactivates
  for i,v in ipairs(self.script) do
    v:desactivate()
  end

  if self.bgm then audio.stop(self.bgm) end

  graphics.printInfo(self.name ..  " desactivate")
end

function map:switch(mapName, position)
  local oldMapName = currentMap.name or "no_map"
  if type(mapName) == "number" then
    mapName = MAP_NAMES[mapName]
  end

  if currentMap ~= nil then
    currentMap:desactivate()
  end

  if maps[mapName] == nil then
    maps[mapName] = map:load(mapName)
    print("MAP.LUA> Loaded new map from " .. oldMapName .. " to " .. mapName)
  else
    print("MAP.LUA> Switch from " .. oldMapName .. " to " .. mapName)
  end
  maps[mapName]:activate()
  currentMap = maps[mapName]


  if maps[mapName].playerState then
    p1:setState(maps[mapName].playerState)
  else
    p1:setState("idle")
  end

  -- set position
  local w = maps[mapName]:findWarp(oldMapName)
  if w then
    position = w.pos
  end
  if position then
    p1:setPosition(position.x, position.y)
    graphics.setCamTarget(p1.obj)
    graphics.setCamPosition(p1.obj.pos.x, p1.obj.pos.y)
    for i=1, 10 do
      graphics.updateCamera()
    end
  end
end

function map:addLight(lightID)
  table.insert(self.lights, lightID)
end

--NOT USING GRAPHICS!!!
function map:renderFloor()
  --Could beusing UV wrapping and UV displacement...
  if floorTest ~= nil then
    local w, h = floorTest.size.x, floorTest.size.y
    local camX, camY = -graphics.camera.fPos.x, -graphics.camera.fPos.y
    local maxTile = 20
    local squeeze = 0.43

    local _x, _y = math.floor(camX / w), math.floor((camY / h) /0.43)

    graphics.push()
    love.graphics.translate(graphics.camera.size.x/2, -graphics.camera.size.y/2 - 100)
    --love.graphics.translate(100,50)
    love.graphics.scale(1, squeeze)
    --love.graphics.rotate(math.pi/4)
    for i=1, maxTile do
      for j =1, maxTile do
        local x = (i - j) * w/2
        local y = (j + i) * h/2

        x = x + (_x * w)
        y = y + (_y * h) --add something for the seqeeze

        love.graphics.draw(floorTest.texture, x, y, math.pi/4, 1, 1, w/2, h/2, 0, 0)
      end
    end
    graphics.pop()
  end
end

function map:renderMask()
  if self.masks == nil then return 0 end
  for i, v in ipairs(self.masks) do
    graphics.drawMask(v)
  end
end

function map:render(mode)
  if ss_debug == true and #self.colliders > 0 then
    --collision.draw(self.colliders)
  end

  if self.drawObjectFlag == true then
    --graphics.setDrawColor(draw_color)
    -- Spritesheet
    graphics.startBatch(self.texture)
    for i, v in ipairs(self.drawable) do
      --if v.display == true then
      graphics.addToBatch(self.objects[v])
      --end
    end
    graphics.endBatch(self.texture)


    -- Extra (no batch)
    for i, v in ipairs(self.extra) do
      v:drawObject()
    end

    if self.canWarp then self:renderWarps() end
  end
end

function map:renderDescription()
  -- Used for the description
  if p1.state == state.description and self.currentDescription then
     self.currentDescription()
   else
   end
end

function map:renderWarps()
  -- Warps
  local sin = math.sin
  local warpX, warpY
  for i, v in ipairs(self.warps) do
    warpX, warpY = v.pos.x, v.pos.y
    local d = sh4_distance(p1.obj.pos.x, p1.obj.pos.y, warpX, warpY)
    if d < 450 then
      graphics.setDrawColor(color.ACTIVE)
      graphics.setTransparency(math.max(1.0 - d*0.003, 0))
      local x, y, a = warpX, warpY, math.abs(v.angle)
      if a == 90 or a == 270 then
        x = x + sin(frameCount*0.05) * 10
      else
        y = y + sin(frameCount*0.05) * 10
      end
      v:drawObject(x, y)
      graphics.setDrawColor()
      graphics.setTransparency()
    end
  end
end

function map:update(deltaTime)
  if self.canWarp then
    for i, v in ipairs(self.warps) do
      if p1:press(v, "A") then
        currentMap:switch(v.destination)
        return 1
      end
    end
  end


  --local t = os.clock()
  if #self.objects > 0 then
    self.drawable = {}

    -- Main distance checking function
    local d, closest, clo_obj = 20, 100, nil
    local px, py = p1.obj.pos.x, p1.obj.pos.y
    local ox, oy = 0, 0
    local o = nil



    for i = #self.objects, 1, -1 do
      d = sh4_distance(px, py, self.objects[i].pos.x, self.objects[i].pos.y)
      --d = 10
      --if d < self.drawDistance and o.display == true then
      if d < self.drawDistance then
        -- This will be drawn on screen
        table.insert(self.drawable, 1, i)
        --table.insert(self.drawable, 1, o)
        -- Check if this is the closest object
        --[[
        if d < closest then
          -- Assign this object as the target
          --p1:setTarget(o)
          closest = d
        end
        --]]
      end
    end
  end
  
  --DCprof_cleanup()

  --print("SH4 DIST ALGO : " .. os.clock() - t)

  for i, v in ipairs(self.trig) do
    if p1.obj.pos:distance(v.pos) < v.trigger.range and self.currentDescription == nil and v.trigger.isDone == false then
    --if p1:isOver(v) and self.currentDescription == nil and v.trigger.isDone == false then
      local trig = v
      if trig.desc_file ~= nil then
        dialog.setFile(trig.desc_file, trig.desc_position)
      else
        dialog.setFile(self.desc_file, trig.desc_position)
      end
      local text, author, result = dialog.getText(trig)
      self.currentDescription = p1:inspect(text, nil, author, result)

      if trig.trigger.type == "REPEAT" then
        local pushBack = v.pos - p1.obj.pos
        p1.velocity:scale(0)
        pushBack:scale(-10)
        p1:addForce(pushBack)
      else
        trig.trigger.done = true --so it doesn't repat
        table.remove(self.trig, i)
      end
    end
  end

  updateScripts(self, deltaTime)
end

function map:addTrigger(obj, range, mode)
  -- mode : "REPEAT"
  if obj == nil then return nil end

  obj.trigger         = {}
  obj.trigger.type    = mode
  obj.trigger.range   = range or obj.size:length() * 0.5
  obj.trigger.isDone  = false
  table.insert(self.trig, obj)
  return #self.trig
end

function map:addObject(obj)
  if obj == nil then return nil end

  table.insert(self.objects, obj)
  -- check if has a npcID
  if obj.npcID ~= nil then
    table.insert(self.npcs, obj)
  end


  return obj
end

function map:getObject(npcID)
  for i, v in ipairs(self.extra) do
    if v.npcID == npcID then
      return v
    end
  end

  for i, v in ipairs(self.objects) do
    if v.npcID == npcID then
      return v
    end
  end
  --print("Map.lua> (getobject)" .. npcID .. " not found!")
end

function map:removeObject(npcID)
  for i, v in ipairs(self.extra) do
    if v.npcID == npcID then
      local obj = table.remove(self.extra, i)
      return obj
    end
  end

  for i, v in ipairs(self.objects) do
    if v.npcID == npcID then
      local obj = table.remove(self.objects, i)
      return obj
    end
  end
  --print("Map.lua> (getobject)" .. npcID .. " not found!")
end

function map:enableObject(npcID)
  local obj = self:getObject(npcID)
  if obj then
    obj.display = true
    obj.active = true
  else
  end
  --print("Map.lua> (getobject)" .. npcID .. " not found!")
end

function map:disableObject(npcID)
  local obj = self:getObject(npcID)
  if obj then
    obj.display = false
    obj.active = false
  else
  end
  --print("Map.lua> (getobject)" .. npcID .. " not found!")
end

function map:door(doorObj, mapName)
  print("map:door : KEYS ->")
  for k, v in pairs(p1.keychain) do print(k) end

  if p1.keychain[doorObj.npcID] then
    newMap = mapName
    currentMap:switch()
  end

  return nil, "no door key"
end

function map:delete()
  for i, v in ipairs(self.objects) do
    self.objects[i]:delete()
  end

  for k, v in pairs(self) do self[k] = nil end
  self = {}
end

function map:getMapInfo()
  return self.width, self.height, #self.objects
end

function map:getMapID(mapName)
  for i, v in ipairs(MAP_NAMES) do
    if v == mapName then
      return i
    end
  end
  return 0
end

function map:findWarp(destination)
  for i, v in ipairs(self.warps) do
    if v.destination == destination then
      return v
    end
  end
end

function map:clearDescriptions()
end
--------------------------------------------------------------------
function map:printData()
  for k, v in pairs(self) do
    print(k .. " > " .. v)
  end
end

function map:updateLights()
  local ACTIVE_DISTANCE = 800
  --Checks for new light to tunr on or off
  for i, v in ipairs(self.lights) do
    --check if the light is active
    if self.activeLights[i] ~= v then
      --if light is close enought
      if p1.obj.pos:distance(v.pos) < ACTIVE_DISTANCE then
        self.activeLights[i] = v
        --print("Activate " .. i)
      end
    end

    if self.activeLights[i] == v then
      if p1.obj.pos:distance(v.pos) > ACTIVE_DISTANCE then
        self.activeLights[i] = nil
        --print("Desactivate " .. i)
      end
    end
  end

  --Resets lights
  for i=3,10 do C_setLight("DISABLE", i, 0.0, 0.0, 0.0, 0.0) end

  --Actually open lights
  local l = 3
  for k, v in pairs(self.activeLights) do
      --print("ENABLE LIGHT " .. k)
      local d = (ACTIVE_DISTANCE - p1.obj.pos:distance(v.pos)) / (ACTIVE_DISTANCE/5)
      d = math.max(math.min(1.0, d), 0.0) * v.color[4] --color[4] = brightness

      C_setLight("ENABLE", l, 0.0, 0.0, 0.0, 0.0)
      C_setLight("SET_DIFFUSE", l, v.color[1] * d, v.color[2] * d, v.color[3] * d, 1.0)
      C_setLight("SET_POSITION", l, v.pos.x, v.pos.y, 75, 1.0)
      --C_writeFont("L:" .. k .. "-" .. l, v.pos.x, v.pos.y, 1)
      l = l + 1
  end
end

function map:setClearColor(r,g,b,a)
  love.graphics.setBackgroundColor(r, g, b, a)
end


--Loading functions--
function loadXML(filename_xml)
  local xml = newParser()

  local file = checkFile(filename_xml)
  if file == nil then return nil end

  local raw = love.filesystem.read(file)
  local xml_data = xml:ParseXmlText(raw)
  return xml_data
end

function loadSpritesheet(filename_json)
  local file = checkFile(filename_json)
  if file == nil then return nil end

  local raw = love.filesystem.read(filename_json)
  sprite_data = json.decode(raw)
  --print("MAP.LUA> Spritesheet decoded")
  return sprite_data
end

function getSpriteData()
  return sprite_data
end

return map
