local myth_loc = {}

--[[
  Do I want to make a location type first, then all of it's states?
  It seems liks this will be a lot of work.

  Ruined location have no types, they're ruins - they might have a secret?
  Empty location... useful? Empty/Ruins in one go?

  Generative are mix of random NPC, or objetcs?
  Quest probably related to "REAL destination". They have written text.

]]

myth_loc.ruins = {
  img     = {"assets/temple_bw.png","assets/arcade_bw.png", "assets/oasis_bw.png"},
  type    = "",
  text    = {
    {"wrecked, and decrepit !lType", "such a shame.", 
    "this place is in shambles", "how unfortunate", "another devastated !lType",
  },
    {"this !lType fell long time ago", "it's just another vestige of time", 
    "a place better forgotten", "there's no one left here", "whoever used this !lType left long time ago",
  },
  },
  update  = {
    "",
    "",
    --function() switchState
  },
}

myth_loc.generative1 = {
  img     = {"assets/npc2_512_bw.png"},
  type    = "",
  text    = {
    {"> you notice a strange figure in a room", "> you hear sound coming out of the !lType"},
    {"oh, you suprised me.", "can I help you?", "what are you doing here?"},
    {"can't you see I'm busy?", "I have work to do traveller...", "this research really cannot wait."},
    {"you should come back at another time", "I don't have time for this"},
  },
  update  = {
  },
}


myth_loc.generative2 = {
  img     = {"assets/arcade_bw.png", "assets/oasis_bw.png"},
  type    = "",
  text    = {
    {"> a group of people are talking around the fire", "> some merchant trading"},
  },
  update  = {
  },
}

myth_loc.generative3 = {
  type    = "",
  text    = {
    {"> you notice a strange figure in a room", "> you hear sound coming out of the !lType"},
    {"oh, you suprised me.", "can I help you?", "what are you doing here?"},
    {"can't you see I'm busy?", "I have work to do traveller...", "this research really cannot wait."},
    {"you should come back at another time", "I don't have time for this"},
  },
  update  = {
  },
}


return myth_loc