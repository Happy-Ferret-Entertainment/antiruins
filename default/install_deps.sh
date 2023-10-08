#!/bin/sh

base_dir=$PWD

cp default/convertToDTEX.sh $base_dir/tools/


##### Install mkdcdisc (required for making the disc image)
if [ -d "$base_dir/tools/mkdcdisc"]; then 
    echo "mkdcdisk is installed."
else
    sudo apt-get install meson libisofs*
    git clone https://gitlab.com/simulant/mkdcdisc.git tools/mkdcdisc_source
    cd tools/mkdcdisc_source && meson setup build 
    cd build && ninja
    cp mkdcdisc $base_dir/tools/
fi
	
cd $base_dir

#### Install texconv
if [ -d "$base_dir/tools/texconv"]; then 
    echo "texconv is installed."
else
    sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
    git clone https://github.com/tvspelsfreak/texconv tools/texconv_source
    cd tools/texconv_source && qmake && make
    cp texconv $base_dir/tools/
fi