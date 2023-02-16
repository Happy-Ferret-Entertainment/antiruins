local xml2lua     = require "lib.xml2lua"
local maf         = require "lib.maf"
local gameObject  = require "gameobject"

local editor = {
  active      = false,
  hover       = nil,
  selected    = nil,
  xml_data    = {},
  lastMode    = "",
  position    = maf.vector(640, 0),
  size        = maf.vector(200, 480),
  mOffset     = maf.vector(0,0),

}

local svg = {
    width = "100",
    height = "20",
    g = {
      id = "layer1",
      image = {
        x = 20,
        y = 5000,
      }
    }
}

function editor.init()
  print("EDITOR> Editor init.")
end

function editor.toggle()
  editor.active = not editor.active

  if editor.active then
    lastMode = mode;
    p1.obj.display = true
    mode = "edit"
    --love.window.setMode(640 + 200, 480 + 200)
    --love.mouse.setVisible(true)
  else
    mode = lastMode
    --love.mouse.setVisible(false)
    --love.window.setMode(640, 480)
    --editor.exportMap()
  end

  print("EDITOR> Editor active : " .. tostring(editor.active))
end

function editor.update()
  if mode ~= "edit" then return end
  p1:setPosition(love.mouse.getPosition())

  editor.updateInput()
end

function editor.render()
  editor.renderMenu()

  for i,v in ipairs(currentMap.objects) do
    if      v == editor.selected then
      graphics.drawQuad(v, 0.75, 0, 0, 0.1);
    elseif  v == editor.hover then
      graphics.drawQuad(v, 0.75, 0.75, 0, 0.1);
    else
      --graphics.drawQuad(v, 0, 0.75, 0.75, 0.1);
    end
  end

  p1:render()
end

function editor.renderMenu()
  graphics.push()
  graphics.translate(editor.position.x, editor.position.y)
  if editor.selected ~= nil then
    graphics.print("Object: " .. editor.selected.npcID, 20, 20)
  end
  graphics.pop()
end


-- MAP EXPORT ----------------------------
function editor.exportMap()
  for i,v in ipairs(currentMap.objects) do

  end
end

function editor.exportObject(obj)
end

function editor.saveMap()
  local filename = "/asset/map_" .. currentMap.name .. "/map_" .. currentMap.name .. ".test"
  local data = xml2lua.toXml(svg, "svg")

  local file = io.open(filename, "wb")
  file:write(data)
  file:close()
end
------------------------------------------

-- INPUT ---------------------------------
function editor.updateInput()

  -- Select
  editor.hover = nil
  for i,v in ipairs(currentMap.objects) do
    if p1:isOver(v) and editor.hover == nil then
      editor.hover = v;
    end
    if v == editor.hover and love.mouse.isDown(1) then
      editor.selected = v
      editor.hover = nil
    end
  end

  -- Deselect
  if editor.selected ~= nil and love.mouse.isDown(2) then
    editor.selected = nil
  end

  -- Dragging
  if editor.selected ~= nil then
    if p1:isOver(editor.selected) and love.mouse.isDown(1) then
      --editor.mOffset = editor.selected:getPosition()- p1:getPosition("vector")
      editor.selected:setPosition(p1:getPosition("vector") + editor.mOffset)
    end
  end

end

function editor.keypressed(key)

  -- Duplicate
  if editor.selected ~= nil and key == "d" then
    local c = gameObject:copy(editor.selected)
    currentMap:addObject(c)
  end
end
----------------------------------------


return editor
