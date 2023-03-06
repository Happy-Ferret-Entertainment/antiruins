local teller        = {}

local csv           = require "lib.csv"
local lume          = require "lib.lume"
local utf8          = require "utf8"
local coinType  = {}

-- globals
local places          = {}
local selection       = {}
local cardOnTable     = false
local selected        = 1
local showTitle        = true

-- Card related
teller.cards        = {}
teller.hand         = {}
local cardIndex     = {} -- this holds all the card key
local hat           = {} -- this is a hat which we can pick (remove) card

function teller.init()
    -- this is where the cards will reside
    teller.cards    = {}
    teller.hand     = {}
    teller.selected = {}

    local csv = require "lib.csv"

    -- Make sure the ' are replaced with proper '
    -- Test with CVS file from notion    
    local raw = csv.open(findFile("assets/cards.csv"), {header=true})
    
    -- each lines
    local c = {}
    for fields in raw:lines() do
        c = {}    
        -- print each key value
        for k, v in pairs(fields) do
            if "Name"           == k then 
                c.name   = v 
            end
            if "Tags"           == k then
                c.tags = {}
                for t in string.gmatch(v, "(%a+)") do
                    table.insert(c.tags, t)
                end
            end
            if "Description"    == k then 
                v = string.gsub(v, "%. ", "..\n") 
                c.desc   = {v}
            end
            if "File"           == k then
                c.obj = gameObject:createFromFile("assets/" .. v)
            end
        end
        teller.cards[c.name] = c 
        --print(c.name, c.tag)
    end


    for k, v in pairs(teller.cards) do
        table.insert(cardIndex, k)
        if v.name == nil then v.name = k end
        if v.desc == nil then v.desc = {""} end
        --v.obj   = nil
        v.angle = 0
        --print(v.name)
    end

    resetHat()

    places = getPlaces()

    table.insert(coinType, gameObject:createFromFile("assets/minidiscw.png"))
    table.insert(coinType, gameObject:createFromFile("assets/minidiscw.png"))
    coinType[1].scale:set(0.5, 0.5)
    coinType[2].scale:set(0.5, 0.5)

    print("Card Init Complete.")
end

function shuffleCard()
    hat = lume.shuffle(hat)
end

function getCard(cardName)
    if cardName == nil or cardName == "" then
        shuffleCard()
        return teller.cards[hat[1]]
    else
        local c = teller.cards[cardName]
        if c then
            return c
        end
    end
    print("Cards.lua---> Cannot find card " .. cardName)      
end

function teller.getCardsTag(tag, max)
    local _c = {}
    local nb = 0
    for k, v in pairs(teller.cards) do
        if lume.find(v.tags, tag) then
            table.insert(_c, v.name)
            nb = nb + 1
        end
    end
    _c = lume.shuffle(_c)
    _c = lume.slice(_c, 1, max)
    print("Found " .. nb .. " cards with tag : " .. tag)
    return _c
end

function getPlaces()
    -- if the list is already populated return that list
    if #places > 0 then return places end

    local places = {}
    for k, v in pairs(teller.cards) do
        if lume.find(v.tags, "Place") then
            table.insert(places, v)
        end
    end
    return places
end

-- Set a random new destination
function findNewPlace()
    nextDestination = lume.randomchoice(getPlaces()) 
    print(nextDestination.name)
end

function resetHat()
    hat = copy(cardIndex)
end

function newSelection(cards, nb)
    if #cards == 0 or cards == nil then return end

    print("-- NEW SELECTION --")
    local sel       = {}
    local c         = {}
    local r         = 0
    local nb        = nb

    if nb == nil then
        nb = #cards
    end

    for i=1, nb do
        c = {}
        -- pick random card from the provided selection
        if type(cards) == "table" then
            --r = math.random(#cards)
            c = getCard(cards[i])

        -- pick a random card
        else
            c = getCard()
        end
        c.pos   = {x = 320, y = -200}
        c.type  = math.random(2)
        print("Adding " ..c.name .. " card to selection")
        table.insert(sel, c)
    end
    teller.hand = sel
end

function resetSelection(nb)
    teller.hand   = nil
    selected    = 1
    resetHat()
    return newSelection(nb)
end

--[[ UPDATE ]]-----------------------
function teller.update()
    local hand = teller.hand
    teller.selected = hand[selected] or nil

    if updateOnInput then
        if input.getButton("A") then
            if      console.textDone() then progress = progress + 1
            else    --console.skipToEnd()
            end
        end
    end

    if cardOnTable then
        if input.getButton("LEFT")  then selected = lume.clamp(selected - 1, 1, #hand) end
        if input.getButton("RIGHT") then selected = lume.clamp(selected + 1, 1, #hand) end
        if input.getButton("A") and  console.textDone() then 
            addToInventory(teller.selected)
            hideCards()
        end 
    end
end

--[[ RENDER ]]-----------------------

function teller.render()
    if teller.hand == nil then return end
    local coin

    for i, v in ipairs(teller.hand) do
        if v.obj == nil then
            v.obj = coinType[v.type]
            print(v.name, " no object found")
        end
        graphics.push()
        graphics.translate(v.pos.x, v.pos.y)
        graphics.rotate(v.angle)
        if i == selected then
            graphics.setDrawColor(1, 0, 0, 1)
            v.obj:draw(0, 0)
            --graphics.rotate(-v.angle)
            if showTitle then
                graphics.print(v.name, 0, -90, {1, 0, 0, 1}, 1)
            end           
        else               
            graphics.setDrawColor(0, 0, 0, 1)
            v.obj:draw(0, 0)
            --graphics.rotate(-v.angle)
            if showTitle then
                graphics.print(v.name, 0, -90, {1, 1, 1, 1}, 1)
            end
        end
        graphics.setDrawColor(1, 1, 1, 1)
        graphics.pop()
    end
end

function showCardsFaceUp(exception)
    showTitle = true
    showCards(exception)
end

function showCardsFaceDown(exception)
    showTitle = false
    showCards(exception)
end

function showCards(exception)
    local exception = exception or 0
    if cardOnTable then
    else
        --print("----> Showing cards")
        local nb = #teller.hand
        --print("Number of cards : " .. nb)
        local r  = math.random 
        for i, v in ipairs(teller.hand) do
            if exception == i then
            else
                flux.to(v.pos, 0.8, {x = 640/(nb+1)*i, y = 240})
                flux.to(v, 0.8, {angle = math.rad((i-2)*10)})
                cardOnTable = true          
            end
        end
    end
end

function hideCards(exception)
    local exception = exception or selected
    if cardOnTable or exception == "force" then
        local r = 0
        local nb = #teller.hand
        for i, v in ipairs(teller.hand) do
            if exception == i then
            else
                r = math.random(100)-50
                flux.to(v.pos, 1.5, {x = 640/(nb+1)*i + r, y = -240})
                cardOnTable = false
            end
        end
    else
    end
end

function keepCards(exception)
    local exception = exception or selected
    if cardOnTable or exception then
        local r = 0
        local nb = #teller.hand
        for i, v in ipairs(teller.hand) do
            if exception == i then
                r = math.random(100)-50
                flux.to(v.pos, 1.5, {x = 320 + r, y = 750})
                cardOnTable = false
                addToInventory(v)
            else
            end
        end
    else
    end
end

function clearFluxes(cards)
    for i,v in ipairs(cards) do
        if v.fluxing == true then
            v.fluxing = nil
        end
    end
end

return teller