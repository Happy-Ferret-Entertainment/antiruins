local demon = {}

--[[
  Each demon has a position, image, hp, speed, pattern?
  demon are strange small symbols, maybe animated.
]]

local demonType = {
  empty = {name="empty", img={"empty.png"}, hp=0, speed=0, aspd=0, dmg=0, reward=0, center={0,0}, color={0,0,0,0}},
  imp   = {name="imp", img={"bat1.png", "bat2.png"}, hp=1, speed=0.7, aspd=1, dmg=1, reward=1, center={8,8}, color={0,0,0.6,1}},
  troll = {name="troll", img={"troll1.png", "troll1.png"}, hp=15, speed=0.4, aspd=5, dmg=5, reward=5, center={16,16}, color={0,0.3,0.3,1}},
  golem = {name="golem", img={"troll1.png", "troll1.png"}, hp=20, speed=0.3, aspd=5, dmg=8, reward=8, center={16,16}, color={0.5,0,0.5,1}},
}

local demonCycle = {
  {demon=demonType.imp, qt=15, delay=2, spawnAfter=15}, -- +15 gp
  {demon=demonType.empty, qt=1, delay=5, spawnAfter=1}, 
  {demon=demonType.imp, qt=30, delay=1, spawnAfter=15}, -- +30 gp
  {demon=demonType.troll, qt=1, delay=3, spawnAfter=1},
  {demon=demonType.empty, qt=1, delay=30, spawnAfter=1},

  -- +45gp

  {demon=demonType.imp, qt=25, delay=0.7, spawnAfter=15}, -- +60 gp
  {demon=demonType.troll, qt=3, delay=7, spawnAfter=3},   -- +25 gp
  {demon=demonType.empty, qt=1, delay=20, spawnAfter=1},

  -- +85gp
  -- END OF LEVEL 1
  {goToLevel=2},
}

local cCycle = 1

function demon.init()
  demon.alive = {}
  for i=1,10 do 
    --table.insert(demon.alive, demon.spawn("imp", math.random()*2-1, math.random()*2-1))
  end

  -- init demon stuff
  for k, v in pairs(demonType) do
    __initDemon(v)
  end
end

function demon.startPhase()
  cCycle = 1
  __nextDemonCycle(demonCycle[cCycle])
end

function demon.spawn(type, x, y)
  --useful if you want to send a empty demon
  if type == nil or type.name == "empty" then return end

  --information that isn't modified, copy by value!
  local d   = {}
  d.type    = type --stuff that are no modified
  d.hp      = d.type.hp
  d.img     = d.type.img
  d.isDemon = true
  d.isAttacking = false

  -- new information related to each demon
  d.pos   = maf.vector(x * 320, y * 240)
  d.pos:normalize()
  d.pos:scale(320)

  d.dest = maf.vector(0, 0)
  d.dir  = maf.vector(d.pos) -- copy this position to simplfy later calculation
  d.dir:sub(d.dest)
  d.dir:normalize()
  d.dir:scale(d.type.speed)

  d.delete = function(self)
    self.status = "DEAD"
  end

  local w, h = 16, 16
  if d.img then
    d.w = d.img[1].w
    d.h = d.img[1].h
  end

  world:add(d, d.pos.x, d.pos.y, d.w, d.h)
  table.insert(demon.alive, d)
  return d
end

function demon.update()
  demon.goToTower()
  demon.checkDeath()
end

function demon.render()
  local fr = 1
  for i, v in ipairs(demon.alive) do
    if v.img ~= nil then
      fr = math.floor(realTime * 10)%2 + 1
      graphics.setDrawColor(v.type.color)
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
    tempPos:set(v.pos)
    dist = math.abs(tempPos:distance(towerPos))
    if dist > 50 then
      tempPos:sub(v.dir)
      newX, newY, cols, lenght = world:move(v, tempPos.x, tempPos.y, __demonCollider)
      v.pos:set(newX, newY)
    elseif v.isAttacking == false then
      v.isAttacking = true
      v.attackTimer = timer.every(v.type.aspd, function()
        tower:damage(v.type.dmg)
      end)
    end
  end
end

function demon.checkDeath()
  for i, v in ipairs(demon.alive) do
    if v.hp <= 0 then
      v.status = "DEAD"
    end

    if v.status == "DEAD" then
      addGold(v.type.reward)
      if v.attackTimer then
        timer.cancel(v.attackTimer)
      end
      world:remove(v)
      table.remove(demon.alive, i)
    end
  end
end

function demon.getCycle()
  return cCycle
end

function __nextDemonCycle(cycle)
  if cycle == nil then
    return
  end

  if cycle.goToLevel then
    print("Going to level " .. cycle.goToLevel)
    cCycle = 1
    toggleState(STATE.build)
    return
  end

  local spawnAfter = cycle.qt - cycle.spawnAfter
  print("Spawning " .. cycle.qt .. " " .. cycle.demon.name .. " every " .. cycle.delay .. " second(s)")
  local realCycle = cCycle

  timer.every(cycle.delay, function()
    demon.spawn(cycle.demon, math.random()*2-1, math.random()*2-1)
    cycle.qt = cycle.qt - 1

    -- using equal so it owny does this on the exact count
    if cycle.qt == spawnAfter then
      cCycle = cCycle + 1
      __nextDemonCycle(demonCycle[cCycle])
    end

    -- spawn the next demon cycle
    if cycle.qt <= 0 then
      print("Cycle " .. realCycle .. " ended")
      return false
    end
  end)
end

function getRandomDemon()
  local r = math.random(#demon.alive)
  return demon.alive[r]
end

function getFirstDemon()
  return demon.alive[1]
end

function __initDemon(d)
  for i, v in ipairs(d.img) do
    d.img[i] = graphics.loadTexture("assets/" .. d.img[i])
  end
  d.isDemon = true
end

function __demonCollider(item, other)
  return "bounce"
end

return demon