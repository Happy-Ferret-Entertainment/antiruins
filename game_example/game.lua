local game = {}

SCENE     = findFile("example_scene.lua")
VIDEO     = findFile("example_video.lua")
SIMPLE    = findFile("example_simple.lua")
SAVEFILE  = findFile("example_savefile.lua")

game = gameworld.loadfile(SAVEFILE)

return game