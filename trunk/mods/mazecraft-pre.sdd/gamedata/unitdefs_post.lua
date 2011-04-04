--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility
--

local function tobool(val)
  local t = type(val)
  if (t == 'nil') then
    return false
  elseif (t == 'boolean') then
    return val
  elseif (t == 'number') then
    return (val ~= 0)
  elseif (t == 'string') then
    return ((val ~= '0') and (val ~= 'false'))
  end
  return false
end


local function disableunits(unitlist)
  for name, ud in pairs(UnitDefs) do
    if (ud.buildoptions) then
      for _, toremovename in ipairs(unitlist) do
        for index, unitname in pairs(ud.buildoptions) do
          if (unitname == toremovename) then
            table.remove(ud.buildoptions, index)
          end
        end
      end
    end
  end
end

--deep not safe with circular tables! defaults To false
function CopyTable(tableToCopy, deep)
  local copy = {}
  for key, value in pairs(tableToCopy) do
    if (deep and type(value) == "table") then
      copy[key] = CopyTable(value, true)
    else
      copy[key] = value
    end
  end
  return copy
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- because the way lua access to unitdefs and weapondefs is setup is insane
--
--[[
for _, ud in pairs(UnitDefs) do
    if ud.collisionVolumeOffsets then
		if not ud.customparams then
			ud.customparams = {}
		end
		ud.customparams.collisionVolumeOffsets = ud.collisionVolumeOffsets  -- For ghost site
    end
 end--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Convert all CustomParams to strings
--

for name, ud in pairs(UnitDefs) do
  if (ud.customparams) then
    for tag,v in pairs(ud.customparams) do
      if (type(v) ~= "string") then
        ud.customparams[tag] = tostring(v)
      end
    end
  end
end 


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Set unit faction and build options
--

local function TagTree(unit, faction, newbuildoptions)
 -- local morphDefs = VFS.Include"LuaRules/Configs/morph_defs.lua"
  
  local function Tag(unit)
    if (not UnitDefs[unit] or UnitDefs[unit].faction) then
      return
    end
	local ud = UnitDefs[unit]
    ud.faction = faction
    if (UnitDefs[unit].buildoptions) then
	  for _, buildoption in ipairs(ud.buildoptions) do
        Tag(buildoption)
      end
	  if (ud.maxvelocity > 0) and unit ~= "armcsa" then
	    ud.buildoptions = newbuildoptions
	  end
    end
--[[	
    if (morphDefs[unit]) then
      if (morphDefs[unit].into) then
        Tag(morphDefs[unit].into)
      else
        for _, t in ipairs(morphDefs[unit]) do
          Tag(t.into)
        end
      end        
    end
]]--  
  end

  Tag(unit)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Calculate mincloakdistance based on unit footprint size
--

local sqrt = math.sqrt

for name, ud in pairs(UnitDefs) do
  if (not ud.mincloakdistance) then
    local fx = ud.footprintx and tonumber(ud.footprintx) or 1
    local fz = ud.footprintz and tonumber(ud.footprintz) or 1
    local radius = 8 * sqrt((fx * fx) + (fz * fz))
    ud.mincloakdistance = (radius + 48)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Disable smoothmesh
-- 

for name, ud in pairs(UnitDefs) do
    if (ud.canfly) then ud.usesmoothmesh = false end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Special Air
--
--[[
if (modOptions and tobool(modOptions.specialair)) then
  local replacements = VFS.Include("LuaRules/Configs/specialair.lua")
  if (replacements[modOptions.specialair]) then
    replacements = replacements[modOptions.specialair]
    for name, ud in pairs(UnitDefs) do
      if (ud.buildoptions) then
        for buildKey, buildOption in pairs(ud.buildoptions) do
          if (replacements[buildOption]) then
            ud.buildoptions[buildKey] = replacements[buildOption];
          end
        end
      end
    end
  end
end
--]]




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Set turnInPlace speed limits, reverse velocities (but not for ships)
--
for name, ud in pairs(UnitDefs) do
  if ud.turninplace == 0 then
	ud.turninplacespeedlimit = ud.maxvelocity*0.6
  end
  if ud.category and not (ud.category:find("SHIP",1,true) or ud.category:find("SUB",1,true)) then
    if (ud.maxvelocity) then ud.maxreversevelocity = ud.maxvelocity * 0.33 end
  end
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lasercannons going through units fix
-- 

for name, ud in pairs(UnitDefs) do
  ud.collisionVolumeTest = 1
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Min Build Range back to what it used to be
-- 
for name, ud in pairs(UnitDefs) do
	if ud.builddistance and ud.builddistance < 128 and name ~= "armasp" then
		ud.builddistance = 128 
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  No leveling ground

--[[
for name, ud in pairs(UnitDefs) do
  if (ud.yardmap)  then
    ud.levelGround = false
  end
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- No reclaiming of live units
-- 

--for name, ud in pairs(UnitDefs) do
--  ud.reclaimable = false
--end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Special Decloak
-- 
if (modOptions and tobool(modOptions.specialdecloak)) then
	for name, ud in pairs(UnitDefs) do
		if not ud.customparams then
			ud.customparams = {}
		end
		ud.customparams.specialdecloakrange = ud.mincloakdistance or 0
		ud.mincloakdistance = 0
	end
end




-------------------------------------
------ UNIT SETUP ---------------
-------------------------------------


for name, ud in pairs(UnitDefs) do
	
	echo ("UD", name)
	
	-- *** Buildings ***
	if not ud.maxSlope then ud.maxSlope = 255 end
	
	--- Build time
	local ignore = { ramp=1, }
	if not ignore[name] then
		if ud.buildcostmetal then
			ud.buildtime 		= ud.buildcostmetal
			ud.buildcostenergy 	= ud.buildcostmetal
		elseif ud.buildcostenergy then
			ud.buildtime 		= ud.buildcostenergy
		end
	end
	
	--- Corpses
	local ignore = { chicken=1, }
	if not ignore[name]	and ud.featuredefs and ud.featuredefs.dead then
		
		ud.corpse = 'dead'
		if not ud.featuredefs.dead.description then
			ud.featuredefs.dead.description = "Dead " .. ud.name
		end
	
		ud.featuredefs.dead.footprintx = ud.footprintx
		ud.featuredefs.dead.footprintz = ud.footprintz
		
		if ud.featuredefs.dead.blocking == nil and ud.footprintx < 2 then
			ud.featuredefs.dead.blocking = false
		end

		ud.featuredefs.dead.metal = ud.buildcostmetal
		ud.featuredefs.dead.energy = ud.buildcostenergy
		
		ud.featuredefs.dead.reclaimTime = ud.buildtime
		
		if not ud.featuredefs.dead.object then
			--echo ('corpse', name)
			if ud.isfeature then
				ud.featuredefs.dead.object = ud.objectname
			else
				ud.featuredefs.dead.object = ud.unitname .. '_dead.s3o' 
			end
		end
		
		if not ud.featuredefs.dead.damage then
			ud.featuredefs.dead.damage = ud.maxdamage * 2
		end
	end
	
	
	-- Misc
	ud.shownanoframe = false
	
	if not ud.nochasecategory then 	ud.nochasecategory = ''					end
	if not ud.maxwaterdepth then 	ud.maxwaterdepth = ud.footprintx * 10 	end
	if not ud.sightdistance then 	ud.sightdistance = 400					end
	if not ud.idleautoheal then 	ud.idleautoheal = 0 					end
	if not ud.objectname then 		ud.objectname = ud.unitname .. '.s3o' 	end
	if not ud.maxslope then 		ud.maxslope = 255						end
	ud.nochasecategory				= ud.nochasecategory .. ' NOTARGET'
	
	if not ud.script then
		local ignore = { 
			armsolar=1,
			testunit=1,
		}
		if not ignore[name]	then
			ud.script = ud.unitname .. '.lua' 
		end
	end
	
end