local weapons = {}

--WEAPON_LIST = {crossbow, blood, lighting, catapult, repair}



weapons = {
  autoaim   = {name="autoaim"},
  crossbow  = {name="Crossbow",     speed=0.7, dmg=1,    color={1,1,1,1}, ascii= "*"},
  blood     = {name="Blood Magic",  speed=0.5,  dmg=0.3,  color={1,0,0,1}, ascii= "~"},
  lighting  = {name="Lighting",     speed=1.5,  dmg=2,    color={1,1,0,1}, ascii="#", type="drop", img="assets/thunder1.png"},
  catapult  = {name="Catapult",     speed=3,    dmg=5,    color={1,0.5,0.5,1}},
  repair    = {name="Repair Crew",  speed=2,    dmg=2,    color={0,1,0,1}, type="repair"}
}

weapons.crossbow.icon  = "assets/icon_crossbow_sm.png"
weapons.blood.icon     = "assets/blood.png"
weapons.repair.icon    = "assets/icon_repair_sm.png"

-- firing speed
weapons.crossbow.fSpeed = 3
weapons.blood.fSpeed = 4

-- the crossbow shoots further with each upgrade
weapons.crossbow.upgrades = {
  {cost=5,    dmg=1,   range = 1.10, speed = 0.7},
  {cost=35,   dmg=1.5, range = 1.15, speed = 0.55},
  {cost=70,   dmg=2,   range = 1.20, speed = 0.40}, 
  {cost=90,   dmg=2.5, range = 1.25, speed = 0.25},
  {cost=150,  dmg=3,   range = 1.30, speed = 0.10},
} 

--blood upgrades that increase blood dmg
weapons.blood.upgrades = {
  {cost=10, dmg=0.4,  repair=0.3, speed = 0.5},
  {cost=30, dmg=0.7,  repair=0.7, speed = 0.4},
  {cost=50, dmg=1.0,  repair=1.0, speed = 0.3},
  {cost=70, dmg=1.5,  repair=1.5, speed = 0.2},
  {cost=100, dmg=2,   repair=2,   speed = 0.15},
}

-- lightin upgrades that increase the number of taerget hit every 3 levels
weapons.lighting.upgrades = {
  {cost=10, dmg=2, area=3},
  {cost=30, dmg=3, area=4},
  {cost=50, dmg=4, area=5},
  {cost=70, dmg=6, area=5},
  {cost=100, dmg=7, area=6},
}

-- repair upgrade a more expensive and repair your tower more efficiently
weapons.repair.upgrades = {
  {cost=20,   repair=3, hpBonus=10},
  {cost=35,   repair=4, hpBonus=15},
  {cost=50,   repair=5, hpBonus=20},
  {cost=75,   repair=7, hpBonus=25},
  {cost=100,  repair=10, hpBonus=30}, 
}

weapons.mods = {
  -- crossbow peirce target
  { weapon="Crossbow", tag="pierce",
    name="Piercing bolts",
    desc="Crossbolt can pierce through multiple targets"
  },
  -- crossbow stun target
  { weapon="Crossbow", tag="stun", value=1,
    name="Stunning bolts",
    desc="Crossbolt can stun target for 1 second"
  },
  -- tower can repair while upgrading
  { weapon="Repair Crew",   tag="always",
    name="Hard workers",
    desc="Tower can repair while upgrading"
  },
    -- tower can repair while upgrading
  { weapon="Repair Crew",   tag="repairFrenzy",
    name="Repair Frenzy",
    desc="Tower repair twice as fast in critical moments"
  },
  -- tower has more defense
  { weapon=nil,        tag="armor", value=0.1,
    name="Reinforced armor",
    desc="Tower has more defense"
  },
  -- faster upgrades
  { weapon=nil,        tag="fastUpgrade", value=0.25,
    name="Fast workers",
    desc="Tower upgrades faster"
  },
}

return weapons