local card          = {}
local cardIndex     = {} -- this holds all the card key
local hat           = {} -- this is a hat which we can pick (remove) cards
local csv           = require "lib.csv"
local lume          = require "lib.lume"
local utf8          = require "utf8"
local coinType  = {}

-- globals
places = {}

function initCard()
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
            if "Name"           == k then c.name   = v end
            if "Tags"           == k then
                c.tag = {}
                for t in string.gmatch(v, "(%a+)") do

                    table.insert(c.tag, t)
                end
            end
            if "Description"    == k then 
                v = string.gsub(v, "%. ", ".\n") 
                c.desc   = {v}
            end
        end
        card[c.name] = c 
        --print(c.name, c.tag)
    end


    for k, v in pairs(card) do
        table.insert(cardIndex, k)
        if v.name == nil then v.name = k end
        if v.desc == nil then v.desc = {""} end
        v.obj   = nil
        v.angle = 0
        --print(v.name)
    end

    resetHat()

    places = getPlaces()

    table.insert(coinType, gameObject:createFromFile("assets/coin1.png"))
    table.insert(coinType, gameObject:createFromFile("assets/coin3.png"))

    print("Card Init Complete.")
end

function fixEncoding(file)
    local str = file:read("*all")
    str = str:gsub("’", "'")
    --print(str)
    
    
    --local byteoffset = utf8.offset(str, -1)
    --print("Byte", byteoffset)
    --str = string.sub(str, 1, byteoffset - 1)
    return str
end

function shuffleCard()
    hat = lume.shuffle(hat)
    for i,v in ipairs(hat) do
        --print(i .." : " ..card[v].name)
    end
end

function getCard(cardName)
    if cardName == nil or cardName == "" then
        shuffleCard()
        local name = table.remove(hat, 1)
        return card[name]
    end
    local c = card[cardName]
    if c then
        return c
    else
        print("Cards.lua---> Cannot find card " .. cardName)    
    end     
end

function getPlaces()
    -- if the list is already populated return that list
    if #places > 0 then return places end

    local places = {}
    for k, v in pairs(card) do
        if lume.find(v.tag, "Place") then
            table.insert(places, v)
            print(v.name)
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

function newSelection(nb)
    print("-- NEW SELECTION --")
    local sel       = {}
    local c         = {}
    local cardNb    = nb

    if type(nb) == "table" then
        cardNb = #nb
    end

    for i=1, cardNb do
        c = {}
        if type(nb) == "table" then
            c = getCard(nb[i])
        else
            c = getCard()
        end
        --sel[i].angle = math.rad((math.random() * 45) - 22)
        c.pos   = {x = 320, y = -200}
        c.type  = math.random(2)
        print("Adding " ..c.name .. " card to selection")
        table.insert(sel, c)
    end
    selection = sel
end

function resetSelection(nb)
    selection   = nil
    selected    = 1
    resetHat()
    return newSelection(nb)
end

function render(card)
    graphics.push()
    graphics.translate(self.pos.x, self.pos.y)
    graphics.rotate(self.angle)
    self.obj:drawObject()
    graphics.pop()
end

function showCards(exception)
    local exception = exception or 0
    if cardOnTable then

    else
        --print("----> Showing cards")
        local nb = #selection
        --print("Number of cards : " .. nb)
        local r  = math.random 
        for i, v in ipairs(selection) do
            if exception == i then
            else
                flux.to(v.pos, 0.8, {x = 640/(nb+1)*i, y = 200 + r(-20, 20) + i * 20})
                cardOnTable = true          
            end
        end
    end
end

function hideCards(exception)
    local exception = exception or selected
    if cardOnTable or exception == "force" then
        local r = 0
        local nb = #selection
        for i, v in ipairs(selection) do
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
        local nb = #selection
        for i, v in ipairs(selection) do
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

function renderCards()
    if selection == nil then return end
    local coin
    for i, v in ipairs(selection) do
        coin = coinType[v.type]
        graphics.push()
        graphics.translate(v.pos.x, v.pos.y)
        graphics.rotate(v.angle)
        if i == selected then
            coin:drawObject()
            graphics.rotate(-v.angle)
            graphics.print(v.name, 0, -128, {1, 0, 0, 1}, 1)           
        else               
            graphics.setDrawColor(0, 0, 0, 1)
            coin:drawObject()
            graphics.rotate(-v.angle)
            graphics.print(v.name, 0, -128, {1, 1, 1, 1}, 1)
        end
        graphics.pop()
    end
end

function clearFluxes(selection)
    for i,v in ipairs(selection) do
        if v.fluxing == true then
            v.fluxing = nil
        end
    end
end

--[[
card.forest = {
    name = "The Forest",
    desc = {
        "The green mother.\nSource of life, the grand wound.\nPerhaps something is growing out there",
        "",
        "",
    },
    stats = {0,1,0}
}

card.garage = {
    name = "Garage",
    stats = {1,0,0}
}

card.maze = {
    name = "Knossos's Maze",
    desc = {
        "An infinite map with no boundary and no rooms.\nAre you just lost or wandering?"
    },
    stats = {0,1,0}
}

card.battery = {
    name = "A small cell",
    desc = {
        "Some ancient battery. Too weak to power a synth.\nA symbol of portable electronics."
    },
    stats = {1,0,0}
}

card.frog = {
    name = "Mechanical Frog",
    desc = {
        "A copper automaton. It can only leap forward."
    },
    stats = {1,0,0}
}

card.synth = {
    name = "Piece of Robot",
    desc = {
        "A piece of a Machine who Lived. I wonder what they lived for.\nYou might need to repair something"
    },
    stats = {0,0,1}
}

card.mirror = {
    name = "Pocket Mirror",
    desc = {""},
    stats = {0,0,1}
}


card.chainmail = {
    name = "Chainmail",
    desc = {""},
    stats = {1,0,0}
}


card.radio = {
    name = "Broken radio",
    desc = {""},
    stats = {0,0,1}
}


card.fish = {
    name = "Dried Fish",
    desc = {""},
    stats = {0,1,0}
}
--]]

return card