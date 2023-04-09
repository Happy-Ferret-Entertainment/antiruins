local gw = {}
local input = require "input"
local bump  = require "lib.bump"

gui     = require "gui"
tower   = require "tower"
demon   = require "demon"
phase   = require "phase"
flux    = require "flux"

realTime  = 0
timer = require "hump_timer"
world = {} -- collision detection

gold  = 100

STATE = {
    title   = 1,
    build   = 2,
    demon   = 3, 
    pause   = 0,
}

gameState = 99
prevState = nil

-- Game Create
function gw.create()
    math.randomseed(os.time())
    world = bump.newWorld(32)

    gui.init()

    -- moved demon.init() + tower.init() to phase.lua

    startTitleScreen()
    --startBuildPhase()
    --startDemonPhase()
end

-- Game Update
function gw.update(dt)
    realTime = realTime + dt
    gui.update(dt)
    timer.update(dt)

    if gameState == STATE.title then
    elseif gameState == STATE.build then
        tower.update()
    elseif gameState == STATE.demon then
        tower.update()
        demon.update()
    end
end

-- Game Render
function gw.render(dt)
    if gameState == STATE.title then
        renderTitle(dt)
    elseif gameState == STATE.build then
        renderBuild(dt)
    elseif gameState == STATE.demon then
        renderDemon(dt)
    end
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

function renderTitle(dt)
    graphics.setClearColor(0,0,0,1.0)
    gui.render(dt)
end

function renderBuild(dt)
    graphics.setClearColor(0,0,0,1.0)
    --slide everything so that 0,0 is center
    graphics.push()
    graphics.translate(320,240)
    --renderCollisions()
    tower:render(dt)
    graphics.pop()

    gui.render(dt)
    --local mouse = input.getMouse()
    --graphics.drawRect(mouse.x, mouse.y, 10, 10, 1, 0, 0, 1)   
end

function renderDemon(dt)
    graphics.setClearColor(0,0,0,1.0)
    --slide everything so that 0,0 is center
    graphics.push()
    graphics.translate(320,240)
    --renderCollisions()
    tower:render(dt)
    demon.render()
    graphics.pop()

    gui.render(dt)
    --local mouse = input.getMouse()
    --graphics.drawRect(mouse.x, mouse.y, 10, 10, 1, 0, 0, 1)
end

return gw

