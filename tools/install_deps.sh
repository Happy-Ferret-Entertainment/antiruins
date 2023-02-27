#!/bin/sh

base_dir=$PWD

## Install Meson
echo "Install Meson & Ninja"
sudo apt-get install meson libisofs*

##### Install mkdcdisc (required for making the disc image)
if [ -d "$PWD/tools/mkdcdisc"]; then 
    echo "mkdcdisk is installed."
else
    echo "This step requires meson and ninja" 
    git clone https://gitlab.com/simulant/mkdcdisc.git tools/mkdcdisc
    cd tools/mkdcdisc && meson setup build 
    cd build && ninja
    cp mkdcdisc $base_dir/tools
    cd $base_dir && ./tools/mkdcdisc/build/mkdcdisc	
fi
	