local antiruins = require "lua/antiruins"
local returnToLoader = 2
local gameW, gameH = 640, 480
local w, h = 0, 0
local xOff, yOff = 0, 0 -- if the image is smaller than the screen, this is the offset to center it
local scaleFactor = 1
local canvas

deltaTime = 0

function love.load()
    love.window.setMode(gameW, gameH, {borderless = true})
    love.graphics.setDefaultFilter("nearest")
    love.filesystem.setRequirePath(config.reqPath)

    -- Once the screen window is initialized, we can initialize the input
    local gameToLoad = initAntiruins("LOVE")

    w, h = love.window.getMode()
    --calculate scale factor
    scaleFactor = math.floor(h / gameH)
    canvas      = love.graphics.newCanvas(gameW, gameH)

    xOff = w/2 - gameW * scaleFactor/2
    yOff = h/2 - gameH * scaleFactor/2


    status, game = loadGameworld(gameToLoad)
    if game == nil then print(status) end
    game.create()

    canvas = graphics.canvas

end

function love.update(dt)
    deltaTime = dt
    -- cheap way to keep it a 30 ftp.
    if dt < 1/30 then
        --love.timer.sleep(1/30 - dt)
    end
    input.update(dt)
    game.update(dt)


    if cont[1].buttonPressed["START"] then
        returnToLoader = returnToLoader - dt
        if returnToLoader < 0 then
            if game.free then game.free() end
            print("Return to loader")
            returnToLoader = 2
            status, game = loadGameworld("lua/loader.lua")
            if game == nil then print(status) end
            game.create()
            
        end
    end
    input.endOfFrame()
end

function love.draw()
    love.graphics.setCanvas(canvas)
    game.render(deltaTime)
    love.graphics.setCanvas()
    love.graphics.setBackgroundColor(0,0,0,1)
    if config.fullscreen then

    else

    end
    local sc = scaleFactor
    love.graphics.draw(canvas, xOff, yOff, 0, scaleFactor, scaleFactor)
end

function getScreenInfo()
    local screenInfo = {
        w = w, 
        h = h, 
        scaleFactor = scaleFactor, 
        xOff = xOff, 
        yOff = yOff
    }
    return screenInfo
end