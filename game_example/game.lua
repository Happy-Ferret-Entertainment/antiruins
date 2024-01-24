local game = {}

SCENE     = findFile("example_scene.lua")
VIDEO     = findFile("example_video.lua")
SIMPLE    = findFile("example_simple.lua")
SAVEFILE  = findFile("example_savefile.lua")
AUDIO     = findFile("example_audio.lua")
ANIMATION = findFile("example_animation.lua")
COLLISION = findFile("example_collision.lua")

game = gameworld.loadfile(SCENE)

return game