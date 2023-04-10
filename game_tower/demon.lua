local demon = {}

--[[
  Each demon has a position, image, hp, speed, pattern?
  demon are strange small symbols, maybe animated.
]]

local demonType = {
  empty = {name="empty", img={"empty.png"}, hp=0, speed=0, aspd=0, dmg=0, reward=0, center={0,0}, color={0,0,0,0}},
  
  imp    =  {name="imp", img={"bat1.png", "bat2.png"}, 
            hp=1, speed=1, aspd=1, dmg=1, reward=1, color={0,0,0.6,1}},
  troll  =  {name="troll", img={"troll1.png", "troll1.png"}, 
            hp=12, speed=0.55, aspd=3, dmg=5, reward=5, color={0,0.3,0.3,1}},
  shield =  {name="shield", img={"troll1.png", "troll1.png"},
            hp=12, speed=0.55, aspd=3, dmg=5, reward=8, color={1,1,0,1}},
  bats   =  {name="bats", img={"bat1.png", "bat2.png"},
            hp=2, speed=0.7, aspd=1, dmg=1, reward=2, color={0.7,0,0.7,1}},
  banshee =  {name="banshee", img={"banshee.png", "banshee.png"},
            hp=15, speed=1.3, aspd=1, dmg=2, reward=6, color={0.45, 0.52, 0.75, 1}},
}


local lvl1 = {
  {demon=demonType.imp,   qt=15, delay=1, spawnAfter=15}, -- +15 gp
  {demon=demonType.empty, qt=1, delay=5, spawnAfter=1}, 
  {demon=demonType.imp,   qt=25, delay=0.8, spawnAfter=15}, -- +30 gp
  {demon=demonType.troll, qt=2, delay=3, spawnAfter=1},
  {demon=demonType.empty, qt=1, delay=20, spawnAfter=1},

  {demon=demonType.imp,   qt=25, delay=0.6, spawnAfter=15}, -- +60 gp
  {demon=demonType.troll, qt=5, delay=5, spawnAfter=3},   -- +25 gp

  {goToLevel=2},
}

local lvl2 = {
  {demon=demonType.imp,    qt=15, delay=1, spawnAfter=4}, -- +15 gp -- +30 gp
  {demon=demonType.troll,   qt=3, delay=5, spawnAfter=2},
  {demon=demonType.shield,  qt=3, delay=5, spawnAfter=2},

  {goToLevel=3},
}

local lvl3 = {
  {demon=demonType.bats,    qt=25, delay=0.5, spawnAfter=5},
  {demon=demonType.banshee, qt=1, delay=1, spawnAfter=1},
  {demon=demonType.imp,     qt=20, delay=0.5, spawnAfter=5},
}

local demonLevel  = {lvl1, lvl2, lvl3}
local cLevel      = 1
local cCycle      = 1

local assetLoaded = false

function demon.init()
  if demon.alive then
    for i, v in ipairs(demon.alive) do
      __destroyData(v)
    end
  end

  demon.spawns  = {} -- hold the spawn timers
  demon.alive   = {} -- demon entity alive
  demon.corpse  = {} -- demon entity dead (for ressurection)
  cCycle        = 1

  --load assets
  if assetLoaded == false then __initDemons() end

end

function demon.startPhase()
  cCycle = 1
  __nextDemonCycle(demonLevel[cLevel][cCycle])
end

function demon.spawn(type, x, y)
  --useful if you want to send a empty demon
  if type == nil or type.name == "empty" then return end

  --information that isn't modified, copy by value!
  local d   = {}
  d.type    = type --stuff that are no modified
  d.hp      = d.type.hp
  d.img     = d.type.img
  d.color   = {0,0,0,0}
  d.demon   = true
  d.isAttacking = false

  timer.tween(0.5, d.color, d.type.color, "in-out-cubic")

  if x == "border" then
    d.pos = maf.vector(math.random()*2-1, math.random()*2-1)
    d.pos:normalize()
    d.pos:scale(300)
  else
    d.pos   = maf.vector(x, y)
  end

  d.dest = maf.vector(0, 0)
  d.dir  = maf.vector(d.pos) -- copy this position to simplfy later calculation
  d.dir:sub(d.dest)
  d.dir:normalize()
  d.dir:scale(d.type.speed)

  d.onDeath = __onDeath
  d.onHit   = demon.hit

  local w, h = 16, 16
  if d.img then
    d.w = d.img[1].w
    d.h = d.img[1].h
  end

  d.timers = {}
  __addBehavior(d)
  
  world:add(d, d.pos.x, d.pos.y, d.w, d.h)
  table.insert(demon.alive, d)
  return d
end

function demon.update()
  demon.goToTower()
  demon.checkDeath()
end

function demon.render()
  for i, v in ipairs(demon.corpse) do
    if v.img ~= nil then
      graphics.setDrawColor(v.color)
      graphics.drawTexture(v.img[1], v.pos.x, v.pos.y)
    end
  end

  local fr = 1
  for i, v in ipairs(demon.alive) do
    if v.img ~= nil then
      fr = math.floor(realTime * 10)%2 + 1
      graphics.setDrawColor(v.color)
      graphics.drawTexture(v.img[fr], v.pos.x, v.pos.y)
    else
      --love.graphics.line(320,240,v.pos.x, v.pos.y)
      graphics.print("X", v.pos.x+4, v.pos.y-6)
    end
  end


end

function demon.goToTower()
  local dist      = maf.vector()
  local towerPos  = getTowerPosition()
  local tempPos   = maf.vector()
  local newX, newY = 0, 0
  local cols, lenght = {}, 0
  for i, v in ipairs(demon.alive) do
    if v.stun   then  goto skip end
    if v.shield then  goto skip end

    tempPos:set(v.pos)

    if v.flyby then
      tempPos:sub(v.dir)
      newX, newY, cols, lenght = world:move(v, tempPos.x, tempPos.y, __demonCollider)
      v.pos:set(newX, newY)
      goto skip
    end

    dist = math.abs(tempPos:distance(towerPos))
    if dist > 50 then
      tempPos:sub(v.dir)
      newX, newY, cols, lenght = world:move(v, tempPos.x, tempPos.y, __demonCollider)
      v.pos:set(newX, newY)
    elseif v.isAttacking == false then
      v.isAttacking = true
      local attackTimer = timer.every(v.type.aspd, function()
        tower:damage(v.type.dmg)
      end)
      table.insert(v.timers, attackTimer)
    end

    ::skip::
  end
end

function demon.checkDeath()
  for i, v in ipairs(demon.alive) do
    if v.hp <= 0 then
      v.status = "DEAD"
    end

    -- out of bound
    if      v.pos.x > 500 or v.pos.x < -500
        or  v.pos.y > 500 or v.pos.y < -500 then
            v.status = "DEAD"
    end

    if v.status == "DEAD" then
      __onDeath(v, i)
    end
  end

  for i, v in ipairs(demon.corpse) do
    if v.status == "DELETE" then
      table.remove(demon.corpse, i)
    end
  end
end

function demon.hit(d, dmg)
  d.hp = d.hp - dmg
  if d.hp <= 0 then return end
  
  local pColor = copy(d.color)
  d.color = {1, 0, 0, 1}
  timer.after(0.1, function()
    d.color = copy(pColor)
  end)

end

function demon.getCycle()
  return cCycle
end

function demon.getLevel()
  return cLevel
end

function getRandomDemon()
  local r = math.random(#demon.alive)
  return demon.alive[r]
end

function getRandomCorpse(mode, pos)
  if #demon.corpse == 0 then return nil end
  
  if mode == "closest" then
    local closest = nil
    local dist, closeDist = 0, 99999
    for i, v in ipairs(demon.corpse) do
      dist = math.abs(v.pos:distance(pos))
      if dist < closeDist then
        closest = v
        closeDist = dist
      end
    end
    return closest
  end

  local r = math.random(#demon.corpse)
  return demon.corpse[r]
end

function getFirstDemon()
  return demon.alive[1]
end

function __nextDemonCycle(cycle)
  if cycle == nil then
    return
  end

  if gameState ~= STATE.demon then return end

  if cycle.goToLevel then
    -- this could have problem if there is a lingering enemy outside of screen.
    timer.every(1, function()
      if #demon.alive == 0 then
        cLevel = cycle.goToLevel
        cCycle = 1
        startBuildPhase()
        return false
      end
    end)
    return
  end

  local spawnAfter  = cycle.qt - cycle.spawnAfter
  local realCycle   = cCycle
  local spawnQt     = cycle.qt

  print("Spawning " .. cycle.qt .. " " .. cycle.demon.name .. " every " .. cycle.delay .. " second(s)")
  local spawnTimer = timer.every(cycle.delay, function()
    demon.spawn(cycle.demon, "border")
    spawnQt = spawnQt - 1

    -- using equal so it owny does this on the exact count
    if spawnQt == spawnAfter then
      cCycle = cCycle + 1
      __nextDemonCycle(demonLevel[cLevel][cCycle])
    end

    -- spawn the next demon cycle
    if spawnQt <= 0 then
      print("Cycle " .. realCycle .. " ended")
      return false
    end
  end)
  table.insert(demon.spawns, spawnTimer)
end

function __initDemons(d)
  if assetLoaded == false then
    for _, d in pairs(demonType) do
      for i, v in ipairs(d.img) do
        d.img[i] = graphics.loadTexture("assets/" .. v)
        print("Loaded " .. v)
      end
    end
  end
  assetLoaded = true
end

function __onDeath(d, id)

  -- give gold
  addGold(d.type.reward)
  
  --delte collider
  world:remove(d)

  -- grey colored corpse
  d.color = {0.5, 0.5, 0.5, 0.7}
  table.insert(demon.corpse, d)
  table.remove(demon.alive, id)

  --color animation
  local corpseTime = 7
  timer.tween(corpseTime, d.color, {0.5, 0.5, 0.5, 0.3})
  timer.after(corpseTime, function()
    d.status = "DELETE"
  end)

  -- delete attack timer, etc
  for i, v in ipairs(d.timers) do
    timer.cancel(v)
  end 
end

function __destroyData(d)
    -- delete timers
    for i, v in ipairs(d.timers) do
      timer.cancel(v)
    end

    d = nil
end

function __demonCollider(item, other) 
  if item.flyby then
    return "cross"
  end

  if other.demon then
    return "cross"
  end

  if other.tower then
    return "touch"
  end



  return "cross"
end

function __addBehavior(d)
  if d.type.name == "shield" then
    d.shield = true
    __shieldInit(d)
  end
  
  if d.type.name == "bats" then
    d.drunk = true
    __drunkInit(d)
  end

  if d.type.name == "banshee" then
    d.ressurect = true
    d.resTarget = nil
    d.flyby     = true
    __ressurectInit(d)
  end
  --]]
end

function __shieldInit(demon)
  local t = timer.every(3, function()

    --if demon == nil  or demon.status == "DEAD" then return false end

    demon.shield = not demon.shield
    --print("Shield: " .. tostring(demon.shield))
    if demon.shield then
      demon.color = {1,1,0,1}
    else
      demon.color = {1,1,1,1}
    end
  end)
  table.insert(demon.timers, t)
end

function __drunkInit(demon)
  local t = timer.every(math.random(3, 5), function()
    demon.dir = maf.vector(math.random()*2-1, math.random()*2-1)
  end)
  table.insert(demon.timers, t)
end

function __ressurectInit(d)
  -- search for corpses
  local t = timer.every(1, function()
    if #demon.corpse == 0   then return end
    if d.stun               then return end

    -- does this work?
    d.resTarget = d.resTarget or getRandomCorpse("closest", d.pos)

    if d.resTarget ~= nil then -- check if the body is to be deleted.
      if d.resTarget.status == "DELETE" then
        d.resTarget = nil
      end
    end

    if d.resTarget == nil then
      --print("Banshee wandering, No corpse found")
      d.dir:set(math.random()*2-1, math.random()*2-1)
      return 
    end

    --print("Banshee found a corpse " .. d.resTarget.type.name, tostring(d.resTarget))
    --check distance between banshee and target
    local dist = d.pos:distance(d.resTarget.pos)
    d.dir:set(d.pos.x - d.resTarget.pos.x, d.pos.y - d.resTarget.pos.y)
    d.dir:normalize()
    d.dir:scale(d.type.speed)
    if dist < 35 then
      --print("Target within range, attempting ressurection")
      -- target is casting (stunned)
      d.stun = true
      timer.after(2, function()
        --ressurect target
        --("Target ressurected")
        local reborn = demon.spawn(demonType[d.resTarget.type.name], d.resTarget.pos.x, d.resTarget.pos.y)
        reborn.color = copy(demonType.banshee.color)
        d.resTarget.status   = "DELETE"
        d.resTarget          = nil
        d.stun = false
        return
      end)

    end
  end)

  table.insert(d.timers, t)
end

return demon