local maf       = require "lib.maf"
local bitOp     = require "lib.bit"
local input = {}

-- Raw DC controller data
DCcont  = {{}, {}, {}, {}}
-- Antiruins controler data
cont    = {{}, {}, {}, {}}

local KEYMAP = {
  l     = 'A',
  p     = 'B',
  k     = 'X',
  o     = 'Y',
  start = "START",
  w     = "UP",
  s     = "DOWN",
  a     = "LEFT",
  d     = "RIGHT"
}

local KEYMAP_ARROW = {
  space = 'A',
  z     = 'B',
  x     = 'X',
  c     = 'Y',
  a     = 'LTRIG',
  s     = 'RTRIG',
  -- = "START",
  up    = "UP",
  down  = "DOWN",
  left  = "LEFT",
  right = "RIGHT",
  e     = "EDIT",
  l     = "LOG",
  q     = "QUICKSAVE"
}

local JOYMAP = {
  'A', 'B', 'X', 'Y',
  "LBUMP", "RBUMP", "SELECT", "START",
  u = "UP",
  d = "DOWN",
  l = "LEFT",
  r = "RIGHT",
}

local controller = {
  buttonPressed = {
    A = false, B = false, X = false, Y = false, START = false,
    UP = false, DOWN = false, LEFT = false, RIGHT = false,
  },
  lButton = {},
  DC_button = 0,
  DC_lButton = 0,
  newButton = nil,
  deadzone  = 128 * 0.20,
  joy   = maf.vector(0,0),
  trig  = maf.vector(0,0),
  realJoystick = false,
}

local tt_inputmode = {}

local joy = nil
local pressed = {}
local ctrlMode = "DEFAULT"
local clickType = {"LEFT_MOUSE", "RIGHT_MOUSE", "MIDDLE_MOUSE"}

local screenInfo = {}

function input.init()
  for i, v in ipairs(cont) do
    --print("Input.lua> Player " .. i .. " init.")
    v.buttons = 0
    v.joy   = maf.vector(0,0)
    v.trig  = maf.vector(0,0)
    -- not filtered
    v.rawButton = {
      A=false, B=false, X=false, Y=false, 
      UP=false, DOWN=false, LEFT=false, RIGHT=false, START=false
    }
    --filtered for pwhen they're clicked only
    v.buttonPressed = {
      A=false, B=false, X=false, Y=false, 
      UP=false, DOWN=false, LEFT=false, RIGHT=false, START=false,
      LEFT_MOUSE=false, MIDDLE_MOUSE=false, RIGHT_MOUSE=false,
    }
    -- last Button
    v.lButtons      = copy(v.buttonPressed)
    
    --for k, v in pairs(v.lButtons) do print(k, v) end
  end

  for i, v in ipairs(DCcont) do
    v.joy   = maf.vector(0,0)
    v.trig  = maf.vector(0,0)
    v.buttonPressed = {} -- processed
    v.rawButton     = {} -- from Dreamcast
    v.lButtons      = {} -- copy of last frame button's pressed
  end

  input.mouse = maf.vector(0,0)

  if platform == "LOVE" then
    if love.joystick.getJoystickCount() > 0 then
      local joysticks = love.joystick.getJoysticks()
      joy = joysticks[1]
      controller.realJoystick = true
      for k,v in pairs(joysticks) do
        print(v:getName())
      end
      tt_inputmode = graphics.addTooltip("Gamepad ".. joysticks[1]:getName() .. " added.\nPress ESC to use keyboard", 60, 5, 4)
    end
    input.hasMouse = true
    __initMouse()
    input.setKeymap(KEYMAP_ARROW)
    screenInfo = getScreenInfo()
    screenInfo.offset = maf.vector(screenInfo.xOff, screenInfo.yOff)
    KEYMAP["return"] = "START"
  end

  if platform == "DC" then
    input.hasMouse = false
    controller.realJoystick = true
    KEYMAP = DC_KEYMAP
  end

  print("INPUT> Init done.")
end

function input.setKeymap(keymap)
  if keymap then KEYMAP = keymap end
end

function input.getPressed()
  for k, v in pairs(controller.buttonPressed) do
    --print(v)
  end
  return pressed
end

function input.setMode(mode)
  if mode == "MOUSE" then
    love.mouse.setVisible(false)
    ctrlMode = mode
  end
end

function input.update()
  if      platform == "LOVE" then
    cont[1].lButtons = copy(cont[1].buttonPressed)
    _updateKeyboard()
    _updateJoystick()
    _updateMouse()

  elseif  platform == "DC" then
  end


  -- deadzone
  local  mag, deadzone = controller.joy:length(), 181 * 0.25
  if mag < deadzone then
    controller.joy:set(0,0)
  else
    local m = (mag - deadzone) / (1 - deadzone)
    --(stickInput.magnitude - deadzone) / (1 - deadzone)
    --controller.joy = controller.joy:normalize()
    controller.joy = controller.joy:scale(-m)
  end
end

-- THE GOOD FUNCTION FOR SINGLE KEYPRESS
function input.getButton(key, contNum)
  -- Set the default controller number to 1 if not defined
  local n = contNum or 1

  if cont[n].newButton == false then return false end

  return cont[n].buttonPressed[key]
end

-- Is the button held down
function input.getButtonDown(key, contNum)
  -- Set the default controller number to 1 if not defined
  local n = contNum or 1
  return cont[n].buttonPressed[key]
end

function input.getJoystick(contNum)
  local contNum = contNum or 1
  return cont[contNum].joy
end

-- Validate the scaling heres
function input.getAxis(contNum)
  local contNum = contNum or 1
  local a = maf.vector(0,0);
  if cont[contNum].buttonPressed["UP"]    then a.y = -255 end
  if cont[contNum].buttonPressed["DOWN"]  then a.y = 255 end
  if cont[contNum].buttonPressed["LEFT"]  then a.x = -255 end
  if cont[contNum].buttonPressed["RIGHT"] then a.x = 255 end
  return a
end

function input.getTriggers(contNum)
  local contNum = contNum or 1
  return cont[contNum].trig
end

function __initMouse()

  function love.mousepressed(x, y, button, isTouch)
    cont[1].buttonPressed[clickType[button]] = true
    cont[1].newButton = true
  end

  function love.mousereleased(x, y, button, isTouch)
    cont[1].buttonPressed[clickType[button]] = false
  end

end

-- NOT OPTIMAL
function _updateMouse(player)
  screenInfo = getScreenInfo()
  screenInfo.offset = maf.vector(screenInfo.xOff/2, screenInfo.yOff/2)
  input.mouse:set(love.mouse.getPosition())
  input.mouse:scale(1/screenInfo.scaleFactor)
  input.mouse:sub(screenInfo.offset)
  
end

-- Keyboard is automatically mapped to player 1
function _updateKeyboard()
  function love.textinput(t)
  end

  function love.keypressed(key)
    if key == 'escape' then
      love.event.quit()
      --joy = nil
      --graphics.clearTooltip(tt_inputmode)
      --tt_inputmode = graphics.addTooltip("Keyboard mode active", 5, 5, 4)
    end
  end

  if joy ~= nil then return nil end


  for k, v in pairs(KEYMAP) do
    local button_name = v
    if love.keyboard.isDown(k) and cont[1].lButtons[v] == false then
      cont[1].buttonPressed[v] = true
      cont[1].newButton = true
      --print("Key> " .. v)
    end

    if love.keyboard.isDown(k) == false then
      cont[1].buttonPressed[v] = false
    end
  end
end

function _updateJoystick()
  if platform == "LOVE" and joy ~= nil then

    local axis = {joy:getAxes()}
    controller.joy:set(axis[1]*128, axis[2]*128)
    local hats = joy:getHat(1)
    for k, v in pairs(JOYMAP) do
      if string.match(hats, k) then
        if controller.lButton[v] == false then
          controller.buttonPressed[v] = true
          controller.newButton = true
        end
      elseif string.match(k, "%a") then
        controller.buttonPressed[v] = false
      end
    end

    for i, v in ipairs(JOYMAP) do
      if joy:isDown(i) == true then
        if controller.lButton[v] == false then
          controller.buttonPressed[v] = true
          controller.newButton = true
        end
      elseif joy:isDown(i) == false then
        controller.buttonPressed[v] = false
      end
    end
  end
end

function _printButtons(controller)
  if controller.newButton then
    local i = 0
    print("======== BUTTONS STATES ===============")
    for k, v in pairs(controller.buttonPressed) do
      print(k, v)
    end
  end
  --if controller.newButton then print("P") end
end

function input.getController_OLD(mode)
  if mode == "copy" then
    local cont = {
      buttonPressed   = copy(controller.buttonPressed),
      lButton         = copy(controller.lButton),
      DC_lButton      = controller.DC_lButton,
      newButton       = controller.newButton,
      joy             = maf.vector(0,0),
      trig            = maf.vector(0,0),
    }
    cont.joy          :set(controller.joy)
    cont.trig         :set(controller.trig)
    return cont
  else
    return controller, controller.joy, controller.trig
  end
end

function input.getController(mode)
  if mode == "copy" then
    local cont = {
      buttonPressed   = copy(controller.buttonPressed),
      lButton         = copy(controller.lButton),
      DC_lButton      = controller.DC_lButton,
      newButton       = controller.newButton,
      joy             = maf.vector(0,0),
      trig            = maf.vector(0,0),
    }
    cont.joy          :set(controller.joy)
    cont.trig         :set(controller.trig)
    return cont
  else
    return controller, controller.joy, controller.trig
  end
end

function input.newInput()
  return controller.newButton
end

function input.setController(new)
  controller.buttonPressed   = copy(new.buttonPressed)
  controller.lButton         = copy(new.lButton)
  controller.DC_lButton      = new.DC_lButton
  controller.newButton       = new.newButton
  controller.joy            :clone(new.joy)
  controller.trig           :clone(new.trig)

  print("SETcontroller" .. tostring(new.joy))
end

function input.getMouse()
  return input.mouse
end

-- called by the engine only at the end of a frame
function input.endOfFrame()
  for i=1,4 do
    cont[i].newButton = false
  end

end

-- This works now please never touch this again.
function _processController(b)
  cont[b].newButton = false

  cont[b].joy:set(cont[b].joyx, cont[b].joyy)
  cont[b].trig:set(cont[b].ltrig, cont[b].rtrig)

  for k, v in pairs(cont[b].rawButton) do
    if v and cont[b].buttonPressed[k] == false then
      cont[b].buttonPressed[k] = v
      cont[b].newButton = true
    else
      cont[b].buttonPressed[k] = v
    end
  end

end

return input
