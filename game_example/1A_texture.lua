local game = {}

local tex 

function game.create()
  -- load a texture (.png or .dtex) from a path
  -- the texture must be pow2 in side, doesn't have to be square (16,32,64,128,256,512,1024)
  -- notice the use of findFile. findFile will look for the file in many location: /pc /cd /sd /rd

  tex = graphics.loadTexture(findFile("assets/logo.dtex"))
  --tex = graphics.loadTexture(findFile("assets/logo.png"))
end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end
end

function game.render(dt)
  -- sets the background color
  -- the colors are floating point between 1.0 and 0.0
  graphics.setClearColor(0,0,0,1)

  -- sets the color of subsequent texture, quads, text, etc.
  -- these color can aso be passed as a table {r,g,b,a}
  graphics.setDrawColor(1,1,1,1)

  -- draws a texture at the center of the screen
  -- draw texture takes the following arguments: texture, x, y, width (optional), height(optional), rotation(optional)
  graphics.drawTexture(tex, 320, 240)
end

function game.free()
  -- free the texture from memory
  graphics.freeTexture(tex)
end

return game