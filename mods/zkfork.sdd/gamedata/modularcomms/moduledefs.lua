--------------------------------------------------------------------------------
-- system functions
--------------------------------------------------------------------------------

VFS.Include("gamedata/modularcomms/functions.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

weapons = {}

local weaponsList = VFS.DirList("gamedata/modularcomms/weapons", "*.lua") or {}
for i=1,#weaponsList do
	local name, array = VFS.Include(weaponsList[i])
	weapons[name] = lowerkeys(array)
end

-- name is needed for widget; description is currently unused
upgrades = {
	-- weapons
	-- it is important that they are prefixed with "commweapon_" in order to get the special handling!
	-- it is important that they are prefixed with "commweapon_" in order to get the special handling!
	
	commweapon_peashooter = {
		name = "Peashooter",
		description = "Basic self-defense weapon",
	},	
	
	commweapon_beamlaser = {
		name = "Beam Laser",
		description = "An effective short-range cutting tool",
	},
--	commweapon_flamethrower = {
--		name = "Flamethrower",
--		description = "Perfect for well-done barbecues",
--	},
	commweapon_heavymachinegun = {
		name = "Heavy Machine Gun",
		description = "Close-in weapon with AoE",
	},
	commweapon_heatray = {
		name = "Heat Ray",
		description = "Rapidly melts anything at short range; loses damage over distance",
	},
	commweapon_gaussrifle = {
		name = "Gauss Rifle",
		description = "Precise armor-piercing weapon",
	},
	commweapon_partillery = {
		name = "Plasma Artillery",
		description = "Long-range artillery gun",
	},
	commweapon_riotcannon = {
		name = "Riot Cannon",
		description = "The weapon of choice for crowd control",
	},
	commweapon_rocketlauncher = {
		name = "Rocket Launcher",
		description = "Medium-range low-velocity hitter",
		func = function(unitDef)
				unitDef.customparams.nofps = "1"
			end,	
	},
	commweapon_shotgun = {
		name = "Shotgun",
		description = "Can hammer a single large target or shred many small ones",
	},
	commweapon_slowbeam = {
		name = "Slowing Beam",
		description = "Slows an enemy's movement and firing rate; non-lethal",
	},
	
	-- dguns
	commweapon_concussion = {
		name = "Concussion Shot",
		description = "Extended range weapon with AoE and impulse",
	},
	commweapon_clusterbomb = {
		name = "Cluster Bomb",
		description = "Hammers multiple units in a wide line",
	},
	commweapon_disintegrator = {
		name = "Disintegrator Gun",
		description = "Short-range weapon that vaporizes anything in its path",
	},
	commweapon_disruptorbomb = {
		name = "Disruptor Bomb",
		description = "Damages and slows units in a large area",
		func = function(unitDef)
				unitDef.customparams.nofps = "1"
			end,	
	},
	commweapon_napalmgrenade = {
		name = "Hellfire Grenade",
		description = "Sets a moderate area ablaze",
		func = function(unitDef)
				unitDef.customparams.nofps = "1"
			end,	
	},		
	commweapon_sunburst = {
		name = "Sunburst Cannon",
		description = "Ruins a single target's day with a medium-range high-energy burst",
	},
	
	-- conversion kits
	conversion_disruptor = {
		name = "Disruptor Beam",
		description = "Slow Beam: +33% reload time, +250 real damage",
		func = function(unitDef)
				ReplaceWeapon(unitDef, "commweapon_slowbeam", "commweapon_disruptor")
				
			end,	
	},
	conversion_shockrifle = {
		name = "Shock Rifle",
		description = "Gauss Rifle: Convert to a long-range sniper rifle",
		func = function(unitDef)
				ReplaceWeapon(unitDef, "commweapon_gaussrifle", "commweapon_shockrifle")
			end,	
	},
	conversion_partillery = {
		name = "Plasma Artillery",
		description = "Riot Cannon: Convert to a medium artillery gun",
		func = function(unitDef)
				ReplaceWeapon(unitDef, "commweapon_riotcannon", "commweapon_partillery")
			end,	
	},		
	
	-- weapon mods
	weaponmod_autoflechette = {
		name = "Autoflechette Mod",
		description = "Shotgun: -25% projectiles, -50% reload time",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if i == "commweapon_shotgun" then
						v.customparams.misceffect = nil
						v.projectiles = 9
						v.reloadtime = v.reloadtime * 0.5
						v.customparams.basereload = v.reloadtime
						--break
					end
				end
			end,	
	},
	weaponmod_disruptor_ammo = {
		name = "Disruptor Ammo",
		description = "Shotgun/Gauss Rifle/Heavy Machine Gun: +40% slow damage",
		func = function(unitDef)
				local permitted = {
					commweapon_shotgun = true,
					commweapon_gaussrifle = true,
					commweapon_heavymachinegun = true,
				}
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					local wcp = v.customparams
					if permitted[i] then
						wcp.timeslow_damagefactor = "0.4"
						v.rgbcolor = [[0.9 0.1 0.9]]
						if i == "commweapon_shotgun" or i == "commweapon_heavymachinegun" then
							v.explosiongenerator = [[custom:BEAMWEAPON_HIT_PURPLE]]
						elseif i == "commweapon_gaussrifle" then
							v.explosiongenerator = [[custom:GAUSS_HIT_M_PURPLE]]
						end
					end
				end
			end,	
	},
	weaponmod_high_frequency_beam = {
		name = "High Frequency Beam",
		description = "Beam Laser/Slow Beam/Disruptor Beam: +15% damage and range",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				local permitted = {
					commweapon_beamlaser = true,
					commweapon_slowbeam = true,
					commweapon_disruptor = true,
				}
				for i,v in pairs(weapons) do
					if permitted[i] then
						v.range = v.range * 1.15
						v.customparams.baserange = v.range
						for armorname, dmg in pairs(v.damage) do
							v.damage[armorname] = dmg * 1.15
							v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
						end
					end
				end
			end,		
	},
	weaponmod_high_caliber_barrel = {
		name = "High Caliber Barrel",
		description = "Shotgun/Riot Cannon/Gauss Rifle/Plasma Artillery: +150% damage, +100% reload time",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				local permitted = {
					commweapon_shotgun = true,
					commweapon_gaussrifle = true,
					commweapon_partillery = true,
					commweapon_riotcannon = true,
				}
				for i,v in pairs(weapons) do
					if permitted[i] then
						v.reloadtime = v.reloadtime * 2
						v.customparams.basereload = v.reloadtime
						for armorname, dmg in pairs(v.damage) do
							v.damage[armorname] = dmg * 2.5
							v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
						end
					end
				end
			end,		
	},
	weaponmod_standoff_rocket = {
		name = "Standoff Rocket",
		description = "Rocket Launcher: +50% range, +20% damage, +50% reload time",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if i == "commweapon_rocketlauncher" then
						v.range = v.range * 1.5
						v.customparams.baserange = v.range
						v.reloadtime = v.reloadtime * 1.5
						v.customparams.basereload = v.reloadtime
						for armorname, dmg in pairs(v.damage) do
							v.damage[armorname] = dmg * 1.2
							v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
						end						
						v.model = [[wep_m_dragonsfang.s3o]]
						v.soundhit = [[explosion/ex_med4]]
						v.soundhitvolume = 8
						v.soundstart = [[weapon/missile/missile2_fire_bass]]
						v.soundstartvolume = 7					
						--break
					end
				end
			end,	
	},
	weaponmod_napalm_warhead = {
		name = "Napalm Warhead",
		description = "Riot Cannon/Plasma Artillery/Rocket Launcher: Reduced direct damage, sets target on fire",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				local permitted = {
					commweapon_partillery = true,
					commweapon_rocketlauncher = true,
					commweapon_riotcannon = true,
				}
				for i,v in pairs(weapons) do
					if permitted[i] then
						if not (i == "commweapon_rocketlauncher") then	-- -25% damage
							for armorname, dmg in pairs(v.damage) do
								v.damage[armorname] = dmg * 0.75
								v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
								v.customparams.burntime = "360"
							end
							v.rgbcolor = [[1 0.3 0.1]]
						else	-- -33% damage, 128 AoE
							for armorname, dmg in pairs(v.damage) do
								v.damage[armorname] = dmg * 2/3
								v.customparams["basedamage_"..armorname] = tostring(v.damage[armorname])
								v.customparams.burntime = "450"
							end
							v.areaofeffect = 128
						end
						v.explosiongenerator = [[custom:NAPALM_Expl]]
						v.customparams.setunitsonfire = "1"
						v.customparams.burnchance = "1"
						v.soundhit = [[weapon/burn_mixed]]
					end
				end
			end,		
	},
	weaponmod_plasma_containment = {
		name = "Plasma Containment Field",
		description = "Heat Ray: +50% range; Heavy Machine Gun/Riot Cannon: +25% range",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if i == "commweapon_heatray" then
						v.range = v.range * 1.5
						v.customparams.baserange = tostring(v.range)
					elseif i == "commweapon_riotcannon" or i == "commweapon_heavymachinegun" then
						v.range = v.range * 1.25
						v.customparams.baserange = tostring(v.range)
					end
				end
			end,	
	},	
	
	-- modules
	module_ablative_armor = {
		name = "Ablative Armor Plates",
		description = "Adds 600 HP",
		func = function(unitDef)
				unitDef.maxdamage = unitDef.maxdamage + 600
			end,
	},
	module_adv_targeting = {
		name = "Advanced Targeting System",
		description = "Extends range of all weapons by 10%",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					if v.range then v.range = v.range + (v.customparams.baserange or v.range) * 0.1 end
				end
			end,	
	},
	module_adv_nano = {
		name = "CarRepairer's Nanolathe",
		description = "Adds +6 metal/s build speed and +60 build distance",
		func = function(unitDef)
				if unitDef.workertime then unitDef.workertime = unitDef.workertime + 6 end
				if unitDef.builddistance then unitDef.builddistance = unitDef.builddistance + 60 end
			end,
	},
	module_autorepair = {
		name = "Autorepair System",
		description = "Self-repairs 20 HP/s",
		func = function(unitDef)
				unitDef.autoheal = (unitDef.autoheal or 0) + 20
			end,
	},
	module_dmg_booster = {
		name = "Damage Booster",
		description = "Increases damage of all weapons by 10%",
		func = function(unitDef)
				local weapons = unitDef.weapondefs or {}
				for i,v in pairs(weapons) do
					for armorname, dmg in pairs(v.damage) do
						v.damage[armorname] = dmg + (v.customparams["basedamage_"..armorname] or dmg) * 0.1
					end
				end
			end,	
	},
	module_energy_cell = {
		name = "Energy Cell",
		description = "Compact fuel cells that produce +6 energy",
		func = function(unitDef)
				unitDef.energymake = (unitDef.energymake or 0) + 6
			end,
	},
	module_fieldradar = {
		name = "Field Radar Module",
		description = "Basic radar system with 1800 range",
		func = function(unitDef)
				unitDef.radardistance = (unitDef.radardistance or 0)
				if unitDef.radardistance < 1800 then unitDef.radardistance = 1800 end
			end,
	},
	module_heavy_armor = {
		name = "High Density Plating",
		description = "Adds 1600 HP, slows comm by +10%",
		func = function(unitDef, attributeMods)
				unitDef.maxdamage = unitDef.maxdamage + 1600
				attributeMods.speed = attributeMods.speed - 0.1
			end,
	},
	module_high_power_servos = {
		name = "High Power Servos",
		description = "More powerful leg actuators increase speed by 10% of base",
		func = function(unitDef, attributeMods)
				attributeMods.speed = attributeMods.speed + 0.1
			end,
	},
	module_personal_cloak = {
		name = "Personal Cloak",
		description = "Cloaks the comm",
		func = function(unitDef)
				unitDef.cloakcost = unitDef.cloakcost or 10
				if unitDef.cloakcost > 10 then unitDef.cloakcost = 10 end
				unitDef.cloakcostmoving = unitDef.cloakcostmoving or 20
				if unitDef.cloakcostmoving > 20 then unitDef.cloakcostmoving = 20 end
			end,
	},
	module_resurrect = {
		name = "Lazarus Device",
		description = "Enables resurrection of wrecks",
		func = function(unitDef)
				unitDef.canresurrect = true
			end,
	},
	module_cloak_field = {
		name = "Cloaking Field",
		description = "Cloaks all friendly units within 350 m",
		func = function(unitDef)
				unitDef.onoffable = true
				unitDef.radarDistanceJam = (unitDef.radarDistanceJam and unitDef.radarDistanceJam > 350 and unitDef.radarDistanceJam) or 350
				unitDef.customparams.cloakshield_preset = "module_cloakfield"
			end,
	},
	module_repair_field = {
		name = "Repair Field",
		description = "Passively repairs all friendly units within 450 m",
		func = function(unitDef)
				unitDef.customparams.repairaura_preset = "module_repairfield"
			end,
	},
	module_jammer = {
		name = "Radar Jammer",
		description = "Masks radar signals of all units within 500 m",
		func = function(unitDef)
				unitDef.radardistancejam = 500
				unitDef.activatewhenbuilt = true
				unitDef.onoffable = true
			end,
	},
	module_areashield = {
		name = "Area Shield",
		description = "Bubble shield that protects surrounding units within 300 m",
		func = function(unitDef)
				ApplyWeapon(unitDef, "commweapon_areashield", 2)
				unitDef.activatewhenbuilt = true
				unitDef.onoffable = true
			end,
	},
	
	-- deprecated
	module_improved_optics = {
		name = "Improved Optics",
		description = "Increases sight distance by 100 m",
		func = function(unitDef)
				unitDef.sightdistance = unitDef.sightdistance + 100
			end,
	},
}

