local quest_raw = {}
local p = p1

function loadQuestData(filename)
  local json = assert(require "json")

  filename = getScriptFolder() .. filename
  if checkFile(filename) then
    local file = io.open(filename, "r")
    local raw =  file:read("*all")
    file:close()
    --Organize the quests based on their ID number
    local json_raw = json.decode(raw)
    for k, v in pairs(json_raw.quest) do
      quest_raw[v.id] = v
    end
    print("QUEST.LUA > Loaded Quest Data")
    return 1
  end
  return nil
end


function addQuest(player, questNumber)
  if player.quest[questNumber] == nil then
    if quest_raw[questNumber] ~= nil then
      player.quest[questNumber] = quest_raw[questNumber]
      player.currentQuest = player.quest[questNumber]
      print("QUEST.LUA > Added quest #" .. questNumber)
      return true
    else
      print("QUEST.LUA > Invalid quest #" .. questNumber)
      return nil
    end
  end
  print("QUEST.LUA > Duplicated quest #" .. questNumber)
  return nil
end

function printAllQuest()
  for k, v in pairs(quest_raw) do
    print(k .. "-" ..  v.name)
  end
end

-- set the quest state (completed, etc)
function setQuestState(id, questState)
  for k, v in pairs(p.quest) do
    if p.quest[id] ~= nil then
      p.quest[id].completed = questState
    end
  end
end

-- set the quest state (completed, etc)
function completeQuest(id)
  if p.quest[id] ~= nil then
    p.quest[id].completed = 1
  end
  return(1)
end

function getQuestNum()
  local questNumber = 0
  for k, v in pairs(p.quest) do
    questNumber = questNumber + 1
  end
  return questNumber
end

function getQuest()
  local q = p.currentQuest
  return q.name, q.desc, q.id, getQuestNum()
end

return quest_raw
