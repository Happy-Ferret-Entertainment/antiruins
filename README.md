# Antiruins

Antiruins is a minimal 2D engine for the SEGA Dreamcast.  
The engine backend is written in C and is precompiled, so you do not need the whole Dreamcast toolchain.  
This greatly reduce compilation and debugging time and lets you focus on the game programming.

The engine currently supports:  
- [x] Texture loading using .dtex and .png files.
- [x] Music streaming using CDDA audio.
- [x] .wav sound effect.
- [x] Loading/saving LUA table to a memory card.
- [x] Displaying images in the VMU.

Currently supported but need better documentation/testing:
- [ ] Sprite atlas and sprite animation.
- [ ] Map loading.
- [ ] Playing DreamRoQ video.

## Documentation
You can check the documentation in the [wiki](https://gitlab.com/lerabot/antiruins/-/wikis/home)

## Dependencies - REQUIRED!
Install the engine dependencies using `make dependency`
* make (you will need to install this yourself)
* git
* mkdcdisc
* lxdream-nitro
* texconv

## Games
A game folder is structured like this :

```
  game_tower
  > assets
  > game.lua
```
You can create additional .lua files and folders in this directory as you wish.  
The engine will look in this directory when you use the `require` or `findFile` function  

To change which game the engine loads, please update `config.lua`.  
```
games = {
  {dir="game_example",        name="Example"},
  {dir="game_tower",          name="Tower"},
}
defaultGame = "Tower",

```

## How to build / test your project
**.cdi**  
`make cdi` then burn to cd or test in your favorite emulator.

**Emulator (lxdream-nitro)**
`make cdi emulator` will build the cdi then launch it in lxdream-nitro

**Serial Adapter**  
Edit the makefile to match your serial port and `make serial`.

**Broadband Adapter**  
Edit the makefile to match your dreamcast IP address and `make bba`.  

## Acknowledgement
Antiruins uses:
* Protofall's [Crayon Savefile](https://github.com/Protofall/Crayon-Savefile/)
* Moop's [DreamHAL](https://github.com/sega-dreamcast/dreamhal)
* Multimedia Mike / Ian MIcheals / BBHoodsta [DreamRoQ](https://github.com/Dreamcast-Projects/dreamroq)