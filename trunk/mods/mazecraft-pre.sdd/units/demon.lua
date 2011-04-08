--------------------------------------------------------------------------------

local unitName = "demon"

--------------------------------------------------------------------------------

local unitDef = {
	
	unitName		= unitName,
	name			= "Demon",
	description		= "Fireballs",

	--Movement
	acceleration	= 1.8,
	brakeRate		= 1.5,
	canMove			= true,
	maxVelocity		= 1.8,
	movementClass	= "KBOT1",
	turnRate		= 1500,

	--Misc
	buildCostMetal	= 100,
	category		= "LAND",
	maxDamage		= 255,
	maxSlope		= 14,
	noChaseCategory	= "AIR",
	upright			= true,
	
	sightDistance	= 400,
	
	--Dimensions
	collisionVolumeOffsets	= "0 0 0",
	collisionVolumeScales	= "15 30 10",
	collisionVolumeType 	= "CylY",
	footprintX		= 1,
	footprintZ		= 1,

	--Death
	--explodeAs		= "SMOKE_EXPLOSION",
	--selfDestructAs	= "SMOKE_EXPLOSION",

	sfxtypes = {
		explosiongenerators = {
			"custom:NONE",
			--"custom:blood_spray",
		},
	},
	
	weapons = {
		[1]  = {def = "FIREBALL", mainDir = "0 0 1", maxAngleDif = 200},
	},

	weaponDefs = {
	  FIREBALL = {
			name				= "Fireball",
			weapontype			= "MissileLauncher",
			turret				= true,
			
			areaofeffect		= 30,
			damage				= {default = 50},
			explosiongenerator	= "custom:fireball_d",
			edgeeffectiveness	= .7,
			flighttime			= 5,
			proximitypriority	= -1.5,
			range				= 150,
			reloadtime			= 3,
			startvelocity		= 300,
			tolerance			= 1000,
			tracks				= false,
			trajectoryheight	= .2,
			turnrate			= 0, --between 0 and 64000
			weaponacceleration	= 0,
			weaponvelocity		= 300,
			
			--Visuals
			cegtag				= "BANISHERTRAIL2",
			model				= "",
			
		},
	},

	
	featureDefs = {
		dead = {
		},
	},

}


--------------------------------------------------------------------------------

return lowerkeys({ [unitName] = unitDef })

--------------------------------------------------------------------------------
