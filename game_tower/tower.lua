local tower   = {}
local maf     = require "lib.maf"
local bump    = require "bump"
local button  = require "button"
local flux    = require "flux"

local WEAPON = require "weapons"


WEAPON_LIST = {WEAPON.crossbow, WEAPON.repair}
UPGRADE_LIST  = {} -- this get refreshed when the gold counts goes up
UPGRADE_PRICE = {}

local menuIndex = 1
local wButtons = {}

function tower.init()
  tower.pos   = maf.vector(0, 0)
  tower.maxHp = 40
  tower.hp    = tower.maxHp
  tower.color = {0.5, 0.5, 0.5, 1}

  tower.img = graphics.loadTexture("assets/tower_white_sm.png")
  tower.aim = maf.vector(0,-1)

  -- UPGRADING SYSTEM
  tower.upgradeAvailable  = false
  tower.isUpgrading       = false
  tower.cUpgrade          = {
    progress = 1,
  }

  __initWeapons()
  --tower.weapons[1].active = true
  tower.bullets = {}
  tower.aoe     = {}
  tower:activateWeapons()
  
  --world:add(tower, tower.pos.x, tower.pos.y, 64, 64)

  __initGUIWeapons()
  __loadTowerSFX()

  
end

--[[ UPDATE FUNCTIONS ]] ---------------
function tower:update()
  if tower.status == "DEAD" then 
    return 

  end
  

  if tower.weaponActive then
    tower:updateBullets()
    tower:updateAoe()
  end
end

function tower:updateBullets()
    -- shoot some guns
    local nX, nY, cols = 0, 0, {}
    local nPos  = maf.vector()
    local demon = {}
    for i, v in ipairs(tower.bullets) do
      nPos:set(v.pos)
      nPos:add(v.dir)
      nX, nY, cols = world:move(v, nPos.x, nPos.y, __collisionFiler)
      --print(nX, nY)
      if #cols > 0 then
        if cols[1].other.isDemon then
          demon = cols[1].other
          demon.hp = demon.hp - v.dmg
          if v.area then
          else
            v.status = "DEAD"
          end
          if v.repair then
            tower:repair(v.repair)
          end
          -- also delete bullet
        end
      end
      v.pos:set(nX, nY)
      --v.pos:set(nPos)
    end
  
    -- MAKE SURE THIS LINE UP WITH COORD SYSTEM
    for i, v in ipairs(tower.bullets) do
      if      v.pos.x > 320 or v.pos.x < -320
          or  v.pos.y > 240 or v.pos.y < -240 then
          v.status = "DEAD"
      end
  
      if v.status == "DEAD" then
        world:remove(v)
        table.remove(tower.bullets, i)
      end
    end
end

function tower:updateAoe()
  local items, len = {}, 0
  for i, v in ipairs(tower.aoe) do

    items, len = world:queryRect(v.pos.x, v.pos.y, v.size.x, v.size.y)
    if len > 0 then
      for _, d in ipairs(items) do
        if d.isDemon then
          d.hp = d.hp - v.dmg
        end
      end
    end
  end

  for i, v in ipairs(tower.aoe) do
    if v.status == "DEAD" then
      table.remove(tower.aoe, i)
    end
  end
end

function tower:updateAim()
  if tower.autoaim == true then return false end
  local aim = input.getAxis()
  -- some mouse input?
  if input.hasMouse then
    aim = input.getMouse()
    aim.x, aim.y = aim.x - 320, aim.y - 240
  end
  aim:normalize()

  local diff = aim - tower.aim
  diff:normalize()
  diff = diff:scale(95)

  tower.aim = tower.aim:add(diff)
  tower.aim:normalize()
end
----------------------------------------

--[[ RENDER FUNCTIONS ]] ---------------
function tower:render(dt)
  -- tower animation
  flux.update(dt)

  graphics.setDrawColor(self.color)
  graphics.drawTexture(self.img, 0, 40, "center")

  -- upgrades
  tower:renderUpgrade()

  if tower.weaponActive then
    tower:renderBullet()
    tower:renderAoe()
  end

  if tower.status == "DEAD" then
    local c = math.sin(love.timer.getTime()/1000)
    graphics.setDrawColor(c, 0,0,1)
    graphics.print("TOWER DESTROYED", 0, -100, {}, "center")
  end

  tower:renderAim()
end

function tower:renderUpgrade()
  --[[
  if #tower.upgrade == 0 then
    graphics.print("No upgrade available", self.pos.x, self.pos.y + 120, {}, "center")
  else
    for i, v in ipairs(tower.upgrade) do
      graphics.print("Upgrade to " .. v.name, self.pos.x, self.pos.y + 120, {}, "center")
    end
  end
  --]]
  if tower.isUpgrading then
    graphics.drawRect(-50, 120, tower.cUpgrade.progress, 10)
  end
end

function tower:renderBullet()
    -- shooting bullets
    for i, v in ipairs(tower.bullets) do
      graphics.setDrawColor(v.color)
      if v.img then
        graphics.drawTexture(v.img, v.pos.x, v.pos.y, "center")
      else
        graphics.print(v.ascii, v.pos.x, v.pos.y-10, v.color,"center")
      end
    end
end

function tower:renderAoe()
  for i, v in ipairs(tower.aoe) do
    graphics.setDrawColor(v.color)
    if v.img then
      graphics.drawTexture(v.img, v.pos.x, v.pos.y)
      -- this is to check collider
      graphics.setDrawColor(1,0,0,0.5)
      --graphics.drawRect(v.pos.x, v.pos.y, v.size.x, v.size.y)
    else
      graphics.print(v.ascii, v.pos.x, v.pos.y)
    end
  end
end

function tower:renderAim()
  if tower.autoaim == false then return end
  local pos       = getTowerPosition()
  local dirScale  = tower.aim:scale(100)
  graphics.setDrawColor(1,0,0,1)
  graphics.push()
  graphics.translate(pos.x + dirScale.x, pos.y + dirScale.y)
  graphics.print("+", 0, 0)
  graphics.pop()
  graphics.setDrawColor()
end
----------------------------------------

function tower:shoot(weapon)
  local d = {}
  if weapon.active == false then return end

  if weapon.type == "repair" then
    tower:repair(weapon.repair)
    return
  end

  if tower.autoaim then
    d = getRandomDemon()
    if d == nil then return end
  else
    d = {pos = maf.vector(tower.aim)}
  end


  local bullet = {}
  bullet.pos    = maf.vector(0,0)
  bullet.dmg    = weapon.dmg
  bullet.repair = weapon.repair
  bullet.color  = copy(weapon.color)
  bullet.ascii  = weapon.ascii
  bullet.img    = weapon.img
  bullet.type   = weapon.type


  if weapon.type == "drop" then
    --bullet.pos = maf.vector(d.pos.x, d.pos.y)
    bullet.pos = maf.vector(math.random(-250, 250), math.random(-200, 200))
    bullet.dir = maf.vector(0,0)
    
    -- aoe size
    bullet.size = {x = bullet.img.w, y = bullet.img.h}

    table.insert(tower.aoe, bullet)    
    flux.to(bullet.color, 2, {0,0,0,0})
    timer.after(weapon.speed, function()
      bullet.status = "DEAD"
    end)
    return
  end

  
  bullet.dir = maf.vector(d.pos.x-tower.pos.x, d.pos.y-tower.pos.y)
  if d.isDemon then
    bullet.dir:add(maf.vector(d.type.img[1].w/2, d.type.img[1].h/2))
  end
  --check for range
  local rangeMod = weapon.range or 1
  local distance = bullet.dir:length()
  if distance > 250 * rangeMod then return end

  -- bullet speed
  local fSpeed = weapon.fSpeed or 2
  bullet.dir:normalize()
  bullet.dir:scale(fSpeed)
  
  -- bullet size
  local bSize = (weapon.area or 1) * 5
  world:add(bullet, bullet.pos.x, bullet.pos.y, bSize, bSize)
  table.insert(tower.bullets, bullet)

  -- audio
  --audio.play(tSFX[1])
end

function tower:damage(dmg)
  self.hp = self.hp - dmg

  if self:getHP("float") < 0.5 then
    self.status  = "DAMAGED"
    self.color    = {0.7,0.5,0.5,1}
    print("Tower status: " .. self.status)
  end

  if self:getHP("float") < 0.25 then
    self.status = "DANGER"
    self.color    = {1,0.3,0.3,1}
    print("Tower status: " .. self.status)
  end

  if self.hp <= 0 then
    self.hp = 0
    self.status = "DEAD"
  end
end

function tower:getHP(type)
  if type == "float" then
    return tower.hp / tower.maxHp
  end
  return math.floor(tower.hp)
end

function tower:repair(hp)
  tower.hp = tower.hp + hp
  if tower.hp > tower.maxHp then
    tower.hp = tower.maxHp
  end
end

function tower:startUpgrade(upgrade, id)
  -- check fi the tower is currently ugrading first
  if tower.isUpgrading then return end

  local enoughGold = removeGold(upgrade.cost)

  if not enoughGold then
    print("Not enough gold")
    return
  end

  if enoughGold then
    tower.isUpgrading = true
    tower.upgradeAvailable = false
    tower:desactivateWeapons()

    -- 100 * 1 = 100 second
    -- 100 * 0.5 = 50 second
    -- 100 * 2 = 200 second
    local upgradeSpeed = tower.weapons[id].upgradeLvl * 0.022
    timer.every(upgradeSpeed, function()
      tower.cUpgrade.progress = tower.cUpgrade.progress + 1

      -- when complete
      if tower.cUpgrade.progress == 100 then
        tower.isUpgrading       = false
        tower.cUpgrade.progress = 0
        local newWeapon = WEAPON_LIST[id]

        -- copying the weapon data
        for k,v in pairs(upgrade) do
          newWeapon[k] = v
        end

        if upgrade.hpBonus then
          self.maxHp = self.maxHp + upgrade.hpBonus
          self.hp    = self.hp + upgrade.hpBonus
        end

        tower.weapons[id]             = newWeapon
        tower.weapons[id].upgradeLvl = tower.weapons[id].upgradeLvl + 1
        tower.weapons[id].nUpgrade    = WEAPON_LIST[id].upgrades[tower.weapons[id].upgradeLvl]
        tower.weapons[id].active      = true
        wButtons[id]:setLabel(tower.weapons[id].nUpgrade.cost)
        --table.insert(tower.weapons, weaponID)
        tower:activateWeapons()
        return false
      end

    end)
  end
end

function tower:activateWeapons(id)
  local id = id or true
  for i, v in ipairs(tower.weapons) do
    for i=1, v.qt do
      v.timer = timer.every(v.speed, function()
        tower:shoot(v)
      end)
    end
  end
end

function tower:desactivateWeapons(id)
  for i, v in ipairs(tower.weapons) do
    if v.timer then
      timer.cancel(v.timer)
    end
  end
end

function getTowerPosition()
  return maf.vector(tower.pos)
end

function addGold(nb)
  gold = gold + nb
  --check next upgrade
  --__checkForUpgrade()
end

function removeGold(nb)
  if gold < nb then return false end
  timer.every(0.1, function()
    gold = gold - 1
  end, nb)
  return true
end

function __checkForUpgrade()
  for i, v in ipairs(WEAPON_LIST) do
    if gold == v.nUpgrade.cost then
      --print("Upgrade avail for " .. v.name)
      wButtons[i]:setLabel("+!")
      wButtons[i].onClick = function()
        tower:startUpgrade(v.nUpgrade, i)
      end
    elseif gold < v.nUpgrade.cost then
      wButtons[i]:setLabel(tower.weapons[i+1].nUpgrade.cost)
      wButtons[i].onClick = function()
        print("Not enough gold")
      end
    end
  end
end

function __initGUIWeapons()
  local weaponNb = 2
  local spacing = 5
  local sq = 40
  local x = 320 - ((weaponNb * sq) + (spacing * 3))/2
  --local x = 210 --calcultation above
  
  function mouseOver(button)
    gui.setTooltip(button.desc)
    --graphics.print(button.desc, button.x + button.w , button.y - 20, {}, "center")
  end

  function upgradeTower(button)
    --print("asda")
    tower:startUpgrade(tower.weapons[button.weaponId].nUpgrade, button.weaponId)
  end

  local nButton = {}
  local label = ""
  for i = 1, weaponNb do
    nButton = button:new(x + (i-1) * (sq + spacing), 480 - graphics.getFontSize() - 10, 40, graphics.getFontSize(), "someFile.png")

    nButton.weaponId = i
    nButton.desc = WEAPON_LIST[i].name

    label = tower.weapons[i].nUpgrade.cost
    nButton:setLabel(label)

    nButton.onHover = mouseOver
    nButton.onClick = upgradeTower
    

    table.insert(wButtons, nButton)
    gui.addButton(nButton)
  end
end

function __loadTowerSFX()
  tSFX = {}
  tSFX[1] = audio.load("assets/sfx/shoot1.wav", "static")
  tSFX[2] = audio.load("assets/sfx/shoot2.wav", "static")

end

function __initWeapons()
  -- load images and assets
  for k, v in pairs(WEAPON) do
    if v.img then v.img = graphics.loadTexture(v.img) end
    if v.qt == nil then v.qt = 1 end
  end

  -- WEAPON SYSTEM
  for i, v in ipairs(WEAPON_LIST) do
    v.upgradeLvl = 1 --add inital upgrade level
  end
  tower.weaponActive  = true  
  tower.autoaim       = true

  tower.weapons = {}
  for i, v in ipairs(WEAPON_LIST) do
    table.insert(tower.weapons, v)
    tower.weapons[i].active     = false
    tower.weapons[i].upgradeLvl = 1
    tower.weapons[i].nUpgrade   = WEAPON_LIST[i].upgrades[1]
  end
end

function __collisionFiler(item, other)
  if item.type == "drop" then
    return "cross"
  end
  if other.type == "demon" then
    return "touch"
  end


  return "slide"
end

return tower