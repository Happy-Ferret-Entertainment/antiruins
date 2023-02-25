local wgfx = {}

wgfx.tex = nil

function wgfx.bg() 
    if wgfx.tex == nil then
        wgfx.tex = graphics.loadTexture("assets/bg1.png")
    end


    graphics.setDrawColor(1,1,1,0.5)
    local rand = math.random
    local r = 0
    local oX, oY = 0, 0
    for x=0,640,64 do
        for y=0, 480, 64 do
            oX, oY = 0, 0
            r = rand(100)
            if r == 86 then oX = oX + 1 end
            if r == 36 then oY = oY + 1 end
            graphics.drawTexture(wgfx.tex, nil, x, y)
        end
    end

end

return wgfx