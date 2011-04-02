--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Chili Cursor Tip 2",
    desc      = "v0.102 Chili Cursor Tooltips.",
    author    = "CarRepairer",
    date      = "2009-06-02",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = true,
  }
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetCurrentTooltip		= Spring.GetCurrentTooltip
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetFeatureDefID			= Spring.GetFeatureDefID
local spGetFeatureTeam			= Spring.GetFeatureTeam
local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spGetUnitTeam				= Spring.GetUnitTeam
local spGetUnitHealth			= Spring.GetUnitHealth
local spGetUnitResources		= Spring.GetUnitResources
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetTeamColor			= Spring.GetTeamColor
local spGetUnitTooltip			= Spring.GetUnitTooltip
local spGetModKeyState			= Spring.GetModKeyState
local spGetMouseState			= Spring.GetMouseState
local spSendCommands			= Spring.SendCommands
local spGetUnitIsStunned		= Spring.GetUnitIsStunned
local spGetUnitResources		= Spring.GetUnitResources

local abs						= math.abs
local strFormat 				= string.format

local echo = Spring.Echo

local iconFormat = ''

local iconTypesPath = LUAUI_DIRNAME.."Configs/icontypes.lua"
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)

local color = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


include("keysym.h.lua")
local tildepressed, drawing, erasing
local glColor		= gl.Color
--local glAlphaTest	= gl.AlphaTest
local glTexture 	= gl.Texture
local glTexRect 	= gl.TexRect

-- pencil and eraser
local cursor_size = 24

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local StackPanel
local Panel
local Grid
local TextBox
local Image
local Multiprogressbar
local Progressbar
local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local B_HEIGHT = 30
local icon_size = 20
local stillCursorTime = 0

local scrH, scrW = 0,0
local cycle = 0
local old_ttstr, old_data
local old_mx, old_my = -1,-1
local mx, my = -1,-1
local showExtendedTip = false
local changeNow = false

local window_tooltip2
local windows = {}
--local tt_buildpic
local tt_healthbar, tt_unitID, tt_fid, tt_ud, tt_fd
local controls = {}
local controls_icons = {}

local stack_main, stack_leftbar
local globalitems = {}

local ttFontSize = 2

local green = '\255\1\255\1'
local cyan = '\255\1\255\255'
local white = '\255\255\255\255'


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[[
local function StaticChanged() 
	if (window_tooltip2) then
		window_tooltip2:Dispose()
	end
	
	Initialize()
end 
--]]
options_path = 'Settings/Interface/Tooltip'
--options_order = { 'tooltip_delay',  'statictip', 'fontsize', 'staticfontsize', 'hpshort'}
options_order = { 'tooltip_delay',  'fontsize', 'hpshort', 'featurehp', 'hide_for_unreclaimable', 'showdrawtooltip',  }

options = {
	tooltip_delay = {
		name = 'Tooltip display delay (0 - 4s)',
		desc = 'Determines how long you can leave the mouse idle until the tooltip is displayed.',
		type = 'number',
		min=0,max=4,step=0.1,
		value = 0,
	},
	fontsize = {
		name = 'Font Size (10-20)',
		desc = 'Resizes the font of the tip',
		type = 'number',
		min=10,max=20,step=1,
		value = 10,
		OnChange = FontChanged,
	},
	--[[
	staticfontsize = {
		name = 'Static Display Font Size (10-30)',
		desc = 'Resizes the font for the static display of group and terrain information',
		type = 'number',
		min=10,max=30,step=2,
		value = 10,
		OnChange = FontChanged,
	},
	statictip = {
		name = "Static Tooltip",
		type = 'bool',
		value = false,
		desc = 'Makes the tooltip static and moveable',
		OnChange = StaticChanged,
	},
	--]]
	hpshort = {
		name = "HP Short Notation",
		type = 'bool',
		value = false,
		desc = 'Shows short number for HP.',
	},
	featurehp = {
		name = "Show HP on Features",
		type = 'bool',
		advanced = true,
		value = false,
		desc = 'Shows healthbar for features.',
		OnChange = function() 
			--fixme: dispose?
			controls['feature']=nil; 
			controls['corpse']=nil; 
		end,
	},
	hide_for_unreclaimable = {
		name = "Hide Tooltip for Unreclaimables",
		type = 'bool',
		advanced = true,
		value = true,
		desc = 'Don\'t show the tooltip for unreclaimable features.',
	},
	showdrawtooltip = {
		name = "Show Map-drawing Tooltip",
		type = 'bool',
		value = true,
		desc = 'Show map-drawing tooltip when holding down ~.',
	},


  groupalways = {name='Always Group Units', type='bool', value=false, OnChange = option_Deselect},
  showgroupinfo = {name='Show Group Info', type='bool', value=true, OnChange = option_Deselect},
  squarepics = {name='Square Buildpics', type='bool', value=true, OnChange = option_Deselect},
  hpshort = {
		name = "HP Short Notation",
		type = 'bool',
		value = false,
		desc = 'Shows short number for HP.',
	},
}

local updateFrequency = 0.2


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function FontChanged() 
	controls = {}
	controls_icons = {}
	ttFontSize = options.fontsize.value
	--gFontSize = options.staticfontsize.value - ttFontSize
end


options.fontsize.OnChange = FontChanged
--options.staticfontsize.OnChange = FontChanged

function comma_value(amount, displayPlusMinus)
	local formatted

	-- amount is a string when ToSI is used before calling this function
	if type(amount) == "number" then
		if (amount ==0) then formatted = "0" else 
			if (amount < 20 and (amount * 10)%10 ~=0) then 
				if displayPlusMinus then formatted = strFormat("%+.1f", amount)
				else formatted = strFormat("%.1f", amount) end 
			else 
				if displayPlusMinus then formatted = strFormat("%+d", amount)
				else formatted = strFormat("%d", amount) end 
			end 
		end
	else
		formatted = amount .. ""
	end

	if options.hpshort.value then 
		local k
		while true do  
			formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then
				break
			end
		end
	end 
  	return formatted
end

--from rooms widget by quantum
local function ToSI(num)
  if type(num) ~= 'number' then
	return 'Tooltip wacky error #55'
  end
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 0.001) then
      return strFormat("%.1fu", 1000000 * num)
    elseif (absNum < 1) then
      return strFormat("%.1f", num)
    elseif (absNum < 1000) then
	  return strFormat("%.0f", num)
    elseif (absNum < 1000000) then
      return strFormat("%.1fk", 0.001 * num)
    else
      return strFormat("%.1fM", 0.000001 * num)
    end
  end
end
local function ToSIPrec(num) -- more presise
  if type(num) ~= 'number' then
	return 'Tooltip wacky error #56'
  end
  if not options.hpshort.value then 
	return num
  end 
  if (num == 0) then
    return "0"
  else
    local absNum = abs(num)
    if (absNum < 0.001) then
      return strFormat("%.2fu", 1000000 * num)
    elseif (absNum < 1) then
      return strFormat("%.2f", num)
    elseif (absNum < 1000) then
      return strFormat("%.1f", num)
    elseif (absNum < 1000000) then
      return strFormat("%.2fk", 0.001 * num)
    else
      return strFormat("%.2fM", 0.000001 * num)
    end
  end
end

local function numformat(num, displayPlusMinus)
	return comma_value(ToSIPrec(num), displayPlusMinus)
end


local function AdjustWindow(window)
	local nx
	if (0 > window.x) then
		nx = 0
	elseif (window.x + window.width > screen0.width) then
		nx = screen0.width - window.width
	end

	local ny
	if (0 > window.y) then
		ny = 0
	elseif (window.y + window.height > screen0.height) then
		ny = screen0.height - window.height
	end

	if (nx or ny) then
		window:SetPos(nx,ny)		
	end

	--//FIXME If we don't do this the stencil mask of stack_rightside doesn't get updated, when we move the mouse (affects only if type(stack_rightside) == StackPanel)
	stack_main:Invalidate()
	stack_leftbar:Invalidate()
	
	if window_tooltip2:GetChildByName('leftbar') then
		window_tooltip2:GetChildByName('leftbar'):Invalidate()
	end
	window_tooltip2:GetChildByName('main'):Invalidate()
	
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetUnitDesc(unitID, ud)
	if not (unitID or ud) then return '' end
	
	local lang = WG.lang or 'en'
	if lang == 'en' then 
		return unitID and spGetUnitTooltip(unitID) or ud.tooltip
	end
	local suffix = ('_' .. lang)
	local desc = ud.customParams and ud.customParams['description' .. suffix] or ud.tooltip or 'Description error'
	if unitID then
		local endesc = ud.tooltip
		return spGetUnitTooltip(unitID):gsub(endesc, desc)
	end
	return desc
end

local UnitDefByHumanName_cache = {}
local function GetUnitDefByHumanName(humanName)
	local cached_udef = UnitDefByHumanName_cache[humanName]
	if (cached_udef ~= nil) then
		return cached_udef
	end

	for _,ud in pairs(UnitDefs) do
		if ud.humanName == humanName then
			UnitDefByHumanName_cache[humanName] = ud
			return ud
		end
	end
	UnitDefByHumanName_cache[humanName] = false
	return false
end

local function tooltipBreakdown(tooltip)
	local unitname = nil
	tooltip = tooltip:gsub('\r', '\n')
	tooltip = tooltip:gsub('\n+', '\n')
	
	local requires, provides, consumes, unitDef, buildType, morph_data
	if tooltip:find('Requires', 5, true) == 5 then
		requires, tooltip = tooltip:match('....Requires([^\n]*)\n....(.*)')
	end
	
	if tooltip:find('Provides', 1, true) == 1 then
		provides, tooltip = tooltip:match('Provides([^\n]*)\n(.*)')
	end
	
	if tooltip:find('Consumes', 5, true) == 5 then
		--consumes, tooltip = tooltip:match('....Consumes([^\n]*)\n....(.*)')
	end
	
	if tooltip:find('Build', 1, true) == 1 then
		local start,fin = tooltip:find([[ - ]], 1, true)
		if start and fin then
			
			local unitHumanName
			
			if (tooltip:find('Build Unit:', 1, true) == 1) then
				buildType = 'buildunit'
				unitHumanName = tooltip:sub(13,start-1)
			else
				buildType = 'build'
				unitHumanName = tooltip:sub(8,start-1)
			end
			unitDef = GetUnitDefByHumanName(unitHumanName)
			
			tooltip = tooltip:sub(fin+1)
		end
		
	elseif tooltip:find('Morph', 1, true) == 1 then
		
		local unitHumanName = tooltip:gsub('Morph into a (.*)(time).*', '%1'):gsub('[^%a \-]', '')
		unitDef = GetUnitDefByHumanName(unitHumanName)
		
		local needunit
		if tooltip:find('needs unit', 1, true) then
  			needunit = tooltip:gsub('.*needs unit: (.*)', '%1'):gsub('[^%a \-]', '')
		end
		morph_data = {
			morph_time 		= tooltip:gsub('.*time:(.*)metal.*', '%1'):gsub('[^%d]', ''),
			morph_cost 		= tooltip:gsub('.*metal: (.*)energy.*', '%1'):gsub('[^%d]', ''),
			morph_prereq 	= needunit,
		}
	end
	
	return {
		tooltip		= tooltip, 
		unitDef		= unitDef, 
		buildType	= buildType, 
		morph_data	= morph_data,
		requires	= requires,
		provides	= provides,
		consumes	= consumes,
	}
end

----------------------------------------------------------------

local function SetHealthbar()
	if 
		not ( tt_unitID or tt_fid )
		then 
		return 'err' 
	end
	
	local tt_healthbar
	
	local health, maxhealth
	if tt_unitID then
		health, maxhealth = spGetUnitHealth(tt_unitID)
		tt_healthbar = globalitems.hp_unit
	elseif tt_fid then
		health, maxhealth = Spring.GetFeatureHealth(tt_fid)
		tt_healthbar = tt_ud and globalitems.hp_corpse or globalitems.hp_feature
	end
	
	if health then
		tt_healthbar.color = {0,1,0, 1}
		
		tt_health_fraction = health/maxhealth
		tt_healthbar:SetValue(tt_health_fraction)
		if options.hpshort.value then
			tt_healthbar:SetCaption(numformat(health) .. ' / ' .. numformat(maxhealth))
		else
			tt_healthbar:SetCaption(math.ceil(health) .. ' / ' .. math.ceil(maxhealth))
		end
		
	else
		tt_healthbar.color = {0,0,0.5, 1}
		local maxhealth = (tt_fd and tt_fd.health) or (tt_ud and tt_ud.health) or 0
		tt_healthbar:SetValue(1)
		if options.hpshort.value then
			tt_healthbar:SetCaption('??? / ' .. numformat(maxhealth))
		else
			tt_healthbar:SetCaption('??? / ' .. math.ceil(maxhealth))
		end
	end
end


local function KillTooltip(force)
	--[[
	if options.statictip.value and not force then
		return
	else
	--]]
		old_ttstr = ''
		tt_unitID = nil
	--end
	
	if window_tooltip2 and window_tooltip2:IsDescendantOf(screen0) then
		screen0:RemoveChild(window_tooltip2)
	end
end

local function UpdateResourceStack(tooltip_type, unitID, ud, tooltip, fontSize)

	local stack_children = {}

	local metal, energy = 0,0
	local color_m = {1,1,1,1}
	local color_e = {1,1,1,1}
	
	local resource_tt_name = 'resources_' .. tooltip_type
	
	if tooltip_type == 'feature' or tooltip_type == 'corpse' then
		metal = ud.metal
		energy = ud.energy
		
		if unitID then
			local m, _, e, _, _ = Spring.GetFeatureResources(unitID)
			metal = m or metal
			energy =  e or energy
		end
	else --tooltip_type == 'unit'
		local metalMake, metalUse, energyMake, energyUse = Spring.GetUnitResources(unitID)
		
		if metalMake then
			metal = metalMake - metalUse
		end
		if energyMake then
			energy = energyMake - energyUse
		end
		
		-- special cases for mexes
		if ud.name=='cormex' then 
			local baseMetal = 0
			local s = tooltip:match("Makes: ([^ ]+)")
			if s ~= nil then baseMetal = tonumber(s) end 
							
			s = tooltip:match("Overdrive: %+([0-9]+)")
			local od = 0
			if s ~= nil then od = tonumber(s) end
			
			metal = metal + baseMetal + baseMetal * od / 100
			
			s = tooltip:match("Energy: ([^ \n]+)")
			s = tonumber(s)
			if s ~= nil and type(s) == 'number' then 
				energy = energy + tonumber(s)
			end 
		end 
		
	end
	
	if tooltip_type == 'feature' or tooltip_type == 'corpse' then
		color_m = {1,1,1,1}
		color_e = {1,1,1,1}
	else
		if metal > 0 then
			color_m = {0,1,0,1}
		elseif metal < 0 then
			color_m = {1,0,0,1}
		end
		if energy > 0 then
			color_e = {0,1,0,1}
		elseif energy < 0 then
			color_e = {1,0,0,1}
		end
	end
	
	if globalitems[resource_tt_name] then
		local metalcontrol 	= globalitems[resource_tt_name]:GetChildByName('metal')
		local energycontrol = globalitems[resource_tt_name]:GetChildByName('energy')
		
		metalcontrol.font:SetColor(color_m)
		energycontrol.font:SetColor(color_e)
		
		metalcontrol:SetCaption( numformat(metal, true) )
		energycontrol:SetCaption( numformat(energy, true) )
		return
	end
	
	local lbl_metal2 = Label:New{ name='metal', caption = numformat(metal, true), autosize=true, fontSize=fontSize, valign='center' }
	local lbl_energy2 = Label:New{ name='energy', caption = numformat(energy, true), autosize=true, fontSize=fontSize, valign='center'  }
	
	globalitems[resource_tt_name] = StackPanel:New{
		centerItems = false,
		autoArrangeV = true,
		orientation='horizontal',
		resizeItems=false,
		width = '100%',
		height = icon_size+1,
		padding = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin = {5,0,0,0},
		children = {
			Image:New{file='LuaUI/images/ibeam.png',height= icon_size,width= icon_size, fontSize=ttFontSize,},
			lbl_metal2,
			Image:New{file='LuaUI/images/energy.png',height= icon_size,width= icon_size, fontSize=ttFontSize,},
			lbl_energy2,
		},
	}
end

local function PlaceToolTipWindow2(x,y)
	if not window_tooltip2 then return end
	
	if not window_tooltip2:IsDescendantOf(screen0) then
		screen0:AddChild(window_tooltip2)
	end
	--if not options.statictip.value then
		local x = x
		local y = scrH-y
		window_tooltip2:SetPos(x,y)
		AdjustWindow(window_tooltip2)
	--end

	window_tooltip2:BringToFront()
end

local function UpdateMorphControl(morph_data)
	
	local morph_controls = {}
	
	local height = 0
	
	local morph_time 	= ''
	local morph_cost 	= ''
	local morph_prereq 	= ''
	if morph_data then
		morph_time 	= morph_data.morph_time
		morph_cost 	= morph_data.morph_cost
		morph_prereq 	= morph_data.morph_prereq
		height = icon_size+1
		
	end	
	if globalitems.morphs then
		globalitems.morphs.height=height
		
		globalitems.morphs:GetChildByName('time'):SetCaption(morph_time)
		globalitems.morphs:GetChildByName('cost'):SetCaption(morph_cost)
		globalitems.morphs:GetChildByName('prereq'):SetCaption(morph_prereq and ('Need Unit: '..morph_prereq) or '')
		
		--[[
		globalitems.morphs:GetChildByName('time').height=height
		globalitems.morphs:GetChildByName('time'):Invalidate()
		globalitems.morphs:Invalidate()
		globalitems.morphs:UpdateLayout()
		--]]
		return
	end
	height = icon_size+1
	
	morph_controls[#morph_controls + 1] = Label:New{ caption = 'Morph: ', height= icon_size, valign='center', textColor=color.tooltip_info, autosize=false, width=45, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Image:New{file='LuaUI/images/clock.png',height= icon_size,width= icon_size, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Label:New{ name='time', caption = morph_time, valign='center', textColor=color.tooltip_info, autosize=false, width=25, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Image:New{file='LuaUI/images/ibeam.png',height= icon_size,width= icon_size, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Label:New{ name='cost', caption = morph_cost, valign='center', textColor=color.tooltip_info, autosize=false, width=25, fontSize=ttFontSize,}
	
	--if morph_prereq then
		--morph_controls[#morph_controls + 1] = Label:New{ 'prereq' caption = 'Need Unit: '..morph_prereq, valign='center', textColor=color.tooltip_info, autosize=false, width=180, fontSize=ttFontSize,}
		morph_controls[#morph_controls + 1] = Label:New{ name='prereq', caption = morph_prereq and ('Need Unit: '..morph_prereq) or '', valign='center', textColor=color.tooltip_info, autosize=false, width=80, fontSize=ttFontSize,}
	--end
	
	
	globalitems.morphs = StackPanel:New {
		centerItems = false,
		autoArrangeV = true,
		orientation='horizontal',
		resizeItems=false,
		width = '100%',
		height = height,
		padding = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin = {0,0,0,0},
		children = morph_controls,
	}
end


local function GetHelpText(tooltip_type)
	local _,_,_,buildUnitName = Spring.GetActiveCommand()
	if buildUnitName then
		return ''
	end

	local sc_caption = ''
	if tooltip_type == 'build' then
		sc_caption = 'Space+click: Show unit stats'
	elseif tooltip_type == 'buildunit' then
			if showExtendedTip then
			
				sc_caption = 
					'Shift+click: x5 multiplier.\n'..
					'Ctrl+click: x20 multiplier.\n'..
					'Alt+click: Add units to front of queue. \n'..
					'Rightclick: remove units from queue.\n'..
					'Space+click: Show unit stats'
			else
				sc_caption = '(Hold Spacebar for help)'
			end
	
	elseif tooltip_type == 'morph' then
		sc_caption = 'Space+click: Show unit stats'
	else
		sc_caption = 'Space+click: Show unit stats'
	end
	--return TextBox:New{ text = sc_caption, textColor=color.tooltip_help, width=250, fontSize=ttFontSize,  }
	return sc_caption
	
end

local function MakeStack(ttname, ttstackdata, leftbar)
	local children = {}
	local height = 0
	
	for i, item in ipairs( ttstackdata ) do
		local stack_children = {}
		local empty = false
		
		if item.directcontrol then
			local directitem = globalitems[item.directcontrol]
			stack_children[#stack_children+1] = directitem

		elseif item.text or item.icon then
			local curFontSize = ttFontSize + (item.fontSize or 0)
			local itemtext =  item.text or ''
			local stackchildren = {}

			if item.icon then
				controls_icons[ttname][item.name] = Image:New{ file = item.icon, height= icon_size,width= icon_size, fontSize=curFontSize,}
				stack_children[#stack_children+1] = controls_icons[ttname][item.name]
			end
			
			if item.wrap then
				controls[ttname][item.name] = TextBox:New{
					name=item.name, 				
					autosize=false,
					text = itemtext , 
					width='100%', 
					valign="ascender", 
					font={ size=curFontSize }, 
					fontShadow=true,
				}
				stack_children[#stack_children+1] = controls[ttname][item.name]
			else
				local rightmargin = item.icon and icon_size or 0
				local width = (leftbar and 50 or 230) - rightmargin
				
				--controls[ttname][item.name] = Label:New{ autosize=false, name=item.name, caption = itemtext, fontSize=curFontSize, valign='center', height=icon_size+5, width = width }
				controls[ttname][item.name] = Label:New{ fontShadow=true, defaultHeight=0, autosize=true, name=item.name, caption = itemtext, fontSize=curFontSize, valign='center', height=icon_size+5, x=icon_size+5, right=1,}
				stack_children[#stack_children+1] = controls[ttname][item.name]
			end
			
			if (not item.icon) and itemtext == '' then
				controls[ttname][item.name]:Resize('100%',0)
			end
			
			
		else
			empty = true
		end
		
		if not empty then
			children[#children+1] = StackPanel:New{
				centerItems = false,
				autoArrangeV = true,
				orientation='horizontal',
				resizeItems=false,
				width = '100%',
				autosize=true,
				padding = {1,1,1,1},
				itemPadding = {0,0,0,0},
				itemMargin = {4,0,0,0},
				children = stack_children,
			}
		end
	end
	return children
end

local function UpdateStack(ttname, stack)
	for i, item in ipairs( stack ) do
		local name = item.name
		
			if item.directcontrol then
				--local directitem = (type( item.directcontrol ) == 'string') and globalitems[item.directcontrol] or item.directcontrol
				local directitem = globalitems[item.directcontrol]
				--[[
				if hideitems[item.directcontrol] then
					directitem:Resize('100%',0)
				else
					directitem:Resize('100%',globalitemheights[item.directcontrol])
				end
				--]]
			end
			if controls[ttname][name] then			
				if item.wrap then	
					controls[ttname][name]:SetText( item.text )
					controls[ttname][name]:Invalidate()
				else
					controls[ttname][name]:SetCaption( item.text )
				end
			end
			if controls_icons[ttname][name] then
				if item.icon then
					controls_icons[ttname][name].file = item.icon
					controls_icons[ttname][name]:Invalidate()
				end
			end
		
	end
	
end

local function SetTooltip(tt_window)
	
	--if options.statictip.value then
	--else
		if not window_tooltip2 or window_tooltip2 ~= tt_window then
			KillTooltip(true)
			window_tooltip2 = tt_window
		end
		PlaceToolTipWindow2(mx+20,my-20)
	--end
end

local function BuildTooltip2(ttname, ttdata)
	if not ttdata.main then
		echo '<Cursortip> Missing ttdata.main'
		return
	end
	if controls[ttname] then
		UpdateStack(ttname, ttdata.main)
		if ttdata.leftbar then
			UpdateStack(ttname, ttdata.leftbar)
		end
	else
	
		controls[ttname] = {}
		controls_icons[ttname] = {}
		local stack_leftbar_temp, stack_main_temp
		local children_main  = MakeStack(ttname, ttdata.main)
		local leftside = false
		if ttdata.leftbar then
			children_leftbar  = MakeStack(ttname, ttdata.leftbar)
			
			stack_leftbar_temp = 
				StackPanel:New{
					name = 'leftbar',
					orientation='vertical',
					padding = {0,0,0,0},
					itemPadding = {1,0,0,0},
					itemMargin = {0,0,0,0},
					resizeItems=false,
					autosize=true,
					width = 70,
					children = children_leftbar,
				}
			leftside = true
		else
			stack_leftbar_temp = StackPanel:New{ width=10, }
		end
		
		stack_main_temp = StackPanel:New{
			name = 'main',
			autosize=true,
			x = leftside and 60 or 0,
			y = 0,
			orientation='vertical',
			centerItems = false,
			width = 240,
			padding = {0,0,0,0},
			itemPadding = {1,0,0,0},
			itemMargin = {0,0,0,0},
			resizeItems=false,
			children = children_main,
		}
		
		windows[ttname] = Window:New{
			name = ttname,
			--skinName = 'default',
			useDList = false,
			resizable = false,
			draggable = false,
			autosize  = true,
			--tweakDraggable = true,
			backgroundColor = color.tooltip_bg, 
			children = { stack_leftbar_temp, stack_main_temp, }
		}
	end
	SetTooltip(windows[ttname])
end

local function GetUnitIcon(ud)
	if not ud then return false end
	return icontypes 
		and	icontypes[(ud and ud.iconType or "default")].bitmap
		or 	'icons/'.. ud.iconType ..iconFormat
end


local function MakeToolTip_Text(text)
	BuildTooltip2('tt_text',{
		main = {
			{ name='text', text = text, wrap=true },
		}
	})
end

local function UpdateBuildpic( ud, globalitem_name )
	if not ud then return end
	
	if not globalitems[globalitem_name] then
		globalitems[globalitem_name] = Image:New{
			file = "#" .. ud.id,
			file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud)),
			keepAspect = false,
			height  = 55*(4/5),
			width   = 55,
		}
		return
	end
	globalitems[globalitem_name].file = "#" .. ud.id
	globalitems[globalitem_name].file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud))
	globalitems[globalitem_name]:Invalidate()
end

local function MakeToolTip_UD(tt_table)
	
	local helptext = GetHelpText(tt_table.buildType)
	local iconPath = GetUnitIcon(tt_table.unitDef)
	
	local tt_structure = {
		leftbar = {
			tt_table.morph_data 
				and { name= 'bp', directcontrol = 'buildpic_morph' }
				or { name= 'bp', directcontrol = 'buildpic_ud' },
			{ name = 'cost', icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat(tt_table.unitDef.metalCost), },
		},
		main = {
			{ name = 'udname', icon = iconPath, text = tt_table.unitDef.humanName, fontSize=2 },
			{ name = 'tt', text = tt_table.unitDef.tooltip, wrap=true },
			{ name='health', icon = 'LuaUI/images/commands/Bold/health.png',  text = numformat(tt_table.unitDef.health), },
			--[[
			{ name = 'requires', text = tt_table.requires and ('REQUIRES' .. tt_table.requires) or '', },
			{ name = 'provides', text = tt_table.provides and ('PROVIDES' .. tt_table.provides) or '', },
			{ name = 'consumes', text = tt_table.consumes and ('CONSUMES' .. tt_table.consumes) or '', },
			--]]
			tt_table.morph_data and { name='morph', directcontrol = 'morphs' } or {},
			{ name='helptext', text = green .. helptext, wrap=true},
			
		},
	}
	
	
	if tt_table.morph_data then
		UpdateBuildpic( tt_table.unitDef, 'buildpic_morph' )
		UpdateMorphControl( tt_table.morph_data )
		
		BuildTooltip2('morph', tt_structure)
	else
		UpdateBuildpic( tt_table.unitDef, 'buildpic_ud' )
		BuildTooltip2('ud', tt_structure)
	end
	
end


local function MakeToolTip_Unit(data, tooltip)
	local unitID = data
	local team, fullname
	tt_unitID = unitID
	team = spGetUnitTeam(tt_unitID) 
	tt_ud = UnitDefs[ spGetUnitDefID(tt_unitID) or -1]
	
	fullname = ((tt_ud and tt_ud.humanName) or "")	
		
	if not (tt_ud) then
		--fixme
		return false
	end
	--local alliance       = spGetUnitAllyTeam(tt_unitID)
	local _, player		= spGetTeamInfo(team)
	local playerName	= player and spGetPlayerInfo(player) or 'noname'
	local teamColor		= Chili.color2incolor(spGetTeamColor(team))
	---local unittooltip	= tt_unitID and spGetUnitTooltip(tt_unitID) or (tt_ud and tt_ud.tooltip) or ""
	local unittooltip	= GetUnitDesc(tt_unitID, tt_ud)
	local iconPath		= GetUnitIcon(tt_ud)
	
	UpdateResourceStack( 'unit', unitID, tt_ud, tooltip, ttFontSize )
	
	local tt_structure = {
		leftbar = {
			{ name= 'bp', directcontrol = 'buildpic_unit' },
			{ name= 'cost', icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat((tt_ud and tt_ud.metalCost) or '0') },
		},
		main = {
			{ name='uname', icon = iconPath, text = fullname .. ' (' .. teamColor .. playerName .. white ..')', fontSize=2, },
			{ name='utt', text = unittooltip, wrap=true },
			{ name='hp', directcontrol = 'hp_unit', },
			{ name='res', directcontrol = 'resources_unit' },
			{ name='help', text = green .. 'Space+click: Show unit stats', },
		},
	}
	
	UpdateBuildpic( tt_ud, 'buildpic_unit' )
	BuildTooltip2('unit', tt_structure)
end

local function MakeToolTip_Feature(data, tooltip)
	local featureID = data
	local tt_fd
	local team, fullname
	
	tt_fid = featureID
	team = spGetFeatureTeam(featureID)
	local fdid = spGetFeatureDefID(featureID)
	tt_fd = fdid and FeatureDefs[fdid or -1]
	local feature_name = tt_fd and tt_fd.name
	
	local desc = ''
	if feature_name:find('dead2') or feature_name:find('heap') then
		desc = ' (debris)'
	elseif feature_name:find('dead') then
		desc = ' (wreckage)'
	end
	local live_name = feature_name:gsub('([^_]*).*', '%1')
	tt_ud = UnitDefNames[live_name]
	
	fullname = ((tt_ud and tt_ud.humanName .. desc) or tt_fd.tooltip or "")
	
	if not (tt_fd) then
		--fixme
		return false
	end
	
	if options.hide_for_unreclaimable.value and not tt_fd.reclaimable then
		return false
	end
	
	--local alliance       = spGetUnitAllyTeam(tt_unitID)
	local _, player		= spGetTeamInfo(team)
	local playerName	= player and spGetPlayerInfo(player) or 'noname'
	local teamColor		= Chili.color2incolor(spGetTeamColor(team))
	---local unittooltip	= tt_unitID and spGetUnitTooltip(tt_unitID) or (tt_ud and tt_ud.tooltip) or ""
	local unittooltip	= GetUnitDesc(tt_unitID, tt_ud)
	local iconPath		= GetUnitIcon(tt_ud)
	
	UpdateResourceStack( tt_ud and 'corpse' or 'feature', featureID, tt_ud or tt_fd, tooltip, ttFontSize )
	
	local tt_structure = {
		leftbar =
			tt_ud and
			{
				{ name= 'bp', directcontrol = 'buildpic_feature' },
				{ name='cost', icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat((tt_ud and tt_ud.metalCost) or '0'), },
			}
			or nil,
		main = {
			{ name='uname', icon = iconPath, text = fullname .. ' (' .. teamColor .. playerName .. white ..')', fontSize=2, },
			{ name='utt', text = unittooltip, wrap=true },
			(	options.featurehp.value
					and { name='hp', directcontrol = (tt_ud and 'hp_corpse' or 'hp_feature'), } 
					or {}),
			{ name='res', directcontrol = tt_ud and 'resources_corpse' or 'resources_feature' },
			{ name='help', text = green .. 'Space+click: Show unit stats', },
		},
	}
	
	
	if tt_ud then
		UpdateBuildpic( tt_ud, 'buildpic_feature' )
		BuildTooltip2('corpse', tt_structure)
	else
		BuildTooltip2('feature', tt_structure)
	end
	return true
end



local function CreateHpBar(name)
	globalitems[name] = Progressbar:New {
		name = name,
		width = '100%',
		height = icon_size+2,
		itemMargin    = {0,0,0,0},
		itemPadding   = {0,0,0,0},	
		padding = {0,0,0,0},
		color = {0,1,0,1},
		max=1,
		caption = 'a',

		children = {
			Image:New{file='LuaUI/images/commands/bold/health.png',height= icon_size,width= icon_size,  x=0,y=0},
		},
	}
end

local function MakeToolTip_Draw()
	local tt_structure = {
		main = {
			{ name='lmb', 		icon = LUAUI_DIRNAME .. 'Images/drawingcursors/pencil.png', 		text = 'Left Mouse Button', },
			{ name='rmb', 		icon = LUAUI_DIRNAME .. 'Images/drawingcursors/eraser.png', 		text = 'Right Mouse Button', },
			{ name='mmb', 		icon = LUAUI_DIRNAME .. 'Images/Crystal_Clear_action_flag.png', 	text = 'Middle Mouse Button', },
			{ name='dblclick', 	icon = LUAUI_DIRNAME .. 'Images/drawingcursors/flagtext.png', 		text = 'Double Click', },
			
		},
	}
	BuildTooltip2('drawing', tt_structure)
end
	
local function MakeTooltip()
	if options.showdrawtooltip.value and  tildepressed and not (drawing or erasing) then
		MakeToolTip_Draw()
		return
	end
	
	local cur_ttstr = screen0.currentTooltip or spGetCurrentTooltip()
	local type, data = spTraceScreenRay(mx, my)
	if (not changeNow) and cur_ttstr ~= '' and old_ttstr == cur_ttstr and old_data == data then
		PlaceToolTipWindow2(mx+20,my-20)
		return
	end
	old_data = data
	old_ttstr = cur_ttstr
	
	tt_unitID = nil
	tt_ud = nil

	--chili control tooltip
	if screen0.currentTooltip ~= nil 
		and not screen0.currentTooltip:find('Build') --detect if chili control shows build option
		and not screen0.currentTooltip:find('Morph') --detect if chili control shows morph option
		then 
		if cur_ttstr ~= '' and cur_ttstr:gsub(' ',''):len() > 0 then
			MakeToolTip_Text(cur_ttstr)
		else
			KillTooltip() 
		end
		return
	end
	
	local tt_table = tooltipBreakdown(cur_ttstr)
	local tooltip, unitDef  = tt_table.tooltip, tt_table.unitDef
		
	if not tooltip then
		KillTooltip()
		return
	elseif unitDef then
		tt_ud = unitDef
		MakeToolTip_UD(tt_table)
		return
	end
	
	-- empty tooltip
	if (tooltip == '') or tooltip:gsub(' ',''):len() <= 0 then
		KillTooltip()
		return
	end	
	
	--unit(s) selected/pointed at 
	local unit_tooltip = tooltip:find('Experience %d+.%d+ Cost ')  --shows on your units, not enemy's
		or tooltip:find('TechLevel %d') --shows on units
		or tooltip:find('Metal.*Energy') --shows on features
	
	--unit(s) selected/pointed at
	if unit_tooltip then
		-- pointing at unit/feature
		if type == 'unit' then
			MakeToolTip_Unit(data, tooltip)
			return
		elseif type == 'feature' then
			if MakeToolTip_Feature(data, tooltip) then
				return
			end
		end
	
		--holding meta or static tip
		if (showExtendedTip) then
			MakeToolTip_Text(tooltip)
		else
			KillTooltip()
		end
		return
	end
	
	--tooltip that shows position
	local pos_tooltip = tooltip:sub(1,4) == 'Pos '
	
	-- default tooltip
	if not pos_tooltip or showExtendedTip then
		MakeToolTip_Text(tooltip)
		return
	end
	
	KillTooltip() 
	return
	
end --function MakeTooltip

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local cycle, timer = 1, 0
local tweakShow = false
function widget:Update(dt)
	--UpdateDynamicGroupInfo()
	timer = timer + dt
	--cycle = cycle%100 + 1
	if timer >= updateFrequency  then
		UpdateSelectedUnitsTooltip()
		UpdateDynamicGroupInfo()
		WriteGroupInfo()
		timer = 0
	end
	--if cycle == 1 then
	--end
	
	if widgetHandler:InTweakMode() then
	  tweakShow = true
	  Show(window_corner)
	elseif tweakShow then
	  tweakShow = false
	  widget:SelectionChanged(Spring.GetSelectedUnits())
	end
	
	--sel
	---
	--tip
	
	cycle = cycle%100 + 1
	old_mx, old_my = mx,my
	alt,_,meta,_ = spGetModKeyState()
	mx,my = spGetMouseState()
	local mousemoved = (mx ~= old_mx or my ~= old_my)
	
	local show_cursortip = true
	if meta then
		if not showExtendedTip then changeNow = true end
		showExtendedTip = true
	
	else
		if options.tooltip_delay.value > 0 then
			if not mousemoved then
				stillCursorTime = stillCursorTime + dt
			else
				stillCursorTime = 0 
			end
			show_cursortip = stillCursorTime > options.tooltip_delay.value
		end
		
		if showExtendedTip then changeNow = true end
		showExtendedTip = false
	
	end

	if mousemoved or changeNow then
		if not show_cursortip then
			KillTooltip()
			return
		end
		MakeTooltip()
		changeNow = false
	end
	
	SetHealthbar()
	
	if cycle == 1 then
		changeNow = true
	end
	
end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	local VFSMODE      = VFS.RAW_FIRST
	_, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
	local confdata = VFS.Include(LUAUI_DIRNAME .. "Configs/epicmenu_conf.lua", nil, VFSMODE)
	color = confdata.color

	-- setup Chili
	 Chili = WG.Chili
	 Button = Chili.Button
	 Label = Chili.Label
	 Window = Chili.Window
	 Panel = Chili.Panel
	 StackPanel = Chili.StackPanel
	 Grid = Chili.Grid
	 TextBox = Chili.TextBox
	 Image = Chili.Image
	 Multiprogressbar = Chili.Multiprogressbar
	 Progressbar = Chili.Progressbar
	 screen0 = Chili.Screen0

	widget:ViewResize(Spring.GetViewGeometry())

	CreateHpBar('hp_unit')
	CreateHpBar('hp_feature')
	CreateHpBar('hp_corpse')
	
	
	stack_main = StackPanel:New{
		width=300, -- needed for initial tooltip
	}
	stack_leftbar = StackPanel:New{
		width=10, -- needed for initial tooltip
	}
	--[[
	if options.statictip.value then
		window_tooltip2_static = Window:New{  
			--skinName = 'default',
			name   = 'tooltip',
			x      = 0,
			y = Chili.Screen.y - 130,
			clientHeight = 130,
			clientWidth  = 250,
			--useDList = false,
			dockable = true,
			resizable = false,
			tweakResizable = true,
			draggable = true,
			tweakDraggable = true,
			backgroundColor = color.tooltip_bg, 
			children = { stack_leftbar, stack_main, },
		}
	
	else
	--]]
		window_tooltip2 = Window:New{
			--skinName = 'default',
			useDList = false,
			resizable = false,
			draggable = false,
			autosize  = true,
			backgroundColor = color.tooltip_bg, 
			children = { stack_leftbar, stack_main, }
		}
	--end

	FontChanged()
	spSendCommands({"tooltip 0"})
	
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local y = tostring(math.floor(screenWidth/screenHeight*0.35*0.35*100 - window_height)) .. "%"

	window_corner = Window:New{
		name   = 'unitinfo';
		x      = 0;
		bottom = 200;
		clientHeight = 120;
		clientWidth  = 400;
		dockable = true,
		--autosize    = true;
		resizable   = false;
		draggable = false,
		tweakDraggable = true,
		tweakResizable = true,
		--padding = {3, 3, 15, 3}
		--color       = {Spring.GetTeamColor(Spring.GetLocalTeamID())};
		minimumSize = {120, 40},
	}
	--[[
	subwindow = ScrollPanel:New{
	  parent = window_corner,
	  name   = 'unitinfo_subwindow';  
      width = "95%",
      height = "95%",
      anchors = {top=true,left=true,bottom=true,right=true},
      horizontalScrollbar = false,
	  backgroundColor = {0, 0, 0, 0}
	}
	--]]

	windMin = Spring.GetGameRulesParam("WindMin")
	windMax = Spring.GetGameRulesParam("WindMax")

	for i=1,#UnitDefs do
		local ud = UnitDefs[i]
		if (ud.isCommander)           --// engine overrides commanders tooltips with playernames
		  or (ud.extractsMetal > 0)   --// the Overdrive gadgets adds additional information to the tooltip, but the visualize it a different way
		then
			ud.chili_selections_useStaticTooltip = true
		end
	end
	
	option_Deselect()

end

function widget:Shutdown()
	spSendCommands({"tooltip 1"})
	if (window_tooltip2) then
		window_tooltip2:Dispose()
	end
end



function widget:KeyPress(key, modifier, isRepeat)
	if key == KEYSYMS.BACKQUOTE then
		if not tildepressed then
			changeNow = true
		end	
		tildepressed = true
	end
end
function widget:KeyRelease(key)
	if key == KEYSYMS.BACKQUOTE then
		if tildepressed then
			changeNow = true
		end
		tildepressed = false
	end
end

function widget:DrawScreen()
	if not tildepressed then return end
	local x, y, lmb, mmb, rmb = Spring.GetMouseState()
	drawing = lmb
	erasing = rmb
	
	local filefound
	if drawing then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/drawingcursors/pencil.png')
	elseif erasing then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/drawingcursors/eraser.png')
	end
	
	if filefound then
		--do teamcolor?
		--glColor(0,1,1,1) 
		if drawing or erasing then
			Spring.SetMouseCursor('none')
		end
		glTexRect(x, y-cursor_size, x+cursor_size, y)
		glTexture(false)
		--glColor(1,1,1,1)
	end
end







-------------
-------------
-------------
-------------
-------------
-------------











--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function round(num, idp)
  if (not idp) then
    return math.floor(num+.5)
  else
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
  end
end
--[[
local function numformat(x, displayPlusMinus)
	
	if (x < 20 and (x * 10)%10 ~=0) then 
		if (displayPlusMinus) then return strFormat("%+.1f", x)
		else return strFormat("%.1f", x) end 
	else 
		if (displayPlusMinus) then return strFormat("%+d", x)
		else return strFormat("%d", x) end
	end 
end
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Show(obj)
	if (not obj:IsDescendantOf(screen0)) then
		screen0:AddChild(obj)
	end
end

local function Hide(obj)
	obj:ClearChildren()
	screen0:RemoveChild(obj)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- group selection

--updates cost, HP, and resourcing info for group info
local function UpdateDynamicGroupInfo()
	gi_cost = 0
	gi_hp = 0
	gi_metalincome = 0
	gi_metaldrain = 0
	gi_energyincome = 0
	gi_energydrain = 0
	gi_usedbp = 0
	
	for i = 1, numSelectedUnits do
		local id = selectedUnits[i]
	
		local ud = UnitDefs[spGetUnitDefID(id) or 0]
		if ud then
			local name = ud.name 
			local hp, _, paradam, cap, build = spGetUnitHealth(id)
			local mm,mu,em,eu = spGetUnitResources(id)
		
			if name ~= "terraunit" then
				gi_cost = gi_cost + ud.metalCost*build
				gi_hp = gi_hp + hp
				
				local stunned_or_inbuld = spGetUnitIsStunned(id)
				if not stunned_or_inbuld then 
					if name == 'armmex' or name =='cormex' then -- mex case
						local tooltip = spGetUnitTooltip(id)
						
						local baseMetal = 0
						local s = tooltip:match("Makes: ([^ ]+)")
						if s ~= nil then 
							baseMetal = tonumber(s) 
						end 
										
						s = tooltip:match("Overdrive: %+([0-9]+)")
						local od = 0
						if s ~= nil then 
							od = tonumber(s) 
						end
						
						gi_metalincome = gi_metalincome + baseMetal + baseMetal * od / 100
							
						s = tooltip:match("Energy: ([^ ]+)")
						if s ~= nil then 
							gi_energydrain = gi_energydrain - tonumber(s) 
						end 
					else
						gi_metalincome = gi_metalincome + mm
						gi_metaldrain = gi_metaldrain + mu
						gi_energyincome = gi_energyincome + em
						gi_energydrain = gi_energydrain + eu
					end
					
					if ud.buildSpeed ~= 0 then
						gi_usedbp = gi_usedbp + mu
					end
				end
			end
		end
		
	end
	
	gi_cost = numformat(gi_cost)
	gi_hp = numformat(gi_hp)
	gi_metalincome = numformat(gi_metalincome)
	gi_metaldrain = numformat(gi_metaldrain)
	gi_energyincome = numformat(gi_energyincome)
	gi_energydrain = numformat(gi_energydrain)
	gi_usedbp = numformat(gi_usedbp)
end

--updates values that don't change over time for group info
local function UpdateStaticGroupInfo()
	gi_count = numSelectedUnits
	gi_finishedcost = 0
	gi_totalbp = 0
	gi_maxhp = 0
	
	for i = 1, numSelectedUnits do
		local ud = UnitDefs[spGetUnitDefID(selectedUnits[i]) or 0]
		if ud then
			local name = ud.name 
			if name ~= "terraunit" then
				gi_totalbp = gi_totalbp + ud.buildSpeed
				gi_maxhp = gi_maxhp + ud.health
				gi_finishedcost = gi_finishedcost + ud.metalCost
			end
		end
	end
	gi_finishedcost = numformat(gi_finishedcost)
	gi_totalbp = numformat(gi_totalbp)
	gi_maxhp = numformat(gi_maxhp)
end

----------------------------------------------------------------
----------------------------------------------------------------

local function GetUnitDesc(unitID, ud)
	local lang = WG.lang or 'en'
	if lang == 'en' then 
		return unitID and spGetUnitTooltip(unitID) or ud.tooltip
	end
	local suffix = ('_' .. lang)
	local desc = ud.customParams and ud.customParams['description' .. suffix] or ud.tooltip or 'Description error'
	if unitID then
		local endesc = ud.tooltip
		--(ud.chili_selections_useStaticTooltip)and(ud.tooltip) or spGetUnitTooltip(unitid);
		return spGetUnitTooltip(unitID):gsub(endesc, desc)
	end
	return desc
end

local function MakeUnitToolTip(unitid)
	local ud             = UnitDefs[spGetUnitDefID(unitid) or 0]
	local team           = spGetUnitTeam(unitid)
	local _, player      = spGetTeamInfo(team)
	local playerName     = spGetPlayerInfo(player) or 'noname'
	local teamColor      = Chili.color2incolor(spGetTeamColor(team))

	window_corner:ClearChildren();
	--window_corner:Resize(300,window_height, true)
	
	Image:New{
		parent  = window_corner;
		file2   = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud));
		file    = "#" .. ud.id;
		keepAspect = false;
		x       = 210;
		height  = 55 * (4/5);
		--height  = 55;
		width   = 55;
		tooltip = 'Middle-click to go to unit.',
		OnClick = {function(_,_,_,button)
			if (button==2) then
				--button2 (middle)
				local x,y,z = Spring.GetUnitPosition( unitid )
				Spring.SetCameraTarget(x,y,z, 1)
			end
		end}
	}
	
	local iconPath = icontypes 
			and	icontypes[(ud.iconType or "default")].bitmap
			or 	'icons/'.. ud.iconType ..iconFormat

			Image:New{
		parent  = window_corner;
		file    = iconPath,
		x       = 0;--57;
		y       = 0;
		height  = 20;
		width   = 20;
	}
	Label:New{
		parent  = window_corner;
		x       = 22;--79;
		height  = 20;
		caption = ud.humanName;-- .. teamColor .. ' (' .. playerName .. ')';
		valign  = 'center';
		fontSize = 14;
		fontShadow = true;
	}

	Label:New{
		parent  = window_corner;
		name 	= 'tooltip';
		x       = 10;--67;
		y       = 20;
		height  = 40;
		width = 235;
		--height = 30;
		autoSize = false;
		--caption = (ud.chili_selections_useStaticTooltip)and(ud.tooltip) or spGetUnitTooltip(unitid);
		caption = GetUnitDesc(unitid, ud);
		valign  = 'top';
	}

	Grid:New{
		name     = 'info';
		parent   = window_corner;
		x        = 200;
		y        = 56;
		height   = 55;
		width    = 71;
		columns  = 2;
		autosize = true;
		resizeItems = false;
		centerItems = true;
		padding     = {0,0,0,0};
		itemPadding = {0,1,0,2};
		itemMargin  = {0,0,0,0};
		--debug=true;
		children = {
			Label:New{
				name    = 'metal';
				autosize= false;
				height  = 15;
				width   = 42;
				caption = '\255\000\254\000+0';
				align   = 'right';
				margin  = {0,0,5,0};
			},
			Image:New{
				file    = 'LuaUI/images/ibeam.png';
				height  = 15;
				width   = 15;
			},

			Label:New{
				name    = 'energy';
				autosize= false;
				height  = 15;
				width   = 42;
				caption = '\255\254\000\000+0';
				align   = 'right';
				margin  = {0,0,5,0};
			},
			Image:New{
				file    = 'LuaUI/images/energy.png';
				height  = 15;
				width   = 15;
			}
		}
	}

	local barGrid = Grid:New{
		name     = 'Bars';
		autosize = true;
		resizeItems = false;
		centerItems = true;
		parent  = window_corner;
		columns = 2;
		x       = 0;--60;
		y       = 55;
		height  = 50;
		width   = 225;
		padding     = {5,5,5,5};
		itemPadding = {0,0,0,0};
		itemMargin  = {0,0,0,0};
--[[
		DrawBackground = function(self)
			gl.BeginEnd(GL.QUADS,function()
				gl.Color(0,0,0,0.1)
				gl.Vertex(self.x,self.y)
				gl.Vertex(self.x+self.width,self.y)
				gl.Color(0,0,0,0.5)
				gl.Vertex(self.x+self.width,self.y+self.height)
				gl.Vertex(self.x,self.y+self.height)
			end)
		end,
--]]
	}

	Image:New{
		parent  = barGrid;
		file    = 'LuaUI/images/commands/Bold/health.png';
		height  = 15;
		width   = 15;
	}
	Progressbar:New{
		name    = 'health';
		parent  = barGrid;
		width   = 200;
		max     = 1;
		caption = "100%";
		color   = {0,0.8,0,1};
	}

	if (ud.name:find("win", 1, true)) then
		Image:New{
			parent  = barGrid;
			file    = 'LuaUI/Images/commands/Bold/wind.png';
			height  = 15;
			width   = 15;
		}
		Progressbar:New{
			name    = 'wind';
			parent  = barGrid;
			width   = 200;
			max     = 1;
			caption = "100%";
			color   = {0.3,0.6,0.8,1};
		}
	end


	if (ud.builder) then
		Image:New{
			parent  = barGrid;
			file    = 'LuaUI/Images/commands/Bold/buildsmall.png';
			height  = 15;
			width   = 15;
		}
		Progressbar:New{
			name    = 'nano';
			parent  = barGrid;
			width   = 200;
			max     = 1;
			caption = "100%";
			color   = {0.8,0.8,0.2,1};
		}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddSelectionIcon(barGrid,unitid,defid,unitids,counts)
	local ud = UnitDefs[defid]
	local item = LayoutPanel:New{
		name    = unitid or defid;
		parent  = barGrid;
		width   = 50;
		height  = 62;
		columns = 1;
		padding     = {0,0,0,0};
		itemPadding = {0,0,0,0};
		itemMargin  = {0,0,0,1};
		resizeItems = false;
		centerItems = false;
		autosize    = true;		
	}
	local img = Image:New{
		parent  = item;
		tooltip = ud.humanName .. " - " .. ud.tooltip.. "\n\255\0\255\0Click: Select \nRightclick: Deselect \nAlt+Click: Select One \nCtrl+click: Select Type \nMiddle-click: Goto";
		file2   = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(UnitDefs[defid]));
		file    = "#" .. defid;
		keepAspect = false;
		height  = 50 * (options.squarepics.value and 1 or (4/5));
		--height  = 50;
		width   = 50;
		padding = {0,0,0,0}; --FIXME something overrides the default in image.lua!!!!
		OnClick = {function(_,_,_,button)
			
			local alt, ctrl, meta, shift = spGetModKeyState()
			
			if (button==3) then
				if (unitid and not ctrl) then
					--// deselect a single unit
					for i=1,numSelectedUnits do
						if (selectedUnits[i]==unitid) then
							table.remove(selectedUnits,i)
							break
						end
					end
				else
					--// deselect a whole unitdef block
					for i=numSelectedUnits,1,-1 do
						if (Spring.GetUnitDefID(selectedUnits[i])==defid) then
							table.remove(selectedUnits,i)
							if (alt) then
								break
							end
						end
					end
				end
				Spring.SelectUnitArray(selectedUnits)
				--update selected units right now
				local sel = Spring.GetSelectedUnits()
				widget:SelectionChanged(sel)
			elseif button == 1 then
				if not ctrl then 
					if (alt) then
						Spring.SelectUnitArray({ selectedUnitsByDef[defid][1] })  -- only 1	
					else
						Spring.SelectUnitArray(unitids) -- no modifier - select all
					end
				else
					-- select all units of the icon type
					Spring.SelectUnitArray(selectedUnitsByDef[defid])
					
					--local sorted = Spring.GetTeamUnitsSorted(Spring.GetMyTeamID())						
					--local units = sorted[defid]
					--if units then Spring.SelectUnitArray(units) end
				end
			else --button2 (middle)
				local x,y,z = Spring.GetUnitPosition( unitids[1] )
				Spring.SetCameraTarget(x,y,z, 1)
			end
		end}
	};
	if ((counts or 1)>1) then
		Label:New{
			parent = img;
			align  = "right";
			valign = "top";
			x =  8;
			--y = 30;
			y = 20;
			width = 40;
			fontsize   = 20;
			fontshadow = true;
			fontOutline = true;
			caption    = counts;
		};
	end
	Progressbar:New{
		parent  = item;
		name    = 'health';
		width   = 50;
		height  = 5;
		max     = 1;
		color   = {0.0,0.99,0.0,1};
	};
end

--this is a separate function to allow group info to be regenerated without reloading the whole tooltip
local function WriteGroupInfo()
	if not options.showgroupinfo.value then return end
	if gi_label then
		window_corner:RemoveChild(gi_label)
	end
	gi_str = 
		"Selected Units " .. gi_count .. "\n" ..
		"Health " .. gi_hp .. " / " ..  gi_maxhp  .. "\n" ..
		"Cost " .. gi_cost .. " / " ..  gi_finishedcost .. "\n" ..
		"Metal \255\0\255\0+" .. gi_metalincome .. "\255\255\255\255 / \255\255\0\0-" ..  gi_metaldrain  .. "\255\255\255\255\n" ..
		"Energy \255\0\255\0+" .. gi_energyincome .. "\255\255\255\255 / \255\255\0\0-" .. gi_energydrain .. "\255\255\255\255\n" ..
		"Build Power " .. gi_usedbp .. " / " ..  gi_totalbp 
		
	gi_label = Label:New{
		parent  = window_corner;
		y=5,
		right=5,
		--x=-110,
		height  = '100%';
		width = 120,
		caption = gi_str;
		valign  = 'top';
		fontSize = 12;
		fontShadow = true;
	}
end

local function MakeUnitGroupSelectionToolTip()
	window_corner:ClearChildren();
	if options.showgroupinfo.value then
		--window_corner:Resize(395,window_height,true)
		--subwindow:Resize("70%",window_height,true)
	else
		--window_corner:Resize(300,window_height,true)
		--subwindow:Resize("95%",window_height,true)
	end
	
	local barGrid = LayoutPanel:New{
		name     = 'Bars';
		resizeItems = false;
		centerItems = false;
		parent  = window_corner;
		height  = "100%";
		x=0,
		--width   = "100%";
		right=options.showgroupinfo.value and 120 or 0,
		--columns = 5;
		itemPadding = {0,0,0,0};
		itemMargin  = {0,0,2,2};
		tooltip = "Left Click: Just select clicked unit(s)\nRight Click: Deselect unit(s)";
	}
	--if check is done in target function
	--if options.showgroupinfo.value then
		WriteGroupInfo()
	--end

	if ((numSelectedUnits<8) and (not options.groupalways.value)) then
		for i=1,numSelectedUnits do
			local unitid = selectedUnits[i]
			local defid  = spGetUnitDefID(unitid)
			local unitids = {unitid}

			AddSelectionIcon(barGrid,unitid,defid,unitids)
		end
	else
		for i=1,#selectionSortOrder do
			local defid   = selectionSortOrder[i]
			local unitids = selectedUnitsByDef[defid]
			local counts  = selectedUnitsByDefCounts[defid]

			AddSelectionIcon(barGrid,nil,defid,unitids,counts)
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdateSelectedUnitsTooltip()
	local selectedUnits = selectedUnits
	if (numSelectedUnits>0) then
		if (numSelectedUnits == 1) then
			local infoContainer = window_corner.childrenByName['info']

			local barsContainer = window_corner.childrenByName['Bars']
			local healthbar = barsContainer.childrenByName['health']
			local health, maxhealth,para,_,buildProgress = spGetUnitHealth(selectedUnits[1])
			if health then
				healthbar:SetValue(health/maxhealth)
				healthbar:SetCaption(numformat(health) .. ' / ' .. numformat(maxhealth))
			else
				--healthbar:SetValue(1)
				--healthbar:SetCaption('??? / ' .. numformat(ud.health))
			end

			local ud = UnitDefs[spGetUnitDefID(selectedUnits[1]) or 0]
			
			local stunned_or_inbuld = spGetUnitIsStunned(selectedUnits[1])
			
			if not stunned_or_inbuld then
				local metalMake, metalUse, energyMake,energyUse = Spring.GetUnitResources(selectedUnits[1])
				local absMetal = metalMake - metalUse
				local absEnergy = energyMake - energyUse
				
				--// Nano/Builders
				local nanobar = barsContainer.childrenByName['nano']
				if (nanobar) then
					if metalUse then
						nanobar:SetValue(metalUse/ud.buildSpeed,true)
						nanobar:SetCaption(round(100*metalUse/ud.buildSpeed)..'%')
					else
						healthbar:SetValue(1)
						healthbar:SetCaption('??? / ' .. numformat(ud.buildSpeed))
					end
				end

				--// Windgens
				local windbar = barsContainer.childrenByName['wind']
				if (windbar) then
					local power = (absEnergy - windMin) / (windMax - windMin)
					windbar:SetValue(power, true)
					windbar:SetCaption( numformat(100*power) .."%" )
				end

				--// Mexes
	--[[ FIXME
				local odbar = barsContainer.childrenByName['overdrive']
				if (odbar) then
					windbar:SetValue(absEnergy / windMax, true)
					windbar:SetCaption(round(100*absEnergy/ windMax)..'%')
				end
	--]]

	-- special cases for mexes
				if mexTooltips[ud.name] then 
					local tooltip = spGetUnitTooltip(selectedUnits[1])
					--local tooltip = GetUnitDesc(selectedUnits[1])
					window_corner.childrenByName['tooltip']:SetCaption(tooltip)
					
					local baseMetal = 0
					local s = tooltip:match("Makes: ([^ ]+)")
					if s ~= nil then baseMetal = tonumber(s) end 
									
					s = tooltip:match("Overdrive: %+([0-9]+)")
					local od = 0
					if s ~= nil then od = tonumber(s) end
					
					absMetal = absMetal + baseMetal + baseMetal * od / 100
					
					s = tooltip:match("Energy: ([^ ]+)")
					if s ~= nil then absEnergy = absEnergy +tonumber(s) end 
				end 
				
				if pylonTooltips[ud.name] then 
					local tooltip = spGetUnitTooltip(selectedUnits[1])
					if windTooltips[ud.name] then
						tooltip = tooltip .. "\nWind Range " .. string.format("%.1f", Spring.GetUnitRulesParam(selectedUnits[1],"minWind")) .. " - " .. Spring.GetGameRulesParam("WindMax")
					end
					window_corner.childrenByName['tooltip']:SetCaption(tooltip)
				end
			
				
				local lbl_metal = infoContainer.childrenByName['metal']
				if abs(absMetal) <= 0.1 then
					lbl_metal.font:SetColor(0.5,0.5,0.5,1)
					lbl_metal:SetCaption("0")
				else
					if (absMetal<0) then
						lbl_metal.font:SetColor(1,0,0,1)
					else
						lbl_metal.font:SetColor(0,1,0,1)
					end
					lbl_metal:SetCaption(numformat(absMetal,true) )
				end

				local lbl_energy = infoContainer.childrenByName['energy']
				if abs(absEnergy) <= 0.1 then
					lbl_energy.font:SetColor(0.5,0.5,0.5,1)
					lbl_energy:SetCaption("0.0")
				else
					if (absEnergy<0) then
						lbl_energy.font:SetColor(1,0,0,1)
					else
						lbl_energy.font:SetColor(0,1,0,1)
					end
					lbl_energy:SetCaption( numformat(absEnergy, true) )
				end
			else -- unit is stunned
			
				--// Nano/Builders
				local nanobar = barsContainer.childrenByName['nano']
				if (nanobar) then
					nanobar:SetValue(0,true)
					nanobar:SetCaption('0%')
				end
				
				--// Windgens
				local windbar = barsContainer.childrenByName['wind']
				if (windbar) then
					windbar:SetValue(0, true)
					windbar:SetCaption('0%')
				end
				
				local lbl_metal = infoContainer.childrenByName['metal']
				lbl_metal:SetCaption("0.0")

				local lbl_energy = infoContainer.childrenByName['energy']
				lbl_energy:SetCaption("0.0")
				
			end
		
		else
			local barsContainer = window_corner.childrenByName['Bars']

			if ((numSelectedUnits<8) and (not options.groupalways.value)) then
				for i=1,numSelectedUnits do
					local unitid = selectedUnits[i]

					local unitIcon = barsContainer.childrenByName[unitid]
					--Spring.Echo(unitid)
					local healthbar = unitIcon.childrenByName['health']
					local health, maxhealth = spGetUnitHealth(unitid)
					if (health) then
						healthbar:SetValue(health/maxhealth)
						healthbar.tooltip = numformat(health) .. ' / ' .. numformat(maxhealth)
					end
				end
			else
				for defid,unitids in pairs(selectedUnitsByDef) do
					local health = 0
					local maxhealth = 0
					for i=1,#unitids do
						local uhealth, umaxhealth = spGetUnitHealth(unitids[i])
						health = health + (uhealth or 0)
						maxhealth = maxhealth + (umaxhealth or 0)
					end

					local unitGroup = barsContainer.childrenByName[defid]
					local healthbar = unitGroup.childrenByName['health']
					healthbar:SetValue(health/maxhealth)
					healthbar.tooltip = numformat(health) .. ' / ' .. numformat(maxhealth)
				end
			end

			--[[
			local nanobar = barsContainer.childrenByName['nano']
			if (nanobar) then
				local ud = UnitDefs[spGetUnitDefID(selectedUnits[1]) or 0]
				local metalMake, metalUse, energyMake,energyUse = Spring.GetUnitResources(selectedUnits[1])
				if metalUse then
					nanobar:SetValue(metalUse/ud.buildSpeed,true)
					nanobar:SetCaption(round(100*metalUse/ud.buildSpeed)..'%')
				else
					healthbar:SetValue(1)
					healthbar:SetCaption('??? / ' .. numformat(ud.buildSpeed))
				end

				local absMetal = metalMake - metalUse
				infoContainer.childrenByName['metal']:SetCaption((((absMetal<0)and'\255\254\000\000')or('\255\000\254\000+')) .. numformat(absMetal,1))

				local absEnergy = energyMake - energyUse
				infoContainer.childrenByName['energy']:SetCaption((((absEnergy<0)and'\255\254\000\000')or('\255\000\254\000+')) .. numformat(absEnergy,1))
			end
			--]]
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--lags like a brick due to being spammed constantly for unknown reason, moved all its behavior to SelectionChanged
--function widget:CommandsChanged()
--end
--


function widget:SelectionChanged(newSelection)
	numSelectedUnits = spGetSelectedUnitsCount()
	selectedUnits = newSelection

	if (numSelectedUnits>0) then
		UpdateStaticGroupInfo()
		UpdateDynamicGroupInfo()
		selectedUnitsByDef       = spGetSelectedUnitsByDef()
		selectedUnitsByDef.n     = nil
		selectedUnitsByDefCounts = {}
		for i,v in pairs(selectedUnitsByDef) do
			selectedUnitsByDefCounts[i] = #v
		end

		--// spGetSelectedUnitsByDef() doesn't save the order for the different defids, so we reconstruct it from spGetSelectedUnits()
		--// else the sort order would change each time we select a new unit or deselect one!
		selectionSortOrder = {}
		local alreadyInList = {}
		for i=1,#selectedUnits do
			local defid = spGetUnitDefID(selectedUnits[i])
			if (not alreadyInList[defid]) then
				alreadyInList[defid] = true
				selectionSortOrder[#selectionSortOrder+1] = defid
			end
		end

		if (numSelectedUnits == 1) then
			MakeUnitToolTip(selectedUnits[1])
		else
			MakeUnitGroupSelectionToolTip()
		end
		Show(window_corner)
	else
		Hide(window_corner)
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Shutdown()

	Spring.SetDrawSelectionInfo(true) 

end

