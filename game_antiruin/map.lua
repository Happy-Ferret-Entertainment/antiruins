local map = {}
local maf = require "lib.maf"
local lume = require "lib.lume"


function map.init()
    map.size = maf.vector(48,32)
    map.ascii = {}
    for y=1,map.size.y do
        map.ascii[y] = {}
        for x=1, map.size.x do
            map.ascii[y][x] = "."
        end
    end

    local rX, rY
    for r=1, 40 do
        rX, rY = math.random(map.size.x), math.random(map.size.y)
        map.ascii[rY][rX] = lume.randomchoice({"*", "!", "¬", "^"})
    end

    map.cursor = maf.vector(math.random(map.size.x), math.random(map.size.y))
    map.lcursor = maf.vector(0, 0)
    map.lascci = map.ascii[map.cursor.y][map.cursor.x]
    map.ascii[map.cursor.y][map.cursor.x] = "X"

end

function map.update()
    
    -- figure out a way to restore the previous cursor on map
    map.lcursor:set(map.cursor)
    
    if input.getButton("LEFT")  then map.cursor.x = map.cursor.x - 1 end
    if input.getButton("RIGHT") then map.cursor.x = map.cursor.x + 1 end
    if input.getButton("UP")    then map.cursor.y = map.cursor.y - 1 end
    if input.getButton("DOWN")  then map.cursor.y = map.cursor.y + 1 end

    -- check if cursor as changed
    if map.cursor:distance(map.lcursor) ~= 0 then
        -- restore previous cursor data
        map.ascii[map.lcursor.y][map.lcursor.x] = map.lascci
        map.lascci = map.ascii[map.cursor.y][map.cursor.x] 
        map.ascii[map.cursor.y][map.cursor.x] = "X"
    end


end

function map.render()
    --local x, y = (640-map.size.x)/2, (480-map.size.y)/2 
    graphics.setDrawColor(1,1,1,1)
    local line
    local c 
    for y=1,map.size.y do
        --line = table.concat(map.ascii[y], "")
        for x=1,map.size.x do
            c = " " .. map.ascii[y][x]
            graphics.print(c, x * 5, y * 10)
        end
    end
end

function map.generateAscii()

end


return map