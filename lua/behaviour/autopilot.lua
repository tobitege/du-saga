AutoPilot = (
function()
	local this = {}

	this.enabled = false
	this.userConfig = {
		agl = agl,
		apState = false,
		autoAGGAdjust = autoAGGAdjust,
		dockMode = dockMode,
		dockWidget = dockWidget,
		hoverHeight = hoverHeight,
		landingMode = false,
		maxPitch = maxPitch,
		maxRoll = maxRoll,
		maxSpaceSpeed = maxSpaceSpeed,
		shieldManage = shieldManage,
		slowFlat = true,
		spaceCapableOverride = spaceCapableOverride,
		throttleBurnProtection = throttleBurnProtection,
		wingStallAngle = wingStallAngle,
		landSpeedHigh = maxLandingSpeedHigh,
		landSpeedLow = maxLandingSpeedLow,
		travelAlt = travelAlt,
		base = nil
	}

	function this:init()
		this:setTargetData(cData.position)
		Config.defaults[configDatabankMap.agl] = this.userConfig.agl
		Config.defaults[configDatabankMap.apState] = this.enabled
		Config.defaults[configDatabankMap.autoAGGAdjust] = this.userConfig.autoAGGAdjust
		Config.defaults[configDatabankMap.base] = nil
		Config.defaults[configDatabankMap.dockMode] = clamp(this.userConfig.dockMode or 1,1,3)
		Config.defaults[configDatabankMap.dockWidget] = this.userConfig.dockWidget
		Config.defaults[configDatabankMap.hoverHeight] = this.userConfig.hoverHeight
		Config.defaults[configDatabankMap.landingMode] = this.userConfig.landingMode
		Config.defaults[configDatabankMap.maxPitch] = this.userConfig.maxPitch
		Config.defaults[configDatabankMap.maxRoll] = this.userConfig.maxRoll
		Config.defaults[configDatabankMap.maxSpaceSpeed] = this.userConfig.maxSpaceSpeed
		Config.defaults[configDatabankMap.shieldManage] = this.userConfig.shieldManage
		Config.defaults[configDatabankMap.slowFlat] = this.userConfig.slowFlat
		Config.defaults[configDatabankMap.spaceCapableOverride] = this.userConfig.spaceCapableOverride
		Config.defaults[configDatabankMap.throttleBurnProtection] = this.userConfig.throttleBurnProtection
		Config.defaults[configDatabankMap.wingStallAngle] = this.userConfig.wingStallAngle
		Config.defaults[configDatabankMap.landSpeedHigh] = this.userConfig.landSpeedHigh
		Config.defaults[configDatabankMap.landSpeedLow] = this.userConfig.landSpeedLow
		Config.defaults[configDatabankMap.travelAlt] = this.userConfig.travelAlt

		EventSystem:register('ConfigDBChanged', this.applyConfig, this)
		this:applyConfig()

		construct.setDockingMode(this.userConfig.dockMode)

		this:resumeFromDatabank()
		if not globals.maneuverMode then
			this:toggleLandingMode(this.userConfig.landingMode)
		end
	end

	function this:applyConfig()
		this.userConfig.agl = Config:getValue(configDatabankMap.agl)
		this.userConfig.autoAGGAdjust = Config:getValue(configDatabankMap.autoAGGAdjust)
		this.userConfig.base = Config:getValue(configDatabankMap.base)
		this.userConfig.dockMode = Config:getValue(configDatabankMap.dockMode)
		this.userConfig.dockWidget = Config:getValue(configDatabankMap.dockWidget)
		this.userConfig.hoverHeight = Config:getValue(configDatabankMap.hoverHeight)
		this.userConfig.landingMode = Config:getValue(configDatabankMap.landingMode)
		this.userConfig.maxPitch = Config:getValue(configDatabankMap.maxPitch)
		this.userConfig.maxRoll = Config:getValue(configDatabankMap.maxRoll)
		this.userConfig.maxSpaceSpeed = Config:getValue(configDatabankMap.maxSpaceSpeed)
		this.userConfig.shieldManage = Config:getValue(configDatabankMap.shieldManage)
		this.userConfig.slowFlat = Config:getValue(configDatabankMap.slowFlat)
		this.userConfig.spaceCapableOverride = Config:getValue(configDatabankMap.spaceCapableOverride)
		this.userConfig.throttleBurnProtection = Config:getValue(configDatabankMap.throttleBurnProtection)
		this.userConfig.landSpeedHigh = Config:getValue(configDatabankMap.landSpeedHigh)
		this.userConfig.landSpeedLow = Config:getValue(configDatabankMap.landSpeedLow)
		this.userConfig.travelAlt = Config:getValue(configDatabankMap.travelAlt)
		if not (cData and cData.isLanded) then
			this:setHoverHeight(this.userConfig.hoverHeight)
		end
		this:updateMaxSpaceSpeed()
	end

	function this:resumeFromDatabank()
		local lastState = Config:getDynamicValue(configDatabankMap.apState)
		if lastState then this:toggleState(lastState) end

		local target = Config:getDynamicValue(configDatabankMap.currentTarget)
		if type(target) ~= 'table' then
			target = Config:getValue(configDatabankMap.base)
		end
		if type(target) == 'table' then
			if target.x ~= nil then
				this:setTarget(target)
			elseif #target == 3 and target[3] and RouteDatabase:getDatabankName() == target[3] then
				this:setActiveRoute(target[1], target[2])
			end
		end
	end

	---@param state boolean
	function this:toggleState(state)
		if state == nil then state = not this.enabled end
		-- do not activate AP while in warp
		if (cData.warpOn or globals.maneuverMode) and state then return end
		this.enabled = state
		if this.enabled then
			this:toggleLandingMode(false)
			this:updateMaxSpaceSpeed()
		else
			resetModes()
		end
		Config:setDynamicValue(configDatabankMap.apState, this.enabled)
	end

	function this:toggleShieldManage(state)
		if state == nil then state = not this.userConfig.shieldManage end
		this.userConfig.shieldManage = state
		Config:setValue(configDatabankMap.shieldManage, state)
	end

	function this:toggleThrottleBurnProtection(state)
		if state == nil then state = not this.userConfig.throttleBurnProtection end
		this.userConfig.throttleBurnProtection = state
		Config:setValue(configDatabankMap.throttleBurnProtection, state)
	end

	function this:toggleSpaceCapableOverride(state)
		if state == nil then state = not this.userConfig.spaceCapableOverride end
		this.userConfig.spaceCapableOverride = state
		Config:setValue(configDatabankMap.spaceCapableOverride, state)
		initEngines()
	end

	function this:toggleSlowFlat(state)
		if state == nil then state = not this.userConfig.slowFlat end
		this.userConfig.slowFlat = state
		Config:setValue(configDatabankMap.slowFlat, state)
	end

	function this:setActiveRoute(routeIndex, pointIndex)
		routeIndex = tonumber(routeIndex)
		if not routeIndex then return end
		if tonumber(pointIndex) == nil then pointIndex = 1 end
		local rdb = RouteDatabase
		local targetPos = rdb:getPointCoordinates(routeIndex, pointIndex)
		if not targetPos then return end
		this.currentRouteIndex = routeIndex
		this.currentPointIndex = pointIndex
		this:setTargetData(targetPos)
		Config:setDynamicValue(configDatabankMap.currentTarget, {this.currentRouteIndex,this.currentPointIndex,rdb.databank.name})
		local cnt = rdb:getRoutePointCount(routeIndex)
		this.targetIsLastPoint = cnt == 0 or this.currentPointIndex == cnt
	end

	function this:setTarget(pos)
		this:setTargetData(pos)
		this.targetIsLastPoint = true
		Config:setDynamicValue(configDatabankMap.currentTarget, pos)
	end

	function this:updateMaxSpaceSpeed()
		local maxUserSpeed = this.userConfig.maxSpaceSpeed
		local maxConstructSpeed = cData.maxSpeed*3.6 - 1
		if maxUserSpeed == 0 then
			this.maxSpaceSpeed = maxConstructSpeed
		else
			this.maxSpaceSpeed = maxUserSpeed
		end
	end

	function this:onPointReached()
		if not this.targetIsLastPoint then
			if this.currentPointIndex ~= nil then
				this.currentPointIndex = this.currentPointIndex + 1
				this:setActiveRoute(this.currentRouteIndex, this.currentPointIndex)
			end
			resetAP()
			return
		end -- Next point doesn't exist
		this:toggleState(false)
		this:toggleLandingMode(true)
	end

	-- Triggered if a route is deleted while it's the target
	function this:onRouteUnloaded()
		this.currentRouteIndex = nil
		this.currentPointIndex = nil
		this:toggleState(false)
	end

	function this:setTargetData(pos)
		this.target = vec3(pos)
		this.targetBody = findClosestBody(this.target)
		this.targetAltitude = getAltitude(this.target)
		this.targetLoc = getLoc(this.targetBody, this.targetAltitude)
		this.targetIsLastPoint = false
	end

	function this:addHoverHeight(delta, loop)
		if tonumber(delta) == nil then return P'E' end
		if loop then
			navCom:updateTargetGroundAltitudeFromActionLoop(delta)
		else
			navCom:updateTargetGroundAltitudeFromActionStart(delta)
		end
		this:setHoverHeight(this.userConfig.hoverHeight + delta)
	end

	function this:setHoverHeight(height)
		if height and tonumber(height) ~= nil then
			this.userConfig.hoverHeight = tonumber(height)
		end
		this.userConfig.hoverHeight = round2(clamp(this.userConfig.hoverHeight or 20,0,50),1)
		if not (this.landingMode or ship.landingMode) then
			navCom:setTargetGroundAltitude(this.userConfig.hoverHeight+this.userConfig.agl)
		end
		Config:setValue(configDatabankMap.hoverHeight, this.userConfig.hoverHeight)
	end

	function this:setAgl(height)
		if tonumber(height) == nil then return end
		this.userConfig.agl = tonumber(height)
		Config:setValue(configDatabankMap.agl, height)
	end

	function this:resetNavCom(stab)
		if stab == true then
			navCom:deactivateGroundEngineAltitudeStabilization()
		elseif stab == false then
			navCom:deactivateGroundEngineAltitudeStabilization()
		end
		navCom:resetCommand(axisCommandId.longitudinal)
		navCom:setThrottleCommand(axisCommandId.longitudinal, 0)
		navCom:setTargetSpeedCommand(axisCommandId.longitudinal,0)
		navCom:resetCommand(axisCommandId.vertical)
		navCom:setTargetSpeedCommand(axisCommandId.vertical,0)
		Nav:update()
	end

	function this:toggleLandingMode(state)
		if state == nil then state = not this.landingMode end
		this.landingMode = state == true
		local gC = globals
		Config:setValue(configDatabankMap.landingMode, this.landingMode)
		if gC.maneuverMode then return end
		if this.landingMode then
			gC.altitudeHold = false
			gC.orbitalHold = false
			gC.rotationDampening = true
			inputs.brake = 1
			inputs.brakeLock = false
			unit.deployLandingGears()
			if not gC.maneuverMode then
				if unit.getControlMode() == 1 then
					swapControl()
				end
				navCom:setThrottleCommand(axisCommandId.longitudinal, 0)
				navCom:setTargetSpeedCommand(axisCommandId.longitudinal,0)
				navCom:setTargetGroundAltitude(-1)
			end
			links.electronics:OpenDoors()
		elseif not gC.maneuverMode then
			navCom:resetCommand(axisCommandId.vertical)
			navCom:setTargetGroundAltitude(AutoPilot.userConfig.hoverHeight)
			navCom:activateGroundEngineAltitudeStabilization()
			Nav:update()
			unit.retractLandingGears()
			links.electronics:CloseDoors()
			inputs.brake = 0
		end
	end
	return this
end
)()

function getLoc(body, altitude)
	if body ~= nil and body.hasAtmosphere and altitude < body.atmoRadius - body.radius then
		return 'surface'
	elseif body ~= nil and not body.hasAtmosphere and altitude < body.surfaceMaxAltitude + 5000 then
		return 'surface'
	end
	return 'space'
end

function orbitHold()
	setTargetOrbitAlt()
	local gCache, ap = globals, AutoPilot
	local apoDiff = (gCache.targetOrbitAlt - cData.orbitFocus.orbitAltTarget)
	local minmax = 20000 + cData.constructSpeed
	local orbPitch = (utils.smoothstep(apoDiff, -minmax, minmax) - 0.5) * 2 * ap.userConfig.maxPitch
	if cData.inAtmo then
		orbPitch = ap.userConfig.maxPitch
	end
	return orbPitch
end

function altHold()
	local gCache, ap, cD = globals, AutoPilot, cData
	if ap.enabled or gCache.altitudeHold or gCache.orbitalHold or gCache.apMode == 'Orbit' then
		local altitude = cD.altitude
		local altDiff = (gCache.holdAltitude - altitude)
		local minmax = 500 + cD.constructSpeed
		gCache.targetPitch = (utils.smoothstep(altDiff, -minmax, minmax) - 0.5) * 2 * ap.userConfig.maxPitch
		if altDiff < 0 and cData.inAtmo then
			gCache.targetPitch = gCache.targetPitch/6
		end
		local pitch = cD.rpy.pitch
		local autoPitchThreshold = 0.1
		if math.abs(gCache.targetPitch - pitch) > autoPitchThreshold then
			if (pitchPID3 == nil) then
				pitchPID3 = pid.new(0.02, 0, 0.1)
			end
			pitchPID3:inject(gCache.targetPitch - pitch)
			local autoPitchInput2 = pitchPID3:get()
			pitchInput2 = autoPitchInput2
		end
	end
end

function controlMode()
	return ternary(unit.getControlMode() == 0, 'travel', 'cruise')
end

function swapControl()
	if unit.getControlMode() > 0 then
		unit.cancelCurrentControlMasterMode()
	end
	Nav:update()
end

function resetAP()
	local gC = globals
	gC.aimTarget = "none"
	gC.orbitLock = false
	gC.brakeTrigger = false
	gC.spaceBrakeTrigger = false
	gC.stallProtect = false
	gC.lastProjectedDistance = 10000000
	gC.missedTarget = false
	gC.horizontalStopped = false
	gC.apMode = 'standby'
	gC.initTurn = true
	inputs.brakeLock = false
end

function resetModes()
	local gC, ap = globals, AutoPilot
	ap.enabled = false
	ap.landingMode = false
	resetAP()
	gC.altitudeHold = false
	gC.orbitalHold = false
	gC.followMode = false
	gC.radialIn = false
	gC.radialOut = false
	gC.cameraAim = false
	radialMode = 'none'
end

function setTargetOrbitAlt()
	local gCache = globals
	gCache.targetOrbitAlt = 100000 -- dummy
	local body = cData.body
	if body == nil then return end
	local targetBody = AutoPilot.targetBody
	if targetBody == nil then return end
	local altBuff = cData.mass/2500
	if gCache.apMode == 'Orbit' then
		if sameBody and targetBody.hasAtmosphere then
			gCache.targetOrbitAlt = (targetBody.atmoRadius - targetBody.radius)+1500+altBuff
		elseif not sameBody and body.hasAtmosphere then
			gCache.targetOrbitAlt = (body.atmoRadius - body.radius)+5000+altBuff
		elseif (not sameBody and not body.hasAtmosphere) or (sameBody and not targetBody.hasAtmosphere) then
			gCache.targetOrbitAlt = body.surfaceMaxAltitude + 3000+altBuff
		end
	elseif gCache.manualOrbitAlt ~= 0 then
		gCache.targetOrbitAlt = gCache.manualOrbitAlt
	else
		if body.hasAtmosphere and gCache.manualOrbitAlt == 0 then
			gCache.targetOrbitAlt = (body.atmoRadius - body.radius)+3000+altBuff --- Setup these to be manually adjustable like altHold.
		else
			gCache.targetOrbitAlt = body.surfaceMaxAltitude + 3000+altBuff
		end
	end
end