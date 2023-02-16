local card = {}
local cardIndex = {}

function initCard()
    for k, v in pairs(card) do
        table.insert(cardIndex, k)
        if v.name == nil then v.name = k end
        if v.desc == nil then v.desc = {""} end
        print(k)
    end
end

function shuffleCard()
    cardIndex = lume.shuffle(cardIndex)
    for i,v in ipairs(cardIndex) do
        --print(i .." : " ..card[v].name)
    end
end

function getCard(cardName)
    if cardName == nil then
        shuffleCard()
        local c = card[cardIndex[1]]
        return c
    end
end

card.forest = {
    name = "The Forest",
    desc = {
        "The green mother.\nSource of life, the grand wound.\nPerhaps something is growing out there",
        "",
        "",
    }
}

card.garage = {
    name = "Garage",
}

card.maze = {
    name = "Knossos's Maze",
    desc = {
        "An infinite map with no boundary and no rooms.\nAre you just lost or wandering?"
    }
}

card.battery = {
    name = "A small cell",
    desc = {
        "Some ancient battery. Too weak to power a synth.\nA symbol of portable electronics."
    }
}

card.frog = {
    name = "Mechanical Frog",
    desc = {
        "A copper automaton. It can only leap forward."
    }
}

card.synth = {
    name = "Peice of Robot",
    desc = {
        "A peice of a Machine who Lived. I wonder what they lived for.\nYou might need to repair something"
    }
}

return card