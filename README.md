# Antiruins
*Dreamcast <-----> Lua <-----> Love2D*

Antiruins is a minimal 2D engine for the SEGA Dreamcast (and Love2D).
It was notably used by Reaperi Cycle and Summoning Signals by Magnes.

## Features
All you need is a game.lua file template included. No C code required.
```
local game = {}

function game.create()
end

function game.update()
end

function game.render()
end

return game

```

Fast drawing of .png and .dtex files
```
img = graphics.load("path/to/file.png)
graphics.draw(img, 50, 50)
```






## Aknowledgement
Antiruins uses:
* Simulant's [GLdc](https://gitlab.com/simulant/GLdc)
* Simulant's [ALdc](https://gitlab.com/simulant/aldc)
* Protofall's [Crayon Savefile](https://github.com/Protofall/Crayon-Savefile/)
* Moop's [DreamHAL](https://github.com/sega-dreamcast/dreamhal)