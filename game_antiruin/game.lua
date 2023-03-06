local gw = {}   
Timer     = require "lib.hump_timer"
utils     = require "utils"
flux      = require "lib.flux"


teller    = require "teller"
myth      = require "myth_souls"
wgfx      = require "wgfx"
console   = require "console"
map       = require "map"
 -- GLOBAL VARIABLES


updateOnInput   = false

local STATE, NEW_STATE = 0, 0
ST_ENCOUNTER  = 1
ST_MAP        = 2

local chapter   = 0

local dialogs   = {}
local cardSeq   = {} -- hold our card progression
local item      = {} -- our inventory
local destination = {} -- our next destination (as a card)
bgImg       = nil
bgColor     = {r=0.0,g=0.0,b=1.0,a=1.0}



local diaX, diaY = 320, 380

local persona = {
    grit    = 0, --strenght, resilence, will to live
    wis     = 0, --reflextion, instinct, mystery
    ego     = 0, --self worth, charm, beauty
}

-- Game Create
function gw.create()
  math.randomseed(os.time()) math.randomseed(os.time()) math.randomseed(os.time())
  console.init()
  teller.init()
  map.init()
  myth.newQuest()
  myth.change("intro")
  updateOnInput = true
  changeState(ST_MAP)
  resetProgress()
end

-- [[ GAME UPDATE ]] --------------------------------------------
function gw.update(dt)
  deltaTime = dt
  flux.update(dt)
  Timer.update(dt)
  
  
  if STATE == ST_ENCOUNTER then
    teller.update()
    console.update()
    if lProgress ~= progress then
      myth.update(progress)
      lProgress = progress
    end
  elseif STATE == ST_MAP then
    map.update()
  end
  
  if input.getButton("X") then
    nextState()
  end

  if NEW_STATE ~= STATE then
    STATE = NEW_STATE
  end

end

-- [[ GAME RENDER ]] --------------------------------------------
function gw.render(dt)
    graphics.setClearColor(0.1,0.1,0.1,1)
    --renderBg()

    if STATE == ST_ENCOUNTER then
        myth.render()
        teller.render()
        console.print()
    elseif STATE == ST_MAP then
        map.render()
    end

    --wgfx.bg()
end

function addToInventory(card)
    local copyPresent = false
    for i, v in ipairs(item) do
        if v.name == card.name then
            copyPresent = true
        end
    end

    if copyPresent == false then
        table.insert(item, card)
        print("added to inventory :", card)
    end
end

function addToMyth(card)
    table.insert(cardSeq, card)

end

function setDestination(card)
    local card = card or teller.selected
    destination = card
    print("Setting destination to " .. card.name)
end

function displayInventory()
    if #item > 0 then
        graphics.print("Inventory :", 20, 20)
        --for i, v in ipairs()
    end
end

function changeBg(filename, newColor)
    if filename == nil then 
        bgImg = nil 
    else
        bgImg = graphics.loadTexture(filename)
    end

    if newColor then
        local c = newColor
        flux.to(bgColor, 0.5, {r = c[1], g = c[2], b = c[3], a = c[4]})
    end
end

function renderBg()
    if bgImg then
        graphics.drawTexture(bgImg, nil, 320, 240, "center")
    end
end

function setInput(state)
    --updateOnInput = state
end

function changeState(newState)
  NEW_STATE = newState

  if NEW_STATE == ST_MAP then
    map.onSwitch()
  end


end

function resetProgress()
  progress, lProgress = 0, 0
end

return gw

