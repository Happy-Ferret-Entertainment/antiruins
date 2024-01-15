local game = {}
local bump = require "lib.bump"
local world = bump.newWorld(32)

local floor = {name = "floor",  x=320, y=480, w=640, h=20}
local left  = {name = "left",   x=0,   y=240, w=20, h=480}
local right = {name = "right",  x=640, y=240, w=20, h=480}

local ball      = {} -- keep this for functions
local balls     = {}
local maxSpeed  = 14
local ballNb    = 1

local scale = {x=2, y=2}
function game.create()
  tex = graphics.loadTexture(findFile("assets/logo.dtex"))

  for i=1, 15 do
    local b = {name = "ball", x=320+math.random(-60,60), y=math.random(-20,20), w=10, h=10}
    b.vel = maf.vector(math.random(-10,10), math.random(1,3))
    b.colFilter       = ball.colFilter
    b.checkCollision  = ball.checkCollision
    world:add(b, b.x, b.y, b.w, b.h)
    table.insert(balls, b)
  end


  world:add(floor, floor.x, floor.y, floor.w, floor.h)
  world:add(left, left.x, left.y, left.w, left.h)
  world:add(right, right.x, right.y, right.w, right.h)

end

function game.update(dt)
  if input.getButton("START") then
    exit()
  end

  if input.getButton("A") then
    for i,v in ipairs(balls) do
      v.y = 40
      v.vel = maf.vector(math.random(-10,10), math.random(1,3))
      world:update(v, v.x, v.y)
    end
  end

  for i, v in ipairs(balls) do
    v.vel = v.vel + maf.vector(0, 0.71)  -- gravity
    if v.vel:length() > maxSpeed then
      v.vel = v.vel:normalize():scale(maxSpeed)
    end

    v.vel = v.vel * 0.999             -- dampening

    -- Bouncy ball
    local cols, len
    v.x, v.y, cols, len = world:move(v, v.x + v.vel.x, v.y + v.vel.y, v.colFilter)
    v:checkCollision(cols, len)
  end
end

function game.render(dt)
  graphics.setClearColor(0,0,0,1)

  --graphics.setDrawColor(1,0.5,0,1)
  --graphics.drawRect(0,0,640,480, "corners")

  graphics.setDrawColor(0,0,1,1)
  graphics.drawRect(floor.x, floor.y, floor.w, floor.h)
  graphics.drawRect(left.x, left.y, left.w, left.h)
  graphics.drawRect(right.x, right.y, right.w, right.h)

  graphics.setDrawColor(1,0,1,1)
  local x, y
  for i,v in ipairs(balls) do
    x, y = world:getPosition(v)
    graphics.drawRect(x, y, v.w, v.h)
  end
end

function game.free()
  graphics.freeTexture(tex)
end

function ball:checkCollision(cols, len)
  if cols[1] then
    local bounce  = maf.vector(cols[1].bounce.x, cols[1].bounce.y)
    local touch   = maf.vector(cols[1].touch.x, cols[1].touch.y)
    local dir     = (bounce - touch):normalize()
    local speed   = self.vel:length()

    self.vel = dir:scale(speed*0.8)
  end
end

function ball.colFilter(item, other)
  return "bounce"
end

return game