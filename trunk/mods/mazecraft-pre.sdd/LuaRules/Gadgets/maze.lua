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

local MC = Spring.MoveCtrl

local a = VFS.Include "LuaRules/Gadgets/mazecode.lua"

local TESTMODE = true

local createUnit 	= {}
local createFeature	= {}
local destroyUnit 	= {}
local destroyFeature 	= {}
local mapWidth 		= math.floor(Game.mapSizeX)
local mapHeight 	= math.floor(Game.mapSizeZ)

local mazeBlock		= 'block'
local mazeDoor		= 'door'

local mysteryBlocks		= {}

local groundHeight	= Spring.GetGroundHeight(1,1)

local function CreateUnit( defName, x, y, z, heading, teamID )
	createUnit[#createUnit+1] = { defName, x, y, z, heading, teamID }
end

local function CreateFeature( defName, x, y, z, heading, AllyTeamID, fType )
	createFeature[#createFeature+1] = { defName, x, y, z, heading, AllyTeamID, fType }
end
local function CreateMysteryBlock( x, y, z, fType )
	--CreateFeature( 'mysteryblock', x, y, z, 0, Spring.GetGaiaTeamID(), fType )
	CreateFeature( 'mysteryblock_dead', x, y, z, 0, 0, fType )
	--CreateUnit( 'mysteryblock', x, y, z, 0, 0, fType )
end

local function DestroyFeature(featureID)
	destroyFeature[#destroyFeature+1] = {featureID}
end
local function DestroyUnit(unitID, param1, param2)
	destroyUnit[#destroyUnit+1] = {unitID, param1, param2}
end

local function AddTerraBlock(x1,z1, x2,z2, size)
	Spring.LevelHeightMap( x1,z1, x2,z2, groundHeight+size )
end
local function RemTerraBlock(x1,z1, x2,z2)
	Spring.LevelHeightMap( x1,z1, x2,z2, groundHeight )
end

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
	local halfsize=size/2
	local lesshalfsize = halfsize*0.9

	local teamID = Spring.GetGaiaTeamID()
	--if TESTMODE then teamID = 0; end
	
	
	
	local w, h = #mazegrid, #mazegrid[1]
	--Spring.LevelHeightMap( origx -size/2, origy-size/2, origx + size*(w + 14), origy + size*(h + 14), 0 )
	
	for x= 1, w do
		for y= 1, h do
			
			local px = origx+x*size 
			local pz = origy+y*size
			pz = mapHeight - pz
			local py = Spring.GetGroundHeight(px, pz)
			
			local fType = 'blank'
			if mazegrid[x][y] == blockStr
				
				--or mazegrid[x][y] == doorStr
				then
				
				fType = 'block'
				
				--createUnit[#createUnit+1] = { tiles[ mazegrid[x][y] ], px, py, pz, 0, teamID }
			end
			
			AddTerraBlock( px-lesshalfsize, pz-lesshalfsize,  px+lesshalfsize, pz+lesshalfsize, size )
			CreateMysteryBlock( px, py, pz, fType )
			
			
			
		end
	end
	
end

local function KillMazeBlocks()
	local allUnits = Spring.GetAllUnits()
	for _, unitID in ipairs(allUnits) do
		local udid = Spring.GetUnitDefID(unitID)
		local ud = UnitDefs[udid]
		if ud and ( ud.name == mazeBlock or ud.name == mazeDoor )then
		
			local x,y,z = Spring.GetUnitPosition(unitID)
			local size = ud.xsize
			size = size * 8
			local halfsize=size/2
			RemTerraBlock( x-halfsize, z-halfsize,  x+halfsize, z+halfsize )
			
			destroyUnit[#destroyUnit+1] = {unitID, false, true}
		end
	end
	local allFeatures = Spring.GetAllFeatures()
	for _, featureID in ipairs(allFeatures) do
		local fdid = Spring.GetFeatureDefID(featureID)
		local fd = FeatureDefs[fdid]
		if fd and (fd.name == 'mysteryblock_dead' or fd.name == 'block_dead' )then
			
			local x,y,z = Spring.GetFeaturePosition(featureID)
			local size = fd.xsize
			size = size * 8
			local halfsize=size/2
			RemTerraBlock( x-halfsize, z-halfsize,  x+halfsize, z+halfsize )
			
			DestroyFeature(featureID)
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


local function GetFeaturesInLos()
	local viewRad = 500
	local mainUnits = Spring.GetTeamUnits(0)
	local visFeatures = {}
	for _, unitID in ipairs(mainUnits) do
		local x,y,z = Spring.GetUnitPosition(unitID)
		local features = Spring.GetFeaturesInRectangle(x-viewRad, z-viewRad, x+viewRad, z+viewRad)
		for _, fID in ipairs(features) do
			local fx, fy, fz = Spring.GetFeaturePosition(fID)
			if Spring.IsPosInLos(fx, fy, fz, 0) then
				visFeatures[fID] = true
			end
		end
	end
	return visFeatures
end

local function ConvertBlock(featureID, toBlock)
	if toBlock == 'blank' then
		local x,y,z = Spring.GetFeaturePosition(featureID)
		local fdid = Spring.GetFeatureDefID(featureID)
		local fd = FeatureDefs[fdid]
		local size = fd.xsize
		size = size * 8
		local halfsize=size/2
		RemTerraBlock( x-halfsize, z-halfsize,  x+halfsize, z+halfsize )
	elseif toBlock == 'block' then
		local x,y,z = Spring.GetFeaturePosition(featureID)
		CreateUnit( mazeBlock, x, y, z, 0, Spring.GetGaiaTeamID() )
		--CreateFeature( 'block_dead', x, y, z, 0, Spring.GetGaiaTeamID() )
	end
	DestroyFeature(featureID)
end

local function CheckFeaturesInLos()
	local visFeatures = GetFeaturesInLos()
	for fID, _ in pairs(visFeatures) do
		if mysteryBlocks[fID] then
			ConvertBlock(fID, mysteryBlocks[fID])
			mysteryBlocks[fID] = nil
		end
	end
end

local function FixBlockPosition(unitID)
	local x,y,z = Spring.GetUnitPosition(unitID)
	MC.Enable(unitID)
	MC.SetPosition(unitID, x,groundHeight,z)
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
		local unitID = Spring.CreateUnit( data[1], data[2], data[3], data[4], data[5], data[6] )
		Spring.SetUnitNeutral(unitID, true)
		if data[7] then
			blocks[unitID] = data[7]
		end
	end
	createUnit = {}
	
	for _, data in ipairs( createFeature ) do
		local x,y,z = data[2], data[3], data[4]
		local fID = Spring.CreateFeature( data[1], x,y,z , data[5], data[6] )
		if data[7] then
			--Spring.SetFeaturePosition( fID, x, groundHeight, z, false )
			mysteryBlocks[fID] = data[7]
		end
	end
	createFeature = {}
	
	for _, data in ipairs( destroyUnit ) do
		Spring.DestroyUnit( data[1], data[2], data[3] )
	end
	destroyUnit = {}
	
	for _, data in ipairs( destroyFeature ) do
		Spring.DestroyFeature( data[1] )
	end
	destroyFeature = {}
	
	CheckFeaturesInLos()
	
end
--[[
local seenBlocks = {}
function gadget:UnitEnteredLos(unitID, unitTeam, allyTeam, unitDefID)
	
	local blockHeight = 200
	
	if unitDefID == UnitDefNames[mazeBlock].id and allyTeam == 0 and not seenBlocks[unitID] then
		local size = UnitDefNames[mazeBlock].xsize
		size = size * 8
		local halfsize = size / 2
		halfsize = halfsize * 0.90
		
		--echo 'block entered los'
		seenBlocks[unitID] = true
		local x, y, z = Spring.GetUnitPosition(unitID)
		Spring.LevelHeightMap( x-halfsize, z-halfsize, x+halfsize, z+halfsize, groundHeight+size )
	end
end
--]]

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitDefID == UnitDefNames[mazeBlock].id then
		FixBlockPosition(unitID)
	end
end

function gadget:FeatureCreated(featureID, allyTeam)
	--local x,y,z = Spring.GetFeaturePosition(featureID)
	--Spring.SetFeaturePosition( featureID, x, -62, z, false )
	
	-- [[
	local fdid = Spring.GetFeatureDefID(featureID)
	--local fd = FeatureDefs[fdid]
	
	if
		fdid == FeatureDefNames['mysteryblock_dead'].id
		or fdid == FeatureDefNames['block_dead'].id
		then
		
		local x,y,z = Spring.GetFeaturePosition(featureID)
		Spring.SetFeaturePosition( featureID, x, groundHeight, z, false )
	end
	
	if unitDefID == 'block_dead' then
		--Spring.SetFeatureAlwaysVisible(featureID)
	end
	--]]
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


