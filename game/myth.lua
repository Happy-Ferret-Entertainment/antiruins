local myth = {}
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
    "Please choose one of those trinkets.",
    "Ah, you chose !cardName, how curious.",
    "!cardDesc", 
    "Let's see how your story unfold...",
    },
    update  = {
        function() end,
        showCards,
        hideCards,
        function() end,
        keepCards,
        {myth.change, "first"}
    },
    cards   = {"Pocket LCD", "Damascus Blade", "Diva’s Lipstick"},
    len     = 6,
    loop    = 1,
}

myth.first = {
    text    = {
        "CHAPTER 1", 
        "Your story starts with the !pickedCard", 
        "What will come next?",
        "Oh, the !cardName", 
        "!cardDesc",
        "",
    },
    update  = {
        function() end,
        function() end,
        showCards,
        hideCards,
        keepCards,
        {myth.change, "first"}
    },
    cards   = 3,
    len     = 3,
    loop    = 3,

}

return myth