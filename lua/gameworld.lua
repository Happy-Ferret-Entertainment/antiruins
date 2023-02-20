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
