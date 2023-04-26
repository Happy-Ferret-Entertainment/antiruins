local gw = {}
local input = require "input"

local t
local maxDraw = 1
local cursor = {x = 320, y = 240}
-- Game Create
function gw.create()
    t = graphics.loadTexture("assets/cat.png")
end

-- Game Update
function gw.update(dt)
    if input.getButton("A") then
        print("A single press of button A!")
        maxDraw = maxDraw + 25
    end

    joystick = input.getJoystick()
    --print(joystick.x, joystick.y)
    cursor.x = cursor.x + joystick.x*0.05
    cursor.y = cursor.y + joystick.y*0.05
end

-- Game Render
function gw.render(dt)
    graphics.setClearColor(1, 1, 0.77, 1)

    --batchExemple()

    --graphics.perfInfo()
end

function gw.free()
    graphics.freeTexture(t)
end



function batchExemple()
    graphics.startBatch(t)
    for i=1, maxDraw do
        graphics.addToBatch(320, 240, 0, 64, 64, 0, 0, 1, 1)
    end
    graphics.endBatch()
end

return gw

