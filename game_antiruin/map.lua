local map = {}
local maf   = require "lib.maf"
local lume  = require "lib.lume"
local noise = require "lib.noise"
local myth_loc      = require "myth_location"
local myth_quest    = require "myth_quests"

local EMPTY = "."
local animX, animY = 0, 0
local curSpeed = 3

local locType = {   "Settlement", "Trade Post", "Oasis", 
                    "Vault", "Temple", "Archive", "Arcology Dome", "Spaceship",
                    "Mystic Abode", "Fort", "Castle", "Research Center"
                }

local locSize = {   "Minor" , "Major", "Important", "Forgotten", "Ruined",
                    "Unknown", "Renowned", "Heretic", "", "", "", "", "", "", "", "", "",
                }

local locNames = "Neutress Koundbudash Laxion Thoxxor Cragxmor Sraja Ivrek Duboko Silma Lukne Mina Purvygraple Stle Lach Poldo Sniano Winge Amblassum Raistnuch Wort Wildcred Planiggsbit Ress Heossa Crokka Rood Chemage Elly Azod Trowwoo Cron Atino Cresse Swakey Kandist Golder Piterry Ions Bushousano Trooset Dyel Trinte Bitton Herry Pinsyv Prinkbirch Busaness Oleed Bircharlice Flytarch Rivysmon Roset Screed Reezedoak Rhubab Wint Mapluiton Jacroot Harsed Scorry Swins Catonans Rosemapple Wholle Cotainort Amblanalde Holl Mirry Cort Worn Deroak Aspbwoot Nese Miggsil Hemulbood Blark Sumpino Prash Vilver Sumewort"

local emptyLocation = {
    type = "",
    name = "",
    myth = nil,
}

function map.init()
    local rand = lume.randomchoice

    local locs = {}
    for w in string.gmatch(locNames, "%a+") do
        table.insert(locs, w)
    end

    map.name        = "Region " .. rand(locs) .. " of Urth"
    map.name        = "Land of Ruins"
    map.size        = maf.vector(48*3,32*3)
    map.ascii           = {}
    map.locations       = {}
    map.locationArray   = {}
    map.noise           = {}
    local rX, rY, rS = math.random(50), math.random(50), math.random(30, 70)
    for y=1,map.size.y do
        map.ascii[y]        = {}
        map.locations[y]    = {}
        map.noise[y]        = {}
        
        for x=1, map.size.x do
            map.ascii[y][x] = EMPTY
            if x == 1 or x == map.size.x then map.ascii[y][x] = "|" end
            if y == 1 or y == map.size.y then map.ascii[y][x] = "-" end

            local noise = math.abs(noise.Noise2D(rY + y/rS, rX + x/rS) * 3)
            noise = math.ceil(noise)/5.0
            map.noise[y][x] = noise
        end
    end


    -- locations -------------------------
    local rX, rY
    local features = math.random(6, 15)
    for r=1, features do
        rX, rY = math.random(10, map.size.x-10), math.random(10, map.size.y-10)
        rX = math.ceil(rX/3) * 3
        rY = math.ceil(rY/3) * 3
        map.ascii[rY][rX]       = rand({"*", "!", "¬", "^"})
        local _type = rand(locType)
        map.locations[rY][rX]   = {
            type    = _type,
            name    = string.lower(rand(locSize) .. " " .. _type),
            pos     = maf.vector(rX, rY)
        }
        table.insert(map.locationArray, map.locations[rY][rX])
    end

    -- assign quest ---------------------
    local _l
    for k, v in pairs(myth_quest) do
        _l            = rand(map.locationArray)
        _l.quest      = true
        _l.myth       = v
        _l.progress   = 0
        _l.name       = v.name
        print(_l.pos)
    end

    map.cursor  = maf.vector(math.random(10, map.size.x/3-10), math.random(10, map.size.x/3-10))
    map.cursor:scale(3)
    map.cursor.x = math.floor(map.cursor.x) -- interger
    map.cursor.y = math.floor(map.cursor.y) -- interger
    print(map.cursor)
    map.lcursor = maf.vector(0, 0)
    map.lascii  = map.ascii[map.cursor.y][map.cursor.x]
    map.ascii[map.cursor.y][map.cursor.x] = "X"

    map.cLocation = ""
end

function map.onSwitch()
    animX, animY = 0, map.size.y
end

function map.update()
    -- loading animation
    if animX < map.size.x then
        animX = animX + 0.7
        animX = lume.clamp(animX, 0, map.size.x)
    end
    if animY < map.size.y then
        animY = animY + 0.7
        animY = lume.clamp(animY, 0, map.size.y)
    end

    map.lcursor:set(map.cursor)

    -- Button input
    if input.getButton("LEFT")  then map.cursor.x = map.cursor.x - curSpeed end
    if input.getButton("RIGHT") then map.cursor.x = map.cursor.x + curSpeed end
    if input.getButton("UP")    then map.cursor.y = map.cursor.y - curSpeed end
    if input.getButton("DOWN")  then map.cursor.y = map.cursor.y + curSpeed end

    if input.getButton("A") and map.cLocation ~= emptyLocation then
        if map.cLocation.myth == nil then
            map.newLocation(map.cLocation)
        end
        myth.change(map.cLocation.myth)
        console.add("--- Entered " .. map.cLocation.name .. " ---")
        changeState(ST_ENCOUNTER)
    end


    map.cursor.x = lume.clamp(map.cursor.x, 2, map.size.x-1)
    map.cursor.y = lume.clamp(map.cursor.y, 2, map.size.y-1)

    -- check if cursor as changed
    if map.cursor:distance(map.lcursor) < 4 then
        -- restore previous cursor data
        map.ascii[map.lcursor.y][map.lcursor.x] = map.lascii
        map.lascii = map.ascii[map.cursor.y][map.cursor.x]

        -- check if it a location
        if map.lascii ~= EMPTY then
            map.cLocation = map.locations[map.cursor.y][map.cursor.x]
        else
            map.cLocation = emptyLocation
        end

        map.ascii[map.cursor.y][map.cursor.x] = "X"
    end


end

function map.renderTitle()
    --graphics.print(map.cLocation, 320, 80, {}, 1)
end

function map.render()
    graphics.setClearColor(0.1, 0.1, 0.1, 1)
    local xS, yS = 3, 3
    local xOff, yOff = (640-map.size.x*xS)/2, (480-map.size.y*yS)/2 
    graphics.setDrawColor(1,1,1,1)
    local line
    local c 
    for y=1,animY do
        for x=1,animX do
            c   = map.ascii[y][x]
            col = map.noise[y][x]
            if c == EMPTY then
                graphics.setDrawColor(col, col , col, 1)
            end
            if c == "X" then
                graphics.setDrawColor(0, 0, 1, 1)
            end
            graphics.print(c, xOff + (x-1) * xS, yOff + (y-1) * yS)
        end
    end
    graphics.print(map.name, 320, 80, {}, 1)
    graphics.print(map.cLocation.name, 320, 400, {}, 1)
end

function map.newLocation(loc)
    local loc = loc or copy(emptyLocation)
    local rand = lume.randomchoice
    
    local condition = rand({"ruined", "someone"})
    loc.condition = condition
    
    if      condition == "ruined" then
        loc.myth = myth_loc.ruins
    elseif  condition == "empty" then
        loc.myth.text = {
            {"this place is empty, but you find something on the ground"},
            {"I had to leave...", "the spring is dark..."}
        }
        loc.myth.update = {
            "", "",
            function() changeState(ST_MAP) end,
        }
    elseif  condition == "someone" then

        loc.myth = rand({myth_loc.generative1, myth_loc.generative2})
    elseif  condition == "quest" then
        -- find someone...
        loc.myth.text = {
            {"I'MA VERY IMPORTANT NPC!"},
        }
        loc.myth.update = {
            "", "",
            function() changeState(ST_MAP) end,
        }
    end

    loc.myth.type = loc.type
    return loc
end

return map