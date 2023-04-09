local phase = {}
local button = require "button"

function startTitleScreen()
  print("--- Starting title screen ---")
  toggleState(STATE.title)
  gui.setTitle("Gravenhal")
  local button = button:new(320-50, 300, 100, 20)
  button:setLabel("Start Game")
  button:setColor({0,0,0,0}, {1,1,1,1}, {1,1,1,1}, {0,0,0,1})
  button.onClick = function()
    startBuildPhase()
    gui.deleteButton(button)
  end
  gui.addButton(button)
end

function startBuildPhase()
  print("--- Starting build phase ---")
  toggleState(STATE.build)
  gui.setTitle("Build Phase")
  timer.after(5, function()
    startDemonPhase()
  end)
end

function startDemonPhase()
  print("--- Starting demon phase ---")
  toggleState(STATE.demon)
  gui.setTitle("Demon Phase")
  demon.startPhase()
end

return phase