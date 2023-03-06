
-- speech is sentences
-- myth is storlyline
local myth  = {}
local speech = {}
local lume      = require "lume"
local teller    = require "teller"
local utils     = require "utils"
local console   = require "console"

local imgColor = 0 --backimg intensity
local imgScale = 0

myth.current = {}

myth.knowledge = {
  qPerson  = false,
  qPlace   = false,
  qItem    = false,
}


function myth.newQuest()
  myth.qPerson      = lume.randomchoice(teller.getCardsTag("Person", 1))
  myth.qPlace       = lume.randomchoice(teller.getCardsTag("Place", 1))
  myth.qItem        = lume.randomchoice(teller.getCardsTag("Equipement", 1))

  myth.quest        = ""

  myth.qItemVerb    = lume.randomchoice(speech.verbs.item)
  myth.qPersonVerb  = lume.randomchoice(speech.verbs.person)

  -- we know only 1 things about the myth
  local _type = lume.randomchoice({"qPerson", "qItem", "qPlace"}) 
  myth.knowledge[_type] = true

  print("Myth.newQuest", myth.qPerson, myth.qPlace, myth.qItem)
  for k, v in pairs(myth.knowledge) do
    if v then print("we know about " .. k, myth[k]) end
  end
end

--[[Change the current myth to another one, resets selection, etc.]]--
function myth.change(name)
    local m = myth[name]
    if type(name) == "table" then
      m = name
    end


    if m then
        resetProgress()
        console.clear("full")
        --print("Changing myth to " .. tostring(name))
        myth.current = m

        -- load image if present AND it's not currently loaded.
        if myth.current.img and myth.current.bg == nil then
          local img
          if type(myth.current.img) == "table" then
            img = lume.randomchoice(myth.current.img)
          else
            img = myth.current.img
          end
          myth.current.bg = graphics.loadTexture(img)
        end

        -- Fade in the image
        if myth.current.bg then
          imgColor = 0.0
          imgScale = 0.7
          Timer.every(0.2, function()
            imgColor = imgColor + 0.1
            if imgColor >= 1 then
              return false
            end
          end)
        end

        -- card stuff
        if m.cards then
          newSelection(m.cards)
          selected = 1
        end
    else
        print("Couldn't find myth " .. tostring(name))
    end 
end

function myth.render()
  if myth.current.bg then
    graphics.push()
    graphics.translate(320,240)
    --graphics.scale(0.75, 0.75)
    --graphics.scale(0.5, 0.5)
    graphics.setDrawColor(imgColor,imgColor,imgColor, imgColor/2)
    graphics.drawTexture(myth.current.bg, 0, 0, "center")
    graphics.pop()
  end
end

--[[Called once everytime we need to change the contect of the text displayed]]--
function myth.update(progress)
    local m = myth.current

    -- Proces then send the text to the console or which ever function
    local rawText = m.text[progress] or " "
    local text    = myth.processText(rawText)
    console.updateText(text)

    -- Automatically return to the map if there is nore more text
    if progress > #m.text then
      changeState(ST_MAP)
      return
    end

    -- Call the "update" function associated with the text.
    local seq   = m.update
    local f     = seq[progress]
    if type(f) == "table" then
        f   = seq[progress][1]
        arg = seq[progress][2]
        
        f(arg)
    else
        if type(f) == "function" then f() end
    end
end

--[[Change words, variable, generate random sentences]]--
function myth.processText(text)
    local rawText = text or " "
    local rand    = lume.randomchoice

      if      type(rawText) == "table" then
        text = rand(rawText)
      elseif  type(rawText) == "function" then
        text = rawText()
      else
        text = rawText
      end

      -- simple replacement
      text = text:gsub("!qPerson", myth.qPerson)
      text = text:gsub("!qPlace" , myth.qPlace)
      text = text:gsub("!qItem"  , myth.qItem)

      -- location replacement
      text = text:gsub("!lType"  , myth.current.type or "place")

      -- pick answer
      if type(speech.answer) == "table" then
        speech.answer = rand(speech.answer)
      end
      text = text:gsub("!answer" , speech.answer)

      if text:find("!nPerson") then
        local newPerson = rand(teller.getCardsTag("Person"))
        text = text:gsub("!nPerson", newPerson)
      end
      if text:find("!nPlace") then
        local newPlace = rand(teller.getCardsTag("Place"))
        text = text:gsub("!nPlace", newPlace)
      end
      if text:find("!nItem") then
        local newPerson = rand(teller.getCardsTag("Person"))
        text = text:gsub("!nPerson", newPerson)
      end

      
      if teller.selected then
        text = text:gsub("!cardName"  , teller.selected.name)
        text = text:gsub("!cardDesc"  , teller.selected.desc[1])
        text = text:gsub("!destination"  , teller.selected.desc[1])
    end
    --[[
    if #item > 0 then
        s = s:gsub("!pickedCard", item[1].name)
    end
    --]] 
    return text
end

function myth.lookForAnswer()
  local chance = math.random(100)
  print("Chance is " .. chance)
  local answer  = {
    "I can't seem to remember...",
    "that's really how out of my scope.",
    "never heard about such things..."
  }
  -- give vague answer
  if chance < 70 then
    answer = {
      "I think !nPerson might know something about that...",
      "Oh, weren't they going to !nPlace?",
    }
  
  -- give true answer
  elseif chance < 25 then
    answer = "CARD DESCRIPTION"

  end
  speech.answer = answer
end

speech.answer = "-----------------"

speech.welcome = {
    "oh, hello.",
    "once again, I am summoned.",
    "you again...",
    "greetings",
    "g'day.",
    "on this day, really?",
}

speech.positive = {
    "hm, yes sure...",
    "certainly",
    "I agree",
    "of course",
    "yes.",
    "you are right",
}

speech.negative = {
    "you're wrong",
    "I can't do this",
    "unfortunatly",
    "this is impossible",
}

speech.vague = {
  "I can't seem to recall much..."
}

speech.newvisit = {
    "you came looking for the !qItem right?",
    "what do you know about !qPlace?",
    "let met guess... !qPerson sent you?",
    "oh.. the !qItem.. yes I heard of it.",
    "let me see if I can recall something about !qPerson ..."
}

speech.verbs = {
  item    = {"stole", "burned", "buried", "broke", "lost", "cursed", "reforged", "fake"},
  person  = {"cried"},
}

speech.adjective = {
  item    = {"glass", "crimon", "", "broken", "lost", "cursed", "reforged", "fake"},
  person  = {""},
}

myth.intro = {
    text    = { 
      speech.welcome,
      {"did we ever met?", "you seem familiar.", "what can I do for you?"},
      speech.newvisit,
      {"alright", "I guess I could assist you...", "oh well.", "Should I help you?"},
      "!answer",
      {"good luck.", "hope you find what you're looking for", "come back anytime."}
    },
    update  = {
      "",
      "",
      myth.lookForAnswer,
      "",
      "",
      "",
      function() changeState(ST_MAP) end,
      "",
    },
    cards   = {},
}

myth.randomNpc = {
  text    = { 
    speech.welcome,
    {"did we ever met?", "you seem familiar.", "what can I do for you?"},
    speech.newvisit,
    {"alright", "I guess I could assist you...", "oh well.", "Should I help you?"},
    "!answer",
    {"good luck.", "hope you find what you're looking for", "come back anytime."}
  },
  update  = {
    "",
    "",
    myth.lookForAnswer,
    "",
    "",
    "",
    function() changeState(ST_MAP) end,
    "",
  },
  cards   = {},
}

myth.empty = {
  text    = { 
      "test text 1",
      "doesn't like empty text some sdfn",
      "swiitcchh",
      "   ",
  },
  update  = {
    "", "", "",
    function() changeState(ST_MAP) end,
    "",
  },
  cards   = {},
}


return myth