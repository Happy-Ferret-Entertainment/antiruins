local gw = {}   
local cards     = require "cards"
local flux      = require "lib.flux"
local myth      = require "myth"

 -- GLOBAL VARIABLES
selection   = {}
cardOnTable = false
selected    = 1
selCard     = {} -- shortcut to the selected card
showTitle   = true

local state = ""
local progress, lProgress  = 1, 0
local chapter   = 0

local dialogs   = {}
local cardSeq   = {} -- hold our card progression
local item      = {} -- our inventory
local destination = {} -- our next destination (as a card)
bgImg       = nil
bgColor     = {r=0.0,g=0.0,b=1.0,a=1.0}

local ST_INTRO      = 1
local ST_FORTUNE    = 2
local ST_CHOOSE     = 3

local diaX, diaY = 320, 380

local persona = {
    grit    = 0, --strenght, resilence, will to live
    wis     = 0, --reflextion, instinct, mystery
    ego     = 0, --self worth, charm, beauty
}

-- Game Create
function gw.create()
    math.randomseed(os.time()) math.randomseed(os.time()) math.randomseed(os.time())

    initCard()
    tryYourLuck()
    myth.change("intro")
end

-- Game Update
function gw.update(dt)
    deltaTime = dt
    flux.update(dt)

    if selection[selected] then
        selCard = selection[selected]
    else
        selCard = nil
    end

    if input.getButton("A") then
        progress = progress + 1
    end

    if cardOnTable then
        if input.getButton("LEFT")  then selected = lume.clamp(selected - 1, 1, #selection) end
        if input.getButton("RIGHT") then selected = lume.clamp(selected + 1, 1, #selection) end
        if input.getButton("A")     then 
            --addToInventory(selection[selected])
        end 
    end

    if lProgress ~= progress then
        lProgress = progress
        myth.update(progress)
    end
end

-- Game Render
function gw.render(dt)
    graphics.setClearColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)

    renderBg()
    renderCards()
    renderText()
end

function addToInventory(card)
    table.insert(item, card)
end

function addToMyth(card)
    table.insert(cardSeq, card)

end

function setDestination(card)
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

function renderText()
    -- this function is generated by updateText
end

function updateText(s)
    local s     = s or "  "
    local len   = 0
    local newString = ""
    
    -- process text
    if selCard then
        s = s:gsub("!cardName"  , selCard.name)
        s = s:gsub("!cardDesc"  , selCard.desc[1])
        s = s:gsub("!destination"  , selCard.desc[1])
    end
    if #item > 0 then
        s = s:gsub("!pickedCard", item[1].name)
    end

    renderText = function()
        len = math.min(len+0.3, #s)
        newString = string.sub(s, 1, math.floor(len))
        graphics.print(newString, diaX, diaY, {}, 1)
    end
    
end

function resetProgress()
    progress = 1
end

function tryYourLuck()
    local totalLuck = 5
    local luck = 0
    for i=1, totalLuck do
        luck = luck + math.random(0, 1)
    end
    print("$$$!!! " .. luck)
    return luck
end

return gw

