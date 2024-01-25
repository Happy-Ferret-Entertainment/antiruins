local game = {}

-- BASIC TOPICS
TEXTURE     = findFile("1A_texture.lua")
FONT        = findFile("1B_font.lua")
INPUT       = findFile("2_input.lua")
AUDIO       = findFile("3_audio.lua")

-- ADVANCED TOPICS
SCENE     = findFile("example_scene.lua")
VIDEO     = findFile("example_video.lua")
SAVEFILE  = findFile("example_savefile.lua")
ANIMATION = findFile("example_animation.lua")
COLLISION = findFile("example_collision.lua")

-- Change the argument to the example you want to run
game = gameworld.loadfile(TEXTURE)

return game