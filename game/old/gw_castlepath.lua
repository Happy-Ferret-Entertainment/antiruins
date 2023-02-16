globals       = require "globals"
game_scripts  = {}
local profiler      = require "lib.profile"

local accumulator = 0.0
ss_debug    = true
godmode     = false

function gameworld.newGame()
  print("== Start new game ==")

  p1:pickItem("Repair Kit", false)
  p1:pickItem("Radio Module", false)
  p1:pickItem("Safety Flare", false)

  p1:addQuest(QUEST_CRASH)

  currentMap:switch("intro")
end

function gameworld.create(startMap, savenum)
  local startMap = startMap or "menu"
  local saveGame = saveGame or nil

  startMap = "castlepath"

  audio.loadDefault()
  p1 = player:new()

  map.init()
  weather.init()
  hardware.init()
  itemList.init()
  signal.init()
  GFX.init()
  repair.init()

  if godmode then
    p1:pickItem("Repair Kit", false)
    p1:pickItem("Radio Module", false)
    p1:pickItem("Safety Flare", false)
    p1:addQuest(QUEST_CRASH, Q_DONE)
  end

  maps["overworld"] = map:load("overworld")
  currentMap = map:new()
  for i, v in ipairs(MAP_NAMES) do
    --maps[v] = map:load(v)
  end
  currentMap:switch(startMap)

  if savenum then
    saveload:load(savenum)
    saveload:applyLoad()
  end

  if platform == "LOVE" then
    profiler.start()
  else
    --profiler.start()
    profiler = nil
  end

  p1:setPosition(1500, 2500)
  return 1
end

function gameworld.update(dt)
  deltaTime = dt
  -- Libs
  timer:update(dt)
  -- I/O
  --flux.update(dt)
  input.update()
  --vmu.update(dt)
  -- Systems
  --hardware.update(dt)
  weather.update(dt)

  -- Game
  graphics.updateCamera()
  updateScripts(game_scripts)
  p1:updatePlayer()
  currentMap:update(dt)

  if profiler then
    if platform == "LOVE" then
      if frameCount % 120 == 0 then
        --print(profiler.report(10))
        --profiler.reset()
      end
    else
      if frameCount % 30 == 0 then
        profiler.start()

      elseif frameCount % 30 == 1 then
        profiler.stop()
        print(profiler.report(25))
        profiler.reset()
      end
    end
  end

  --collectgarbage("step", 25)

  return 1
end

function gameworld.render()
  graphics.push()
  weather.render("under")

  -- CAMERA TRANSLATE SECTION
  graphics.translateCamera()
  currentMap:render()
  renderScripts(currentMap)
  renderScripts(game_scripts)
  p1:render()
  graphics._label()
  currentMap:renderDescription()
  graphics.pop()

  -- POST CAMERA TRANSLATION
  --repair:render()
  --hardware.render()
  --itemList.render()
  --graphics.renderTooltip()

  if p1.state == state.overworld then
    maps.overworld:render()
    renderScripts(maps.overworld)
  end


  graphics.endFrame(ss_debug)
  return 1
end

function gameworld.free()
  p1:delete()
  weather.delete()
  currentMap = nil
  maps.menu:delete()
  maps.menu = nil
  currentMap = nil
end

return gameworld
