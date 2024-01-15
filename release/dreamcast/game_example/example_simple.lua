local game = {}

local scale = {x=2, y=2}
function game.create()
  tex = graphics.loadTexture(findFile("assets/logo.dtex"))
end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end

  -- scaling the image
  local joy = input.getJoystick()
  scale.x = scale.x + joy.y * 0.001
  if scale.x < 0.1  then scale.x = 0.1 end
  if scale.x > 3    then scale.x = 3 end
  scale.y = scale.x

end

function game.render(dt)
  graphics.setClearColor(0,0,0,1)

  graphics.setDrawColor(1,1,1,1)
  graphics.drawTexture(tex, 320, 240, tex.w * scale.x, tex.h * scale.y)
end

function game.free()
  graphics.freeTexture(tex)
end

return game