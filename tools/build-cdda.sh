#! /bin/sh

PROJECT_NAME=Summoning-Signals_DEMOCDDA
TARGET=main.elf

RELEASE_DIR=release
BUILD_DIR=$RELEASE_DIR/dreamcast

find asset/sounds/bgm -type f -iname 'menu.mp3' -exec bash -c '

FILE={}
FILE_PATH=${FILE%/*}
FILE_CDDA=${FILE/.mp3/.raw}
DEST_CDDA=${FILE_PATH/bgm/cdda}


ffmpeg -y -i ${FILE} -ar 44100 -ac 2 -f s16le ${FILE_CDDA}
mv ${FILE_CDDA} ${DEST_CDDA}
echo "$FILE converted to RAW .wav for CDDA"
' \;

LBASIZE=$(wine $KOS_BASE/utils/mds4dc/lbacalc.exe asset/sounds/cdda/*.raw)
echo "LBA size = $LBASIZE"

# Build the ISO
cd $BUILD_DIR
sh-elf-objcopy -R .stack -O binary $TARGET output.bin
$KOS_BASE/utils/scramble/scramble output.bin 1ST_READ.BIN
mkisofs -C 0,$LBASIZE -V $PROJECT_NAME -G IP.BIN -r -J -l $EXCLUDE_DIR -o ../$PROJECT_NAME.iso .


# Make the MDS Combo
wine $KOS_BASE/utils/mds4dc/mds4dc.exe -c ../$PROJECT_NAME.mds ../$PROJECT_NAME.iso ../cdda/track01.raw > ../cdda.log

cd ..
cp -f $PROJECT_NAME.mds /media/magnes/GDEMU_BB/34/disc.mds
cp -f $PROJECT_NAME.mdf /media/magnes/GDEMU_BB/34/disc.mdf
