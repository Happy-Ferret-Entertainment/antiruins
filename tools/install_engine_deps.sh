#!/bin/sh

# require cmake
echo " Installing cmake"
sudo apt-get install cmake

## GLdc #####################################

# Deleting old libGl
echo "Deleting old libGL library"
rm -rf $KOS_BASE/../kos-port/libGL

cd $KOS_BASE/addons

# Cloning  + Entering Directoy
git clone https://gitlab.com/simulant/GLdc.git
cd GLdc

# Building GLdc
mkdir dcbuild
cd dcbuild
cmake -DCMAKE_TOOLCHAIN_FILE=../toolchains/Dreamcast.cmake -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" ..
make

# Adding link to /addons/include 
ln -sf $PWD/libGLdc.a $KOS_BASE/addons/lib/dreamcast/libGLdc.a
ln -sf $PWD/../include/GL $KOS_BASE/addons/include/GL
