#! /bin/sh

find asset/ -type f -iname 'spritesheet.png' -exec bash -c '

FILE={}
FILE_PATH=${FILE%/*}

convert $FILE -flip ${FILE_PATH}/_flip.png
$PWD/tools/texconv --in ${FILE_PATH}/_flip.png --format ARGB1555 --out ${FILE_PATH}/spritesheet.dtex

rm ${FILE_PATH}/_flip.png

echo "$FILE converted to .dtex"
' \;
