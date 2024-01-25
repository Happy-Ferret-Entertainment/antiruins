local game = {}

local font 

function game.create()
  -- loads a font from a texture. this texture must be a monospaced font.
  -- the 16 and 8 are the column and rows in your texture atlas
  graphics.loadFont(findFile("assets/MonofontSmall.dtex"), 16, 8)
end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end
end

function game.render(dt)
  graphics.setClearColor(0,0,0,1)


  graphics.setDrawColor(0,0,1,1)
  -- draws text at the given position
  graphics.print("SEGA Dreamcast!", 20, 20)

  graphics.setDrawColor(1,1,1,1)
  -- draws text at the given position, and centers it if you add the "center" flag
  graphics.print("Hello World!", 320, 240, "center")

end

function game.free()
  -- free the texture from memory
  graphics.freeTexture(tex)
end

return game