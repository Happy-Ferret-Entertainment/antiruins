local gw = {}
local cards = require "cards"
local c
local selection = {}
local selected  = 1

local state = ""
local progress = 1

local ST_INTRO      = 1
local ST_FORTUNE    = 2
local ST_CHOOSE     = 3

local diaX, diaY = 20, 400

local persona = {
    grit    = 0,
    wis     = 0,
    ego     = 0,
}

function intro()
    local t = {"Welcome traveller.", "Please choose one of those trinkets.", "Ah, you chose this one, how curious."}
    if #selection == 0 then newSelection(3) end 

    graphics.print(t[progress], diaX, diaY, {}, 1)

    if progress == 2 then
        if input.getButton("LEFT") then selected = lume.clamp(selected - 1, 1, #selection) end
        if input.getButton("RIGHT") then selected = lume.clamp(selected + 1, 1, #selection) end
        for i,v in ipairs(selection) do
            if i == selected then
                graphics.print(v.name, 640/4 * i, 240, {1, 0, 0, 1})
            else
                graphics.print(v.name, 640/4 * i, 240, {1, 1, 1, 1})
            end
        end
    end

    if progress == 3 then

    end

    


end

function fortune()

end

function newSelection(nb)
    print("-- NEW SELECTION --")
    for i=1, nb do
        selection[i] = getCard()
        print(selection[i].name)
    end
end

function gw.create()
    initCard()
    state = ST_INTRO
end

function gw.update(dt)
    
    if input.getButton("A") then
        progress = progress + 1
    end
end

function gw.render()
    local g = graphics
    graphics.setClearColor(0,0,0,1)

    if state == ST_INTRO then
        intro()
    elseif state == ST_FORTUNE then
        fortune()
    elseif state == ST_CHOOSE then
        pickCard()
    end


   -- g.print(c.name, 20, 20)
   -- g.print(c.desc[1], 20, 50)

end

return gw