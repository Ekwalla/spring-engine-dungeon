function gadget:GetInfo()
	return {
		name = "Jump",
		desc = "Introduces the jump command",
		author = "KDR_11k (David Becker)",
		date = "2007-12-14",
		license = "none yet",
		layer = 3,
		enabled = true
	}
end

local CMD_JUMP = 32298

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

local jumpData = {} --contains info about the unittypes that can jump
local jumper = {} --contains the currently jumping units
	-- id :
	-- direction
	-- vspeed
local jumpDesc = {
	name="Jump",
	tooltip="jump over a certain distance",
	action="jump",
	id=CMD_JUMP,
	type=CMDTYPE.ICON_MAP,
	cursor="Unload units",
}
local closeinList = {} --Marks which units should close in to which radius to which location
	-- id:
	-- posx, posy, posz,
	-- radius
local teamJump = {}
local jumpOffset = {}

local orderJumpList={}

function gadget:Initialize()
	for i,u in pairs(UnitDefs) do
		if u.customParams.jumpDistance then
			local j = {
				distance = toNumber(u.customParams.jumpdistance),
				delay = toNumber(u.customParams.jumpdelay) * 30,
				hspeed = toNumber(u.customParams.jumpspeed),
				vspeed = toNumber(u.customParams.jumpvert)
			}
			jumpData[i]=j
		end
	end
	jumpData[UnitDefNames.jumper.id] = {
		distance=700,
		delay=300,
		hspeed=9,
		vspeed=1
	}
	_G.jumper=jumper
	_G.jumpData=jumpData
end

function gadget:AllowCommand(unit, def, team, cmd, param, opts,tag,synced)
	if cmd == CMD_JUMP then
		if jumpData[def] then
			if not opts.ctrl then
				if not Spring.GetGroundBlocked(param[1], param[3]) then
					if not opts.alt then
						if not teamJump[team] then
							teamJump[team] = {count = 0,x = 0, z = 0}
						end
						teamJump[team].count = teamJump[team].count + 1
						local x,y,z = Spring.GetUnitPosition(unit)
						teamJump[team].x = teamJump[team].x + x
						teamJump[team].z = teamJump[team].z + z
						return true
					else
						if not jumper[unit] and not teamJump[team] then
							teamJump[team]= {count = 0,x = 0, z = 0}
							return true
						end
					end
				end
			else
				return false
			end
		end
		return false
	end
	return true
end

function gadget:CommandFallback(unit, def, team, cmd, params, opts)
	if cmd == CMD_JUMP then
		if not jumper[unit] then
			orderJumpList[unit]=params
			local x,y,z = Spring.GetUnitPosition(unit)
			local tx,ty,tz
			tx = params[1]
			ty = params[2]
			tz = params[3]
			if teamJump[team] and teamJump[team].count > 0 then
				jumpOffset[unit] = {x = teamJump[team].x / teamJump[team].count - x, z = teamJump[team].z / teamJump[team].count - z}
				tx = tx - jumpOffset[unit].x
				tz = tz - jumpOffset[unit].z
			elseif not jumpOffset[unit] then
				jumpOffset[unit] = {x = 0, z = 0}
			else
				tx = tx - jumpOffset[unit].x
				tz = tz - jumpOffset[unit].z
			end
			local dist = math.sqrt((x-tx)*(x-tx) + (z-tz)*(z-tz))
			if dist <= jumpData[def].distance then
				local j = {}
				j.direction=Spring.GetHeadingFromVector(tx-x, tz-z)
				j.vspeed = dist / 2 * jumpData[def].vspeed / jumpData[def].hspeed
				j.coolDown = Spring.GetGameFrame() + jumpData[def].delay
				j.jumping = true
				Spring.MoveCtrl.Enable(unit)
				Spring.SetUnitCOBValue(unit, 82, j.direction)
				Spring.CallCOBScript(unit, "JumpStart", 0)
				SendToUnsynced("sound","sounds/jumpstart.wav",x,y,z)
				--Spring.SetUnitRotation(unit, 0,j.direction,0)
				jumper[unit]=j
--				closeinList[unit] = {
--					posx = tx,
--					posy = ty,
--					posz = tz,
--					radius = 0
--				}
				return true, true
			else
				closeinList[unit] = {
					posx = tx,
					posy = ty,
					posz = tz,
					radius = jumpData[def].distance
				}
				return true, false
			end
		else
			return true, false
		end
	end
	return false
end

function gadget:UnitCreated(unit, def, team)
	if jumpData[def] then
		Spring.InsertUnitCmdDesc(unit,jumpDesc)
	end
end

function gadget:UnitDestroyed(unit, def, team, aunit, adef, ateam)
	jumper[unit]=nil
	jumpOffset[unit] = nil
end

function gadget:GameFrame(f)
	for u,params in pairs(orderJumpList) do
		Spring.GiveOrderToUnit(u,CMD_JUMP,params,{"ctrl"}) --this gets blocked on the leader unit but forwarded to the squad
		orderJumpList[u]=nil
	end
	for unit, j in pairs(jumper) do
		if j.jumping then
			local def = Spring.GetUnitDefID(unit)
			Spring.MoveCtrl.SetRelativeVelocity(unit, 0, j.vspeed, jumpData[def].hspeed)
			j.vspeed = j.vspeed - jumpData[def].vspeed
			local x,y,z = Spring.GetUnitBasePosition(unit)
			if y < Spring.GetGroundHeight(x,z) then
				j.jumping = false
				Spring.MoveCtrl.Disable(unit)
				Spring.CallCOBScript(unit, "JumpEnd", 0)
				Spring.GiveOrderToUnit(unit,CMD.INSERT,{0,CMD.MOVE,0,x,y,z},{"alt"})
				SendToUnsynced("sound","sounds/jumpend.wav",x,y,z)
			end
		elseif j.coolDown < f then
			jumper[unit] = nil
		end
	end
	for team, _ in pairs(teamJump) do
		teamJump[team]=nil
	end
	for unit, goal in pairs(closeinList) do
		Spring.SetUnitMoveGoal(unit, goal.posx, goal.posy, goal.posz, goal.radius)
		closeinList[unit]=nil
	end
end


else
--UNSYNCED

function gadget:RecvFromSynced(msg,file,x,y,z)
	if msg == "sound" then
		Spring.PlaySoundFile(file,5,x,y,z)
	end
end

function gadget:DrawWorld()
	local team = Spring.GetLocalAllyTeamID()
	local f = Spring.GetGameFrame()
	for u,d in spairs(SYNCED.jumper) do
		if Spring.GetUnitAllyTeam(u)==team and  d.coolDown > f then
			local ud = Spring.GetUnitDefID(u)
			gl.PushMatrix()
			local x,y,z = Spring.GetUnitPosition(u)
			gl.Translate(x,y,z)
			gl.Billboard()
			gl.Color(.2,.2,.2,1)
			gl.Rect(-21,-24,21,-16)
			gl.Color(.7,.7,0,1)
			gl.Rect(-20,-23,-20 + 40 * (1+(f - d.coolDown)/SYNCED.jumpData[ud].delay),-17)
			gl.PopMatrix()
		end
	end
	gl.Color(1,1,1,1)
end

function gadget:Initialize()
	Spring.SetCustomCommandDrawData(CMD_JUMP,"Unload units",{.2,.2,1,1})
end

end
