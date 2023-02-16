local globals     = require "globals"
local gameworld   = require "gameworld"
local profiler    = require "lib.profile"

function gameworld.create(startMap)
  if platform == "DC" then
    os.clock = C_clock
  end

  profiler.start()
  local t = os.clock()
  print(t)
  --[[
  local r = 0
  -- SH4 SINE
  for i=1, 100000 do
    r = sh4_sin(1)
  end
  local t1 = os.clock()
  local message = string.format("100k SH4 SINE: %.10f", t1 - t)
  print(message)

  -- REGULAR SINE
  t = os.clock()
  for i=1, 100000 do
    r = math.sin(1)
  end
  t1 = os.clock()
  local message = string.format("100k REGULAR SINE: %.10f", t1 - t)
  print(message)
  --]]

  -- MAF NORMALIZE
  t = os.clock()
  v = maf.vector(70,70)
  v1 = maf.vector()
  for i=1, 1000 do
    v:normalize()
  end
  print(tostring(v))
  t1 = os.clock()
  local message = string.format("1k MAF NORMALIZE: %.10f", t1 - t)
  print(message)


  t = os.clock()
  local x, y, z = v.x, v.y, 0
  for i = 1, 1000 do
    v.x, v.y, v.z = sh4_vecNormalize(x, y, z)
  end
  t1 = os.clock()
  local message = string.format("1k SH4 VEC2 NORMALIZE: %.10f", t1 - t)
  print(message)

  profiler.stop()
  print(profiler.report(25))-- SH4 NORMALIZE
  return 1
end

function gameworld.update(dt)
  return 1
end

function gameworld.render()
  graphics.setClearColor(0, 0, 1, 1)
  return 1
end

function gameworld.free()
  return 1
end

return gameworld
