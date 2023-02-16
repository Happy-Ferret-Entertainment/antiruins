#! /bin/sh

FILE=$1
FILE_FLIP="$1_flip.png"
FILE_PATH=${FILE%/*}

echo $FILE_PATH

convert $FILE -flip $FILE_FLIP

$KOS_BASE/utils/texconv/texconv --in $FILE_FLIP --format ARGB1555 --preview $FILE_PATH/sprite_prev.png --out $FILE_PATH/spritesheet.dtex

rm $FILE_FLIP

#rm $FILE_FLIP
