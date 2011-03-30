function gadget:GetInfo()
	return {
		name = "No Sharing",
		desc = "Prevent all voluntary sharing of units",
		author = "KDR_11k (David Becker)",
		date = "2009-03-06",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

if (gadgetHandler:IsSyncedCode()) then

--SYNCED

function gadget:AllowUnitTransfer(u, ud, team, newteam, capture)
	return capture
end

else

--UNSYNCED

return false

end
