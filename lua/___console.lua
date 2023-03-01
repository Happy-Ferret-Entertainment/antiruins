-- local gameObject = require "gameobject"
-- local graphics = require "graphics"
local maf = require "lib.maf"

local console = {}

console.active = false --true, false
console.pos = maf.vector(10,10)
console.messages = {}
console.limit = 10
console.temp = ""

function console.init()
  console.box = gameObject:createFromFile("asset/romdisk/box_console.png", 0,0)
  local obj = console.box
  obj.pos:set(640 - obj.size.x - 10, 480- obj.size.y - 10)
  obj.pos:set(console.pos.x, console.pos.y)
  obj.scale:set(2,2)
  console.active = false
  console.add("Console Init.")
end

function console.add(string, mode)
  if mode == "temp" then
    console.temp = string
    return
  end

  table.insert(console.messages, string)
  if #console.messages > console.limit then
    table.remove(console.messages, 1)
  end
end

function console.update()
  if p1:press(nil, "Y") then
    console.active = not console.active
  end
end

function console.render()
  local char_width = 10
  local x, y = console.pos.x, console.pos.y

  if console.active == false then return end
  graphics.setDrawColor(1, 1, 1, 1)
  console.box:drawObject()

  --[[
  if console.temp ~= nil then
    local message = copy(console.temp)
    graphics.print(message, 620 - (#message * char_width), 460 - 20)
    console.temp = nil
    return
  end


  if console.active == true then
    for i, v in pairs(console.messages) do
      graphics.print(v, 620 - (#v * char_width), 460 - (i * 20))
    end
  end

  if console.active == "lastMessage" then
    local message = console.messages[#console.messages]
    graphics.print(message, 620 - (#message * char_width), 460 - 20)
  end
  --]]
end

return console
