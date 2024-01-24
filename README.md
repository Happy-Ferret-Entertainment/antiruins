# Antiruins

Antiruins is a minimal 2D engine for the SEGA Dreamcast that uses Lua as its only programming language.
The engine backend is written in C and is precompiled, so you do not need the whole Dreamcast toolchain.  
This greatly reduce compilation and debugging time and lets you focus on the game programming.

The engine currently supports:  
- [x] Texture loading using .dtex and .png files.
- [x] Music streaming using CDDA audio.
- [x] .wav sound effect.
- [x] Loading/saving LUA table to a memory card.
- [x] Displaying images in the VMU.
- [x] Playing DreamRoQ video.

Currently supported but need better documentation/testing:
- [ ] Sprite atlas and sprite animation.
- [ ] Map loading.

## Documentation
You can read the documentation in the [wiki](https://gitlab.com/lerabot/antiruins/-/wikis/home)

## Quick start

1. Install and build the dependencies
```
git clone https://gitlab.com/lerabot/antiruins.git
cd antiruins
make dependency
```

2. Test a .CDI in LXdream-nitro
`make cdi emulator`

3. Check the examples in the *game_example* folder.

4. Create a new project using `make new NAME=rpg`. This will create a new game folder (game_sonic) and with an empty game template.
Make sure that you add your game to the *config.lua* file.

```
games = {
  {dir="game_example",        name="Example"},
  {dir="game_rpg",            name="Dark Moon"},
}
defaultGame = "Dark Moon",
```

## How to build / test your project
**.cdi**  
`make cdi` then burn to cd or test in your favorite emulator.

**Emulator (LXdream-nitro)**
`make cdi emulator` will build the CDI and launch it in LXdream-nitro

**Serial Adapter**  
Edit the makefile to match your serial port and `make serial`.

**Broadband Adapter**  
Edit the makefile to match your dreamcast IP address and `make bba`.  

## Acknowledgement
Antiruins uses:
* Protofall's [Crayon Savefile](https://github.com/Protofall/Crayon-Savefile/)
* Moop's [DreamHAL](https://github.com/sega-dreamcast/dreamhal)
* Multimedia Mike / Ian MIcheals / BBHoodsta [DreamRoQ](https://github.com/Dreamcast-Projects/dreamroq)
* Simulant [LXdream-nitro](https://gitlab.com/simulant/community/lxdream-nitro)