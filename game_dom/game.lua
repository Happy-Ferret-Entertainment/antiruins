local gw = {}
local scenes = require "scenes"

local cursor = nil

-- current scene
local cScene = nil
function gw.create()
    cursor = gameObject:createFromFile("assets/cursor.png", 320, 240)
    cursor.scale.x, cursor.scale.y = 0.5, 0.5
    loadScene("intro_s")

end

function gw.update(dt)
    local joystick = input.getAxis(1) --get controller 1 DPAD
    cursor:addForce(joystick, 0.01)
    cursor:updatePosition()

    if input.getButton("A") then
        if cursor.pos.x < 150 then loadScene(cScene.destination.left) end
        if cursor.pos.x > 390 then loadScene(cScene.destination.right) end
    end

end

function gw.render(dt)
    if cScene.bgImg then
        cScene.bgImg:draw()    
    end

    cursor:draw()

end

function loadScene(sc)
    local sc = scenes[sc]
    if sc == nil then
        print("INVALID SCENE NAME")
        return 0
    end

    -- delete the previous bgImg to prevent making copies.
    if cScene then
        cScene.bgImg:delete()
    end

    if sc.bgImgFile then
        sc.bgImg = gameObject:createFromFile(sc.bgImgFile, 320, 240)
        --sc.bgImg.scale.y, sc.bgImg.scale.y = 2, 2
    end

    cScene = sc
end

return gw