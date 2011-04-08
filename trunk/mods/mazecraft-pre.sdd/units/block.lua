--------------------------------------------------------------------------------

local unitName = "block"

--------------------------------------------------------------------------------

unitDef = {
	unitname			= unitName,
	name				= 'Block',
	description			= 'Block',

	--Misc
	buildCostMetal		= 10,
	category			= 'LAND UNARMED STRUCTURE',
	levelGround			= false,
	maxDamage			= 99999,
	maxSlope			= 250,
	maxVelocity			= 0,
	sightDistance		= 0,
	script				= 'empty.lua',
	
	buildPic	= 'ARMSOLAR.png',
	objectName	= 'walla.2.s3o',
	
	--isFeature			= true,
	
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
			description		= "Block",
			blocking		= true,
		},
	},
	
	
}

return lowerkeys({ [unitName] = unitDef })
