local script_template = {}

script_template.index = script_template
setmetatable(script_template, {__call = function(cls, ...) return csl.new(...) end,})

function script_template:new()
  local s = {
    name = "template",
    parent = {},
  }
  local self = setmetatable(s, script_template)
  return self
end

function script_template:onLoad() end
function script_template:activate() end
function script_template:desactivate() end
function script_template:update() end
function script_template:render() end


return script_template
