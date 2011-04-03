-------------------------

echo = Spring.Echo

-- this populates global namespace with all the piece names
for k, v in pairs(Spring.GetUnitPieceMap(unitID)) do
    _G[k] = v
    -- auto-hide flares
    if string.find(k, 'flare', 1, true) then
        Hide(v)
    end
end

SIG_WALK 	= 2
SIG_AIM 	= 4
SIG_AIM_2	= 8
SIG_AIM_3	= 16
SIG_RESTORE	= 32

mounted 	= false
moving 		= false
attacking	= false

restore_delay 	= 3000

local COBRATIO = 1/30*65535

function Turn2(piecenum,axis, degrees, speed)
	local radians = degrees * 3.1415 / 180
	if speed then
		local speed1 = speed * 3.1415 / 180
		Turn(piecenum, axis, radians, speed1) 
	else
		Turn(piecenum, axis, radians ) 
	end
end

MOVEANIMSPEED_ORIG = 1
MOVEANIMSPEED = 1
function SetMoveAnimationSpeed()
	MOVEANIMSPEED = GetUnitValue(COB.MAX_SPEED) * MOVEANIMSPEED_ORIG / COBRATIO
	
	--if statements inside walkscripts contain wait functions that can take forever if speed is too slow
	if MOVEANIMSPEED < 0.1 then 
		MOVEANIMSPEED = 0.1
	end
	
end

function BuildBigDirt()
	BuildDirt('dirt3')
end
function BuildSmallDirt()
	BuildDirt('dirt')
end

function BuildDirt(ceg)
	local x,y,z = Spring.GetUnitPosition(unitID)
	local buildProgress = 0
	while buildProgress < 1 do
		Spring.SpawnCEG( ceg, x,y,z )
		Sleep(500)
		buildProgress = select(5, Spring.GetUnitHealth(unitID) )
	end
	
end


parry = {}
for i=1,#WeaponDefs do
    --echo (WeaponDefs[i].description, WeaponDefs[i].name)
    if WeaponDefs[i].description:find('Sword') then
        parry[i] = true
    end
end
