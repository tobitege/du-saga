--[[
	Command List				Description										Usage Sample (commands not case sensitive)
	/menu						-- Toggle the main menu on and off				/menu
	/scale						-- Set the hud scale in percent					/scale 100
	/addpos						-- Add a pos to current route					/addpos ::pos{0,2,35.3951,104.1187,285.5413}
	/goto						-- Set target to temp point						/goto ::pos{0,2,35.3951,104.1187,285.5413}
	/setMaxSpaceSpeed /setMSP   -- Set Max Space Speed in km/h					/setMSP 20000
	/setMaxPitch /setMP			-- Set Max Pitch Degree							/setMP 45
	/setMaxRoll /setMR			-- Set Max Roll Degree							/setMR 35
	/landSpeedHigh			  	-- Max landing speed above 1km altitude			/landSpeedHigh 200
	/landSpeedLow			  	-- Max landing speed below 1km altitude			/landSpeedLow 100
	/shield						-- Enable or disable auto shield management		/shield
	/space						-- Toggle if ship is space capable				/space
	/hover						-- Set hover height when out of parking mode	/hover 20
	/atp						-- Enable or disable atmo Auto throttle			/atp
									protection. Prevents accelerating above
									atmo burn speed.
									NOT for Maneuver mode (yet)!
	/alt /altitude				-- Set specific altitude for Alt Hold mode.		/alt 2500
									Standard flight mode only!
	/orbitAlt					-- Set TargetOrbitAlt							/orbitAlt 10000
	/agg						-- Toggle AGG on/off							/agg
	/aggAlt						-- Set AGG altitude								/aggAlt 5000

	HELPERS
	/agl						-- Set above ground level in meters				/agl 1.2
									Use "Ground" value when landed, as this
									depends on the linked element that provides
									ground detection, like a telemeter or
									any ground engine
	/convert					-- Converts a ::pos to world coords				/convert ::pos{0,2,35.3951,104.1187,285.5413}
	/current					-- Outputs current pos in world/local ::pos		/current
	/dockingMode				-- Sets docking mode (1,2 or 3)					/dockingMode 2
	/freeze						-- Freeze player for remote controller use		/freeze

	MANEUVER MODE (for VTOL-enabled ships only!):
	/base						-- Sets visual target mark to current position	/base
	/go							-- Travel to target marker (if active)			/go 500
									at an optional altitude
	/goAlt						-- Move to specified altitude					/goAlt 500
	/vertical					-- Move vertically x meters from current		/vertical 1000
									altitude, i.e. positive or negative		 	/vertical -123
									distance possible (-200000 to 200000)
	WIDGETS:
	/core						-- Toggles display of core stress info on/off	/core
	/dock						-- Toggles display of docking info on/off		/dock
	/unit						-- Toggles unit widget on/off					/unit
	/radar						-- Toggle Radar Widget on/off					/radar
	/radarbox					-- Toggle display of radar hud boxes			/radarbox
]]

local function Err(text) error('[E] '..(text or '')) return false end
local ERR_INV_POS = 'Invalid ::pos'
local ERR_INV_DIST = 'No vertical distance provided'

---@param action string
---@param numVal number
---@param isPct boolean
---@param defaultNum number
---@param minValue number
---@param maxValue number
---@param configKey string
---@param apKey string|nil
---@param successMessage string
---@return number|nil
local function setConfigValue(action, numVal, isPct, defaultNum, minValue, maxValue, configKey, apKey, successMessage)
	local uround = utils.round
	if numVal == nil then
		Err(string.format('%s value (%d-%d) missing', action or '', uround(minValue or 0), uround(maxValue or 0)))
		return nil
	end
	numVal = clamp(uround(numVal or defaultNum), minValue, maxValue)
	if configKey ~= nil then
		Config:setValue(configKey, ternary(isPct, numVal / 100, numVal))
	end
	if apKey ~= nil then
		AutoPilot.userConfig[apKey] = numVal
		AutoPilot:applyConfig()
	end
	if successMessage then
		P(string.format(successMessage, numVal))
		return numVal
	end
end

function onInput(text)
	if text == nil or text == "" then return end
	local gC, cD, ap, _hud, cfMap = globals, cData, AutoPilot, HUD, configDatabankMap
	local inputParts = split(text, ' ')
	local action = inputParts[1]:lower()
	local num2 = ternary(#inputParts > 1, tonumber(inputParts[2]), nil)

	if action:sub(1, 1) ~= '/' then
		if _hud and _hud.Config and _hud.Config.mainMenuVisible then
			local hovered = Widgets.mainMenu.optionMenu:getHoveredEntry()
			if not hovered or not hovered.actions or not hovered.actions.input then return end
			if hovered.actions.input.filter ~= nil then text = hovered.actions.input.filter(text) end
			hovered.actions.input.func(text, hovered.actions.input.arg)
			return
		end
	end
	if action == '/menu' and _hud then _hud.toggleMainMenu() end
	if action == '/core' and _hud then _hud.toggleCoreWidget() end
	if action == '/dock' and _hud then _hud.toggleDockWidget() end
	if action == '/dockingmode' then
		local num = setConfigValue(action, num2, false, 1, 1, 3, cfMap.dockMode, nil, "Docking mode %d")
		if num ~= nil then
			construct.setDockingMode(num)
		end
	end
	if action == '/debug' then gC.debug = not gC.debug end

	if action == '/scale' then
		setConfigValue(action, num2, true, 100, 40, 250, cfMap.hudScale, nil, "Scale set to %d")
	end

	if action == '/landspeedhigh' then
		setConfigValue(action, num2, false, 100, 20, 500, cfMap.landSpeedHigh, "landSpeedHigh", "High-alt landing speed set to %d")
	end

	if action == '/landspeedlow' then
		setConfigValue(action, num2, false, 100, 20, 200, cfMap.landSpeedLow, "landSpeedLow", "Low-alt landing speed set to %d")
	end

	if action == '/travelalt' then
		setConfigValue(action, num2, false, 1500, 100, 20000, cfMap.travelAlt, "travelAlt", "Travel altitude set to %.2f")
	end

	--TODO action == '/addlocation' ?
	if action == '/addpos' then
		if RouteDatabase.currentEditId == nil then
			Err'First open a route in menu'
		elseif #inputParts == 2 then
			addCustomPos(inputParts[2])
		end
		return Err(ERR_INV_POS)
	end

	if gC.maneuverMode then
		if action == '/setbase' then
			setApTarget(cD.position)
			Config:setValue(cfMap.base, cD.position)
			return
		elseif action == '/clearbase' then
			Config:setValue(cfMap.base, nil)
			P('[I] Base cleared.')
			return
		elseif action == '/go' then
			if vec3.isvector(ap.target) then
				P('Moving to '..Vec3ToPosString(ap.target))
				-- ship.travel = gotoTarget(ap.target, true, cD.inAtmo and ap.userConfig.travelAlt or cD.altitude)
				ship.travel = gotoTarget(ap.target, true, cD.altitude)
			end
		elseif action == '/goalt' then
			if num2 == nil then return Err(ERR_INV_DIST) end
			num2 = clamp(num2,0,200000)
			if num2 > cD.altitude then
				local alt = ternary(num2 - cD.altitude > 0, num2 - cD.altitude, cD.altitude - num2)
				P('[I] Moving to '..round2(num2,2)..'m altitude.')
				ship.vertical = moveVert(alt)
			end
		elseif action == '/rtb' then
			local tmp = Config:getValue(cfMap.base, nil)
			if not tmp then return Err('No base set!') end
			P('[I] Back to base '..tostring(vec3(tmp)))
			ship.travel = gotoTarget(tmp)
		elseif action == '/down' then
			if num2 == nil then return Err(ERR_INV_DIST) end
			ship.vertical = moveVert(-clamp(abs(num2),-200000,2000000))
		elseif action == '/up' then
			if num2 == nil then return Err(ERR_INV_DIST) end
			ship.vertical = moveVert(clamp(num2,0,200000))
		end
	end

	if action == '/goto' then
		if #inputParts < 2 or #inputParts > 3 then
			return Err(ERR_INV_POS)
		end
		local target = convertToWorldCoordinates(inputParts[2])
		if target == nil then
			return Err(ERR_INV_POS)
		end
		ap:setTarget(target)
		resetAP()
		local b, tA = ap.targetBody, ap.targetAltitude
		if (b ~= nil) and (tA == nil or tA == 0 or (ap.target == b.center)) then
			tA = math.max(b.maxStaticAltitude or 1000, b.surfaceMaxAltitude or 1000)
			if cD.inAtmo and cD.altitude > tA then
				tA = cD.altitude
			end
		end
		if #inputParts == 3 then
			local num3 = tonumber(inputParts[3])
			if num3 ~= nil and num3 >= 100 and num3 > tA then
				tA = num3
			end
		end
		ap.targetAltitude = round2(tA,0)
		if gC.maneuverMode then
			gotoTarget(target, true, cD.inAtmo and ap.userConfig.travelAlt or cD.altitude)
			ship.travel = true
		elseif not ap.enabled then
			onAlt1()
		end
		return P('Target set to '..inputParts[2]..' near '..ap.targetBody.name..
			' '..ap.targetLoc..' at '..ap.targetAltitude..' m ')
	end

	if action == '/alt' or action == '/altitude' then
		if gC.altitudeHold then
			if num2 == nil then return end
			num2 = clamp(num2,-1000,100000)
			gC.holdAltitude = round2(num2,0)
			return P('Holding altitude set to '..gC.holdAltitude..'m')
		end
		Err"Engage 'Altitude hold' mode first"
	end

	if action == '/convert' then
		if #inputParts < 2 then
			return Err(ERR_INV_POS)
		end
		local wPos = convertToWorldCoordinates(inputParts[2])
		if wPos == nil then return Err(ERR_INV_POS) end
		P(Vec3ToPosString(wPos))
		P(worldToMapStr(wPos) or ERR_INV_POS)
	end

	if action == '/current' then
		P(Vec3ToPosString(cD.position))
		P(worldToMapStr(cD.position) or ERR_INV_POS)
	end

	if action == '/setmaxspacespeed' or action == '/setmsp' then
		setConfigValue(action, num2, false, 20000, 100, 50000, cfMap.maxSpaceSpeed, nil, 'Max Space Speed set to %d')
	end

	if action == '/setmaxpitch' or action == '/setmp' then
		setConfigValue(action, num2, false, 30, 0, 80, cfMap.maxPitch, "maxPitch", 'Max Pitch set to %d')
	end

	if action == '/setmaxroll' or action == '/setmr' then
		setConfigValue(action, num2, false, 35, -89, 89, cfMap.maxRoll, "maxRoll", 'Max Roll set to %d')
	end

	if action == '/shield' then
		ap.userConfig.shieldManage = not ap.userConfig.shieldManage
		P('Shield management '..ternary(ap.userConfig.shieldManage,'enabled','disabled'))
		Config:setValue(cfMap.shieldManage, ap.userConfig.shieldManage)
	end

	if action == '/space' then
		ap.userConfig.spaceCapableOverride = not ap.userConfig.spaceCapableOverride -- might just auto detect if space engines?
		P('Space function '..ternary(ap.userConfig.spaceCapableOverride,'enabled','disabled'))
		Config:setValue(cfMap.spaceCapableOverride, ap.userConfig.spaceCapableOverride)
	end

	if action == '/agl' then
		if num2 == nil then return Err('Missing input') end
		num2 = clamp(num2,0,20)
		ap:setAgl(num2)
		P('AGL set to '..ap.userConfig.agl)
	end

	if action == '/hover' then
		if num2 == nil then return end
		num2 = clamp(num2,0.5,60)
		ap:setHoverHeight(num2)
		P('Hover height set to '..ap.userConfig.hoverHeight)
	end

	if action == '/atp' then
		ap:toggleThrottleBurnProtection()
		P('Auto throttle burn protection '..ternary(ap.userConfig.throttleBurnProtection,'enabled','disabled'))
	end

	if action == '/orbitalt' then
		if gC.oribtalHold then
			if num2 == nil then
				return Err'No valid number provided'
			end
			gC.manualOrbitAlt = round(num2,0)
			P('Orbit Alt set to '..gC.manualOrbitAlt)
			setTargetOrbitAlt()
		else
			Err"Engage 'Orbital hold' mode first!"
		end
	end

	if Radar ~= nil then
		if action == '/radar' then
			Radar:toggleWidget()
		elseif action == '/radarbox' then
			Radar:toggleBoxes()
		end
	end

	if action == '/freeze' and not player.isSeated() then
		player.freeze(not player.isFrozen())
		P('Frozen = ' ..tostring(player.isFrozen()))
	end

	if action == '/aggalt' and links.antigrav ~= nil then
		if num2 == nil then
			return Err'Enter valid altitude number >= 1000!'
		end
		num2 = math.max(1000,round(num2,0))
		links.antigrav.setTargetAltitude(num2)
		P('AGG target altitude: '..num2)
	end

	---@TODO toggle for warp drive widget
	-- if action == '/warp' and links.warpdrive ~= nil then
	-- end

	if action == '/unit' and _hud then
		_hud.toggleUnitWidget()
	end
end