local maf = require "lib.maf"

local collision = {}

local tri = {
  maf.vector(0,0),
  maf.vector(0,0),
  maf.vector(0,0),
}

local insideIndex = 0

function collision.init()
  if platform == "LOVE" then
    collision.pointInTri = collision.LUA_insideTriangle
  else
    --collision.pointInTri = collision.LUA_insideTriangle
    collision.pointInTri = collision.C_insideTriangle
  end

  collision.nTri = {} --neighbours
  print("COLLISION> Init. (" .. platform ..")")
end

-- Nightmare function. DO NOT TOUCH.
function collision.getTriangles(xml)
  local allTriangle = {}
  for i=1, #xml.path do
    local raw = xml.path[i]["@d"]
    raw = string.gsub(raw, "[,LMZ ]", " ")
    --print(raw)
    local index, tri, swap = 1, {}, false
    local value, v1, v2
    for word in string.gmatch(raw, "%S+")do
      value = string.match(word, "(%-?%d+.%d+)")

      if value == nil then
        if string.match(word, "V") then
          v2 = tri[index-2]
        end

        if string.match(word, "H") then
          v1 = tri[index-1]
          swap = true
        end
      end

      if value ~= nil then
        if index % 2 == 1 then
          v1 = value
        else
          v2 = value
        end
      end


      if index % 2 == 0 then
        if swap then
          table.insert(tri, tonumber(v2))
          table.insert(tri, tonumber(v1))
        else
          table.insert(tri, tonumber(v1))
          table.insert(tri, tonumber(v2))
        end
        swap = false
      end
      index = index + 1
    end
    --print(table.unpack(tri))
    table.insert(allTriangle, tri)
  end
  return allTriangle
end

--[[
function collision.LUA_insideTriangle(t, tri)
  local v0, v1, v2 = tri[1], tri[2], tri[3]
  local area = 0.5 *(-v1.y*v2.x + v0.y*(-v1.x + v2.x) + v0.x*(v1.y - v2.y) + v1.x*v2.y)
  local s = 1/(2*area)*(v0.y*v2.x - v0.x*v2.y + (v2.y - v0.y)*t.x + (v0.x - v2.x)*t.y);
  local t = 1/(2*area)*(v0.x*v1.y - v0.y*v1.x + (v0.y - v1.y)*t.x + (v1.x - v0.x)*t.y);

  if s > 0 and t > 0 and 1-s-t > 0 then
    return true
  else
    return false
  end
end
--]]

function collision.LUA_insideTriangle(t, tri)
  --local v0, v1, v2 = maf.vector(tri[1], tri[2]), maf.vector(tri[3], tri[4]), maf.vector(tri[5], tri[6])

  --[[
  local area = 0.5 *(-v1.y*v2.x + v0.y*(-v1.x + v2.x) + v0.x*(v1.y - v2.y) + v1.x*v2.y)
  local s = 1/(2*area)*(v0.y*v2.x - v0.x*v2.y + (v2.y - v0.y)*t.x + (v0.x - v2.x)*t.y);
  local t = 1/(2*area)*(v0.x*v1.y - v0.y*v1.x + (v0.y - v1.y)*t.x + (v1.x - v0.x)*t.y);
  --]]

  local area = 0.5 *(-tri[4]*tri[5] + tri[2]*(-tri[3] + tri[5]) + tri[1]*(tri[4] - tri[6]) + tri[3]*tri[6])
  local s = 1/(2*area)*(tri[2]*tri[5] - tri[1]*tri[6] + (tri[6] - tri[2])*t[1] + (tri[1] - tri[5])*t[2]);
  local t = 1/(2*area)*(tri[1]*tri[4] - tri[2]*tri[3] + (tri[2] - tri[4])*t[1] + (tri[3] - tri[1])*t[2]);


  if s > 0 and t > 0 and 1-s-t > 0 then
    return true
  else
    return false
  end
end

function collision.C_insideTriangle(t, tri)
  return sh4_insideTriangle(tri[1], tri[2], tri[3], tri[4], tri[5], tri[6], t[1], t[2])
end

function collision.computeCloseTri(triangles)
end

function collision.check(point, triangles)
  local p = {point.x, point.y}
  -- Check the last checked collisition first
  if collision.lastCol ~= nil then
    if collision.pointInTri(p, collision.lastCol) then return true end
    -- else check this triangle neighbours
    for i,v in ipairs(collision.lastCol.n) do
    end
  end
  -- Otherwise, check all triangle (should ideally never get there)
  for i, v in ipairs(triangles) do
    if collision.pointInTri(p, v) then
      insideIndex = i
     return true, i
   end
  end
  insideIndex = 0
  return false
end

function collision.draw(triangles)
  for i, v in ipairs(triangles) do
    if i == insideIndex then
      graphics.drawPoly(v, 0, 1, 0, 1)
    else
      graphics.drawPoly(v, 1, 0, 0, 1)
    end
  end
end

return collision
