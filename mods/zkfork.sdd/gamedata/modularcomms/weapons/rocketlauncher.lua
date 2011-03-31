local name = "commweapon_rocketlauncher"
local weaponDef = { 
	name                    = [[Rocket]],
	areaOfEffect            = 48,
	cegTag                  = [[missiletrailred]],
	craterBoost             = 0,
	craterMult              = 0,

	customParams			= {
		slot = [[5]],
		muzzleEffect = [[custom:STORMMUZZLE]],
		rangeperlevel = [[25]],
		damageperlevel = [[17.5]],
	},
	
	damage                  = {
		default = 350,
		planes  = 350,
		subs    = 17.5,
	},
	
	fireStarter             = 180,
	flightTime              = 3,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 2,
	lineOfSight             = true,
	model                   = [[wep_m_hailstorm.s3o]],
	noSelfDamage            = true,
	predictBoost            = 1,
	range                   = 430,
	reloadtime              = 3.5,
	smokedelay              = [[.1]],
	smokeTrail              = true,
	soundHit                = [[weapon/missile/sabot_hit]],
	soundHitVolume          = 8,
	soundStart              = [[weapon/missile/sabot_fire]],
	soundStartVolume        = 7,
	startsmoke              = [[1]],
	startVelocity           = 200,
	texture2                = [[darksmoketrail]],
	tracks                  = false,
	trajectoryHeight        = 0.05,
	turret                  = true,
	weaponAcceleration      = 100,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 250,
}

return name, weaponDef
