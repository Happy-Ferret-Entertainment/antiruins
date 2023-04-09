local gui = {}
local button  = require "button"
local line    = 20
local timer = require "hump_timer"

-- title color, used for tweening
local tColor = {}

function gui.init()
  gui.buttons = {}
  gui.tooltip = ""
  guiTimer = timer.new()
  tColor = {1,1,1,0}
end

function gui.update()
  for i, v in ipairs(gui.buttons) do
    v:update()
  end
end

function gui.render(dt)
  -- in render because immediate mode gui
  guiTimer:update(dt)
  graphics.setFontScale(1)
  for i, v in ipairs(gui.buttons) do
    v:render()
  end

  if gameState == STATE.title then return end

  -- [[ UI IS STILL LOCATED AT DC COORD]]
  graphics.print("Gold:"      .. gold, 20, line, {})

  graphics.setDrawColor(1,1,1,1)
  graphics.drawRect(320-100, line, 200, 20)
  graphics.setDrawColor(0,0.5,0,1)
  local hp = lume.lerp(0, 198, tower:getHP("float"))
  graphics.drawRect(320-99, line+1, hp, 20-2)
  
  hp = tower:getHP() .. "/" .. tower.maxHp
  graphics.print(hp, 320, line-2, {0,0,0,1}, "center")
  
  graphics.print("Cycle:"     .. demon.getCycle(), 560, line, {}, "center")
  graphics.print(gui.tooltip, 320, 420, {}, "center")
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

function gui.setTooltip(text)
  if text == gui.tooltip then return end

  gui.tooltip = text
  gui.tooltipTimer = guiTimer:after(2, function()
    gui.tooltip = ""
  end)

end

function gui.setTitle(text)
  if gui.title then
    tColor = {0,0,0,0}
    guiTimer:cancel(gui.title)
  end

  guiTimer:tween(0.5, tColor, {1,1,1,1})

  gui.title = guiTimer:during(4, function()
    graphics.setFont("big")
    graphics.print(text, 320, 240, tColor, "center")
    graphics.setFont()
  end)

  guiTimer:after(3, function()
    guiTimer:tween(0.5, tColor, {1,1,1,0})
  end)
end


return gui