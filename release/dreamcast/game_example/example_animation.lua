local game = {}
local realTime = 0

-- no local here, this is a global timer.
timer = require "lib.hump_timer" -- required for the animation

local texture
local skeleton
local skelX, skelY = 320, 240
local currentDirection  = nil
local isMoving          = false

function game.create()
    -- loads in the spritesheet texture
    texture = graphics.loadTexture(findFile("assets/spritesheet.png"))

    -- no spritesheet map, texture, 16 columns, 4 rows (16 x 4 spritesheet)
    -- each of the cell becomes a frame (16x4 =  64 frame in this case)
    -- when you set an animation, you specify the start and end frame -> see the change direction
    skeleton = sprite.new(nil, texture, 16, 4)

    skeleton:play(0.1, 2 + 32, 9 + 32)
end

function game.update(dt)
    -- we need the timer to update the animation
    timer.update(dt)
    realTime = realTime + dt

    isMoving = false
    if input.getButtonDown("UP")    then move("UP") end
    if input.getButtonDown("DOWN")  then move("DOWN") end
    if input.getButtonDown("LEFT")  then move("LEFT") end
    if input.getButtonDown("RIGHT") then move("RIGHT") end

    if isMoving == false then
       skeleton:stop()
       currentDirection = nil
    end

    if input.getButton("START") then exit() end
end

function game.render(dt)
    skeleton:draw(skelX, skelY)
end

function game.free()
end

function move(newDirection)
    local speed = 2
    if      newDirection == "UP" then
        skelY = skelY - speed
    elseif  newDirection == "DOWN" then
        skelY = skelY + speed
    elseif  newDirection == "LEFT" then
        skelX = skelX - speed
    elseif  newDirection == "RIGHT" then
        skelX = skelX + speed
    end

    isMoving = true

    if newDirection == currentDirection then return end
    currentDirection = newDirection

    if      currentDirection == "UP" then
        skeleton:loop(0.1, 2, 9)
    elseif  currentDirection == "LEFT" then
        skeleton:loop(0.1, 2+16, 9+16)
    elseif  currentDirection == "DOWN" then
        skeleton:loop(0.1, 2+32, 9+32)
    elseif  currentDirection == "RIGHT" then
        skeleton:loop(0.1, 2+48, 9+48)
    end
end

return game

