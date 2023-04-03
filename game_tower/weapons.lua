local weapons = {}

--WEAPON_LIST = {crossbow, blood, lighting, catapult, repair}



weapons = {
  autoaim   = {name="autoaim"},
  crossbow  = {name="Crossbow",     speed=0.75, dmg=1, color={1,1,1,1}, ascii= "*"},
  blood     = {name="Blood Magic",  speed=0.5, dmg=0.3, color={1,0,0,1}, ascii= "~"},
  lighting  = {name="Lighting",     speed=1.5, dmg=2, color={1,1,0,1}, ascii="#", type="drop", img="assets/thunder1.png"},
  catapult  = {name="Catapult",     speed=3, dmg=5, color={1,0.5,0.5,1}},
  repair    = {name="Repair Crew",  speed=3, dmg=2, color={0,1,0,1}, type="repair"}
}

-- the crossbow shoots further with each upgrade
weapons.crossbow.upgrades = {
  {cost=5,  dmg=1, range = 1.1},
  {cost=10, dmg=2, range = 1.2},
  {cost=15, dmg=2, range = 1.3},
  {cost=20, dmg=3, range = 1.4},
  {cost=25, dmg=3, range = 1.5},
  {cost=30, dmg=4, range = 1.6},
  {cost=35, dmg=4, range = 1.7},
  {cost=40, dmg=5, range = 1.8},
  {cost=45, dmg=5, range = 1.9},
  {cost=50, dmg=7, range = 2},
} 

--blood upgrades that increase blood dmg
weapons.blood.upgrades = {
  {cost=10, dmg=0.4,  repair=0.3, speed = 0.5},
  {cost=20, dmg=0.45, repair=0.3, speed = 0.44},
  {cost=30, dmg=0.45, repair=0.3, speed = 0.4},
  {cost=40, dmg=0.5,  repair=0.4, speed = 0.35},
  {cost=50, dmg=0.55, repair=0.4, speed = 0.3},
  {cost=60, dmg=0.55, repair=0.4, speed = 0.25},
  {cost=70, dmg=0.6,  repair=0.5, speed = 0.2},
  {cost=80, dmg=0.65, repair=0.5, speed = 0.2},
  {cost=90, dmg=0.65, repair=0.5, speed = 0.15},
  {cost=100, dmg=0.7, repair=0.5, speed = 0.15},
}

-- lightin upgrades that increase the number of taerget hit every 3 levels
weapons.lighting.upgrades = {
  {cost=10, dmg=2, area=3},
  {cost=20, dmg=2.5, area=3},
  {cost=30, dmg=2.5, area=3},
  {cost=40, dmg=3, area=4},
  {cost=50, dmg=3, area=4},
  {cost=60, dmg=3.5, area=4},
  {cost=70, dmg=4, area=5},
  {cost=80, dmg=5, area=5},
  {cost=90, dmg=6, area=5},
  {cost=100, dmg=7, area=6},
}

-- repair upgrade a more expensive and repair your tower more efficiently
weapons.repair.upgrades = {
  {cost=20,   repair=3},
  {cost=35,   repair=4},
  {cost=50,   repair=5},
  {cost=75,   repair=7},
  {cost=100,  repair=10}, 
}





return weapons