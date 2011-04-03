------------------------------------

include "anim_util.lua"


------------------------------------

local emit_summon = piece 'base' --fixme
local aimpoint = piece 'head' --fixme

------


local MOVEANIMATIONSPEED


local ATK_CHEST_SPEED_B = 150
local ATK_CHEST_SPEED_F = 400
local ATK_CHEST_SPEED_S = 400

local ATK_UPARM_SPEED_B = 450
local ATK_UPARM_SPEED_F = 400
local ATK_LOARM_SPEED_B = 450
local ATK_LOARM_SPEED_F = 400

local ATK_RHAND_SPEED_B = 450
local ATK_RHAND_SPEED_F = 400

local SUMMONING	 = 1024+0
local GREYCLOUD	 = 1025+0
local BURROWING	 = 1026+0

local echo = Spring.Echo


local function SetMoveAnimationSpeed()
	MOVEANIMATIONSPEED = GetUnitValue(COB.MAX_SPEED)/600
	
	--if statements inside walkscript contain wait functions that can take forever if speed is too slow
	if MOVEANIMATIONSPEED < 50 then 
		MOVEANIMATIONSPEED = 50
	end
end



-- Walk Motion
local function Walkscript()
	SetSignalMask(SIG_WALK)

	while true do
		if moving then
			SetMoveAnimationSpeed()
			
			if not attacking then
				
				Turn2( r_uarm, x_axis, 30, MOVEANIMATIONSPEED*1.2 )
				end
			Turn2( r_thigh, x_axis, -30, MOVEANIMATIONSPEED )
			Turn2( r_shin, x_axis, 40, MOVEANIMATIONSPEED*1.6 )
			Move( pelvis, y_axis, 0.3, 8 )
			WaitForTurn(l_thigh, x_axis)
			end
		if moving then
			SetMoveAnimationSpeed()
			if not attacking then
				
				Turn2( l_uarm, x_axis, -30, MOVEANIMATIONSPEED*1.2 )
				Turn2( torso, z_axis, -5, MOVEANIMATIONSPEED )
				Turn2( head, z_axis, 5, MOVEANIMATIONSPEED*0.3 )
				end
			Turn2( l_thigh, x_axis, 20, MOVEANIMATIONSPEED )
			Turn2( pelvis, z_axis, 10, MOVEANIMATIONSPEED*0.8 )
			Turn2( l_thigh, z_axis, -10, MOVEANIMATIONSPEED*0.8 )
			Turn2( r_thigh, z_axis, -10, MOVEANIMATIONSPEED*0.8 )
			WaitForTurn(r_shin, x_axis)
			end
		if moving then
			SetMoveAnimationSpeed()
			Turn2( r_shin, x_axis, 0, MOVEANIMATIONSPEED*1.6 )
			Move( pelvis, y_axis, 0, 8 )
			WaitForTurn(r_thigh, x_axis)
			end
		if moving then
			SetMoveAnimationSpeed()
			if not attacking then
				
				Turn2( l_uarm, x_axis, 30, MOVEANIMATIONSPEED*1.2 )
				Turn2( torso, z_axis, 5, MOVEANIMATIONSPEED )
				Turn2( head, z_axis, -5, MOVEANIMATIONSPEED*0.3 )
				end
			Turn2( r_thigh, x_axis, 20, MOVEANIMATIONSPEED )
			Turn2( pelvis, z_axis, -10, MOVEANIMATIONSPEED*0.8 )
			Turn2( l_thigh, z_axis, 10, MOVEANIMATIONSPEED*0.8 )
			Turn2( r_thigh, z_axis, 10, MOVEANIMATIONSPEED*0.8 )
			WaitForTurn(l_thigh, x_axis)
			end
		if moving then
			SetMoveAnimationSpeed()
			if not attacking then
				
				Turn2( r_uarm, x_axis, -30, MOVEANIMATIONSPEED*1.2 )
				end
			Turn2( l_thigh, x_axis, -30, MOVEANIMATIONSPEED )
			Turn2( l_shin, x_axis, 40, MOVEANIMATIONSPEED*1.6 )
			Move( pelvis, y_axis, 0.3, 8 )
			WaitForTurn(l_shin, x_axis)
			end
		if moving then 
			SetMoveAnimationSpeed()
			Turn2( l_shin, x_axis, 0, (MOVEANIMATIONSPEED*1.6) )
			Move( pelvis, y_axis, 0, 8 )
			WaitForTurn(r_thigh, x_axis)
			end

		if not moving then 
			SetMoveAnimationSpeed()
			Turn2( r_thigh, x_axis, 0, MOVEANIMATIONSPEED )
			Turn2( l_thigh, x_axis, 0, MOVEANIMATIONSPEED )
			Turn2( r_shin, x_axis, 0, MOVEANIMATIONSPEED*1.6 )
			Turn2( l_shin, x_axis, 0, MOVEANIMATIONSPEED*1.6 )
			Turn2( pelvis, z_axis, 0, MOVEANIMATIONSPEED*0.8 )
			Turn2( torso, z_axis, 0, MOVEANIMATIONSPEED )
			Turn2( l_thigh, z_axis, 0, MOVEANIMATIONSPEED*0.8 )
			Turn2( r_thigh, z_axis, 0, MOVEANIMATIONSPEED*0.8 )
			Move( pelvis, y_axis, 0, 8 )
			Turn2( head, z_axis, 0, MOVEANIMATIONSPEED*0.3 )
			end
		Sleep(10)
	end
end


------------------------ ACTIVATION



function script.Create()
	
	SetMoveAnimationSpeed()
	--Turn2( emit_summon, x_axis, -90 )
	StartThread( Walkscript )
end

function script.StartMoving()
	moving = true
end

function script.StopMoving()
 
	moving = false
end
  
local function RestoreAfterDelay()
	Sleep(restore_delay)
	Turn2( torso, y_axis, 0, 100 )
	Turn2( torso, x_axis, 0, 100 )
	Turn2( torso, z_axis, 0, 100 )
	return (0)
end



--weapon 1 -----------------------------------------------------------------

function script.QueryWeapon1 () return aimpoint end

function script.AimFromWeapon1 () return torso end

local function Aim(heading, pitch)
	Signal(SIG_AIM)
   	SetSignalMask(SIG_AIM)
 	Turn(torso, y_axis, heading, 8)
	WaitForTurn(torso, y_axis)
	RestoreAfterDelay()
   	return true
end
   
function script.AimWeapon1(heading, pitch)
   	return Aim(heading, pitch)
end
  
function script.Shot1()
	StartThread(Attack)
end
	
Attack=function()
		attacking=true
		Turn2( torso, x_axis, 0 )
--		Turn2( torso, y_axis, 0 )
		Turn2( torso, z_axis, 0 )
		
		--lean back
		Turn2( torso, x_axis, -25, ATK_CHEST_SPEED_B )
		
		--attack
		Turn2( torso, x_axis, 22.5, ATK_CHEST_SPEED_F )
--		Turn2( torso, y_axis, -10, ATK_CHEST_SPEED_S		 )
		
		
		
		--back to null position
--		Turn2( torso, x_axis, 0, ATK_CHEST_SPEED_B )
		Turn2( torso, y_axis, 0, ATK_CHEST_SPEED_B )
		
		WaitForTurn(torso, x_axis)
--		WaitForTurn(torso, y_axis)
		WaitForTurn(torso, z_axis)
		
		attacking=false
		return(1)
end

function script.HitByWeapon( x, z, weaponDefID, damage ) 
	if damage > 5 then
		--EmitSfx( torso, 1024+1)
	end
end


function script.Killed( damage, health )
		Turn2( pelvis, x_axis, 90, 22 )
		Turn2( l_uarm, x_axis, -137, 15 )
		Turn2( r_uarm, x_axis, 170, 15 )
		Turn2( r_thigh, x_axis, 21, 15 )
		Turn2( r_thigh, z_axis, -64, 15 )
		Turn2( r_shin, z_axis, 252, 15 )
		Move( base, y_axis, -2.6, 4.5 )
--		WaitForTurn(pelvis, x_axis)
		--EmitSfx(pelvis,GREYCLOUD)
		--EmitSfx(head,GREYCLOUD)
		return (1)
end