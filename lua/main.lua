local antiruins = require "lua/antiruins"
local returnToLoader = 2

function love.load()
    love.window.setMode(640, 480, {borderless = true})
    love.filesystem.setRequirePath(config.reqPath)
        
    local gameToLoad = initAntiruins("LOVE")
    
    status, game = loadGameworld(gameToLoad)
    if game == nil then print(status) end
    game.create()
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
    game.render()
end