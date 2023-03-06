local antiruins = require "lua/antiruins"
local returnToLoader = 2
local w, h = 0, 0
local scaleFactor = 1
local canvas

function love.load()
    love.window.setMode(640, 480, {borderless = true})
    love.graphics.setDefaultFilter("nearest")
    love.filesystem.setRequirePath(config.reqPath)


    local gameToLoad = initAntiruins("LOVE")
    
    status, game = loadGameworld(gameToLoad)
    if game == nil then print(status) end
    game.create()

    w, h = love.window.getMode()
    --calculate scale factor
    scaleFactor = math.floor(h / 480)
    --scaleFactor = 1
    canvas = love.graphics.newCanvas(640, 480)
end

function love.update(dt)
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
end

function love.draw()

    love.graphics.setCanvas(canvas)
    game.render()

    love.graphics.setCanvas()
    love.graphics.setBackgroundColor(0,0,0,1)
    if config.fullscreen then

    else

    end
    local sc = scaleFactor
    love.graphics.draw(canvas, w/2-640*sc/2, h/2-480*sc/2, 0, sc, sc)
end