--------------------------------------------------------------------------------

local unitName = "weirdblock"

--------------------------------------------------------------------------------

unitDef = {
	unitname			= unitName,
	name				= 'Weird Block',
	description			= 'What does it do?',

	--Misc
	buildCostMetal		= 10,
	category			= 'LAND UNARMED STRUCTURE',
	levelGround			= false,
	maxDamage			= 99999,
	maxSlope			= 250,
	maxVelocity			= 0,
	sightDistance		= 0,
	script				= 'empty.lua',
	
	--isFeature			= true,
	
	buildPic	= 'ARMSOLAR.png',
	objectName	= 'walld.s3o',
	--objectName	= 'walla.2.s3o',
	
	--Dimensions
	footprintX			= 5,
	footprintZ			= 5,
	collisionvolumeoffsets	= "0 0 0",
	collisionvolumescales	= "20 20 20",
	collisionvolumetest		= 1,
	collisionvolumetype		= "box",
	yardMap				= 'f',

	featureDefs			= {
		dead  = {
			description		= "Weird Block",
			blocking		= true,
		},
	},
	
	
}

return lowerkeys({ [unitName] = unitDef })
