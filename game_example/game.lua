local gw = {}

local logo, sfx, bgm
local texX, texY = 320, 240
local realTime = 0

-- Game Create
function gw.create()
    -- Loads a font from a file.
    -- The font file is a texture atlas with 16x8 characters
    -- The last argument means no font resizing.
    local font = graphics.loadFont(findFile("assets/MonofontSmall.dtex"), 16, 8, 0)
    

    -- Loads a texture from a file.
    -- Find file will look for the file at /pc /rd / cd and /sd
    -- It will also look for the file in the current game directory
    logo = graphics.loadTexture(findFile("assets/logo.png"))

    -- Loads a .wav file in the SPU memory. Mostly used for short sound and SFX.
    sfx = audio.load(findFile("assets/login.wav"), "SFX")

    -- Loads the first .wav file in the music folder.
    bgm = audio.load(0, "STREAM")
    -- Play the music at 200/254 volume and loop.
    audio.play(bgm, 250, 1)
end

-- Game Update
function gw.update(dt)
    realTime = realTime + dt

    if input.getButton("START") then
        exit()
    end

    if input.getButton("A") then
        audio.play(sfx, 210)
    end

    -- Get the joystick of controller 1
    local joy = input.getJoystick(1)
    texX = texX + joy.x / 128.0
    texY = texY + joy.y / 128.0

end

-- Game Render
function gw.render(dt)
    graphics.setClearColor(0,0,0.5,1)

    graphics.setDrawColor(1,0,0,1)
    -- Arguments are: textureID, x, y, width, height, rotation
    local texWidth = 128 + (math.sin(realTime) * 64)
    local texHeight = 32 + (math.sin(realTime) * 16)
    graphics.drawTexture(logo, texX, texY, texWidth, texHeight, realTime * 10)

    graphics.drawLine(20, 300, 620, 400)

    graphics.setDrawColor(1,1,1,1)
    graphics.print("DT: " .. dt, 20, 440)
end

function gw.free()
end

return gw

