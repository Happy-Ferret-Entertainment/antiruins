local log         = {}
local gameObject  = require "gameobject"
local graphics    = require "graphics"
local maf         = require "lib.maf"

log.message     = {}
log.string      = ""
log.update      = false
log.maxMessage  = 6
log.box         = gameObject:new()
log.pos         = maf.vector(5, 475)
log.active      = false

function log.add(message)
  table.insert(log.message, message)
  if #log.message > log.maxMessage then
    table.remove(log.message, 1)
  end
  log.update = true
end

function log.toggle()
  log.active = not log.active
end

function log.print()
  if log.active ~= true then return end

  if log.update then
    log.string = table.concat(log.message, "\n")
    log.box.size:set(630, #log.message * 16)
    log.box.pos:set(log.pos.x + log.box.size.x * 0.5, log.pos.y - log.box.size.y * 0.5)
  end
  graphics.drawQuad(log.box, 0, 0, 0, 0.5)
  graphics.print(log.string, log.pos.x + 5, 5 + log.pos.y - #log.message * 16)
end

return log
