function lowerkeys(t)
  local tn = {}
  for i,v in pairs(t) do
    local typ = type(i)
    if type(v)=="table" then
      v = lowerkeys(v)
    end
    if typ=="string" then
      tn[i:lower()] = v
    else
      tn[i] = v
    end
  end
  return tn
end

mapWeaponToCEG = {
	[3] = {3,4},
	[5] = {1,2},
}

function RemoveWeapons(unitDef) 
-- because for some reason comms have a default weapon with no purpose and I don't want to screw with that
	if unitDef.weapons then
		for i=3,6 do
			if unitDef.weapons[i] then
				unitDef.weapons[i] = nil
			end
		end
	end
end

function ApplyWeapon(unitDef, weapon, replace, forceslot)
	local wcp = (weapons[weapon] and weapons[weapon].customparams) or {}
	local slot = tonumber(wcp.slot) or 4
	local isDgun = (tonumber(wcp.slot) == 3)
	local altslot = tonumber(wcp.altslot or 3)
	local dualwield = false
	
	if (not isDgun) and unitDef.customparams.alreadyhasweapon and not replace then	-- dual wield
		slot = altslot
		dualwield = true
	end
	
	slot = forceslot or slot
	
	Spring.Echo(weapons[weapon].name .. " into slot " .. slot)
	
	unitDef.weapons[slot] = {
		def = weapon,
		badtargetcategory = wcp.badtargetcategory or [[FIXEDWING]],
		onlytargetcategory = wcp.onlytargetcategory or [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
	}
	unitDef.weapondefs[weapon] = CopyTable(weapons[weapon], true)
	
	if isDgun then
		unitDef.candgun = true
	end
	
	-- upgrade by level
	
	local level = (tonumber(unitDef.customparams.level) - 1) or 0
	local wd = unitDef.weapondefs[weapon]
	--[[
	if wd.range then
		wd.range = wd.range + (wd.customparams.rangeperlevel or 0) * level
	end
	if wd.damage then
		wd.damage.default = wd.damage.default + (wd.customparams.damageperlevel or 0) * level
	end
	]]--
	
	-- clear other weapons
	--[[
	for i=4,6 do	-- subject to change
		if unitDef.weapons[i] and i ~= slot then
			unitDef.weapons[i] = nil
		end
	end
	]]--
	-- add CEGs
	if mapWeaponToCEG[slot] and unitDef.sfxtypes and unitDef.sfxtypes.explosiongenerators then
		unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][1]] = wcp.muzzleeffect or [[custom:NONE]]
		unitDef.sfxtypes.explosiongenerators[mapWeaponToCEG[slot][2]] = wcp.misceffect or [[custom:NONE]]
	end
	
	--base customparams
	wcp.baserange = tostring(wd.range)
	for armorname,dmg in pairs(wd.damage) do
		wcp["basedamage_"..armorname] = tostring(dmg)
		--Spring.Echo(armorname, v.customparams["basedamage_"..armorname])
	end
	
	if (not isDgun) and not dualwield then
		unitDef.customparams.alreadyhasweapon = true
	end
end

function ReplaceWeapon(unitDef, oldWeapon, newWeapon)
	local weapons = unitDef.weapons or {}
	for i,v in pairs(weapons) do
		if v.def == oldWeapon then
			Spring.Echo("replacing " .. oldWeapon .. " with " .. newWeapon)
			ApplyWeapon(unitDef, newWeapon, false, i)
			break -- one conversion, one weapon changed. Get 2 if you want 2
		end
	end
end

function ModifyWeaponRange(unitDef, factor)
	local weapons = unitDef.weapondefs or {}
	for i,v in pairs(weapons) do
		if v.range then v.range = v.range * factor end
	end
end

function ModifyWeaponDamage(unitDef, factor)
	local weapons = unitDef.weapondefs or {}
	for i,v in pairs(weapons) do
		for armorname, dmg in pairs(v.damage) do
			v.damage[armorname] = dmg * factor
		end
	end
end