#!/bin/sh


vlc v4l2:///dev/video1:v4l2-standard= :v4l2-dev=/dev/video1 :v4l2-vbidev= :v4l2-chroma=VYUY :v4l2-input=0 :v4l2-caching=0 :v4l2-audio-input=-1 :v4l2-width=640 :v4l2-height=480 :v4l2-aspect-ratio=4\:3 :v4l2-fps=60


#vlc v4l2://dev/video1:v4l2-vbidev= :v4l2-chroma=VYUY :v4l2-input=0 :v4l2-audio-input=-1 :v4l2-width=640 :v4l2-height=480 :v4l2-aspect-ratio=4\:3 :v4l2-fps=60
