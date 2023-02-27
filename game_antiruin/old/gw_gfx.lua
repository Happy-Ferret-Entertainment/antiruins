local globals     = require "globals"
local profiler    = require "lib.profile"

local obj = {}
local tri = {-50, -50, 50, -50, 0, 50}
local a = 0.01
local catNum = 100
local frameCount = 0

function gameworld.create(startMap)


  obj[1] = gameObject:createFromFile("asset/default/cat.png", 320, 240)
  obj[2] = gameObject:createFromFile("asset/default/spacemono.png", 320, 240)

  obj[1].scale:set(2,2)
  obj[1].angle = 12
  --profiler.start()
  return 1
end

function gameworld.update(dt)
  --graphics.setClearColor(0,0,0,1)
  deltaTime = dt
  input.update()

  if input.getButton("A") then
    catNum = catNum + 10
  end

  frameCount = frameCount + 1
  return 1
end

function gameworld.render(dt)
  graphics.setClearColor(0.3,0.3,0.3, 1)

  -- REGULAR OBJECT
  for i=1, catNum do
    --graphics.setDrawColor(1,0,1, 1)
    --obj[1]:drawObject(280, 240)
  end

  local t = os.clock()
  -- BATCHING
  --graphics.startBatch(obj[1].texture)
  local batch = {}
  for i=1, catNum do
    --obj[1].angle = math.random(360)
    graphics.addToBatch2(obj[1])
  end
  C_endBatch2(obj[1].texture)
  graphics.print("CATS:" .. catNum .. " | " .. os.clock()-t, 20, 240)

  graphics.endFrame(true)

  if frameCount % 10 == 0 then
    --print(profiler.report(25))
    --profiler.reset()
    --os.exit()
  end

  return 1
end

function gameworld.free()

  return 1
end

return gameworld
