local phase       = {}
local button      = require "button"
local tempButtons = {}

function startTitleScreen()
  print("--- Starting title screen ---")
  toggleState(STATE.title)
  gui.setTitle("Gravenhal")
  local b = button:new(320-50, 300, 100, 20)
  b:setLabel("Start Game")
  b:setColor({0,0,0,0}, {1,1,1,1}, {1,1,1,1}, {0,0,0,1})
  b.onClick = function()

    timer.after(0.1, function()
      tower.init()
      demon.init()
      startBuildPhase()
      gui.clearTitle()
      gui.deleteButton(b)
    end) 
  end
  gui.addButton(b)
end

function startBuildPhase()
  print("--- Starting build phase ---")
  toggleState(STATE.build)
  gui.setTitle("Build Phase")
  
  
  if demon.getLevel() > 0 then
    local mods = tower:getRandomMods(3)
    --print("Mods: " .. #mods)
    local b
    for i=1, #mods do
      b = button:new(320-75, 300 + (i-1)*30, 150, 20)
      b:setLabel(mods[i].name)
      b:setColor({0,0,0,0}, {1,1,1,1}, {1,1,1,1}, {0,0,0,1})
      
      b.onClick = function()
        tower:addMod(mods[i])
        deleteTempButtons()
        gui.clearTitle()
        startDemonPhase()
      end

      b.onHover = function()
        gui.setTooltip(mods[i].desc)
      end
      gui.addButton(b)
      table.insert(tempButtons, b)
    end
  end
  
end

function startDemonPhase()
  print("--- Starting demon phase ---")
  toggleState(STATE.demon)
  gui.setTitle("Demon Phase")
  demon.startPhase()
end

function deleteTempButtons()
  for i, v in ipairs(tempButtons) do
    gui.deleteButton(v)
  end
end

return phase