--based on STEC class by Shadow Templar v1.19
local abs, clamp, max, min, atan, rad, sign, uround, mceil, sqrt = math.abs, utils.clamp, math.max, math.min, math.atan, math.rad, utils.sign, utils.round, math.ceil, math.sqrt

function STEC()
	local self = {}
	-- Speed scale factor for rotations
	self.rotationSpeed = 0.25
	-- Starting speed for auto-scaling rotation
	self.rotationSpeedMin = 0.25
	-- Maximum speed for auto-scaling rotation
	self.rotationSpeedMax = 15
	-- Step for increasing the rotation speed
	self.rotationStep = 0.025
	-- Amount of thrust to apply in world space, in Newton. Stacks with {{direction}}
	self.thrust = vec3()
	self.angularThrust = vec3()
	self.inertialDampening = true ---@TODO not yet toggable
	self.IDIntensity = 9
	-- Braking speed multiplier
	self.brakingFactor = 10
	-- Whether or not the vessel should attempt to face perpendicular to the gravity vector
	self.followGravity = true
	-- Control Mode - Travel (0) or Cruise (1)
	self.controlMode = nil -- must be nil for initialisation!
	-- Alternate Control Mode for remote control (Cruise)
	self.alternateCM = false
	-- Amount of throttle to apply. -100-100 range
	self.throttle = 100
	-- Placeholder for throttle value when switching control modes
	self.tempThrottle = 100
	self.mmbThrottle = false -- Middle-Mouse-Button double-click = 0%/100% throttle toggle
	self.priorityTags1 = "brake,airfoil,torque,vertical,lateral,longitudinal"
	self.priorityTags2 = "atmospheric_engine,space_engine"
	-- angle on target for travel commands
	self.angle = 0
	-- flag if ship is above target
	self.isAbove = false
	-- several flight mode flags
	self.gotoLock = nil
	self.landingMode = false
	self.traverse = false
	self.targetVector = nil
	self.targetVectorAutoUnlock = true
	self.vertical = false
	-- we use the altitude from when alt hold was activated,
	-- not the global one, as that could be drastically changed by user input!
	self.holdAltitude = cData.altitude
	self.targetDist = 0
	self.state = nil
	self.yawDamp = true -- default true to dampen fwd/back movement
	self.travelAltitude = nil -- desired altitude for travel in autopilot
	self.latPID = pid.new(5, 0, 10.0)

	function self.toggleMmb(state)
		if state == nil then state = not self.mmbThrottle end
		local gC, cD = globals, cData
		self.mmbThrottle = state == true
		-- in cruise mode, always reset MMB
		if self.alternateCM then
			navCom:resetCommand(axisCommandId.longitudinal)
			cD.curThrottle = 0
			self.throttle = 0
			self.mmbThrottle = false
			return
		end
		-- do not go full throttle if already moving!
		if self.mmbThrottle and self.gotoLock ~= nil then
			self.mmbThrottle = false
			return
		end
		gC.altitudeHold = self.mmbThrottle
		if self.mmbThrottle then
			self.throttle = 100
			cD.curThrottle = 1
			gC.holdAltitude = cD.altitude
			self.holdAltitude = cD.altitude
		end
	end

	function self.scaleRotation()
		if self.rotationSpeed < self.rotationSpeedMax then
			self.rotationSpeed = clamp(self.rotationSpeed + self.rotationStep,
				self.rotationSpeedMin, self.rotationSpeedMax)
		end
	end

	function self.movePosAltitude(pos, distance)
		local cD = cData
		if cD.gravity == nil then return pos end
		return pos - (cD.gravityDir * (distance or 0))
	end

	function self.moveWaypointZ(cD, altitude)
		return cD.position - (cD.gravityDir * (altitude or 0))
	end

	function self.moveWaypointY(cD, altitude, distance)
		local a = self.moveWaypointZ(cD, altitude - cD.altitude)
		return a - (cD.wRight:cross(cD.gravity):normalize()) * -distance
	end

	function self.prepLanding()
		if self.landingMode then
			inputs.up = false
			inputs.down = false
			unit.deployLandingGears()
		else
			unit.retractLandingGears()
		end
	end

	function self.resetFlags()
		local gC = globals
		if gC.maneuverMode then
			gC.altitudeHold = false
		end
		self.dt = nil
		self.followGravity = true
		self.gotoLock = nil
		self.landingMode = false
		self.mmbThrottle = false
		self.state = nil
		self.takeoff = false
		self.targetVector = nil
		self.travel = false
		self.traverse = false
		self.vertical = false
	end

	function self.resetMoving()
		if AutoPilot.landingMode then
			-- AutoPilot:toggleLandingMode(false)
			AutoPilot.landingMode = false
		end
		local gC = globals
		gC.altitudeHold = false
		if gC.maneuverMode then
			self.toggleMmb(false)
			self.resetFlags()
		end
	end

	function self.resetManeuver()
		local gC = globals
		gC.maneuverMode = true
		gC.rotationDampening = true
		resetModes()
		if unit.getControlMode() == 1 then
			unit.cancelCurrentControlMasterMode()
			Nav:update()
			self.controlMode = 0
			self.throttle = 100
			self.alternateCM = false
		end
		AutoPilot:resetNavCom(false)
		inputs.direction = vec3()
		inputs.rotation = vec3()
		self.resetFlags()
		self.alternateCM = false
		self.controlMode = 0
		self.throttle = 100
		setThrottle(1,1,1)
		dynamicSVG()
	end

	function self.stopLanding()
		local gC, ap = globals, AutoPilot
		self.resetMoving()
		self.targetVector = nil
		self.landingMode = false
		if not gC.startup then
			-- ap:toggleLandingMode(false)
			-- if gC.prevStdMode then gC.maneuverMode = false end
			if gC.prevStdMode then
				-- gC.maneuverMode = false
				gC.maneuverMode = true --needed for toggling
				onAlt9()
			end
			if not player.isSeated() or unit.isRemoteControlled() then unit.exit() end
		end
		inputs.brake = 1
		inputs.brakeLock = true
	end

	function self.trimAngle(cD)
		if not ((abs(self.angle) <= 0.001) or self.isAbove) then
			local dmpVal, wUp = self.angle, cD.worldUp
			-- Calculate the angular acceleration along the reference axis
			local yAAcc = cD.worldAngularAcceleration:dot(wUp)
			-- predicted velocity
			local yAVel = cD.worldAngularVelocity:dot(wUp)
			local pYVel = yAVel + yAAcc * self.dt

			-- Check if both angular velocity and acceleration are effectively zero and give it a nudge
			if abs(dmpVal) > 0.01 and abs(yAVel) < 0.01 and abs(yAAcc) < 0.01 then
				dmpVal = dmpVal + sign(dmpVal) * self.rotationSpeedMin
			end
			dmpVal = getDampener('P', dmpVal, 2*math.pi)
			pYVel = pYVel * dmpVal
			local dAVel = (self.angle - pYVel) * dmpVal
			dmpVal = (dAVel - yAVel) * dmpVal
			self.yawDamp = abs(pYVel) >= 0.15 -- further dampening is needed
			return wUp * dmpVal
		end
		return vec3()
	end

	function self.applyAltitudeHold(cD, doHoldAlt, tmp, atmp)
		-- For altitude hold we do not use AP's altitude, because that
		-- might be drastically changed via user input.
		-- The pilot may still change altitude via C/SPACE keys manually.
		if doHoldAlt then
			-- For now just clamp to +/- 5m difference
			local deltaAltitude = clamp((self.holdAltitude or cD.altitude) - cD.altitude, -10, 10)
			local wp = self.moveWaypointY(cD, self.holdAltitude - deltaAltitude, cD.forwardSpeed + 100)
			self.targetVector = (wp - cD.position):normalize()
			tmp = tmp - (cD.gravity * cD.mass * deltaAltitude)
					  - (cD.mass * (cD.vertSpeed + vec3(0,0,cD.axisAccel.z * 1)))
		elseif not (cD.isLanded or self.landingMode or self.takeoff or self.vertical)
				and not (inputs.up or inputs.down)
				and (self.mmbThrottle or inputs.pitch ~= 0) then
			-- in "free flight" also try to stay at altitude
			tmp = tmp - (cD.mass * (cD.vertSpeed + vec3(0,0,cD.axisAccel.z * 1)))
		end
		-- Adjust pitch
		atmp = atmp - (cD.wRight:cross(cD.wFwd:cross(cD.gravity:normalize())) *
					   ((cD.worldAngularVelocity * 3) - (cD.angularAirFriction * 3)))
		return tmp, atmp
	end

	function self.switchState(state)
		if self.state == state then return end
		self.state = state
		if state then P('[I] ' .. state) end
	end

	function self.miniPilot(cD, tmpOrg, atmpOrg)
		if self.gotoLock == nil then return tmpOrg, atmpOrg end

		local tmp, atmp = tmpOrg:clone(), atmpOrg:clone()
		local gC, ap, cPos = globals, AutoPilot, cD.position
		local targetRadius, b, mass = 0.02, cD.body, cD.mass
		self.yawDamp = true

		-- Define the states for the process flow.
		local states = {
			"ALTITUDE",		-- adjust altitude vertically
			"ALIGNING",		-- align to target
			"TRAVERSING",	-- traverse to target
			"LANDING",		-- landing mode
			"LANDED"		-- landed
		}

		-- Map externally set flags to current state
		if self.landingMode then
			self.state = 'LANDING'
		elseif (self.travel and not self.state) or self.takeoff or self.vertical then
			self.state = 'ALTITUDE'
		elseif self.travel and self.traverse then
			self.state = 'TRAVERSING'
		elseif (cD.isLanded or self.state == 'LANDED') and not (self.takeoff or self.vertical) then
			self.resetMoving()
			return tmp,atmp
		end
		if not self.state then
			P'[E] State not set!'
			return tmp, atmp
		end

		-- Initial target processing
		local target = vec3(self.gotoLock):clone()
		local tmpAltOrg = getAltitude(target)
		local tmpAlt = tmpAltOrg -- temporary desired altitude

		-- * Altitude adjustment (only for travel/traversal!)
		-- Pre-determine the altitude based on the target either being 50m above
		-- target OR stay at any higher of current or travelAltitude
		if self.state == 'ALTITUDE' and (self.travel or self.traverse) then
			--TODO the 50 needs to be a LUA param or config value
			local altCeil = tmpAlt + ternary(self.travel, 50, 0)
			-- Determine new projected "travel" altitude
			local trvA = 0
			if cD.inAtmo and self.travel and self.travelAltitude then
				trvA = self.travelAltitude
			end
			if trvA > altCeil and trvA > cD.altitude then
				altCeil = trvA
			elseif cD.altitude > altCeil then
				altCeil = cD.altitude
			end
			-- Move "target" to interim waypoint above target at new (travel) altitude
			target = self.movePosAltitude(cPos, altCeil - cD.altitude )
			-- Get the final altitude from waypoint
			tmpAlt = getAltitude(target)
			self.travelAltitude = tmpAlt -- set it for TRAVERSING
		end

		-- Preset crucial data points
		local altDiff = round2(tmpAlt - cD.altitude, 2)
		local targetDirection = (target - cPos)
		self.targetDist = abs(targetDirection:len())
		self.angle = -math.rad(getTargetAngle(target))
		self.isAbove = isDirectlyAbove(cPos, target, 0.3)

-- if gC.debug then
-- addDbgVal('Status', tostring(' ['..(self.state or 'Flight')..']'), true)
-- addDbgVal('A Endpoint',round2(tmpAlt,2))
-- addDbgVal('A WP',round2(tmpAlt,2))
-- addDbgVal('A Diff',altDiff)
-- end

		-- frame time
		self.dt = clamp(system.getActionUpdateDeltaTime(),0.0015,0.5)

		-- For downward vertical movement adjust the speed
		local speed = ap.userConfig.landSpeedLow
		if self.state == "TRAVERSING" then
			speed = ternary(cD.inAtmo, min(1080, cD.burnSpeedKph - 100), 200)
		elseif self.vertical and (altDiff > 0) then
			speed = ap.userConfig.landSpeedHigh
		end

		-- Main state handlers
		local delta = vec3()
		if self.state == "ALTITUDE" or self.state == "LANDING" then

			--TODO actually for /vertical and /goAlt commands we should
			-- use the starting location as reference point, and not
			-- the current location as that may bring deviations in?

			-- If going down AND ground detected earlier than anticipated,
			-- update altDiff and target to avoid premature collision!
			if altDiff < 0 and cD.GrndDist and (cD.GrndDist <= abs(altDiff)) then
				altDiff = cD.GrndDist
				self.gotoLock = self.movePosAltitude(cPos, -altDiff)
				-- re-assign target so the marker gets updated
				target = self.gotoLock:clone()
				tmpAlt = getAltitude(target)
				tmpAltOrg = tmpAlt
			end
			targetDirection = target - cPos
			self.targetDist = abs(targetDirection:len() - targetRadius)

			-- target is already the temp waypoint, check for bailout
			if (self.targetDist <= targetRadius) or (abs(altDiff) <= 0.1) or
				((self.takeoff or self.vertical) and self.targetDist <= 0.1) or
				(self.landingMode and self.GrndDist and self.GrndDist <= 0.2)
			 then
				if self.vertical or self.takeoff then
					self.resetMoving()
					self.switchState()
				elseif self.state == 'LANDING' then
					self.switchState('LANDED')
					self.landingMode = false
					if gC.prevStdMode then
						-- do NOT call self.stopLanding() if Standard mode!
						gC.maneuverMode = false
						setThrottle()
					else
						self.stopLanding()
					end
				elseif self.landingMode then
					self.switchState('LANDING')
				else
					self.switchState('ALIGNING')
				end
			else
				-- need to estimate the altitude which splits between high and low
				-- altitude speed limit: surfaceAverageAltitude works for all planets incl. Thades
				local atmoLimit = 1000 -- meters
				if cD.inAtmo and b and tonumber(b.surfaceAverageAltitude) ~= nil then
					-- do NOT use surfaceMinAltitude!!!
					atmoLimit = atmoLimit + b.surfaceAverageAltitude
				end

				-- * Vertical speed limit
				local axis = (self.landingMode or altDiff < 0) and 'worldUp' or 'worldDown'
				local res = AxisLimiter(cD, axis, atmoLimit, altDiff)
				if res and vec3.isvector(res) then
					delta.z = res.z
					-- convert delta to world vec3
					delta = localToWorld(delta, cD.worldUp, cD.wRight, cD.wFwd)
					tmp = tmp - (delta * mass * cD.G)
				else self.resetMoving() end
			end
		elseif self.state == "ALIGNING" then
			if abs(self.angle) <= 0.0008 then
				self.travelAltitude = cD.altitude
				if cD.inAtmo then
					self.travelAltitude = min(cD.altitude, ap.userConfig.travelAlt)
				end
				self.holdAltitude = self.travelAltitude
				self.switchState('TRAVERSING')
			else
				-- try to align very precisely
				atmp = atmp + self.trimAngle(cD)
			end
		elseif self.state == "TRAVERSING" then
			-- Before we set new target/targetDistance, check if we are closer
			-- than 50m to disable altitude hold early
			gC.altitudeHold = self.targetDist >= 50
			if gC.altitudeHold and not self.holdAltitude then
				self.holdAltitude = gC.holdAltitude
			end

			-- check for angle adjustment
			atmp = atmp + self.trimAngle(cD)

			-- Move interim target to waypoint over final target
			-- The travelAltitude was already set in ALIGNING state
			target = self.movePosAltitude(self.gotoLock, cD.altitude - self.holdAltitude)
			self.targetVector = (target - cPos):normalize()
			self.isAbove = isDirectlyAbove(cPos, target, 0.3)

			-- angleSign of -1 means the target is behind us
			local angleSign = (self.angle >= (-math.pi / 2)) and (self.angle <= (math.pi / 2)) and 1 or -1
			local locPos = worldToLocal(cPos)
			local locTrg = worldToLocal(target)
			self.targetDist = angleSign * getTravelDistance(locTrg, locPos, cD.body)

			-- Correct sideways movement
			self.latPID:reset()
			self.latPID:inject(cD.lateralSpeed * self.dt)
			local latCorr = self.latPID:get()
			delta = delta + cD.wRight * latCorr

			if self.targetDist > 0 then
				-- * Longitudinal speed limit
				local res = AxisLimiter(cD, 'cFwd', speed, self.targetDist)
				if res and vec3.isvector(res) then delta.y = res.y else self.resetMoving() end

				-- convert delta to world vec3
				delta = localToWorld(delta, cD.worldUp, cD.wRight, cD.wFwd)
				tmp = tmp + (delta * mass * cD.G)
			end

			-- Check if we're close enough to land
			if ((self.isAbove or self.targetDist <= 0.2) and math.abs(cD.forwardSpeed) < 1) then
				-- if we just reached the interim point above the actual target,
				-- reset the destination to the final target
				self.resetFlags()
				self.prepLanding()
				self.landingMode = true
				self.switchState('LANDING')
			end
		end
		return tmp, atmp

	end -- ###################################################################################

	function self.apply(cD)
		local tmp = self.thrust
		local atmp = self.angularThrust
		self.throttle = ternary(self.alternateCM, cD.curThrottle / 100, cD.curThrottle)

		-- shortcut some vars
		local gC, ap, landed = globals, AutoPilot, cD.isLanded
		local isStartup, mass, cSpeed = gC.startup, cD.mass, cD.constructSpeed

		-- * Lateral / Strafing
		if inputs.direction.x ~= 0 then
			-- we ignore throttle and try to use the full force
			tmp = tmp + (sign(inputs.direction.x) * cD.wRight * ternary(inputs.direction.x, cD.MaxKinematics.Right, cD.MaxKinematics.Left))
		end

		-- * Forward
		if not self.alternateCM then
			if (self.mmbThrottle ) or inputs.pitch < 0 then
				local t = ternary(self.mmbThrottle, 100, self.throttle)
				tmp = tmp + (t * cD.wFwd * cD.MaxKinematics.Forward)
			elseif inputs.pitch > 0 then
				tmp = tmp - (self.throttle * cD.wFwd * cD.MaxKinematics.Backward)
			end
		end

		-- * Yaw left/right (rotation.z)
		if inputs.yaw ~= 0 then
			self.scaleRotation()
			atmp = atmp - ((cD.wFwd:cross(cD.wRight) * inputs.yaw) * self.rotationSpeed)
		end

		-- * Vertical
		if inputs.up or inputs.down then
			-- keep both distinctly active!
			if inputs.up then
				tmp = tmp + (cD.worldUp * cD.MaxKinematics.Up * self.IDIntensity)
			end
			if inputs.down then
				tmp = tmp - (cD.worldUp * cD.MaxKinematics.Down * self.IDIntensity)
			end
		end

		-- * Rotation PITCH
		-- * No PITCH in maneuver mode -> keys used as fwd/back!
		-- if inputs.rotation.x ~= nil and inputs.rotation.x ~= 0 then
		--  self.scaleRotation()
		--  atmp = atmp + (cD.wFwd:cross(cD.worldUp) * inputs.rotation.x * self.rotationSpeed)
		--  if self.targetVectorAutoUnlock then
		--	  self.targetVector = nil
		--	  gC.altitudeHold = false
		--  end
		-- end
		-- * Rotation ROLL
		-- * We do not ROLL in maneuver mode!
		-- if inputs.rotation.y ~= 0 then
		--  self.scaleRotation()
		--  atmp = atmp + ((cD.worldUp:cross(cD.wRight) * inputs.rotation.y) * self.rotationSpeed)
		-- end

		-- * Braking - always cancels everything!
		local braking = inputs.brakeLock or (inputs.brake ~= 0)
		if braking then
			gC.altitudeHold = false
			if self.mmbThrottle then
				self.toggleMmb()
			end
			self.resetFlags()
			local a1 = self.brakingFactor * max(1, cSpeed / cD.atmoD * 1)
			if inputs.brakeLock then
				tmp = -cD.wVel * mass * max(brakeFlatFactor,0.01)
			else
				tmp = -cD.wVel * mass * max(a1, cSpeed * cSpeed)
			end
		end

		-- Sanitize altitude to hold
		-- self.holdAltitude = gC.holdAltitude or cD.altitude
		if self.holdAltitude < 100 then
			self.holdAltitude = cD.altitude
		end

		-- * Altitude Hold
		if not landed then
			local doHoldAlt = gC.altitudeHold and self.holdAltitude >= 100
							and not (self.landingMode or self.takeoff or self.vertical)
			tmp, atmp = self.applyAltitudeHold(cD, doHoldAlt, tmp, atmp)
		end

		-- * Follow Gravity (pitch / rotation.x)
		if self.followGravity then
			atmp = atmp - (cD.worldUp:cross(cD.gravity:normalize()) * cD.gravity:len())
		end

		-- * Stop any targeted movement in case of up/down inputs.
		if not self.alternateCM and (self.landingMode or self.takeoff or self.vertical)
				and (inputs.up or inputs.down) then
			self.resetMoving()
		end

		-- * Clear gotoLock if no vector
		if self.targetVector == nil then
			self.gotoLock = nil
		end

		self.angle, self.isAbove = 0, false
		if ap.target ~= nil and self.gotoLock == nil then
			-- angle is used in radians as DU's methods do
			self.angle = -math.rad(getTargetAngle())
		end

		-- * Autopilot
		-- gotoLock supports /goto and /go chat commands
		if not braking then
			tmp, atmp = self.miniPilot(cD, tmp, atmp)
		end

		if self.landingMode and landed and not gC.startup then
			self.state = 'LANDED'
			return
		end

		-- Yaw inertial dampening
		if (self.yawDamp or self.gotoLock == nil) then
			atmp = atmp - ((cD.worldAngularVelocity * 3) - (cD.angularAirFriction * 3))
		end

		-- * Cruise mode
		if self.alternateCM and not (braking or self.landingMode) then
			local speed = self.throttle / 3.6 ---@TODO
			local dot = cD.wFwd:dot(cD.angularAirFriction)
			local modifiedVelocity = (speed - dot)
			local desired = cD.wFwd * modifiedVelocity
			tmp = tmp + ((desired - cD.wVel) * mass * cD.G)
		end

		-- * Inertial Dampening
		if self.inertialDampening and not isStartup and not landed then
			-- Important: do NOT use world velocity here, like cD.wVel!
			local delta, locV = vec3(), cD.velocity
			local chg = false
			-- dampen X-axis (lateral)
			if not (inputs.left or inputs.right) then
				delta.x = locV.x
				chg = true
			end

			-- dampen Y-axis (longitudinal)
			if not (braking or inputs.forward or inputs.backward) then
				-- we dampen to prevent burn speed
				-- OR rotational dampening is OFF and no user input
				if (cD.inAtmo and cD.ySpeedKPH > (cD.burnSpeedKph - 50)) then
					delta.y = locV.y * 2
				elseif (gC.rotationDampening and inputs.pitch == 0
						and not (self.mmbThrottle or self.alternateCM)) then
					delta.y = locV.y
				end
				chg = true
			end

			-- dampen Z-axis (vertical)
			-- do not dampen if miniPilot is active (gotoLock) or user input
			if not (self.gotoLock or inputs.up or inputs.down) then
				---@TODO this is a bit messy, in space trying to counter some down movement
				if not cD.inAtmo and not self.vertical and cD.G > 9.9
					and cD.GrndDist and cD.GrndDist >= 0 and cD.GrndDist < 10 then
					delta.z = (locV.z * 1.5)
				else
					delta.z = locV.z * ternary(self.alternateCM, 1, cD.atmoD)
				end
				chg = true
			end

			-- MUST use local coordinates here or above code would need a rewrite!
			if chg then
				delta = localToWorld(delta, cD.worldUp, cD.wRight, cD.wFwd)
				tmp = tmp - (delta * cD.G * mass)
			end
		end
		if not (isStartup or landed or self.landingMode or inputs.down) then
			tmp = tmp - (cD.gravity * mass)
		end
		tmp = tmp / mass

		-- React to controlMode change
		if self.controlMode ~= unit.getControlMode() then
			self.controlMode = unit.getControlMode()
			if self.controlMode == 0 then
				self.resetManeuver()
				self.alternateCM = false
				self.throttle = self.tempThrottle
			else
				self.alternateCM = true
				self.tempThrottle = self.throttle
				self.throttle = round2(cD.speedKph,0)
			end
		end

		-- If in hover-range AND user selected 'primary' as engines,
		-- only use ground engines to save fuel
		local p1tag = self.priorityTags1
		local p2tag = self.priorityTags2
		if not self.landingMode and cD.GrndDist and (cD.hasvBoosters or cD.hasHovers)
			and (gC.boostMode == 'all' or gC.boostMode == 'hybrid')
			and cD.GrndDist > 0 and cD.GrndDist < cD.maxHoverDist then
			p1tag = "brake,airfoil,torque,ground,lateral,longitudinal"
			p2tag = ""
		end
		unit.setEngineCommand(
			"all",
			{ tmp:unpack() },
			{ atmp:unpack() },
			false, --keep Force Collinearity
			false, --keep Torque Collinearity
			p1tag,
			p2tag,
			""
		)
		if isStartup and landed then
			inputs.brakeLock = true
			inputs.brake = 1
		elseif not inputs.brakeLock and abs(cD.zSpeedKPH) < 0.1 then
			inputs.brake = 0
		end
	end

	return self
end

function setApTarget(vec)
	AutoPilot:setTarget(vec)
end

function gotoTarget(vec, apIsSet, travelAltitude)
	if type(vec) ~= 'table' or not vec3.isvector(vec) then return false end
	ship.resetManeuver() -- incl. resetFlags()
	if not apIsSet then setApTarget(vec) end
	local gC, s = globals, ship
	gC.altitudeHold = false
	gC.rotationDampening = true
	inputs.brakeLock = false
	inputs.brake = 0
	s.travelAltitude = nil
	local trvAlt = tonumber(travelAltitude)
	if trvAlt and trvAlt > 100 and trvAlt <= 10000 then
		s.travelAltitude = trvAlt
		s.holdAltitude = trvAlt
	end
	s.targetVector = (vec - cData.position):normalize()
	s.gotoLock = vec
	return true
end

function moveVert(dist)
	dist = clamp(dist or 0,-200000,200000)
	local a = ship.moveWaypointZ(cData, dist)
	if gotoTarget(a) then
		local aPos = Vec3ToPosString(a)
		P("Moving to: " .. tostring(aPos))
		return true
	end
	return false
end

function shipLandingTask(cD)
	if not ship.landingMode then return end
	local dist = cD.altitude
	-- If a body is close then don't use plain 0 but an estimate
	if cD.body then
		local surfAvg = tonumber(cD.body.surfaceAverageAltitude)
		-- do NOT use surfaceMinAltitude!!!
		if cD.body.name == 'Thades' then
			dist = dist - 13700
		-- elseif cD.altitude > surfAvg then
		-- 	dist = dist - surfAvg
		end
	end
	-- Try to land into AGG altitude if AGG present and active
	local agg = links.antigrav
	if agg and agg.isActive() then
		local a = agg.getBaseAltitude()
		if a < cD.altitude then
			dist = cD.altitude - a
		end
	end

	---@TODO how treat fishy distances??
	-- If fishy, try 1km
	if dist < 0 and cD.altitude == 0 then dist = 1000 end
	-- Always use detected ground distance (if <= 100m)
	if cD.GrndDist and cD.GrndDist > 0 then
		dist = cD.GrndDist
	end
	local a = ship.moveWaypointZ(cD, -dist + 0.1)
	gotoTarget(a)
	ship.landingMode = true -- needs to be re-set!
end