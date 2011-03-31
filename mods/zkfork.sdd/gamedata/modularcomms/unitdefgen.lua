--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    unitdefgen.lua
--  brief:   procedural generation of unitdefs for modular comms
--  author:  KingRaptor (L.J. Lim)
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Spring.Utilities = Spring.Utilities or {}
VFS.Include("LuaRules/Utilities/base64.lua")
--------------------------------------------------------------------------------
--	HOW IT WORKS: 
--	First, it makes unitdefs as specified by the decoded modoption string, one for each unique comm type.
--		The unitdefs are named: <name>
--	It then modifies each unitdef based on the upgrades selected for that comm type.
--	Upgrade types are defined in gamedata/modularcomms/moduledefs.lua.
--
--	Comms are later assigned to players in start_unit_setup.lua.
--
--	TODO:
--		Figure out how modstats should handle procedurally generated comms
--			* Teach gadget to treat them as baseline comms
--
--------------------------------------------------------------------------------
--	PROPOSED SPECS FOR TEMPLATE UNITDEFS
--	Weapon 1: fake laser
--	Weapon 2: shield
--	Weapon 3: special weapon (uses CEG 3 and 4)
--	Weapon 4: main weapon (no CEG) --> change to something else, such as second shield
--	Weapon 5: main weapon (uses CEG 1 and 2)
--	Weapon 6: flamethrower only?
--------------------------------------------------------------------------------

-- just some comm cloning stuff (to avoid having to maintain multiple unitdefs)
local copy = {
	armcom1 = {
		armcom2 = {
			level = 2,
			mainstats = {maxdamage = 3000, objectname = "armcom2.3do"},
			customparams = {rangebonus = "0.05"},
		},
		armcom3 = {
			level = 3,
			mainstats = {maxdamage = 4000, objectname = "armcom3.3do"},
			customparams = {rangebonus = "0.1"},
		},
		armcom4 = {
			level = 4,
			mainstats = {maxdamage = 6000, objectname = "armcom4.3do"},
			customparams = {rangebonus = "0.2"},
		},
	},
	corcom1 = {
		corcom2 = {
			level = 2,
			mainstats = {maxdamage = 3600, objectname = "corcom2.s3o"},
			customparams = {damagebonus = "0.1"},
		},
		corcom3 = {
			level = 3,
			mainstats = {maxdamage = 5000, objectname = "corcom3.s3o"},
			customparams = {damagebonus = "0.2"},
		},
		corcom4 = {
			level = 4,
			mainstats = {maxdamage = 7200, objectname = "corcom4.s3o"},
			customparams = {damagebonus = "0.3"},
		},
	},
	commrecon1 = {
		commrecon2 = {
			level = 2,
			mainstats = {maxdamage = 2750, maxvelocity = 1.55, objectname = "commrecon2.s3o"},
			customparams = {damagebonus = "0.05"},
		},
		commrecon3 = {
			level = 3,
			mainstats = {maxdamage = 3600, maxvelocity = 1.7, objectname = "commrecon3.s3o"},
			customparams = {damagebonus = "0.1"},
		},
		commrecon4 = {
			level = 4,
			mainstats = {maxdamage = 5000, maxvelocity = 1.9, objectname = "commrecon4.s3o"},
			customparams = {damagebonus = "0.15"},
		},
	},
	commsupport1 = {
		commsupport2 = {
			level = 2,
			mainstats = {maxdamage = 2500, workertime = 15, description = "Econ/Support Commander, Builds at 15 m/s", objectname = "commsupport2.s3o"},
			customparams = {rangebonus = "0.1"},
		},
		commsupport3 = {
			level = 3,
			mainstats = {maxdamage = 3200, workertime = 18, description = "Econ/Support Commander, Builds at 18 m/s", objectname = "commsupport3.s3o"},
			customparams = {rangebonus = "0.2"},
		},
		commsupport4 = {
			level = 4,
			mainstats = {maxdamage = 4500, workertime = 24, description = "Econ/Support Commander, Builds at 24 m/s", objectname = "commsupport4.s3o"},
			customparams = {rangebonus = "0.3"},
		},
	},
}

for sourceName, copyTable in pairs(copy) do
	for cloneName, stats in pairs(copyTable) do
		UnitDefs[cloneName] = CopyTable(UnitDefs[sourceName], true)
		UnitDefs[cloneName].unitname = cloneName
		for statName, value in pairs(stats.mainstats) do
			UnitDefs[cloneName][statName] = value
		end
		for statName, value in pairs(stats.customparams) do
			UnitDefs[cloneName].customparams[statName] = value
		end
		UnitDefs[cloneName].customparams.level = stats.level
		UnitDefs[cloneName].name = (UnitDefs[cloneName].name) .. " - Level " .. stats.level
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("gamedata/modularcomms/moduledefs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local commDataRaw = Spring.GetModOptions().commandertypes
local commDataFunc, err, success, commData
if not (commDataRaw and type(commDataRaw) == 'string') then
	err = "Comm data entry in modoption is empty or in invalid format"
	commData = {}
else
	commDataRaw = string.gsub(commDataRaw, '_', '=')
	commDataRaw = Spring.Utilities.Base64Decode(commDataRaw)
	Spring.Echo(commDataRaw)
	commDataFunc, err = loadstring("return "..commDataRaw)
	if commDataFunc then
		success, commData = pcall(commDataFunc)
		if not success then	-- execute Borat
			err = commData
			commData = {}
		end
	end
end
if err then 
	Spring.Echo('Modular Comms error: ' .. err)
end

if not commData then commData = {} end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
commDefs = {}	--holds precedurally generated comm defs

local function ProcessComm(name, config)
	if config.chassis and UnitDefs[config.chassis] then
		Spring.Echo("Processing comm: "..name)
		local name = name
		commDefs[name] = CopyTable(UnitDefs[config.chassis], true)
		commDefs[name].customparams = commDefs[name].customparams or {}
		local cp = commDefs[name].customparams
		cp.basespeed = tostring(commDefs[name].maxvelocity)
		cp.basehp = tostring(commDefs[name].maxdamage)
		for i,v in pairs(commDefs[name].weapondefs or {}) do
			v.customparams = v.customparams or {}
			v.customparams.baserange = tostring(v.range)
			v.customparams.basereload = tostring(v.reloadtime)
			for armorname,dmg in pairs(v.damage) do
				v.customparams["basedamage_"..armorname] = tostring(dmg)
				--Spring.Echo(armorname, v.customparams["basedamage_"..armorname])
			end
		end
		
		if config.modules then
			local hasWeapon = false
			RemoveWeapons(commDefs[name])
			-- sort: weapons first, weapon mods next, regular modules last
			table.sort(config.modules,
				function(a,b)
					return (a:find("commweapon_") and not b:find("commweapon_"))
					or (a:find("conversion_") and not (b:find("commweapon_") or b:find("conversion_")) )
					or (a:find("weaponmod_") and b:find("module_")) 
				end )

			-- process all modules (including weapons)
			for _,moduleName in ipairs(config.modules) do
				if moduleName:find("commweapon_",1,true) then
					if weapons[moduleName] then
						--Spring.Echo("\tApplying weapon: "..moduleName)
						ApplyWeapon(commDefs[name], moduleName)
						hasWeapon = true
					else
						Spring.Echo("\tERROR: Weapon "..moduleName.." not found")
					end
				end
				if upgrades[moduleName] then
					--Spring.Echo("\tApplying upgrade: "..moduleName)
					local attributeMods = { -- add a mod for everythings that can have a negative adjustment
						speed = 0,
						reload = 0,
					}
					if upgrades[moduleName].func then --apply upgrade function
						upgrades[moduleName].func(commDefs[name], attributeMods) 
					end	
					if attributeMods.speed ~= 0 then
						commDefs[name].maxvelocity = commDefs[name].customparams.basespeed*(1+attributeMods.speed)
					else
						commDefs[name].maxvelocity = commDefs[name].customparams.basespeed/(1-attributeMods.speed)
					end		
				else
					Spring.Echo("\tERROR: Upgrade "..moduleName.." not found")
				end
			end
			if not hasWeapon then
				ApplyWeapon(commDefs[name], "commweapon_peashooter", true)
			end
		end
		if config.name then
			commDefs[name].name = config.name
		end
		config.cost = config.cost or 0
		commDefs[name].buildcostmetal = commDefs[name].buildcostmetal + config.cost
		commDefs[name].buildcostenergy = commDefs[name].buildcostenergy + config.cost
		commDefs[name].buildtime = commDefs[name].buildtime + config.cost
	end
end

for name, config in pairs(commData) do
	ProcessComm(name, config)
end

--stress test: try every possible module to make sure it doesn't crash
local stressDefs = {}
local stressChassis = {
	"armcom3", "corcom3", "commrecon3", "commsupport3"
}
local stressTemplate = {
	name = "st",
	modules = {},
}
for name in pairs(upgrades) do
	stressTemplate.modules[#stressTemplate.modules+1] = name
end
for index,name in pairs(stressChassis) do
	local def = stressTemplate
	def.chassis = name
	def.name = def.name..name
	ProcessComm("stresstest"..index, def)
	stressDefs["stresstest"..index] = true
end

-- for easy testing; creates a comm with unitName testcomm
local testDef = VFS.Include("gamedata/modularcomms/testdata.lua")
for i = 1, testDef.count do
	ProcessComm(testDef[i].name, testDef[i])
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- postprocessing
for name, data in pairs(commDefs) do
	Spring.Echo("\tPostprocessing commtype: ".. name)
	-- apply intrinsic bonuses
	if data.customparams.damagebonus then
		ModifyWeaponDamage(data, data.customparams.damagebonus + 1)
	end
	if data.customparams.rangebonus then
		ModifyWeaponRange(data, data.customparams.rangebonus + 1)
	end	
	
	-- set weapon1 range	- may need exception list in future depending on what weapons we add
	if data.weapondefs then
		local maxRange = 0
		local weaponRanges = {}
		local weaponNames = {}
		local wep1Name
		-- first check if the comm is actually using the weapon
		if data.weapons then
			for index, weaponData in pairs(data.weapons) do
				weaponNames[string.lower(weaponData.def)] = true
			end
		end
		for name, weaponData in pairs(data.weapondefs) do
			if weaponNames[name] and not (string.lower(weaponData.name):find('fake')) and not weaponData.commandfire then
				if (weaponData.range or 0) > maxRange then
					maxRange = weaponData.range 
				end
				weaponRanges[name] = weaponData.range 
			end
		end
		-- lame-ass hack, because the obvious methods don't work
		for name, weaponData in pairs(data.weapondefs) do
			if string.lower(weaponData.name):find('fake') then
				weaponData.range = maxRange
			end
		end
		for name, range in pairs(weaponRanges) do -- only works for 2 weapons max
			if maxRange ~= range then
				data.customparams.extradrawrange = range
			end 
		end
	end
	-- set wreck values
	for featureName,array in pairs(data.featuredefs or {}) do
		local mult = 0.4
		if featureName == "HEAP" then mult = 0.2 end
		array.metal = data.buildcostmetal * mult
		array.reclaimtime = data.buildcostmetal * mult
		array.damage = data.maxdamage
	end
	-- rez speed
	if data.canresurrect then data.resurrectspeed = data.workertime * 5/6 end
	-- make sure weapons can hit their max range
	if data.weapondefs then
		for name, weaponData in pairs(data.weapondefs) do
			if weaponData.weapontype == "MissileLauncher" then
				weaponData.flighttime = math.max(weaponData.flighttime or 3, 1.2 * weaponData.range/weaponData.weaponvelocity)
			elseif weaponData.weapontype == "Cannon" then
				weaponData.weaponvelocity = math.max(weaponData.weaponvelocity, math.sqrt(weaponData.range * 140))
			end
		end
	end
end

-- remove stress test defs
for key,_ in pairs(stressDefs) do
	commDefs[key] = nil
end

-- splice back into unitdefs
for name, data in pairs(commDefs) do
	UnitDefs[name] = data
end
