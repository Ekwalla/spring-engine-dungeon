function gadget:GetInfo()
  return {
    name      = "Maze",
    desc      = "Make mazes and stuff",
    author    = "CarRepairer",
    date      = "2011-03-24",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

--[[

	To make a maze type:
	
		/luarules maze <size> <depth> <min corridor width>
		
	size - height and width (must be odd number, greater than 5)
	depth - how many times it's split in half
	min corridor width - minimum width of corridors
	example: /luarules maze 51 7 4
--]]

local echo 			= Spring.Echo

local function include(filedir,filename,env)
  if (VFS.FileExists(filename,VFS.RAW_ONLY)) then
    return VFS.Include(filename,env,VFS.RAW_ONLY)
  else
    return VFS.Include(filedir .. filename,env,VFS.ZIP_ONLY)
  end
end


if gadgetHandler:IsSyncedCode() then
-------------------------------------
----- SYNCED -----


local a = VFS.Include "LuaRules/Gadgets/mazecode.lua"

local TESTMODE = true

local createUnit 	= {}
local destroyUnit 	= {}
local mapWidth 		= math.floor(Game.mapSizeX)
local mapHeight 	= math.floor(Game.mapSizeZ)

local mazeBlock		= 'block'
local mazeDoor		= 'door'

local function PlaceMazeBlocks(mazegrid)
	local blockStr = 'X'
	local doorStr = 'D'
	local tiles = {
		[blockStr] = mazeBlock,
		[doorStr] = mazeDoor,
	}
	
	local origx, origy = 100,100
	local size = UnitDefNames[mazeBlock].xsize
	size = size * 8

	local teamID = Spring.GetGaiaTeamID()
	if TESTMODE then teamID = 0; end
	
	local w, h = #mazegrid, #mazegrid[1]
	for x= 1, w do
		for y= 1, h do
			if mazegrid[x][y] == blockStr
				or mazegrid[x][y] == doorStr
				then
				
				local px = origx+x*size 
				local pz = origy+y*size
				
				pz = mapHeight - pz
				
				local py = Spring.GetGroundHeight(px, pz)
				
				createUnit[#createUnit+1] = { tiles[ mazegrid[x][y] ], px, py, pz, 0, teamID }
			end
		end
	end
	
end

local function KillMazeBlocks()
	local allUnits = Spring.GetAllUnits()
	for _, unitID in ipairs(allUnits) do
		local udid = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[udid]
		if ud and (ud.name == mazeBlock or ud.name == mazeDoor )then
			destroyUnit[#destroyUnit+1] = {unitID, false, true}
		end
	end
end


local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

---------------------------------------
--callins

function gadget:RecvLuaMsg(msg, playerID)
	
	local msg = explode('|',msg)
	local cmd = msg[1]
	local param1 = msg[2]
	local param2 = msg[3]
	local param3 = msg[4]
	
	
	if cmd == 'maze' then
		local width, height = 21, 21
		if param1 then
			param1=param1+0
			width, height = param1, param1
		else
			return
		end
	
		if TESTMODE then echo '-- CALLING MAZE CODE --'; end
		--local mazemaster = MazeMasterRecBack( width, height )
		--local mazemaster = MazeMasterHuntKill( width, height )
		
		local mazemaster = MazeMasterRecDiv( width, height )
		
		if not mazemaster then return end
		
		--mazemaster:SetSize(30,5)
		if param2 then
			mazemaster:SetDepth(param2+0)
		end
		if param3 then
			mazemaster:SetMinCorridor(param3+0)
		end
		mazemaster:GenerateMaze()
		mazemaster:MakeEntrance()
		mazemaster:MakeExit()
		
		
		if TESTMODE	then echo ( mazemaster ); end
		
		PlaceMazeBlocks(mazemaster:GetGrid())
		
		if TESTMODE	then echo 'DONE'; end
	elseif cmd == 'killmaze' then
		KillMazeBlocks()
	end
end

function gadget:GameFrame(f)
	for _, data in ipairs( createUnit ) do
		Spring.CreateUnit( data[1], data[2], data[3], data[4], data[5], data[6] )
	end
	createUnit = {}
	
	for _, data in ipairs( destroyUnit ) do
		Spring.DestroyUnit( data[1], data[2], data[3] )
	end
	destroyUnit = {}
	
end



----- SYNCED -----
-------------------------------------
else
-------------------------------------
----- UNSYNCED -----


local function DoMaze(cmd, line, words, playerID)
	--echo ('test', cmd, line, words, words[1] )
	local cmdline = cmd
	if words[1] then
		cmdline = cmdline ..'|'.. table.concat( words, '|' )
	end
	
	Spring.SendLuaRulesMsg(cmdline)
end

function gadget:Initialize()
	gadgetHandler:AddChatAction('maze', DoMaze )
	gadgetHandler:AddChatAction('killmaze', DoMaze )
end


----- UNSYNCED -----
-------------------------------------
end


