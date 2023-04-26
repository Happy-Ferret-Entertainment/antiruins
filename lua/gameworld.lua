local graphics  = require "graphics"
local audio     = require "audio"
local input     = require "input"


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
    if platform == "LOVE" then
      love.filesystem.setRequirePath(LOVE2D_PATH .. ";" .. folder .. "/?.lua;")
      print(love.filesystem.getRequirePath())
      local ok, result = pcall(love.filesystem.load, file)
      if ok then
        game = result()
      else
        print("ERROR LOADING GAMEWORLD -> " .. result)
      end 
    else
      game = dofile(file)
    end
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
