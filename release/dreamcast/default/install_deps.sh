#!/bin/sh

base_dir=$PWD

cp default/convertToDTEX.sh $base_dir/tools/

## Install mkdcdisc (required for making the disc image)
if [ -f "$base_dir/tools/mkdcdisc" ]; then 
    echo "mkdcdisk is installed."
else
    sudo apt-get install meson libisofs*
    git clone https://gitlab.com/simulant/mkdcdisc.git tools/mkdcdisc_source
    cd tools/mkdcdisc_source && meson setup build 
    cd build && ninja
    cp mkdcdisc $base_dir/tools/
fi
	
cd $base_dir

## Install texconv
if [ -f "$base_dir/tools/texconv" ]; then 
    echo "texconv is installed."
else
    sudo apt-get install qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
    git clone https://github.com/tvspelsfreak/texconv tools/texconv_source
    cd tools/texconv_source && qmake && make
    cp texconv $base_dir/tools/
fi

cd $base_dir

## Install lxdream-nitro
if [ -f "$base_dir/tools/lxdream-nitro" ]; then 
    echo "lxdream-nitro is installed."
else
    git clone https://gitlab.com/simulant/community/lxdream-nitro.git tools/lxdream-nitro_source
    cd tools/lxdream-nitro_source && meson setup builddir && meson compile -C builddir
    cp builddir/lxdream-nitro $base_dir/tools/
fi