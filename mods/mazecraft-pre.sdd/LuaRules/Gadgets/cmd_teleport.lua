function gadget:GetInfo()
  return {
    name      = "Teleport",
    desc      = "Teleport Gates.",
    author    = "CarRepairer",
    date      = "2011-06-05",
    license   = "GNU GPL, v2 or later",
    layer     = 1,
    enabled   = true,
  }
end


local echo 			= Spring.Echo
local CMD_WARPGATE 	= 32104

local warpgate_udid = UnitDefNames['weirdblock'].id

-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then 
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------


local gaiaTeam, gaiaAlliance

local warpList = {}
local closeList = {}
local range = {}

local warpPaired = {}
local lastWarpgate = nil

local warpDist = 150

local warpgateCmdDesc = {
	id      = CMD_WARPGATE,
	type    = CMDTYPE.ICON_UNIT,
	cursor  = 'cursorpickup',
	name    = 'WarpGate',
	action  = 'warpgate',
	tooltip = 'Enter warp gate.',
}



local function Warp(unitID, warpgateID)
	local x,y,z = Spring.GetUnitPosition( warpPaired[warpgateID] )
	local randomOffX = math.random(40,60)
	local randomOffZ = math.random(40,60)
	Spring.SetUnitPosition( unitID, x+randomOffX,y,z+randomOffZ)
end

-------------------------------------------------------------------------------------
--Callins

function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = Spring.GetTeamInfo(gaiaTeam)
	
	
	gadgetHandler:RegisterCMDID(CMD_WARPGATE)
	
	local allUnits = Spring.GetAllUnits()
	for _,unitID in ipairs(allUnits) do
		local udid = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated( unitID, udid )
	end
end

function gadget:GameFrame(f)

	for i,o in pairs(closeList) do
		closeList[i] = nil
		Spring.SetUnitMoveGoal(o.unit,o.x,o.y,o.z,warpDist/2)
	end
	
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if UnitDefs[unitDefID] and UnitDefs[unitDefID].speed > 0 then
		Spring.InsertUnitCmdDesc(unitID, 12345, warpgateCmdDesc)
	end
	
	if unitDefID == warpgate_udid then
		if lastWarpgate and not warpPaired[lastWarpgate] then
			warpPaired[unitID] = lastWarpgate
			warpPaired[lastWarpgate] = unitID
		end
		lastWarpgate = unitID
	end
end


function gadget:CommandFallback(unitID,udid,team,cmd,param,opt)

	if cmd == CMD_WARPGATE then
		local x,_,z = Spring.GetUnitPosition(unitID)
		local targetID = param[1]
		local tx, ty, tz = Spring.GetUnitPosition( targetID  )
		local dist = Spring.GetUnitSeparation( unitID, targetID )
		if dist <= warpDist then
			Warp(unitID, targetID)
			return true, true
		else
			table.insert(closeList, {unit = unitID, x=tx, y=ty, z=tz })
		end
		return true, false
	end
	return false
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
else  -- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------




function gadget:DefaultCommand(type,id)
	if type == 'unit' then
		local target_udid = Spring.GetUnitDefID(id)
		if target_udid == warpgate_udid then
			return CMD_WARPGATE
		end
	end
end



-- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
end