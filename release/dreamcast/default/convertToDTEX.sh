#! /bin/sh

# format types
#Texture formats:
#  RGB565  ARGB4444  YUV422  ARGB1555  PAL8BPP  BUMPMAP  PAL4BPP

folder=$1
format=$2
name="${filename%.*}"

echo "Usage: ./convertToDTEX.sh <folder/file> <format>"
echo "Texture formats: RGB565  ARGB4444  YUV422  ARGB1555  PAL8BPP  BUMPMAP  PAL4BPP"

if [ -d "$folder" ]; then
  echo "Converting folder $folder to .dtex files."
  for f in $folder/*.png; do
    name="${f%.*}"
    $PWD/tools/texconv --in $f --out $name.dtex --format $format
  done
else
  echo "Converting $folder file to .dtex file."
  name="${folder%.*}"
  $PWD/tools/texconv --in $name.png --out $name.dtex --preview preview.png --format $format
fi
