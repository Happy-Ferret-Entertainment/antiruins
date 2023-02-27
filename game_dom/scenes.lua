local scenes = {}

scenes.intro_s = {
    bgImgFile = "assets/hub_c4_south.png",
    
    destination = {
        left    = "intro_e",
        right   = "intro_w",
    },
    

    objects = {
        map = {
            name        = "Curious Map",
            position    = {24, 100},
            image       = "assets/curiousMap.png",
            onClick     = function() end
        }
    }
}

scenes.intro_w = {
    bgImgFile = "assets/hub_c4_west.png",
    
    destination = {
        left    = "intro_s",
        right   = "intro_n",
    },
    

    objects = {
        map = {
            name        = "Curious Map",
            position    = {24, 100},
            image       = "assets/curiousMap.png",
            onClick     = function() end
        }
    }
}

scenes.intro_e = {
    bgImgFile = "assets/hub_c4_east.png",
    
    destination = {
        left    = "intro_n",
        right   = "intro_s",
    },
    

    objects = {
        map = {
            name        = "Curious Map",
            position    = {24, 100},
            image       = "assets/curiousMap.png",
            onClick     = function() end
        }
    }
}

scenes.intro_n = {
    bgImgFile = "assets/hub_c4_north.png",
    
    destination = {
        left    = "intro_w",
        right   = "intro_e",
    },
    

    objects = {
        map = {
            name        = "Curious Map",
            position    = {24, 100},
            image       = "assets/curiousMap.png",
            onClick     = function() end
        }
    }
}

return scenes