local log         = {}
local maf         = require "lib.maf"

log.message     = {}
log.string      = ""
log.update      = true
log.maxMessage  = 6
log.box         = gameObject:new()
log.pos         = maf.vector(5, 440)
log.active      = true

function log.init()
  log.pos = maf.vector(20, 480 - graphics.fontSize)
end

function log.add(message)
  if #message < 1 then return end

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
  --graphics.drawQuad(log.box, 0, 0, 0, 0.5)
  graphics.print(log.string, log.pos.x + 5, 5 + log.pos.y - #log.message * graphics.fontSize)
end

function log.clear()

  for i, v in ipairs(log.message) do
    Timer.every(0.05, function() 
      log.message[i] = string.sub(log.message[i], 0, #log.message[i]-1)
      if #log.message[i] == 0 then
        log.message[i] = ""
        return false
      end
    end)
  end

end

function log.change(text, id)
  local id = id or #log.message
  log.message[id] = text
end

return log
