local game = {}

local logo, font, sfx, bgm
local logoX, logoY = 320, 240
local spinSpd = 10.0
local realTime = 0

function game.create()
    font = graphics.loadFont(findFile("assets/MonofontSmall.dtex"), 16, 8, 0)
    
    logo = graphics.loadTexture(findFile("assets/logo.png"))

    sfx = audio.load(findFile("assets/login.wav"), "SFX")

    bgm = audio.load(0, "STREAM")
    audio.play(bgm, 250, 1)
end

function game.update(dt)
    realTime = realTime + dt

    if input.getButton("START") then
        exit()
    end

    if input.getButton("A") then
        audio.play(sfx, 210)
    end

    local joy = input.getJoystick(1)
    logoX = logoX + joy.x / 128.0
    logoY = logoY + joy.y / 128.0

    local trig = input.getTriggers(1)
    if trig.x > 0 then
        spinSpd = spinSpd + (trig.x * 0.01);
    end

    if trig.y > 0 then
        spinSpd = spinSpd - (trig.y * 0.01);
    end
end

function game.render(dt)
    graphics.setClearColor(0,0,0.5,1)

    graphics.setDrawColor(1,0,0,1)
    local logoWidth = 128 + (math.sin(realTime) * 64)
    local logoHeight = 32 + (math.sin(realTime) * 16)
    graphics.drawTexture(logo, logoX, logoY, logoWidth, logoHeight, realTime * spinSpd)

    graphics.setDrawColor(1,1,1,1)
    graphics.print("DT: " .. dt, 20, 440)
end

function game.free()
    graphics.freeTexture(logo)
    graphics.freeFont(font)
    audio.free(sfx)
end

return game

