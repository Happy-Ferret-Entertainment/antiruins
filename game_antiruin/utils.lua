local utils = {}

function tryYourLuck()
    local totalLuck = 5
    local luck = 0
    for i=1, totalLuck do
        luck = luck + math.random(0, 1)
    end
    return luck
end

function updateAfter(second)
    local second = second or 1
    Timer.after(second, function()
        progress = progress + 1
    end)
end

return utils