local gw = {}
local cards = require "cards"
local flux  = require "lib.flux"
local myth  = require "myth"

 -- GLOBAL VARIABLES
selection   = {}
cardOnTable = false
selected    = 1
selCard     = {} -- shortcut to the selected card

local state = ""
local progress, lProgress  = 1, 0
local chapter   = 0

local dialogs   = {}
local cardSeq   = {} -- hold our card progression
local item      = {} -- our inventory
local destination = {} -- our next destination (as a card)


local ST_INTRO      = 1
local ST_FORTUNE    = 2
local ST_CHOOSE     = 3

local diaX, diaY = 320, 400

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
    myth.change("maze")
end

-- Game Update
function gw.update(dt)
    deltaTime = dt
    flux.update(dt)

    if selection then
        selCard = selection[selected]
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
function gw.render()
    local g = graphics
    graphics.setClearColor(0.4,0,1,1)

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

function renderText()
    -- this function is generated by updateText
end

function updateText(s)
    local s     = s or "  "
    local len   = 0
    local newString = ""
    
    -- process text
    if selection then
        s = s:gsub("!cardName"  , selection[selected].name)
        s = s:gsub("!cardDesc"  , selection[selected].desc[1])
        s = s:gsub("!destination"  , selection[selected].desc[1])
    end
    if #item > 0 then
        s = s:gsub("!pickedCard", item[1].name)
    end

    renderText = function()
        len = math.min(len+0.1, #s)
        newString = string.sub(s, 1, len)
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

--[[
function intro()
    local t = {
        "Welcome traveller.", 
        "Please choose one of those trinkets.", 
        "Ah, you chose this one, how curious.", 
        "Let's see how your story unfold..."
    }
    if progress == 0 then
        selection = newSelection(3) 
    end 

    if progress == 2 then
        showCards()
    end

    if progress == 3 then
        hideCards(selected)
    end

    if progress == 4 then
        keepCards(selected)
    end

    if progress == 5 then
        state = ST_FORTUNE
        resetSelection(4)
        resetProgress()
        chapter = chapter + 1
    end

end

function fortune()
    local t = {"CHAPTER ", "Your story starts with the %s", "What will come next?", ""}
    if progress == 1 then
        graphics.push()
        graphics.translate(320,240)
        --graphics.scale(3)
        t[1] = t[1] .. chapter
        graphics.pop()
    end

    if progress == 2 then
        t[progress] = string.format(t[progress], string.lower(item[1].name))
        
    end

    if progress == 3 then
        showCards()
    end

    if progress == 4 then
        t[4] = selection[selected].desc[1]
        hideCards(selected)
        --hideCards("force")
    end

    
    if progress == 5 then
        --hideCards(selected)  
        hideCards("force")
    end

    if progress == 6 then
        resetProgress()
        resetSelection(math.random(2, 5))
        chapter = chapter + 1
    end

end
]]--

return gw

