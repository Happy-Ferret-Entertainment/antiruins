local gui     = {}
local button  = require "button"
local line    = 20
local timer   = require "hump_timer"

-- title color, used for tweening
local tColor    = {}
local maxMem    = 0
local guiTimer  = nil

function gui.init()
  gui.deleteAllButtons()
  gui.buttons = {}
  gui.tooltip = ""
  gui.bottomLine = 480 - graphics.getFontSize() - 10

  if guiTimer then guiTimer:clear() end
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

  if gui.title then gui.renderTitle() end

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
  
  --graphics.print("Cycle:"     .. demon.getCycle(), 560, line, {}, "center")
  
  graphics.print(gui.tooltip, 320, 420, {}, "center")

  --[[ DEBUG DATA]]
  if debug then
    gui.debugInfo()
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

function gui.deleteAllButtons()
  if gui.buttons == nil then return end
  for i, v in ipairs(gui.buttons) do
    table.remove(gui.buttons)
  end
  gui.buttons = {}
end

function gui.setTooltip(text)
  if text == gui.tooltip then return end

  gui.tooltip = text
  gui.tooltipTimer = guiTimer:after(2, function()
    gui.tooltip = ""
  end)

end

function gui.renderTitle()
  graphics.setFont("big")
  graphics.print(gui.title, 320, 220, tColor, "center")
  graphics.setFont()
end

function gui.setTitle(text, delayBeforeFade)
  gui.title = text
  guiTimer:tween(0.5, tColor, {1,1,1,1})

  if delayBeforeFade then
    guiTimer:after(delayBeforeFade, function()
      gui.clearTitle()
    end)
  end
end

function gui.clearTitle()
  guiTimer:tween(0.5, tColor, {1,1,1,0})
  guiTimer:after(0.5, function()
    gui.title = nil
  end)
end

function gui.debugInfo()
  local mem = math.ceil(collectgarbage("count"))
  if mem > maxMem then maxMem = mem end
  graphics.print("Mem: " .. mem .. "kb / Max: " .. maxMem .. "kb", 20, 460, {})
  graphics.print("Demons: " .. #demon.alive, 20, 440, {})
end


return gui