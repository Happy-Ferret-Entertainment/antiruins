local loader = {}
local cGame = 1 
local lume = require "lib.lume"
local logo

function loader.create()
    logo = graphics.loadTexture("logo.png")
end

function loader.update(dt)
    if input.getButton("START") then exit() end
    if input.getButton("Y")     then loadNewGame() end


    if input.getButton("DOWN")  then cGame = cGame + 1 end
    if input.getButton("UP")    then cGame = cGame - 1 end
    cGame = lume.clamp(cGame, 1, #config.games)


    if input.getButton("A")     then
        loadNewGame(config.games[cGame].dir)
    end

end

function loader.render()
    graphics.setClearColor(0.57,0.17,0.17, 1)
    local xPos, yPos = 60, 60
    graphics.drawTexture(logo, 320, 240)
    --graphics.print("Antiruins Loader", 0, 100)

    
    yPos = 100
    for i, v in ipairs(config.games) do
        graphics.setDrawColor(1,1,1,1)
        if i == cGame then graphics.setDrawColor(0,0,1,1) end
        graphics.print(v.name, xPos, yPos)
        yPos = yPos + 20
    end
    
end

function loader.free()
    graphics.freeTexture(logo)
end

return loader