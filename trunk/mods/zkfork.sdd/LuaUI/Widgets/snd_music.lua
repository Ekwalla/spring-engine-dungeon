--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--	file:		gui_music2.lua
--	brief:	yay music
--	author:	cake
--
--	Copyright (C) 2007.
--	Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name			= "Music Player",
		desc			= "Plays music based on situation",
		author		= "cake, trepan, Smoth, Licho",
		date			= "Mar 01, 2008, Aug 20 2009",
		license	= "GNU GPL, v2 or later",
		layer		= 0,
		enabled	= true	--	loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local unitExceptions = include("Configs/snd_music_exception.lua")

local windows = {}

local WAR_THRESHOLD = 5000
local PEACE_THRESHOLD = 1000

local musicType = 'peace'
local dethklok = {} -- keeps track of the number of doods killed in each time frame
local timeframetimer = 0
local lastTrack = ''
local lastTrackType = ''
local newTrackWait = 1000
local numVisibleEnemy = 0
local fadeVol
local curTrack	= "no name"
local songText	= "no name"

local warTracks		=	VFS.DirList('sounds/music/war/', '*.ogg')
local peaceTracks	=	VFS.DirList('sounds/music/peace/', '*.ogg')


local firsttime = true
local firstFade = true
local initTrack
	
initTrack = peaceTracks[math.random(1, #peaceTracks)]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	-- Spring.Echo(math.random(), math.random())
	-- Spring.Echo(os.clock())
 
	-- for TrackName,TrackDef in pairs(peaceTracks) do
		-- Spring.Echo("Track: " .. TrackDef)	
	-- end
	math.randomseed(os.clock()* 101.01)--lurker wants you to burn in hell rgn
	-- for i=1,20 do Spring.Echo(math.random()) end
	
	for i = 1, 30, 1 do
		dethklok[i]=0
	end
end



function widget:Shutdown()
	Spring.StopSoundStream()
	
	for i=1,#windows do
		(windows[i]):Dispose()
	end
end

function widget:Update(dt)
	if (Spring.GetGameSeconds() < 3) then
		dethklok[1] = 0
	else
		timeframetimer = timeframetimer + dt
		if (timeframetimer > 1) then	-- every second
			timeframetimer = 0
			newTrackWait = newTrackWait + 1

			local PlayerTeam = Spring.GetMyTeamID()
			numVisibleEnemy = 0
			local doods = Spring.GetVisibleUnits()
		for _, u in ipairs(doods) do
			if (Spring.IsUnitAllied(u) ~= true) then
				numVisibleEnemy = numVisibleEnemy + 1
			end
		end
			
		totalKilled = 0
		for i = 1, 10, 1 do
			totalKilled = totalKilled + (dethklok[i] * 2)
		end
		
		for i = 11, 20, 1 do
			totalKilled = totalKilled + dethklok[i]
		end
		
		for i = 20, 1, -1 do
			dethklok[i+1] = dethklok[i]
		end
		dethklok[1] = 0
		
		--Spring.Echo (totalKilled)
		
		if (totalKilled > WAR_THRESHOLD) then
			musicType = 'war'
		end
		
		if (totalKilled <= PEACE_THRESHOLD) then
			musicType = 'peace'
		end
		
		if (firsttime) then
			Spring.PlaySoundStream(initTrack,WG.music_volume or 0.5) --init to something
			WG.music_start_volume = WG.music_volume
			firsttime = false -- pop this cherry	
		end
		
		local playedTime, totalTime = Spring.GetSoundStreamTime()
		playedTime = math.floor(playedTime)
		totalTime = math.floor(totalTime)
		
		--Spring.Echo(playedTime, totalTime, newTrackWait)
		
			--if((totalTime - playedTime) <= 6 and (totalTime >= 1) ) then
				--Spring.Echo("time left:", (totalTime - playedTime))
				--Spring.Echo("volume:", (totalTime - playedTime)/6)
				--if ((totalTime - playedTime)/6 >= 0) then
				--	Spring.SetSoundStreamVolume((totalTime - playedTime)/6)
				--else
				--	Spring.SetSoundStreamVolume(0.1)
				--end
			--elseif(playedTime <= 5 )then--and not firstFade
				--Spring.Echo("time playing:", playedTime)
				--Spring.Echo("volume:", playedTime/5)
				--Spring.SetSoundStreamVolume( playedTime/5)
			--end
		

			if ( (musicType ~= lastTrackType and musicType == 'war') or (playedTime > totalTime)	) then
				lastTrackType = musicType
				local newTrack
				repeat
				if musicType == 'peace' then
					newTrack = peaceTracks[math.random(1, #peaceTracks)]
				elseif musicType == 'war' then
					newTrack = warTracks[math.random(1, #warTracks)]
				end
				until newTrack ~= lastTrack
				
				-- for key, val in pairs(oggInfo) do
					-- Spring.Echo(key, val)	
				-- end
				firstFade = false
				lastTrack = newTrack
				
				-- if (oggInfo.comments.TITLE and oggInfo.comments.TITLE) then
					-- Spring.Echo("Song changed to: " .. oggInfo.comments.TITLE .. " By: " .. oggInfo.comments.ARTIST)
				-- else
					-- Spring.Echo("Song changed but unable to get the artist and title info")
				-- end
				curTrack = newTrack
				Spring.PlaySoundStream(newTrack,WG.music_volume or 0.5)
				WG.music_start_volume = WG.music_volume
				
				--Spring.Echo("Track: " .. newTrack)
				newTrackWait = 0
			end
		end
	end
end

function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if unitExceptions[unitDefID] then
		return
	end
	
	if (damage < 1.5) then return end
	local PlayerTeam = Spring.GetMyTeamID()
	
	if (UnitDefs[unitDefID] == nil) then return end
		
	if paralyzer then
		return
	else
		if (teamID == PlayerTeam) then
			damage = damage * 1.5
		end
		local multifactor = 1
		if (numVisibleEnemy > 3) then
			multifactor = math.log(numVisibleEnemy)
		end
		dethklok[1] = dethklok[1] + (damage * multifactor);
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID) 
	if unitExceptions[unitDefID] then
		return
	end
	local unitWorth = 50
	if (UnitDefs[unitDefID].metalCost > 500) then
		unitWorth = 200
	end
	if (UnitDefs[unitDefID].metalCost > 1000) then
		unitWorth = 300
	end
	if (UnitDefs[unitDefID].metalCost > 3000) then
		unitWorth = 500
	end
	if (UnitDefs[unitDefID].metalCost > 8000) then
		unitWorth = 700
	end
	if (teamID == PlayerTeam) then
		unitWorth = unitWorth * 1.5
	end
	local multifactor = 1
	if (numVisibleEnemy > 3) then
		multifactor = math.log(numVisibleEnemy)
	end
	dethklok[1] = dethklok[1] + (unitWorth*multifactor);
end




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------