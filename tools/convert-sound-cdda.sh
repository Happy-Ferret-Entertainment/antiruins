#! /bin/sh

find asset/sounds/bgm -type f -iname 'menu.mp3' -exec bash -c '

FILE={}
FILE_PATH=${FILE%/*}
FILE_CDDA=${FILE/.mp3/.raw}
DEST_CDDA=${FILE_PATH/bgm/cdda}


ffmpeg -y -i ${FILE} -ar 44100 -ac 2 -f s16le ${FILE_CDDA}

mv ${FILE_CDDA} ${DEST_CDDA}

echo ${DEST_CDDA}

echo "$FILE converted to  raw .wav for CDDA"
' \;
