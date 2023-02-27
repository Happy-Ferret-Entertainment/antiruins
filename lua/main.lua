local antiruins = require "lua/antiruins"


function love.load()
    love.window.setMode(640, 480, {borderless = true})
    love.filesystem.setRequirePath(package.path .. ";lua/?.lua" .. ";game/?.lua" .. ";game/lib/?.lua")
    initAntiruins("LOVE")

    status, game = loadGameworld("game/game.lua")
    if game == nil then print(status) end
    
    game.create()
end

function love.update(dt)
    -- cheap way to keep it a 30 ftp.
    if dt < 1/30 then
        love.timer.sleep(1/30 - dt)
     end
    input.update(dt)
    game.update(dt)
end

function love.draw()
    game.render()
end