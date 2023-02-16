globals     = require "globals"
gameworld   = require "gameworld"
player      = require "player"

local maf = require "lib.maf"
local profiler    = require "lib.profile"


local tri = {}
local v0, v1, v2
local max, min = math.max, math.min
local lPosition
local outside, f

function gameworld.create(startMap)
  print(os.clock() .. " is time")
  profiler.start()

  currentMap = map:new()
  p1 = player:new()
  p1:setPosition(100, 100)
  --lPosition = p1:getPosition("vector")

  point = {70, 70}

  v0 = maf.vector(50, 50)
  v1 = maf.vector(150, 50)
  v2 = maf.vector(350, 250)
  v3 = maf.vector(50, 150)
  v4 = maf.vector(50, 300)

  triangle = {v0, v1, v2}
  triangle1 = {v0, v3, v2}
  triangle2 = {v4, v3, v2}
  t1 = {v0.x, v0.y, v1.x, v1.y, v2.x, v2.y}
  t2 = {v0.x, v0.y, v3.x, v3.y, v2.x, v2.y}

  allTri = {triangle,triangle1, triangle2}
  allTri = {t1, t2}

  if platform == "LOVE" then
    collision.C_insideTriangle = collision.LUA_insideTriangle
  end

  local s = 0
  s = os.clock()
  for i=1,1000 do
    collision.LUA_insideTriangle(point, t1)
  end
  print("LUA : 1k Point Inside Triangle function: " .. os.clock() - s)


  s = os.clock()
  for i=1,1000 do
    collision.C_insideTriangle(point, t1)
  end
  print("SH4 : 1k Point Inside Triangle function: " .. os.clock() - s)



  profiler.stop()
  print(profiler.report(25))
  return 1
end


local checkDist = 15
local bounceForce = 1
function gameworld.update(dt)
  input.update()
  p1:updatePlayer()

  coll, tNum = collision.check(p1:getDirection(checkDist, true), allTri)
  --print(coll)

  return 1
end

function gameworld.render()

  collision.draw(allTri)
  p1:render()

  return 1
end

function gameworld.free()

  return 1
end


return gameworld
