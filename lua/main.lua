local antiruins = require "lua/antiruins"


function love.load()
    love.window.setMode(640, 480, {borderless = true})
    love.filesystem.setRequirePath(package.path .. ";lua/?.lua" .. ";game/?.lua" .. ";game/lib/?.lua")
    initAntiruins("LOVE")
    status, game = loadGameworld("game/game.lua")
    game.create()
end

function love.update(dt)
    input.update(dt)
    game.update(dt)
end

function love.draw()
    game.render()
end