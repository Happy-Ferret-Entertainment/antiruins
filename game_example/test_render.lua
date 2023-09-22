local gw = {}

function loadTexture()
  tex = graphics.loadTexture(findFile("assets/logo.dtex"))
end

function testRender()

  for i=1, 250 do
    graphics.drawTexture(tex, (i * 35) % 500, (i * 35) % 480, 64, 16, i)
  end

end