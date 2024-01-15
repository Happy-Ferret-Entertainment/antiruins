--[[
This is currently running as a coroutine, but it doesn't have to.
This was mostly done so you get a reading on screen if you don't have  terminal printouts.


The important parts are vmu.initSavefile(gameName, saveName, shortDesc, longDesc)
                        vmu.checkForSave(saveFile)
                        vmu.loadGame(saveFile)
                        vmu.saveGame(saveFile, gameData)
                        vmu.deleteGame(saveFile)                       
]]

local game = {}

local vmuRoutine = nil
local log = {}

function testVMU(verbose)
    local gameName = "Antiruins"
    local saveName = "TEST_SAVE"
    local saveFile = vmu.initSavefile(gameName, saveName,  "", "")
    coroutine.yield("Savefile initialized. (Name: " .. gameName .. ")")

    local gameData = nil
    if vmu.checkForSave(saveFile) then
        gameData = vmu.loadGame(saveFile)
        coroutine.yield("Savefile found.")

    else
        gameData = {}
        coroutine.yield("Savefile not found.")
    end

    gameData.value1 = "a string"
    gameData.value2 = 5
    gameData.value3 = {console = "dreamcast", company = "SEGA"}

    vmu.saveGame(saveFile, gameData)
    coroutine.yield("Savefile update with new data.")

    local saveString = {}
    for k, v in pairs(gameData) do
        local _value = tostring(k) .. " -> " .. tostring(v)
        table.insert(saveString, _value)
    end
    coroutine.yield("Savefile data: \n" .. table.concat(saveString, "\n"))

    local delete = false
    if delete then
        vmu.deleteGame(saveFile)
        coroutine.yield("Savefile deleted.")
    end
end


function game.create()
    graphics.loadFont(findFile("assets/MonofontSmall.dtex"), 16, 8, 0)
    vmuRoutine = coroutine.create(testVMU)
end

function game.update(dt)
    if input.getButton("START") then
        exit()
    end

end

function game.render(dt)
    local message, status = "", ""

    if coroutine.status(vmuRoutine) ~= "dead" then
        status, message = coroutine.resume(vmuRoutine)
        table.insert(log, message)
    else
        message = "VMU test finished."
    end

    graphics.print(table.concat(log, "\n"), 20, 20)
end

return game