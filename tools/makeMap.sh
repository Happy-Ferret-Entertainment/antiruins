#!/bin/sh

MAPNAME=$1


mkdir RAW/map_$MAPNAME

if [ $? -ne 0 ] ; then
  echo "Map : $MAPNAME already exists"
  exit 0
else
  echo "Making new map -> $MAPNAME"
fi

# Copies the template map
cp -r RAW/map_template/map_template.svg RAW/map_$MAPNAME/map_$MAPNAME.svg


# Make the asset folder and make a link to file
echo "Creating linked map -> $MAPNAME"
mkdir asset/map_$MAPNAME
# Forces the link
ln -f RAW/map_$MAPNAME/map_$MAPNAME.svg asset/map_$MAPNAME/map_$MAPNAME.svg

# Add the script_map.lua file
cp -r RAW/map_template/script_template.lua asset/map_$MAPNAME/script_$MAPNAME.lua
