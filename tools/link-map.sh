#!/bin/sh


echo "--- Linking Maps ---"

find RAW/ -type f -iname 'map_*.svg' -exec bash -c '

raw=$(pwd)/"{}"
path=${raw/RAW/asset}

ln -f $raw $path 2> /dev/null

' \;

echo "--- Linking Spritesheets --- "

find RAW/ -type f -iname 'spritesheet*' -exec bash -c '

raw=$(pwd)/"{}"
path=${raw/RAW/asset}

ln -f $raw $path 2> /dev/null


' \;
