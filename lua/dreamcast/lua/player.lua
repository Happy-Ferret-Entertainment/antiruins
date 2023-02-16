local newButton = 0
local maf       = require "lib.maf"
local itemList  = require "item_list"
local quests    = require "questlist"

local player = {}
player.__index = player
setmetatable(player, {__call = function(cls, ...) return csl.new(...) end,})

local ACTION = {
  A  = nil,
  B  = nil,
  X  = nil,
  Y  = noAction,
  --START   = function() menu.set("save") end,
}

local MOUVEMENT = {
  UP      = function(cont) cont.joy.y = -128 end,
  DOWN    = function(cont) cont.joy.y = 128  end,
  LEFT    = function(cont) cont.joy.x = -128 end,
  RIGHT   = function(cont) cont.joy.x = 128  end,
}

-- GLOBAL!!!
state = {
  idle        = 1,
  inventory   = 2,
  radio       = 3,
  description = 4,
  menu        = 5,
  repair      = 6,
  overworld   = 7,
  arcade      = 8,
}

local nextState     = state.idle
local previousState = state.idle
--[[BASICS]]--------------------------
function player:new()
  local playerData = {
    obj       = gameObject:new(),
    velocity  = maf.vector(0, 0),
    force     = maf.vector(0, 0),
    size      = maf.vector(5, 5),
    npcID     = "redrick",
    velScale  = 0.90,
    speed     = 0.6,
    maxSpeed  = 2,
    cont      = {},
    scale     = 1.0,
    alpha     = 1.0,
    active    = true,
    display   = true,
    state     = state.idle,
    target    = nil,

    -- Access
    menuAccess  = true,
    invAccess   = true,

    -- Inventory
    inventory = {},

    -- Scripts
    scripts   = {},

    -- Maps
    currentMapName = "",

    -- Quest
    quests     = {},
    currentQuest = NO_QUEST, -- NO-QUEST = 0

    -- Tag
    canMove = true,

    access = {
      queen   = false,
      harbour = false,
    }
  }

  if platform == "LOVE" then
    playerData.obj = gameObject:createFromFile("asset/romdisk/arrow_20.png", 320, 240)
  else
    playerData.obj = gameObject:createFromFile("asset/romdisk/arrow.png", 320, 240)
  end

  local self = setmetatable(playerData, player)
  self.obj.lPos = maf.vector(0,0)

  self:loadSFX()
  --self:loadAssets()
  self.walkMode = false
  self.collide = false

  self.VMU_repair = vmu.createAnimation("repair", 3, 0.2, 2)

  event:register("use_tool", self.useTool)
  --event:register("quest_update")
  event:register("tooltip_player", function(text)
    local x, y =
    graphics.label_delay(text, p1.obj.pos.x, p1.obj.pos.y + 20, nil, "center", 2000)
  end)

  return self
end


-- UPDATE -----------------------------------
function player:updatePlayer(deltaTime)
  -- happens all the time
  local c = input.getController("copy")
  self:updateController(c)
  self:checkCollision()

  -- I'M NOT SURE ABOUT THIS.....
  p1:getOver()

  if self.state ~= nextState then
    previousState = self.state
    self.state = nextState
  end

  if self.state == state.idle then
    self:updateMovement()

    if self.target ~= nil then
      if self.target.canRepair == ITEM_BROKEN then
        vmu.playAnimation(self.VMU_repair, 3, true)
      end
    end

    -- Inspect routine
    if p1:getButton("A") then
      self:inspectRoutine()
    end

    -- open inventory
    if self:getButton("X") then
      p1:toggleInventory()
    end

    if self:getButton("QUICKSAVE") then
      saveload:save(3)
    end

    -- activate map
    if self:getButton("START") then
      self:toggleOverworld()
    end

    -- edit mode
    if self:getButton("EDIT") then
      editor.toggle()
    end

    -- show log
    if self:getButton("LOG") then
      --log.toggle()
    end

    return 1
  end

  if self.state == state.description then


    -- open inventory
    if self:getButton("X") then
      --p1:toggleInventory(true)
    end

    -- activate map
    if self:getButton("START") then
      self:toggleOverworld()
    end
  end

  if self.state == state.overworld then
    -- activate map
    if self:getButton("START") or self:getButton("B") then
      self:toggleOverworld()
    end

    maps.overworld:update(deltaTime)
    --self:updateMovement()
  end

  if self.state == state.inventory then
    self:updateInventory()

    if self:getButton("B") then
        p1:toggleInventory(false)
    end

    if self:getButton("X") then
      p1:toggleInventory(false)
    end
  end

  if self.state == state.radio then
  end

  if self.state == state.arcade then
    self:updateMovement()
  end

  if self.state == state.repair then
    local r = repair:update()

    if self:getButton("B") then
      self:setState("idle")
    end

    -- if object is repaired
    if r == true then
      self:setState("idle")
    end
  end

  if self.state == state.menu then
  end
end

function player:updateMovement()
  if self.active == false then
    self.velocity:set(0, 0)
    return nil
  end

  -- Saving last position (for direction)
  self.obj.lPos:set(self.obj.pos.x, self.obj.pos.y)

  self.cont.joy:scale(self.speed/128)

  if self.collide ~= true then
    self:addForce(self.cont.joy)
  else
    self:resetDynamic()
    self:addForce(-self:getDirection(3))
  end

  -- Regular physics
  self.velocity :add(self.force)
  if self.velocity:length() > self.maxSpeed then
    self.velocity = self.velocity:normalize() * self.maxSpeed
  end

  self.obj.pos  :add(self.velocity)

  if currentMap ~= nil then
    if self.obj.pos.x < 0 then self.obj.pos.x = 0 end
    if self.obj.pos.y < 0 then self.obj.pos.y = 0 end
    if self.obj.pos.x > currentMap.width  then self.obj.pos.x = currentMap.width end
    if self.obj.pos.y > currentMap.height then self.obj.pos.y = currentMap.height end
  end

  self.velocity :scale(self.velScale)
  self.force    :scale(0)
  return self.position
  --print("Player Pos X" .. self.obj.pos.x .. " Y" .. self.obj.pos.y )
end

function player:updateController(controller)
  --if editor.active == true then return 0 end
  self.cont       = controller

  -- Might want to add a condition here based on DPADs etc
  if self.cont.buttonPressed["UP"]    then self.cont.joy.y = -128 end
  if self.cont.buttonPressed["DOWN"]  then self.cont.joy.y = 128 end
  if self.cont.buttonPressed["RIGHT"] then self.cont.joy.x = 128 end
  if self.cont.buttonPressed["LEFT"]  then self.cont.joy.x = -128 end
end

function player:addForce(force)
  local maxSpeed = 10
  self.force:add(force)
  if self.force:length() > maxSpeed then
    --self.force:normalize():scale(maxSpeed)
  end
end

function player:getDirection(length, withPosition)
  local d = self.obj.pos - self.obj.lPos
  d:set(self.cont.joy)
  d:normalize()
  d:scale(length)

  if withPosition == nil then
    return d
  end

  d = self.obj.pos + d
  return d
end

function player:walk(direction)

  if self.isWalking == false then
    self.cFrame = self.cFrame + 0.2
    if self.cFrame > 7 then self.cFrame = 1 end
  end

  local f = math.floor(self.cFrame)

  if direction == "right" then self.obj.scale:set(1, 1) end
  if direction == "left"  then self.obj.scale:set(-1, 1) end
  if direction == "up"    then f = f + 7 end
  if direction == "down"  then end

  self.obj:setTexture(self.frames[f])
  self.isWalking = true
end

function player:resetDynamic()
  self.force:set(0,0)
  self.velocity:set(0,0)
end

function player:checkCollision()
  if #currentMap.colliders > 0 then
    local dir = self:getDirection(15, true)
    local tri = 0
    self.collide, tri = collision.check(dir, currentMap.colliders)
  end
end
-----------------------------------------

-- INPUT -----------------------------
function player:getButton(key)
  if self.cont.newButton == false then return false end

  if self.cont.buttonPressed[key] == true and self.cont.lButton[key] == false then
    return true
  else
    return false
  end
end

function player:holdButton(key)
  return self.cont.buttonPressed[key]
end

function player:hold(obj, key, precision)
  if key == nil or self.cont.buttonPressed[key] == false then return nil end

  --Check for current button press
  if self.cont.buttonPressed[key] == true then
    --Check if player is over an object
    if obj == nil then
      return true
    elseif self:isOver(obj, precision) then
      return true
    end
  end

  return false
end

function player:press(obj, key, precision)
  if key == nil or self.cont.newButton == nil then return nil end

  --Check for current button press
  if self:getButton(key) then
    --Check if player is over an object
    if obj == nil then
      return true
    elseif type(obj) == "table" then
      if self:isOver(obj, precision) then
        return true
      end
    else
      for i, v in ipairs(currentMap.objects) do
        if v.npcID == obj or v == obj then
          if self:isOver(v, precision) then
            return true
          end
        end
      end
    end
  end

  return false
end

function player:newInput()
  return self.cont.newButton
end

function player:isOver(target, precision)
  local target = target

  if type(target) == "string" then
    target = currentMap:getObject(target)
  end

  if target == nil or target.active == false then return false end
  local a = {}
  local b = {}

  local precision = precision or target.hitSize
  precision = math.max(precision, 15)

  local d = sh4_distance(self.obj.pos.x, self.obj.pos.y, target.pos.x, target.pos.y)
  if d < precision then
    return true
  else
    return false
  end
end

function player:getOver(mode)

  -- reverse order, from front to bottom
  local obj
  for i = #currentMap.npcs, 1, -1 do
    obj = currentMap.npcs[i]
    if p1:isOver(obj) then
      p1.target = obj
      return obj
    end
  end

  for i, v in ipairs(currentMap.extra) do
    if p1:isOver(v) then
      p1.target = v
      return v
    end
  end

  p1.target = nil
  return nil
end

function player:getOverID()
  local t = self:getOver()
  print(t.npcID)

  if t then
    return t.npcID
  else
    return ""
  end
end

---------------------------------------------------------------



-- Quest ----------------------------------------------------------
function player:addQuest(quest, progress)
  if quest == nil then return nil end
  local quest = quest

  -- Converting quest constants
  if type(quest) == "number" then
    for k, v in pairs(quests) do
      --print(k)
      if v.id == quest then
        quest = v
      end
    end
  end

  if self.quests[quest.id] == nil then
    -- Loading quest files
    if quest.file then
      local f = checkFile("asset/quests/" .. quest.file .. ".lua")
      if f then
        local r = attachScript(game_scripts, f)
        if r then print("PLAYER> Quest " .. quest.name .. " script loaded.") end
      end
    end
    self.quests[quest.id]           = quest
    self.quests[quest.id].progress  = progress or Q_ACTIVE

    print("PLAYER> Quest " .. quest.name .. " added. ")
  end
end

function player:removeQuest(quest, status)
  local quest = quest or nil
  local status = status or Q_DONE
  if quest == nil then return nil end

  -- Converting quest constants
  if type(quest) == "number" then
    for k, v in pairs(quests) do
      if v.id == quest then
        quest = v
      end
    end
  end

  -- Loading quest files
  if self.quests[quest.id] ~= nil then
    self.quests[quest.id].progress = status
    print("PLAYER> Quest " .. quest.name .. " removed with status " .. status)
  end
end

function player:setQuest(questID, questState)
  local questState = questState or 1
  if self.quests[questID] ~= nil then
    self.quests[questID].progress = questState
    print("Player> Quest " .. self.quests[questID].name .. " going " .. questState)
  end
end

function player:hasQuest(quest)
  if quest == nil then return NO_QUEST end

  for k, v in pairs(self.quests) do
    if v.id == quest then
      return v.progress
    end
  end

  return NO_QUEST
end

-------------------------------------------------------------------

-- Actions -------------------------------------
function player:inspect(block, type, author, result)
  if block == nil then return nil end
  local block               = block
  local c, cTotal           = 1, 1 -- char
  local l, lTotal           = 1, #block-- line
  local isDone              = false -- check if the current desc is done
  local t                   = realTime + 10 -- default is 25
  local text                = ""
  local maxLine             = 2
  local result              = result or nil

  if block == nil then return nil end

  if type == nil then
    self:setState("description")
  elseif type == "radio" then
    maxLine = 1
  end
  --Put 2 lines in a single text-----
  local buffer = {}
  for i=1, maxLine do
    -- check for "empty" lines
    local line = table.remove(block, 1)
    if line and #line > 1 then
      table.insert(buffer, line)
    end
  end
  text = table.concat(buffer, "\n")
  cTotal = #text
  -----------------------------------


    -- Generator --------------------
  return function()
    if isDone == true then return false end

    -- Skip animation
    if type == "radio" then
    else
      if p1:getButton("A") and c > 2 then
        if c < cTotal then
          c = cTotal - 2
        else
          c = cTotal
          t = realTime - 1
          return
        end
      end
    end

    -- Delete after x second
    if realTime > t then
      -- Checks if there are still some lines to process.
      if lTotal > 2 then
        currentMap.currentDescription = self:inspect(block, type, author, result)
      else
        currentMap.currentDescription = nil
        if result then
          local t = loadstring(result)()
        end
        isDone = true
        p1:setState()
      end
    end

    -- Typing Effect
    if frameCount % 4 == 0 then
      c = c + 1
      if c > cTotal then
        t = realTime + 3
      end
    end

    -- Actual string
    if type == "radio" then
    else
      graphics.label(author, 50, 380, color.ACTIVE, "STATIC")
      graphics.label(string.sub(text, 1, c), 50, 400, color.WHITE, "STATIC")
    end
  end
end

function player:inspectRoutine(target)
  if self.active == false then return end

  local t = target or self:getOver()
  if t ~= nil and t.npcID and t.active then
    if t.desc_file ~= nil then
      --Set the file but also the NPC last file position
      dialog.setFile(t.desc_file, t.desc_position)
    else
      --Just set the file
      --print("Using map description")
      dialog.setFile(currentMap.desc_file, t.desc_position)
    end
    local text, author, trigger = dialog.getText(t)
    currentMap.currentDescription = self:inspect(text, nil, author, trigger)
  end
end

-- repair tool
function player:useTool(arg)
 local obj = self:getOver()

 if obj ~= nil then
   if     obj.canRepair == nil then
     graphics.label_delay("Invalid", p1.obj.pos.x, p1.obj.pos.y - 30)
      table.insert(arg, false)
     arg[1] = false
   elseif obj.canRepair == ITEM_BROKEN then
     table.insert(arg, true)
     repair:generate(obj)
     self:toggleInventory(false)
     self:setState("repair")
     arg[1] = true
     return true
   elseif obj.canRepair == ITEM_REPAIRED then
     graphics.label_delay("Invalid", p1.obj.pos.x, p1.obj.pos.y - 30)
    arg[1] = false
     return false
   end
 end
 graphics.label_delay("Invalid target", p1.obj.pos.x, p1.obj.pos.y - 30)
 arg[1] = false
end

function player:pickItem(obj, tooltip)

  local obj = itemList.find(obj)
  if obj == nil then return nil end
  table.insert(self.inventory, obj)
  local tt =  obj.name .. " added to inventory."
  if tooltip == false then

  else -- print tooltip
    graphics.addTooltip(tt, 20, 20, 3)
    audio.play(audio.sfx.pickObject, 0.7, false, "SFX")
  end

  --obj.active  = false
  --obj.display = false

  return obj
end

function player:useItem(obj)

end

function player:hasItem(_item)
  local item = itemList.find(_item)
  if item == nil then return false end

  for i, v in ipairs(self.inventory) do
    if v.name == item.name then print("Player> has item " .. v.name) return true end
  end

  print("Player> doesn't have item " .. item.name)
  return false
end
player.hasObject = player.hasItem

function player:toggleInventory(newState)
  if self.invAccess == false then return nil end

  itemList.active = newState or not itemList.active
  audio.play(self.SFX[1], 175, false)

  if itemList.active == true then
    self:setState("inventory")
  else
    self:setState()
  end
end

function player:displayInventory()
  itemList.display(self.inventory, self.obj.pos.x + 5, self.obj.pos.y + 5)
end

function player:updateInventory()
  itemList.update(self.inventory)
end

-- Overworld ------------------------------------------------------------
function player:toggleOverworld()
  if self.menuAccess == false then return nil end

  if self.state == state.overworld then
    p1:setState()
  else
    currentMap.currentDescription = nil
    event:emit("reset_menu_position")
    event:emit("update_repair_info")
    --event:emit("update_save_data")
    p1:setState("overworld")
  end
end

---------------------------------------------------------------------------

-- Sounds / SFX------------------------------------------------------------
function player:loadSFX()
  self.SFX = {}
  self.SFX[1] = audio.load("sfx/click.wav", "SFX")
  self.SFX[2] = audio.load("sfx/neg2.wav", "SFX")
  print("PLAYER> Loading sounds assets.")
end

function player:playSFX(name)
  if name == "negative" then
    audio.play(self.SFX[2], 0.3)
  end
end

----------------------------------------------------------------------------

-- Physics ----------------------------------------------------------------


-- RENDER ------------------------------------------------------------
function player:renderShadow()
  if self.active ~= false then
    self.obj.angle = 0
    self.obj:drawTexture(self.obj.texture_ombre)
  end
end

function player:render()
  --local x, y = math.floor(self.obj.pos.x), math.floor(self.obj.pos.y)
  --graphics.setDrawColor()

  if self.target ~= nil then
    graphics.setDrawColor(color.ACTIVE)
    self.obj:drawObject()
    graphics.setDrawColor()
  else
    graphics.setDrawColor(1,1,1,1)
    self.obj:drawObject()
    graphics.setDrawColor()
  end

  if itemList.active and #self.inventory > 0 then
    p1:displayInventory()
  end
end
-------------------------------------------------------------------------


-- Generic way to write next to cursor
function player:label(string)
  --graphics.label(string, self.obj.pos.x + 2, self.obj.pos.y + 2)
  graphics.label(string, 50, 400, color.WHITE, "STATIC")
end


--[[SAVE/LOAD]]-------------------------------------
function player:delete()
  self.obj:delete()
  self.velocity   = nil
  self.force      = nil
  self.size       = nil
end

-------------------------------------------------------
function player:setState(newState)
  if state[newState] == self.state then return end
  local newState = newState or "idle"

  nextState = state[newState]
  print("Player> P1 state = " .. tostring(newState) .. " > " .. tostring(nextState))
  return nextState
end

-- RENDER/ACTIVATEW THE PLAYER ------------------------
function player:setActive(state)
  --stupid trick because you can't false or true
  if state == nil then state = true end
  self.active = state
  self.obj.display = state
  return state
end

function player:setVisible(state)
  if state == nil then state = true end
  self.obj.display = state
  return state
end

function player:setPosition(x, y)
  self.obj.pos.x, self.obj.pos.y = x, y
end

function player:getPosition(mode)
  local mode = mode or nil
  if mode == "string" then
    local s = "X " .. math.floor(self.obj.pos.x) .. " Y " .. math.floor(self.obj.pos.y)
    return s
  elseif mode == "vector" then
    return self.obj:getPosition()
  else
    return self.obj.pos.x, self.obj.pos.y
  end
end

function player:addToKeychain(keyName, status)
  local status = status or 1
  self.keychain[keyName] = status
end

function player:addToMap(mapName)
  if self.visitedMap[mapName] == nil then
    p1.visitedMap[mapName] = 1
  end
end

function player:hasVisited(mapName)
  return p1.visitedMap[mapName]
end


function player:canCast() if self.castSpell == "none" then return 1 else return nil end end
function player:cantCast() return not self:canCast() end
function player:newButton() return self.cont.newButton end

return player
