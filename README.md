# Antiruins
*Dreamcast <-----> Lua <-----> Love2D*

Antiruins is a minimal 2D engine for the SEGA Dreamcast (and Love2D).
It was notably used by Reaperi Cycle and Summoning Signals by Magnes.

## Dependencies
* make
* git
* mkisocd

You can also install some dependencie using `make dependency`

## How to use
*Dreamcast*
1. Add you game files in the game folder
2. `make cdi`
3. Try the .cdi in your gdemu / emulator / burn the cd.

*Love2D*
Make sure that the Love executable is in your path
1. Add you game files in the game folder
2. `make love2d`

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






## Acknowledgement
Antiruins uses:
* Simulant's [GLdc](https://gitlab.com/simulant/GLdc)
* Simulant's [ALdc](https://gitlab.com/simulant/aldc)
* Protofall's [Crayon Savefile](https://github.com/Protofall/Crayon-Savefile/)
* Moop's [DreamHAL](https://github.com/sega-dreamcast/dreamhal)