mmbClick = 0 -- special MMB double-click handler
forwardClick = 0 -- special W double-tap handler

inputs = {
	pitch = 0,
	roll = 0,
	yaw = 0,
	brake = 0,
	manualBrake = false,
	brakeLock = false,
	up = false,
	down = false,
	left = false,
	right = false,
	alt = false,
	shift = false,
	mouseLeft = false,
	direction = vec3(0,0,0),
	rotation = vec3(0,0,0),
	mu = false,
	md = false,
	ml = false,
	mr = false
}
local axisLong = axisCommandId.longitudinal
local axisLat = axisCommandId.lateral
local axisVert = axisCommandId.vertical

function onShift(on)
	inputs.shift = on
	-- P('Shift: ' .. tostring(on))
end

function onAlt(on)
	inputs.alt = on
	-- P('Alt: ' .. tostring(on))
end

function onMouseDown()
	inputs.mouseLeft = true
end

function onMouseUp()
	inputs.mouseLeft = false
end

function onAlt1()
	if inputs.shift then return HUD.toggleMainMenu() end
	local ap, s, cD = AutoPilot, ship, cData
	if not globals.maneuverMode then
		return ap:toggleState(not ap.enabled)
	end
	-- Maneuver mini-Autopilot :)
	if not ap.target then return end
	if s.gotoLock then
		s.resetMoving()
		resetAP()
		ap.target = nil
	elseif cD.isLanded then
		P'[E] Liftoff first!'
	else
		inputs.brakeLock = false
		s.switchState('ALTITUDE')
		s.gotoLock = ap.target
		s.targetVector = (s.gotoLock - cD.position):normalize()
		s.travel = true
		P("Moving to: " .. tostring(Vec3ToPosString(ap.target)))
	end
end

function onAlt2()
	local gC, _inputs = globals, inputs
	if cData.warpOn or ship.landingMode then
		gC.altitudeHold = false
		gC.followMode = false
		return
	end
	gC.manualOrbitAlt = 0
	if not (gC.altitudeHold or gC.followMode) then
		if gC.maneuverMode or not _inputs.shift then
			gC.holdAltitude = cData.altitude
			gC.altitudeHold = true
		else
			if player.isSeated() == false then
				gC.followMode = true
			else
				P('[E] Not on Remote, follow disabled!')
			end
		end
		return
	end
	if not gC.altitudeHold and gC.followMode then
		gC.followMode = false
	elseif gC.altitudeHold and not gC.followMode then
		gC.altitudeHold = false
	end
end

function onAlt3()
	local gC = globals
	if cData.warpOn or gC.maneuverMode then return end
	gC.manualOrbitAlt = 0
	if not gC.orbitalHold then
		if gC.spaceCapable then
			resetModes()
			gC.orbitalHold = true
			setTargetOrbitAlt()
		else
			P('Space thrust not detected: Orbital Hold Disabled')
			gC.orbitalHold = false
		end
	else
		gC.orbitalHold = false
	end
end

function onAlt4()
	local gC = globals
	if not gC.radialOut and not gC.radialIn and not gC.cameraAim then
		gC.radialMode = 'radial out'
		gC.radialOut = not gC.radialOut
	elseif gC.radialOut then
		gC.radialMode = 'radial in'
		gC.radialOut = not gC.radialOut
		gC.radialIn = not gC.radialIn
	elseif gC.radialIn then
		gC.radialMode = 'camera aim'
		gC.cameraAim = true
		gC.radialIn = not gC.radialIn
	else
		gC.radialMode = 'off'
		gC.cameraAim = false
	end
end

function onAlt5()
	local gC = globals
	if gC.boostMode == 'all' then
		gC.boostMode = 'primary'
	elseif gC.boostMode == 'primary' then
		gC.boostMode = 'hybrid'
	elseif gC.boostMode == 'hybrid' then
		gC.boostMode = 'locked'
	else gC.boostMode = 'all'
	end
end

local function newRtIdx(current, maxIdx, down)
	if down then return math.max(1, current - 1) end
	return math.min(maxIdx, current + 1)
end

function onAlt6()
	local ap, rdb = AutoPilot, RouteDatabase
	if ap.enabled or #rdb.routes < 1 then return end
	if not inputs.shift and inputs.alt then
		ap.currentRouteIndex = newRtIdx(ap.currentRouteIndex or 1, #rdb.routes, true)
		ap:setActiveRoute(ap.currentRouteIndex)
	elseif inputs.shift and inputs.alt then
		setApTarget(Config:getValue(configDatabankMap.base))
	end
end

function onAlt7()
	local ap, rdb = AutoPilot, RouteDatabase
	if ap.enabled or #rdb.routes < 1 then return end
	if not inputs.shift and inputs.alt then
		ap.currentRouteIndex = newRtIdx(ap.currentRouteIndex or 1, #rdb.routes, false)
		ap:setActiveRoute(ap.currentRouteIndex)
	elseif inputs.shift and inputs.alt then
		Config:setValue(configDatabankMap.base, cData.position)
		local aPos = Vec3ToPosString(cData.position)
		P("Base set to: " .. tostring(aPos))
	end
end

-- OLD: AR mode toggle
-- function onAlt7()
-- 	local gC = globals
-- 	if gC.arMode == 'none' then
-- 		gC.arMode = 'planets'
-- 	elseif gC.arMode == 'planets' then
-- 		gC.arMode = 'moons'
-- 	elseif gC.arMode == 'moons' then
-- 		gC.arMode = 'both'
-- 	else
-- 		gC.arMode = 'none'
-- 	end
-- end

function onAlt8()
	local gC, ap = globals, AutoPilot
	if inputs.shift then
		ap.userConfig.slowFlat = not ap.userConfig.slowFlat
	elseif inputs.alt then
		gC.rotationDampening = not gC.rotationDampening --useful for PvP, probably wont keep on this key?
	end
end

function onAlt9()
	local gC, ap = globals, AutoPilot
	if cData.warpOn or ap.enabled then
		return P"[E] Can't toggle now"
	end
	if gC.maneuverMode then ship.resetMoving() end
	gC.maneuverMode = not gC.maneuverMode
	Config:setValue(configDatabankMap.maneuverMode, gC.maneuverMode)
	if gC.maneuverMode then return end
	setThrottle()
	navCom:resetCommand(axisCommandId.vertical)
	navCom:deactivateGroundEngineAltitudeStabilization()
end

function onWarpDown() -- Warp drive v
	if links.warpdrive ~= nil then links.warpdrive.activateWarp() end
end

function onAntigravDown() -- Antigrav v
	if links.antigrav ~= nil then links.antigrav.toggle() end
end

function onBoosterDown() -- Booster v
	Nav:toggleBoosters()
end

function onLightDown() -- Light v
	if unit.isAnyHeadlightSwitchedOn() then
		unit.switchOffHeadlights()
	else
		unit.switchOnHeadlights()
	end
end

local DOUBLE_CLICK_MIN_THRESHOLD = 0.1 -- seconds
local DOUBLE_CLICK_MAX_THRESHOLD = 0.4 -- seconds

function onMmbDown() -- Stop engines v
	if globals.maneuverMode then
		local currentTime = system.getUtcTime()
		mmbClick = mmbClick or 0
		local time_since_last_click = currentTime - mmbClick
		if mmbClick == 0 or
			time_since_last_click < DOUBLE_CLICK_MIN_THRESHOLD or
			currentTime - mmbClick >= DOUBLE_CLICK_MAX_THRESHOLD then
			-- First click or too slow for double click
			mmbClick = currentTime
		else
			mmbClick = 0 -- Double click within valid range
			ship.toggleMmb()
		end
	else
		navCom:resetCommand(axisLong)
	end
end

function onMmbUp() -- Stop engines ^
end

function onLandingGearDown() -- Landing gear v
	local gC, ap = globals, AutoPilot

	-- Reset some states
	if ap.enabled then ap:toggleState(false) end
	if ship.mmbThrottle then ship.toggleMmb() end
	gC.altitudeHold = false
	gC.prevStdMode = false

	inputs.brake = 0
	inputs.brakeLock = false
	-- When already landed, do a liftoff to hover height in active mode
	if cData.isLanded then
		ship.landingMode = false
		-- Liftoff in either mode
		if not gC.maneuverMode then
			return ap:toggleLandingMode(false)
		end
		moveVert(ap.userConfig.hoverHeight)
		ship.takeoff = true
		ship.travel = false
		ship.vertical = false
		return
	end

	-- Not landed and landing mode is active, toggle it off
	if (ap.landingMode or ship.landingMode) then
		ap.landingMode = false
		ship.landingMode = false
		if gC.maneuverMode then
			--return ternary(gC.maneuverMode, ship.resetManeuver(), ship.resetMoving())
			ship.resetMoving()
			if gC.prevStdMode then
				gC.maneuverMode = false
			end
		end
		if not gC.maneuverMode then
			setThrottle()
			navCom:activateGroundEngineAltitudeStabilization()
			if not gC.startup then
				ap:toggleLandingMode(false)
			end
		end
		return
	end

	-- Finally, turn on landing mode and remember coming from Standard mode
	if not gC.maneuverMode then
		ship.resetManeuver()
		gC.prevStdMode = true
	end
	ship.landingMode = true
	ap.landingMode = false
	-- ap:toggleLandingMode(true)
	ship.prepLanding()
	setThrottle(1,1,1)
end

function onUpArrowDown() -- Up Arrow v
	inputs.md = false
	local gC = globals
	if HUD.Config.mainMenuVisible then
		inputs.mu = true
	else
		inputs.up = true
		if gC.maneuverMode then
			isStartup = false
			inputs.brakeLock = false
			inputs.brake = 0
		else
			navCom:resetCommand(axisVert)
			navCom:deactivateGroundEngineAltitudeStabilization()
			navCom:updateCommandFromActionStart(axisVert, 1.0)
		end
	end
	gC.verticalState = true
end

function onUpArrowUp() -- Up Arrow ^
	inputs.mu = false
	inputs.up = false
	local gC = globals
	if not HUD.Config.mainMenuVisible then
		if gC.maneuverMode then
			if gC.altitudeHold then gC.holdAltitude = cData.altitude end
		else
			navCom:resetCommand(axisVert)
			navCom:activateGroundEngineAltitudeStabilization()
		end
	end
	gC.verticalState = false
end

function onDownArrowDown() -- Down Arrow v
	inputs.mu = false
	local gC = globals
	if HUD.Config.mainMenuVisible then
		inputs.md = true
	else
		inputs.down = true
		if not (cData.isLanded or gC.maneuverMode) then
			navCom:resetCommand(axisVert)
			navCom:deactivateGroundEngineAltitudeStabilization()
			navCom:updateCommandFromActionStart(axisVert, -1.0)
		end
	end
	gC.verticalState = true
end

function onDownArrowUp() -- Down Arrow ^
	inputs.md = false
	inputs.down = false
	local gC = globals
	if not HUD.Config.mainMenuVisible then
		if gC.maneuverMode then
			if gC.altitudeHold then gC.holdAltitude = cData.altitude end
		else
			-- navCom.targetGroundAltitude = AutoPilot.userConfig.hoverHeight
			navCom:resetCommand(axisVert)
			navCom:activateGroundEngineAltitudeStabilization()
		end
	end
	gC.verticalState = false
end

local function isForStdMode()
	return not (globals.maneuverMode or HUD.Config.mainMenuVisible)
end

local function axLat(isStart,value)
	if globals.maneuverMode then return end
	if isStart then
		navCom:updateCommandFromActionStart(axisLat, value)
	else
		navCom:updateCommandFromActionStop(axisLat, value)
	end
end

local function resetLeftRight()
	inputs.direction.x = 0
	inputs.left = false
	inputs.right = false
	inputs.ml = false
	inputs.mr = false
end

function onLeftArrowDown() -- Strafe Left Arrow v
	resetLeftRight()
	if HUD.Config.mainMenuVisible then inputs.ml = true return end
	inputs.direction.x = -1
	inputs.left = true
	if isForStdMode() then axLat(true,-1) end
	globals.lateralState = true
end

function onLeftArrowUp() -- Strafe Left Arrow ^
	resetLeftRight()
	if isForStdMode() then axLat(false,1) end
	globals.lateralState = false
end

function onRightArrowDown() -- Strafe Right Arrow v
	resetLeftRight()
	if HUD.Config.mainMenuVisible then inputs.mr = true return end
	inputs.direction.x = 1
	inputs.right = true
	if isForStdMode() then axLat(true,1) end
	globals.lateralState = true
end

function onRightArrowUp() -- Strafe Right Arrow ^
	resetLeftRight()
	if isForStdMode() then axLat(false,-1) end
	globals.lateralState = false
end

function onForwardDown() -- Forward v
	inputs.pitch = inputs.pitch - 1
	if not globals.maneuverMode or not inputs.alt then return end
	local currentTime = system.getUtcTime()
	forwardClick = forwardClick or 0
	local time_since_last_click = currentTime - forwardClick
	if forwardClick == 0 or
		time_since_last_click < DOUBLE_CLICK_MIN_THRESHOLD or
		currentTime - forwardClick >= DOUBLE_CLICK_MAX_THRESHOLD then
		forwardClick = currentTime
	else
		forwardClick = 0
		ship.toggleMmb()
	end
end

function onForwardUp() -- Forward ^
	inputs.pitch = 0
end

function onBackwardDown() -- Backward v
	inputs.pitch = inputs.pitch + 1
end

function onBackwardUp() -- Backward ^
	inputs.pitch = 0
end

function onLeftDown() -- Left v
	inputs.roll = inputs.roll - 1
end

function onLeftUp() -- Left ^
	inputs.roll = 0
end

function onRightDown() -- Right v
	inputs.roll = inputs.roll + 1
end

function onRightUp() -- Right ^
	inputs.roll = 0
end

function onYawLeftDown()
	if inputs.yaw < 0 then
		ship.rotationSpeed = ship.rotationSpeedMin
	end
	inputs.yaw = 1
end

function onYawLeftUp()
	if inputs.yaw > 0 then
		inputs.yaw = 0
	else
		ship.rotationSpeed = ship.rotationSpeedMin
	end
end

function onYawRightDown()
	if inputs.yaw > 0 then
		ship.rotationSpeed = ship.rotationSpeedMin
	end
	inputs.yaw = -1
end

function onYawRightUp()
	if inputs.yaw < 0 then
		inputs.yaw = 0
	else
		ship.rotationSpeed = ship.rotationSpeedMin
	end
end

function onGroundAltitudeDownDown(loop) -- Altitude Down v
	local gC, s = globals, ship
	if gC.maneuverMode and gC.altitudeHold then
		if s.holdAltitude > 109 then
			s.holdAltitude = RoundAlt(s.holdAltitude, ternary(loop, -5, -10))
		end
	else
		AutoPilot:addHoverHeight(-0.25, loop)
	end
end

function onGroundAltitudeUpDown(loop) -- Altitude Up v
	local gC, s = globals, ship
	if gC.maneuverMode and gC.altitudeHold then
		s.holdAltitude = RoundAlt(s.holdAltitude, ternary(loop, 5, 10))
	else
		AutoPilot:addHoverHeight(0.25, loop)
	end
end

function onSpeedUpDown() -- Speed Up v
	navCom:updateCommandFromActionStart(axisLong, 5.0)
	globals.safetyThrottle = false
end

function onSpeedUpLoop() -- Speed Up >
	navCom:updateCommandFromActionLoop(axisLong, 1.0)
	globals.safetyThrottle = false
end

function onSpeedDownDown() -- Speed Down v
	navCom:updateCommandFromActionStart(axisLong, -5.0)
	globals.safetyThrottle = false
end

function onSpeedDownLoop() -- Speed Down >
	navCom:updateCommandFromActionLoop(axisLong, -1.0)
	globals.safetyThrottle = false
end

function onBrakeDown() -- Brake v
	inputs.brake = 1
	inputs.manualBrake = true
	AutoPilot.enabled = false
	resetAP()
	inputs.brakeLock = inputs.alt
end

function onBrakeLoop() -- Brake >
	if globals.maneuverMode then inputs.brake = 1 return end
	if navCom:getAxisCommandType(axisLong) == axisCommandType.byTargetSpeed then
		local speed = navCom:getTargetSpeed(axisLong)
		if (math.abs(speed) > 0.01) then
			navCom:updateCommandFromActionLoop(axisLong, - utils.sign(speed))
		end
	end
end

function onBrakeUp() -- Brake ^
	if not inputs.alt then
		inputs.brake = 0
		inputs.manualBrake = false
	end
end

function onActionStart(id)
	if id == "lalt" then onAlt(true) end
	if id == "lshift" then onShift(true) end
	if id == "brake" then onBrakeDown() end
	if id == "option1" then
		onAlt1()
	elseif id == "option2" then
		onAlt2()
	elseif id == "option3" then
		onAlt3()
	elseif id == "option4" then
		onAlt4()
	elseif id == "option5" then
		onAlt5()
	elseif id == "option6" then
		onAlt6()
	elseif id == "option7" then
		onAlt7()
	elseif id == "option8" then
		onAlt8()
	elseif id == "option9" then
		onAlt9()
	elseif id == "forward" then
		onForwardDown()
	elseif id == "backward" then
		onBackwardDown()
	elseif id == "left" then
		if globals.maneuverMode then
			onLeftArrowDown()
		else
			onLeftDown()
		end
	elseif id == "right" then
		if globals.maneuverMode then
			onRightArrowDown()
		else
			onRightDown()
		end
	elseif id == "yawleft" then
		onYawLeftDown()
	elseif id == "yawright" then
		onYawRightDown()
	elseif id == "strafeleft" then
		onLeftArrowDown()
	elseif id == "straferight" then
		onRightArrowDown()
	elseif id == "up" then
		onUpArrowDown()
	elseif id == "down" then
		onDownArrowDown()
	elseif id == "groundaltitudeup" then
		onGroundAltitudeUpDown()
	elseif id == "groundaltitudedown" then
		onGroundAltitudeDownDown()
	elseif id == "gear" then
		onLandingGearDown()
	elseif id == "light" then
		onLightDown()
	elseif id == "leftmouse" then
		onMouseDown()
	elseif id == "stopengines" then
		onMmbDown()
	elseif id == "antigravity" then
		onAntigravDown()
	elseif id == "booster" then
		onBoosterDown()
	end
	if not globals.maneuverMode then
		if id == "speedup" then
			onSpeedUpDown()
		elseif id == "speeddown" then
			onSpeedDownDown()
		end
	end
end

function onActionEnd(id)
	if id == "lalt" then onAlt(false) end
	if id == "lshift" then onShift(false) end
	if id == "brake" then onBrakeUp() end
	if id == "forward" then
		onForwardUp()
	elseif id == "backward" then
		onBackwardUp()
	elseif id == "left" then
		if globals.maneuverMode then
			onLeftArrowUp()
		else
			onLeftUp()
		end
	elseif id == "right" then
		if globals.maneuverMode then
			onRightArrowUp()
		else
			onRightUp()
		end
	elseif id == "yawleft" then
		onYawLeftUp()
		ship.rotationSpeed = ship.rotationSpeedMin
	elseif id == "yawright" then
		onYawRightUp()
		ship.rotationSpeed = ship.rotationSpeedMin
	elseif id == "strafeleft" then
		onLeftArrowUp()
	elseif id == "straferight" then
		onRightArrowUp()
	elseif id == "up" then
		onUpArrowUp()
	elseif id == "down" then
		onDownArrowUp()
	elseif id == "leftmouse" then
		onMouseUp()
	end
end

function onActionLoop(id)
	if id == "groundaltitudeup" then
		onGroundAltitudeUpDown(true)
	elseif id == "groundaltitudedown" then
		onGroundAltitudeDownDown(true)
	elseif id == "brake" then
		onBrakeLoop()
	elseif id == "left" then
		if globals.maneuverMode then
			onLeftArrowDown()
		else
			onLeftDown()
		end
	elseif id == "right" then
		if globals.maneuverMode then
			onRightArrowDown()
		else
			onRightDown()
		end
	end
	if not globals.maneuverMode then
		if id == "speedup" then
			onSpeedUpLoop()
		elseif id == "speeddown" then
			onSpeedDownLoop()
		elseif id == "strafeleft" then
			onLeftArrowDown()
		elseif id == "straferight" then
			onRightArrowDown()
		end
	end
end