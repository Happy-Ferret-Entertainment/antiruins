local game = {}


local video

function game.create()
  graphics.playVideo(findFile("assets/test.roq"), 320, 240, 320, 240)
end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end

end

function game.render(dt)

end

return game