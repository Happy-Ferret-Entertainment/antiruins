local loader = {}
local cGame = 1 
local lume = require "lib.lume"
local logo

function loader.create()
    logo = gameObject:createFromFile("default/logo.png")

end

function loader.update(dt)
    if input.getButton("DOWN")  then cGame = cGame + 1 end
    if input.getButton("UP")    then cGame = cGame - 1 end
    cGame = lume.clamp(cGame, 1, #config.games)


    if input.getButton("A")     then
        status, game = loadGameworld(config.games[cGame].dir, true)
        if game == nil then print(status) end
        game.create()
    end

end

function loader.render()
    graphics.setClearColor(0.599, 0.416, 0.770, 1)
    local xPos, yPos = 60, 60
    logo:draw(xPos+ 113, 70)
    --graphics.print("Antiruins Loader", xPos, yPos)

    yPos = 100
    for i, v in ipairs(config.games) do
        graphics.setDrawColor(1,1,1,1)
        if i == cGame then graphics.setDrawColor(0,0,1,1) end
        graphics.print(v.name, xPos, yPos)
        yPos = yPos + 20
    end
end

function loader.free()
    logo:delete()
end

return loader