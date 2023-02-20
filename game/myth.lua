local myth  = {}
local cards = require "cards"

myth.current = {}

function myth.change(name)
    local m     = myth[name]
    if m then
        resetProgress()
        print("Changing myth to " .. name)
        myth.current = m
        newSelection(m.cards)
    else
        print("Couldn't find myth")
    end 
end

function myth.update(progress)
    local m = myth.current
    -- print text
    local text = m.text[progress] or "" 
    updateText(text)
    
    local seq   = m.update
    local f     = seq[progress]
    --local arg =
    
    if type(f) == "table" then
        f   = seq[progress][1]
        arg = seq[progress][2]
        
        f(arg)
    else
        if type(f) == "function" then f() end
    end
end

myth.intro = {
    text    = { "Welcome traveller.", 
    "Please choose one of these trinkets.",
    "Ah, you chose !cardName, how curious.",
    "!cardDesc", 
    "Let's see where you'll begin...",
    },
    update  = {
        "",
        showCards,
        hideCards,
        "",
        keepCards,
        {myth.change, "firstLoc"}
    },
    cards   = {"Pocket LCD", "Damascus Blade", "Diva's Lipstick"},
}

myth.firstLoc = {
    text    = { "Chapter 1 - The Forest", 
    "Deep, dark and green.\nTall pine tree, ground full of acorn.",
    "You have been walking for hours, thinking about...",
    "", 
    "!cardDesc",
    "Hm, I wonder what brings you there...",
    },

    
    cards   = {"Greyvalley", "Knossos's Maze", "Echo Fabrication Lab"},

    update  = {
        "", "", "",
        showCards,
        hideCards,
        function() setDestination(selCard)  end,
        keepCards,
        {myth.change, "motivation"}
    },
}

myth.motivation = {
    text    = {
        "", 
        "Hmm I can see why you are in such a hurry", 
        "You know, the journey seeking !cardName is a tricky one...",
        "Are you sure that you are ready for such a quest?",
        "I hope you find what you're looking for",
        "", 
        "",
        "",
    },
    update  = {
        showCards,
        hideCards, "", "",
        keepCards,
        findNewPlace,
        {myth.change, "encounter"}
    },
    cards   = {"Fame","Vengeance","Friendship","Love","Treasure"},
}

myth.maze = {
    text    = {
        "At the end of road lies a large arch.\nAn opening to a colorful city.",
        "A large painted sign welcomes you:\nTlacololli of the Minotaur", 
        "Crawling inside, you observe many empty stalls and deserted alleyway.",
        "You wander carefully, searching for\nthe fabled Nagual, the Minotaur.",
        "You hear strange buzzing sound coming from a small alleyway.",
        "A young child is trying to pilot a tank-like robot\nstuck underneath collased wall.",
        "In my language, Tlacololli means something wrong, twisted.", 
    },
    update  = {
        tryYourLuck,
        tryYourLuck,
        tryYourLuck,
        "","","","","","","","","","","","",
        {myth.change, "first"}
    },
    cards   = {"Fame","Vengeance","Friendship","Love","Treasure"},
}

return myth