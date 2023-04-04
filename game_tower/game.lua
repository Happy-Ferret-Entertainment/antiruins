local gw = {}
local input = require "input"
local bump  = require "lib.bump"

gui     = require "gui"
tower   = require "tower"
demon   = require "demon"

realTime  = 0
timer = require "hump_timer"
world = {} -- collision detection

gold  = 25

STATE = {
    idle    = 1, 
    build   = 2, 
    pause   = 0,
}

gameState = STATE.idle
prevState = nil

-- Game Create
function gw.create()
    math.randomseed(os.time())
    world = bump.newWorld(32)

    gui.init()
    tower.init()
    demon.init()
end

-- Game Update
function gw.update(dt)
    realTime = realTime + dt
    gui.update()
    timer.update(dt)
    demon.update()
    tower.update()
    
    if input.getButton("B") then
        toggleState(STATE.build)
    end
end

-- Game Render
function gw.render(dt)
    graphics.setClearColor(0,0,0,1.0)
    --slide everything so that 0,0 is center
    graphics.push()
    graphics.translate(320,240)
    --renderCollisions()
    tower:render()
    demon.render()
    graphics.pop()

    gui.render()
    --local mouse = input.getMouse()
    --graphics.drawRect(mouse.x, mouse.y, 10, 10, 1, 0, 0, 1)
end

function renderCollisions()
    --render collision
    local items, len = world:getItems()
    graphics.setDrawColor(1, 0, 0, 0.5)
    for i, v in ipairs(items) do
        graphics.drawRect(world:getRect(v))
    end
    graphics.setDrawColor()
end

function toggleState(newState)
    if gameState == newState then
        gameState = prevState
    else
        prevState = gameState
        gameState = newState
    end
end

return gw

