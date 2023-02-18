local gw = {}
local cards = require "cards"
local flux = require "lib.flux"
local c

local selection = {}
local selected  = 1
local cardOnTable = false

local state = ""
local progress = 1

local myth      = {} -- hold our card progression
local item      = {} -- our inventory
local coinType  = {}

local ST_INTRO      = 1
local ST_FORTUNE    = 2
local ST_CHOOSE     = 3

local diaX, diaY = 320, 400

local persona = {
    grit    = 0,
    wis     = 0,
    ego     = 0,
}

function intro()
    local t = {
        "Welcome traveller.", 
        "Please choose one of those trinkets.", 
        "Ah, you chose this one, how curious.", 
        "Let's see how your story unfold..."
    }
    if #selection == 0 then newSelection(3) end 

    graphics.print(t[progress], diaX, diaY, {}, 1)

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
        resetSelection()
        resetProgress()
    end
end

function fortune()
    local t = {""}
    if progress == 1 then
        graphics.push()
        graphics.translate(320,240)
        --graphics.scale(3)
        graphics.print("PREMIER", 0, 0, nil, 1)
        graphics.pop()
    end

    if progress == 2 then
        showCards()
    end

    if progress == 3 then
        hideCards(selected)
    end

    if progress == 4 then
        hideCards("force")
    end

end

function resetSelection()
    selection   = nil
    selected    = 1
    resetHat()
    newSelection(5)
end

function resetProgress()
    progress = 1
end

function newSelection(nb)
    print("-- NEW SELECTION --")
    selection = {}
    for i=1, nb do
        selection[i] = getCard()
        selection[i].angle = math.rad(math.random() * 30 - 15)
        selection[i].pos   = {x = 320, y = -200}
        selection[i].type  = math.random(2)
        print(selection[i].name)
    end
end

function gw.create()
    table.insert(coinType, gameObject:createFromFile("assets/coin1.png"))
    table.insert(coinType, gameObject:createFromFile("assets/coin3.png"))
    math.randomseed(os.time()) math.randomseed(os.time()) math.randomseed(os.time())
    initCard()
    state = ST_INTRO
end

function gw.update(dt)
    deltaTime = dt
    flux.update(dt)
    if input.getButton("A") then
        progress = progress + 1 
    end
    if cardOnTable then
        if input.getButton("LEFT")  then selected = lume.clamp(selected - 1, 1, #selection) end
        if input.getButton("RIGHT") then selected = lume.clamp(selected + 1, 1, #selection) end
        if input.getButton("A")     then 
            table.insert(item, selection[i])
        end 
    end

end

function gw.render()
    local g = graphics
    graphics.setClearColor(0.4,0,1,1)

    if      state == ST_INTRO then
        intro()
    elseif  state == ST_FORTUNE then
        fortune()
    elseif  state == ST_CHOOSE then
        pickCard()
    end

    renderCards()

end

function showCards(exception)
    local exception = exception or 0
    if cardOnTable or exception == "force" then
    else
        local nb = #selection
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
    local exception = exception or 0
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
    local exception = exception or 0
    if cardOnTable or exception then
        local r = 0
        local nb = #selection
        for i, v in ipairs(selection) do
            if exception == i then
                r = math.random(100)-50
                flux.to(v.pos, 1.5, {x = 320 + r, y = 750})
                cardOnTable = false
            else
            end
        end
    else
    end
end

function renderCards()
    if selection == nil then return end
    local coin
    for i,v in ipairs(selection) do
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

function displayInventory()
    if #item > 0 then
        graphics.print("Inventory :", 20, 20)
        --for i, v in ipairs()
    end
end

function clearFluxes()
    for i,v in ipairs(selection) do
        if v.fluxing == true then
            v.fluxing = nil
        end
    end
end

return gw