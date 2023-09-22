local gameworld = {
  init    = function() end,
  create  = function() end,
  update  = function() end,
  render  = function() end,
  free    = function() end,
}
-- ONLY HAPPENS ONCE! EVER!
function gameworld.init()
end

function gameworld.load(folder)
  local status    = 0
  print("== Loading new game : " .. folder .. " ==")

  local file = findFile("game.lua")

  -- If it finds the file, tries to load it.
  if file then
    game = dofile(file)
  else
    print("gameworld.lua> Cannot find gameworld " .. folder)
  end

  if game then
    print("gameworld.lua> Gameworld loaded.")
    status = 1
  end

  return status, game
end

-- Will be retrig on reloads
function gameworld.create()
end

function gameworld.update(dt)
  return 1
end

function gameworld.render()
  return 1
end

function gameworld.free()

end

return gameworld
