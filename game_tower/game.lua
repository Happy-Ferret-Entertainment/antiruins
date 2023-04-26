local gw = {}
local input = require "input"
local bump  = require "lib.bump"

gui     = require "gui"
tower   = require "tower"
demon   = require "demon"
phase   = require "phase"

realTime  = 0
timer = require "lib.hump_timer"
world = {} -- collision detection

debug = false

zoomScale = 1.0

gold  = 10
--gold  = 100

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
    startTitleScreen()
end

-- Game Update
function gw.update(dt)
    realTime = realTime + dt

    gui.update(dt)
    timer.update(dt)

    if      gameState == STATE.title then

    elseif  gameState == STATE.build then
        tower.update()
    elseif  gameState == STATE.demon then
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
    --print("-> Current State is: " .. gameState .. " and new state is: " .. newState)
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
    graphics.scale(zoomScale)
    if debug then renderCollisions() end
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
    graphics.scale(zoomScale)
    --renderCollisions()
    tower:render(dt)
    demon.render()
    graphics.pop()

    gui.render(dt)
    --local mouse = input.getMouse()
    --graphics.drawRect(mouse.x, mouse.y, 10, 10, 1, 0, 0, 1)
end

function clearAllData()
  -- THIS DELETES EVERY TIMER + gui + the world!
  -- VERY USEFUL
  timer.clear()
  gui.init()
  world = bump.newWorld(32)

  gold = math.max(10, gold)

  print("!!! --> Cleared all game data")
end

function zoom()
    if input.hasMouse then

    end
end

--[[
function love.wheelmoved(x, y)
    if y > 0 then
        zoomScale = zoomScale + 0.01
    elseif y < 0 then
        zoomScale = zoomScale - 0.01
    end
    zoomScale = math.max(0.5, zoomScale)
    --print("zoomScale: " .. zoomScale)
end
--]]

return gw

