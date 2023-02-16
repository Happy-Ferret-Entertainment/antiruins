#!/bin/sh


# DreamHAL
cd $KOS_BASE/addons &&
git pull https://github.com/Moopthehedgehog/DreamHAL.git


# GLdc
git pull https://gitlab.com/simulant/GLdc.git
cd GLdc
#make defaultall
#make create_kos_link

#cdi4dc
cd $KOS_BASE/utils
git pull https://github.com/Kazade/img4dc.git
