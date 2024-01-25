local game = {}

local tex
local x, y = 320, 240
local scale = 1
local color = {1,1,1,1}
local angle = 0

function game.create()
  tex = graphics.loadTexture(findFile("assets/logo.dtex"))
end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end

  -- gets the joystick input from the first joystick
  local joy = input.getJoystick(1)
  -- move the texture around
  x = x + joy.x / 128.0
  y = y + joy.y / 128.0

  -- get the triggers from the first controller
  local trig = input.getTriggers(1)
  -- scale the texture
  scale = scale + trig.x *0.0001
  scale = scale - trig.y *0.0001
  if scale > 5    then scale = 5 end
  if scale < 0.1  then scale = 0.1 end


  -- change the drawing color when a button is pressed
  -- by default this is return the first controller, but you can add a second argument for the controller number
  if input.getButton("A") then
    color = {math.random(), math.random(), math.random(), 1}
  end

  -- get button down will be true when the button is held down
  if input.getButtonDown("B") then
    angle = angle + 1
  end

end

function game.render(dt)
  graphics.setClearColor(0,0,0,1)

  graphics.setDrawColor(color)
  graphics.drawTexture(tex, x, y, 256 * scale, 64 * scale, angle)
end

function game.free()
  graphics.freeTexture(tex)
end

return game