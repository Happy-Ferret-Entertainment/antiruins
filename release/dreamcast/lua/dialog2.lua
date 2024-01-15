local dialog = {}
local raw = {}
local block = {}
local nextPosition = 0 -- specific for the love filesystem hack
local fileLoaded = false
local lastFile = ""

-- Go to a block based on tag
function goToBlock(tag)
  local tag = tag or nil
  local pre, line = "" , ""

  for i, line in ipairs(raw) do
    if line == nil then resetFile() return false end
    if line then

      pre   = string.sub(line, 1, 1)
      data  = string.sub(line, 3, -1)

      if      pre == "#" and data == tag then
        nextPosition = i
        print("Dialog> Going to " .. tostring(tag) .. " at " .. i)
        return true, nextPosition
      end
    end
  end

  print("Dialog> Coudn't find tag : " .. tostring(tag))
  return false, 0
end

-- Get the next block in line
function loadNextBlock(tag)
  local tag = tag or nil
  local pre, line, i = "" , "", 1
  block = { text = {} }

  while line ~= nil do
    line = raw[nextPosition]
    if line == nil then nextPosition = 1 return nil end
    line = string.gsub(line, "  ", "", 1) -- This could be kind of dangerous. detele de 2x space (tabs)

    if line then
      pre   = string.sub(line, 1, 1)
      data  = string.sub(line, 3, -1)
      --print(pre)
      if      pre == "#" then block.tag = data block.position = nextPosition
      elseif  pre == "?" then block.condition = data
      elseif  pre == "!" then block.trigger = data
      elseif  pre == ">" then block.next = data
      elseif  pre == "-" then block.unmet = {}
      elseif  pre == "@" then block.author = data
      elseif  pre == "|" then
        if block.unmet then
          table.insert(block.unmet, "")
        else
          table.insert(block.text, "")
        end
      elseif  pre == "=" then  break -- block.position = nextPosition
      elseif  pre == " " or pre == "" then --nothing
      else
        if block.unmet then
          table.insert(block.unmet, line)
        else
          table.insert(block.text, line)
        end
      end
    else
      break
    end
    nextPosition = nextPosition + 1
  end
end

-- Process the whole block, trigger, text, etc.
function processBlock(block)
  if block == nil then return nil end
  local status
  --Check the block condition
  if checkCondition(block) then
    block.conditionCheck = true
    --printBlock(block)

    --Trigger
    --if block.trigger then triggerBlock(block) end

    -- Go to next
    if    block.next then
      status, block.position = goToBlock(block.next)
    else
      status, block.position = resetBlock()
    end

  -- Unmet condition
  else
      print("Dialog> Condition not met.")
      block.trigger = nil
      block.text = block.unmet
      block.next = block.tag
      block.conditionCheck = false
      status, block.position = resetBlock()
  end
    return block.position
end

-- Reset the curent block
function resetBlock()
  return goToBlock(block.tag)
end

function resetFile()
  nextPosition = 0
  -- block = nil ??
end

-- Print the normal text, or unmet text
function printBlock(block, tag)
  if block == nil then return nil end
  if tag == "unmet" and block.unmet then
    for i, v in ipairs(block.unmet) do
      print(v)
    end
    return
  else
    for i, v in ipairs(block.text) do
      print(v)
    end
  end
  print("---")
end

-- Print the normal text, or unmet text
function getBlockText(block, tag)
  if block == nil then return nil end
  if tag == "unmet" and block.unmet then
    for i, v in ipairs(block.unmet) do
      print(v)
    end
    return
  else
    for i, v in ipairs(block.text) do
      print(v)
    end
  end
  print("---")
end
-- Check the block condition
function checkCondition(block)
  if block.condition == nil then return true end
  local cond = "return " .. block.condition
  local c = loadstring(cond)()
  return c
end

-- Check the block condition
function triggerBlock(block)
  if block.trigger == nil then return true end
  --print(block.trigger)
  local c = loadstring(block.trigger)()
  return true
end

function dialog.setFile(file, position)
  if file == nil then fileLoaded = false print("setFile error") return nil end

  if lastFile ~= file then
    raw = {}
    local file = checkFile(file)
    if platform == "LOVE" then
      for l in love.filesystem.lines(file) do
        table.insert(raw, l)
      end
    else
      for l in io.lines(file) do
        table.insert(raw, l)
      end
    end
  -- If the file is already loaded
  else
    print("Dialog> file " .. file .. " already loaded")
  end

  if raw == nil then
    fileLoaded = false
    print("Dialog> Couldn't find file " .. file)
    block = nil
    return nil
  else
    lastFile = file
    fileLoaded = true
    block = {}
    print("Dialog> Found file " .. file)
  end

  if fileLoaded and position then
    print("POSITION = " .. position)
    nextPosition = position
  end

  return fileLoaded
end

function dialog.getText(target)
  if raw == nil or fileLoaded == false then print("Dialog> Invalid file for dialog") return nil end

  local status

  if target.desc_position > 1 then
    --print("Dialog >>> Choosing next position")
    status = true
    nextPosition = target.desc_position
  else
    --print("Dialog >>> Choosing npcID")
    status, nextPosition = goToBlock(target.npcID)
  end

  if status then
    loadNextBlock()
    nextPosition = processBlock(block)
  end

  if target.name ~= nil then
    --block.author = target.name
  end

  target.desc_position = block.position
  if block.text then
    return block.text, block.author, block.trigger
  else
    return nil
  end
end

function dialog.getConditionCheck(target)
  local status
  if target.desc_position > 1 then
    --print("Dialog >>> Choosing next position")
    status = true
    nextPosition = target.desc_position
  else
    --print("Dialog >>> Choosing npcID")
    status, nextPosition = goToBlock(target.npcID)
  end

  loadNextBlock()
  local cond = checkCondition(block)
  print("DIALOG> Checking conditon for " .. target.npcID .. " = " .. tostring(cond))
  return cond
end

function dialog.setRaw(new_raw)
  if new_raw ~= nil then
    raw = new_raw
    nextPosition = 1
    lastFile = ""
    --print("DIALOG> New Raw data - position reset")
  end
end

function dialog.getRaw()
  return raw
end

function dialog.resetRaw()
  raw           = {}
  block         = {}
  nextPosition  = 1
  fileLoaded    = false
end


return dialog
