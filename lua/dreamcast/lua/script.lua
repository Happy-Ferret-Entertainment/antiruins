local script = {}

script.index = script
setmetatable(script, {__call = function(cls, ...) return csl.new(...) end,})

function script:new()
  local s = {
    name          = "template",
    parent        = {},
    onLoad        = function(self) end,
    update        = function(self) end,
    render        = function(self) end,
    delete        = function(self) end,
    activate      = function(self) end,
    desactivate   = function(self) end,
  }
  local self = setmetatable(s, script)
  return self
end



--GLOBALS FUNCTIONS
function attachScript(parent, path)
  --Load the script
  local scriptFile = love.filesystem.load(path)
  if scriptFile == nil then return false end

  -- COPY???
  local loadedScript = scriptFile()
  if loadedScript == nil then
    return nil
  else
    --print("SCRIPT DEBUG ------ script loaded fine")
  end

  --Run the onLoad
  if parent == nil then print("SCRIPT> parent is nil?") end
  loadedScript.parent = parent

  -- Check if there is a table for scripts in the parent
  if loadedScript.parent.script == nil then
    loadedScript.parent.script = {}
  end

  local r = loadedScript:onLoad()

  table.insert(parent.script, loadedScript)
  return true
end

function updateScripts(target, deltaTime)
  if target.script == nil then return end
  for i, v in ipairs(target.script) do
    --print(target.scripts[i].name)
    target.script[i]:update(deltaTime)
  end
end

function renderScripts(target, deltaTime)
  if target.script == nil then return end

  for i, v in ipairs(target.script) do
    --print(target.scripts[i].name)
    target.script[i]:render(deltaTime)
  end
end

function removeScript(parent, scriptName)
  for i,v in ipairs(parent) do
    if v.name == scriptName then
      table.remove(parent, i)
    end
  end
end

return script
