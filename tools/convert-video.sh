#!/bin/bash

FILE=$1
EXTENSION=${FILE#*.}
FILE_OGV=${FILE%.${EXTENSION}}.ogv
FILE_ROQ=${FILE%.${EXTENSION}}.roq

echo "--- ffmpeg > OGV version ---"
ffmpeg -v 24  -y -i $1 -vf scale=640x480 -b:v 3000k $FILE_OGV

echo "--- ffmpeg > ROQ version ---"
ffmpeg -v 24 -y -i $1 -r 30 -vf scale=512x512 -ar 22050 $FILE_ROQ
