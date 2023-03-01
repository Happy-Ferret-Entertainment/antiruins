local myth  = {}
local utils     = require "utils"
local console   = require "console"

myth.current = {}

function myth.change(name)
    local m     = myth[name]
    if m then
        resetProgress()
        console.clear()
        print("Changing myth to " .. name)
        myth.current = m
        newSelection(m.cards)
        selected = 1
    else
        print("Couldn't find myth " .. name)
    end 
end

function myth.update(progress)
    local m = myth.current
    -- print text
    local text = m.text[progress] or "" 
    console.updateText(text)
    
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

myth.welcome = {
    "oh, hello.",
    "once again, I am summoned.",
    "you again...",
    "greetings",
    "g'day.",
    "on this day, really?",
}

myth.positive = {
    "hm, yes sure...",
    "certainly",
    "I agree",
    "of course",
    "yes.",
    "you are right",
}

myth.negative = {
    "you're wrong",
    "I can't do this",
    "unfortunatly",
    "this is impossible",
}


myth.newvisit = {
    "you came looking for !qObject right?",
    "let met guess... !qPerson sent you?",
    "oh.. !qObject.. yes I heard it.",
    "let me see if I can recall something about !qPerson ..."
}

myth.intro = {
    text    = { 
    "Welcome traveller.", 
    "Please choose one of the 3 datadiscs.",
    "Ah, you chose !cardName.",
    "!cardDesc", 
    "Consider this your first gift.",
    "Let's pick a random location..."
    },
    update  = {
        function() updateOnInput = true end,
        showCards,
        "", 
        "", 
        keepCards,
        "",
        console.clear,
        {myth.change, "firstLoc"}
    },
    cards   = {"Pocket LCD", "Damascus Blade", "Diva's Lipstick"},
}


return myth