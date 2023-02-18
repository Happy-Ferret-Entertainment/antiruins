local card = {}
local cardIndex     = {} -- this holds all the card key
local hat           = {} -- this is a hat which we can pick (remove) cards

function initCard()
    for k, v in pairs(card) do
        table.insert(cardIndex, k)
        if v.name == nil then v.name = k end
        if v.desc == nil then v.desc = {""} end
        v.obj   = nil
        v.angle = 0
        --print(k)
    end
    resetHat()
end

function shuffleCard()
    hat = lume.shuffle(hat)
    for i,v in ipairs(hat) do
        --print(i .." : " ..card[v].name)
    end
end

function getCard(cardName)
    if cardName == nil then
        shuffleCard()
        local name = table.remove(hat, 1)
        return card[name]
    end
end

function resetHat()
    hat = copy(cardIndex)
end

-- can be used with card.render()
function render(card)
    graphics.push()
    graphics.translate(self.pos.x, self.pos.y)
    graphics.rotate(self.angle)
    self.obj:drawObject()
    graphics.pop()
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