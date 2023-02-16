#! /bin/sh


filename=$1
name="${filename%.*}"

echo name

convert $filename -flip $name_flip.png
$PWD/tools/texconv --in $name_flip.png --format ARGB1555 --out $name.dtex
rm $name_flip.png

echo "$name converted to .dtex"
