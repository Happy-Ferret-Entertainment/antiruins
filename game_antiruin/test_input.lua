local gw = {}
local input = require "input"

-- Game Create
function gw.create()

end

-- Game Update
function gw.update(dt)
    if input.getButton("A") then
        print("A single press of button A!")
    end
end

-- Game Render
function gw.render(dt)
 
end

return gw

