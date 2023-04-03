local gui = {}
local button = require "button"
local line = 20



function gui.init()
  gui.buttons = {}
end

function gui.update()
  for i, v in ipairs(gui.buttons) do
    v:update()
  end
end

function gui.render()


  -- in render because immediate mode gui

  -- [[ UI IS STILL LOCATED AT DC COORD]]
  graphics.print("Gold:"      .. gold, 20, line, {})
  local hp = "Solidity:"  .. tower:getHP() .. "/" .. tower.maxHp
  graphics.print(hp, 320, line, {}, "center")

  graphics.print("Cycle:"     .. demon.getCycle(), 560, line, {}, "center")

  --graphics.print("Bullets:"   .. #tower.bullets, 10, 10)
  --graphics.print("Demons:"    .. #demon.alive, 10, 25)
  --local mem = math.floor(collectgarbage("count"))
  --graphics.print("Memory:" .. mem .. "kb", 10, 460)
  for i, v in ipairs(gui.buttons) do
    v:render()
  end
end

function gui.addButton(b)
  table.insert(gui.buttons, b)
end

function gui.deleteButton(b)
  for i, v in ipairs(gui.buttons) do
    if v == b then
      table.remove(gui.buttons, i)
    end
  end
end



return gui