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

function gameworld.loadfile(file)
  print("== Loading new game : " .. file .. " ==")
  local status  = 0
  local game    = gameworld

  -- If it finds the file, tries to load it.
  if file then
    local raw, error = loadfile(file)
    if raw == nil then
      print("ERROR > Cannot load game.lua : " .. error)
      exit()
      return status, nil
    end

    game = raw()
  else
    print("ERROR > Cannot find gameworld " .. file)
    exit()
  end

  if game then
    print("gameworld.lua> Gameworld loaded.")
    status = 1
  end

  return game, status
end

function gameworld.load(folder)
  print("== Loading new game : " .. folder .. " ==")

  local file    = findFile("game.lua")
  local status  = 0
  local game    = gameworld

  -- If it finds the file, tries to load it.
  if file then
    local raw, error = loadfile(file)
    if raw == nil then
      print("ERROR > Cannot load game.lua : " .. error)
      exit()
      return status, nil
    end

    game = raw()

    --game = pcall(dofile(file))
  else
    print("ERROR > Cannot find gameworld " .. folder)
    exit()
  end

  if game then
    print("gameworld.lua> Gameworld loaded.")
    status = 1
  end

  return game, status
end

-- Will be retrig on reloads
function gameworld.create()
end

function gameworld.update(dt)
  if input.getButton("START") then
    exit()
  end
  return 1
end

function gameworld.render()
  return 1
end

function gameworld.free()

end

return gameworld
