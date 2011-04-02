--------------------------------------------------------------------------------

local unitName = "door"

--------------------------------------------------------------------------------

unitDef = {
	unitname			= unitName,
	name				= 'Door',
	description			= 'Door',

	--Misc
	buildCostMetal		= 10,
	category			= 'LAND UNARMED STRUCTURE',
	energyMake			= 1,
	levelGround			= false,
	maxDamage			= 99999,
	maxSlope			= 250,
	maxVelocity			= 0,
	sightDistance		= 0,
	script				= 'empty.lua',
	
	buildPic	= 'ARMSOLAR.png',
	objectName	= 'wallc.2.s3o',
	
	--Dimensions
	footprintX			= 8,
	footprintZ			= 8,
	collisionvolumeoffsets	= "0 0 0",
	collisionvolumescales	= "80 80 80",
	collisionvolumetest		= 1,
	collisionvolumetype		= "box",
	yardMap				= 'f',

	featureDefs			= {
		dead  = {
		},
	},
	
	
}

return lowerkeys({ [unitName] = unitDef })
