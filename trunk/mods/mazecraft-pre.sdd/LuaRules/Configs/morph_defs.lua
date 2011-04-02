--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local devolution = false


local morphDefs = {

 

  --[[ // sample definition1 with multiple possible morphs... you nest arrays inside the definition
  armcom = {
    {
      into = 'armcomdgun',
      time = 20,
      metal = 10,
      energy = 10,
      tech = 1,
      xp = 0,
    },
    {
      into = 'corcom',
      time = 20,
      metal = 10,
      energy = 10,
      tech = 1,
      xp = 0,
    },
  }
  --]]
  
    
  
  --]]
}


local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

--[[
if (modOptions and modOptions.commtype == 'default') then
  morphDefs.corcom = {
    into = 'corcomdgun',
    time = 40,
	metal = 800,
	energy = 800,
    rank = 0,
  }

end
--]]



--
-- Here's an example of why active configuration
-- scripts are better then static TDF files...
--

--
-- devolution, babe  (useful for testing)
--
if (devolution) then
  local devoDefs = {}
  for src,data in pairs(morphDefs) do
    devoDefs[data.into] = { into = src, time = 10, metal = 1, energy = 1 }
  end
  for src,data in pairs(devoDefs) do
    morphDefs[src] = data
  end
end


return morphDefs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
