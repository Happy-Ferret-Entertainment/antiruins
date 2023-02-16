#!/bin/sh

#https://linuxize.com/post/how-to-rename-files-in-linux/

#for f in sounds/*.{wav,WAV}; do ffmpeg -i "$f" -c:a libvorbis -q:a 4 "sounds/${f%.*}.ogg"; done
#'ffmpeg -i "$0" -c:a libvorbis -q:a 4 "${f/%wav/ogg}"' '{}'

#find asset/sounds/bgm -type f -iname '._*.wav'  -exec bash -c 'rm "{}"' \;

#find asset/sounds/bgm -type f -name '*.wav'     -exec sh -c '

#  f="{}"; ffmpeg -n -y -i "{}" -c:a libvorbis -q:a 4 "{}.ogg"

#  ' \;


#find asset/sounds/bgm -name '*.wav.ogg' -print0 | xargs -0 -n1 bash -c 'mv "$0" "${0/wav.ogg/ogg}"'
#find asset/sounds/bgm -type f -iname '*.wav' -exec bash -c 'rm "{}"' \;

#! /bin/sh

find asset/sounds -type f -iname '*.ogg' -exec bash -c '

FILE={}
FILE_MP3=${FILE/.ogg/.mp3}
FILE_PATH=${FILE%/*}

ffmpeg -y -i ${FILE} -codec:a libmp3lame -b:a 192k -r:a 44100 ${FILE_MP3}
#rm ${FILE_PATH}/_flip.png

echo "$FILE converted to .mp3"
' \;
