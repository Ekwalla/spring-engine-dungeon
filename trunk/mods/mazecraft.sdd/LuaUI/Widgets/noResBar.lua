function widget:GetInfo()
	return {
		name = "noResBar",
		desc = "Removes the res bar",
		author = "KDR_11k (David Becker)",
		date = "2007-11-18",
		license = "Public Domain",
		layer = 1,
		enabled = true
	}
end

function widget:Initialize()
	Spring.SendCommands({"resbar 0"})
	widgetHandler:RemoveWidget()
end
