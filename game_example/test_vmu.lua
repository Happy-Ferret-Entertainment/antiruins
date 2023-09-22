function testVMU(verbose)
    local saveFile = vmu.initSavefile("Antiruins", "TEST_SAVE",  "", "")
    vmu.deleteGame(saveFile)

    local gameData = {}
    if vmu.checkForSave(saveFile) then
        gameData = vmu.loadGame(saveFile)
        vmu.addToSave(gameData, {key1 = true})
        vmu.addToSave(gameData, {key2 = "a string"})
        vmu.addToSave(gameData, {key3 = 5})
        vmu.addToSave(gameData, {key4 = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}})

        vmu.saveGame(saveFile, gameData)
    
    else -- No savefile found
        vmu.addToSave(gameData, {gameID = "Antiruins"})

        vmu.saveGame(saveFile, gameData)
    end

    gameData = vmu.loadGame(saveFile)
    print("Save file as table: ")
    for k, v in pairs(gameData) do
        print(k .. " -> " .. tostring(v))
    end

    vmu.deleteGame(saveFile)
    return 1
end

return testVMU