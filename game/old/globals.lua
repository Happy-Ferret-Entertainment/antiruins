gameworld   = require "gameworld"
hardware    = require "hardware"
weather     = require "weather"
itemList    = require "item_list"
quests      = require "questlist"
GFX         = require "GFX.GFX"
hw          = require "hardware"
repair      = require "repair"

-- TIME AND WEATHER
deltaTime       = 0.0
realTime        = 0
timeOffset      = 0.0
dayLenght       = 60                    -- Usual value is 60 (second)
mainSpeed       = math.pi / dayLenght   -- complete circle(3.14) in time(60) x 2
frameCount      = 0
mode, lastMode  = "basic", ""

-- Signal / Events
event = hump_signal.new()
timer = hump_timer.new()

--Player data
p1 = {}

--MAPS
maps        = {}
currentMap  = nil

MAP_NAMES = {
  "MAP 0",
  "crash",
  "mountain",
  "mountainpath",
  "shed",
  "harbour",
  "castlepath",
  "queen",
  "queen-video",
  "overworld",
  "menu",
  "intro",
  "garage",
  "lair",
  "dragon",
}


--Colors
color = {
  ACTIVE = {0.16, 0.91, 0.76, 1},
  YELLOW = {0.8, 0.8, 0, 1},
  WHITE  = {1, 1, 1, 1},
  BLACK  = {0, 0, 0, 1},
  ERROR  = {1, 0, 0, 1},
  GREY   = {0.1, 0.1, 0.1, 1},
  LGREY  = {0.35, 0.35, 0.35, 1}
}

-- Love2D stuff
canvas = nil

return 1
