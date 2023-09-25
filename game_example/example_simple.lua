local game = {}

function game.create()
  tex = graphics.loadTexture(findFile("assets/logo.dtex"))
end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end

end

function game.render(dt)
  graphics.setClearColor(0,0,0,1)

  graphics.setDrawColor(1,1,1,1)
  graphics.drawTexture(tex, 320, 240)
end

function game.free()
  graphics.freeTexture(tex)
end

return game