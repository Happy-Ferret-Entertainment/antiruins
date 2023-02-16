local love = {
  filesystem = {},
  graphics = {},
  audio = {},
}

romdisk = {
  loaded = false,
  name = "",
}

function setLOVEfunctions()

  love.graphics.setBackgroundColor    = C_setClearColor
  love.graphics.setColor              = C_setDrawColor

  math.sin    = sh4_sin
  math.cos    = sh4_cos
  math.sqrt   = sh4_sqrt
  math.sum_sq = sh4_sum_sq
  math.lerp   = sh4_lerp
  math.abs    = sh4_abs

  graphics.drawTexture = graphics.DC_drawTexture
  graphics.setDrawColor = graphics.DC_setDrawColor

  graphics.addToBatch = graphics.addToBatch2

  --graphics.startBatch = C_startBatch
  --graphics.addToBatch = C_addToBatch
  --graphics.endBatch   = C_endBatch

  print("Love2Dream> Love function override.")
end

-- GRAPHICS ------------------------------------
function graphics.DC_drawTexture(texture, obj, x, y, mode)
  if texture == nil then return nil end

  C_drawTexture(texture, x, y, obj.angle, obj.scale.x, obj.scale.y)
  graphics.drawCall = graphics.drawCall + 1
  graphics.fillrate = graphics.fillrate + (obj.size.x * obj.size.y * obj.scale.x * obj.scale.y)
  return 1
end

function graphics.DC_setDrawColor(r,g,b,a)
  local _r, _g, _b, _a

  if type(r) == "table" then
    _r = r[1] or 1.0
    _g = r[2] or 1.0
    _b = r[3] or 1.0
    _a = r[4] or 1.0
  else
     _r = r or 1.0
     _g = g or 1.0
     _b = b or 1.0
     _a = a or 1.0
  end

  C_setDrawColor(_r, _g, _b, _a)

  dColor = {_r, _g, _b, _a}
end

-- FILESYSTEM ----------------------------------
function love.filesystem.read(file)
  local f = io.open(file, "r")
  local raw = f:read("*all")
  f:close()
  --print("Remapped love.filesys.read worked > " .. file)
  return raw
end

function love.filesystem.load(file)
  --local chunk, err = assert(loadfile(file))
  return loadfile(file)
end


return love
