function getConstructData(construct, core)
	local gC, ap, r2d, abs, atan, sign = globals, AutoPilot, constants.rad2deg, math.abs, math.atan, utils.sign

	local wVel = vec3(construct.getWorldVelocity())
	local worldForward = vec3(construct.getWorldOrientationForward())
	local worldUp = vec3(construct.getWorldOrientationUp())
	local worldRight = vec3(construct.getWorldOrientationRight())
	local worldVertical = vec3(core.getWorldVertical())
	local cWP = vec3(construct.getWorldPosition())
	local currentRollDeg = getRoll(worldVertical, worldForward, worldRight)
	local wFu, wVu = {worldForward:unpack()}, {worldVertical:unpack()}
	local localGrav = vec3(library.systemResolution3({worldRight:unpack()}, wFu, {worldUp:unpack()}, wVu))
	local localVert = vec3(library.systemResolution3({(worldVertical:cross(worldForward)):unpack()}, wFu, wVu, {vec3(0,0,1):unpack()}))
	-- Check for zero vectors
	if localGrav:len() == 0 then
		localGrav = vec3(0, 0, 1) -- Default to a neutral gravity vector if zero
	end
	if localVert:len() == 0 then
		localVert = vec3(0, 0, 1) -- Default to a neutral vertical vector if zero
	end

	local _cD = {
		locGrav = localGrav,
		locVert = localVert,
		yaw = (atan(-localVert.x, localVert.y) * r2d) % 360,
		pitch = 180 - (atan(localGrav.y, localGrav.z) * r2d),
		wVert = worldVertical, -- World Vertical, current up vector in world space while on a planet, 0 in space
		worldUp = worldUp, -- World Up
		worldDown = -worldUp, -- World Down
		wRight = worldRight, -- World Right
		worldLeft = -worldRight, -- World Left
		wFwd = worldForward,
		worldBack = -worldForward,
		wVel = wVel, -- world velocity
		wVelDir = wVel:normalize(), -- velocity vector against our direction
		wVelAbs = vec3(construct.getWorldAbsoluteVelocity()),
		worldAcceleration = vec3(construct.getWorldAcceleration()),
		worldAngularVelocity = vec3(construct.getWorldAngularVelocity()), -- World Angular Velocity
		worldAngularAcceleration = vec3(construct.getWorldAngularAcceleration()),
		worldAirFriction = vec3(construct.getWorldAirFrictionAcceleration()),
		curThrottle = unit.getThrottle(),
		acceleration = vec3(construct.getAcceleration()),
		angularAirFriction = vec3(construct.getWorldAirFrictionAngularAcceleration()), -- World Angular Velocity
		angularVelocity = vec3(construct.getAngularVelocity()), -- Angular Velocity
		velocity = vec3(construct.getVelocity()),
		velocityDir = vec3(construct.getVelocity()):normalize(),
		velocityAbs = vec3(construct.getAbsoluteVelocity()),
		mass = construct.getTotalMass(),
		constructSpeed = wVel:len(), -- total speed in m/s
		currentRollDeg = currentRollDeg, -- Current Roll Deg
		currentRollDegAbs = abs(currentRollDeg), -- Current roll Deg Absolute
		currentRollDegSign = sign(currentRollDeg), -- Current Roll Deg Sign
		forwardSpeed = wVel:dot(worldForward),
		lateralSpeed = wVel:dot(-worldRight),
		vertSpeed = wVel:dot(-worldVertical), -- world downward speed m/s
		position = cWP,
		atmoDensity = round2(unit.getAtmosphereDensity() or 0,2),
		burnSpeed = construct.getFrictionBurnSpeed(), -- m/s
		maxSpeed = construct.getMaxSpeed(), -- m/s
		G = core.getGravityIntensity(), -- float m/s
		gravity = vec3(core.getWorldGravity()), -- vec3 m/s2
		gravityDir = vec3(core.getWorldGravity()):normalize(),
		currentBrake = construct.getCurrentBrake(),
		pvpTimer = construct.getPvPTimer(),
		pvpZone = construct.isInPvPZone(),
		body = findClosestBody(cWP),
		nearPlanet = unit.getClosestPlanetInfluence() > 0,
		rpy = getRPY(worldForward, worldUp, worldRight, worldVertical, wVel),
		GrndDist = nil,
		hasvBoosters = links.vBoosterCount > 0,
		hasHovers = links.hoverCount > 0,
		telemeter = links.telemeter,
		hasTelemeter = links.telemeter ~= nil and true,
		telemDist = nil,
		maxHoverDist = nil,
		warpOn = construct.isWarping(),
		cFwd = vec3(construct.getForward()),
		cBack = -vec3(construct.getForward()),
		-- Currently not used:
		--cDown = -vec3(construct.getUp()),
		--cRight = vec3(construct.getRight()),
		--cUp = vec3(construct.getUp()),
		--crossSection = construct.getCrossSection(),
		--wCOM = vec3(construct.getWorldCenterOfMass()),
		--lCOM = vec3(construct.getCenterOfMass())
	}
	_cD.currentRollDegAbs = abs(_cD.currentRollDeg)
	_cD.currentRollDegSign = sign(_cD.currentRollDeg)

	_cD.altitude = getAltitude(cWP) -- needs body to be set first
	_cD.hasGndDet = _cD.hasTelemeter or _cD.hasvBoosters or _cD.hasHovers
	if _cD.hasGndDet then
		-- telemeter has precedence with detection up to 100m
		if _cD.hasTelemeter then
			local ray = _cD.telemeter.raycast()
			if ray.hit then
				_cD.telemDist = ray.distance
			end
		end
		if _cD.hasHovers and _cD.atmoDensity > 0.1 then
			for _, hv in ipairs(links.hovers) do
				if type(hv.getMaxDistance) == 'function' then -- Doh! in hovercraft chair this is nil!
					_cD.maxHoverDist = math.max(_cD.maxHoverDist or 0, hv.getMaxDistance())
					local dist = hv.getDistance()
					if dist >= 0.01 and (not _cD.GrndDist or (dist < _cD.GrndDist)) then
						_cD.GrndDist = dist
					end
				end
			end
		end
		if _cD.hasvBoosters then
			for _, hv in ipairs(links.vboosters) do
				if type(hv.getMaxDistance) == 'function' then
					_cD.maxHoverDist = math.max(_cD.maxHoverDist or 0, hv.getMaxDistance())
					local dist = hv.getDistance()
					if dist >= 0.01 and (not _cD.GrndDist or (dist < _cD.GrndDist)) then
						_cD.GrndDist = dist
					end
				end
			end
		end
	end
	_cD.aboveWater = false
	if _cD.GrndDist or _cD.telemDist then
		-- ground engines measure down to ground OR sea level (0m altitude)
		-- BUT telemeter ignores sea level and looks below sea level!
		_cD.aboveWater = (_cD.telemDist and _cD.GrndDist and _cD.telemDist > _cD.GrndDist) or false
		_cD.GrndDist = max(_cD.telemDist or 0, _cD.GrndDist or 0)
		if ap.userConfig.agl then
			_cD.GrndDist = _cD.GrndDist - ap.userConfig.agl
		end
		_cD.GrndDist = round2(_cD.GrndDist or 0,2)
	end
	_cD.inAtmo = _cD.atmoDensity > 0

	local tkForward = construct.getMaxThrustAlongAxis("all", { vec3(0,1,0):unpack() })
	local tkUp = construct.getMaxThrustAlongAxis("all", { vec3(0,0,1):unpack() })
	local tkUpGrndAtmo = construct.getMaxThrustAlongAxis("fueled thrust ground vertical", { vec3(0,0,1):unpack() })
	local tkUpGrndSpace = construct.getMaxThrustAlongAxis("fueled thrust booster_engine vertical", { vec3(0,0,1):unpack() })
	local tkDownAtmo = construct.getMaxThrustAlongAxis("fueled thrust atmo vertical", { vec3(0,0,-1):unpack() })
	local tkDownSpace = construct.getMaxThrustAlongAxis("fueled thrust space_engine vertical", { vec3(0,0,-1):unpack() })
	local tkRight = construct.getMaxThrustAlongAxis("all", { vec3(1,0,0):unpack() })
	local tkOffset = 0
	if _cD.atmoDensity < 0.1 then tkOffset = 2 end
	_cD.gravMass = _cD.mass * _cD.G
	_cD.gravLong = _cD.gravity:dot(worldForward)
	_cD.gravLat = _cD.gravity:dot(-worldRight)
	_cD.gravVert = _cD.gravity:dot(-worldUp)

	local virtGravEngine = vec3(
		library.systemResolution3(
			{ _cD.wRight:unpack() },
			{ _cD.wFwd:unpack() },
			{ _cD.worldUp:unpack() },
			{ vec3(_cD.gravity * _cD.mass):unpack() }
		))
	_cD.MaxKinematics = {
		Forward = math.abs(tkForward[1 + tkOffset] + virtGravEngine.y),
		Backward = math.abs(tkForward[2 + tkOffset] - virtGravEngine.y),
		Up = math.abs(tkUp[1 + tkOffset] + virtGravEngine.z),
		UpGroundAtmo = math.abs(tkUpGrndAtmo[1] + virtGravEngine.z),
		UpGroundSpace = math.abs(tkUpGrndSpace[3] + virtGravEngine.z),
		DownAtmo = math.abs(tkDownAtmo[2] + virtGravEngine.z),
		DownSpace = math.abs(tkDownSpace[4] + virtGravEngine.z),
		Down = math.abs(tkUp[2 + tkOffset] - virtGravEngine.z),
		Right = math.abs(tkRight[1 + tkOffset] + virtGravEngine.x),
		Left = math.abs(tkRight[2 + tkOffset] - virtGravEngine.x)}
	if _cD.atmoDensity >= 0.01 and _cD.atmoDensity < 0.1 then
		_cD.MaxKinematics.Forward = math.abs((tkForward[1] + tkForward[3]) + virtGravEngine.y)
	end
	--_cD.forceRatio = round2(_cD.MaxKinematics.Forward / _cD.MaxKinematics.Up, 4) -- forward-to-vertical force ratio
	if gC.maxBrake and gC.maxBrake > 1 then
		_cD.maxBrake = gC.maxBrake
	end
	local c = 13888.889 -- 50000000 / 3600
	local v = _cD.constructSpeed
	_cD.velMag = _cD.wVelAbs:len()
	_cD.vtolCapable = _cD.MaxKinematics.Up > (_cD.mass * _cD.G)
	_cD.ySpeedKPH = _cD.forwardSpeed*3.6
	_cD.xSpeedKPH = _cD.lateralSpeed*3.6
	_cD.zSpeedKPH = _cD.vertSpeed*3.6
	_cD.burnSpeedKph = _cD.burnSpeed*3.6
	_cD.speedKph = v*3.6
	_cD.brakes = getBrakes(_cD)
	_cD.orbitalParameters = getOrbitalParameters(_cD)
	_cD.orbitFocus = getOrbitFocus(_cD)

	-- Acceleration per all 3 axis in a vec3()
	_cD.axisAccel = getAccAllAxes(_cD)
	_cD.isLanded = tonumber(_cD.GrndDist) ~= nil and _cD.GrndDist < 0.5 and _cD.speedKph < 1
	-- atmoD is a boost factor for low atmo densities,
	-- e.g. for Thades where it is only 35% or less
	_cD.atmoD = ternary(_cD.atmoDensity > 0.1, _cD.atmoDensity, 1)

	-- * other possibly helpful values, that are currently unused:
	-- _cD.inertia = 1 / math.sqrt(1 - ((v * v) / (c * c)))
	-- _cD.inertialMass = clamp(_cD.mass * _cD.inertia, _cD.mass, _cD.mass * 1.5)
	-- _cD.maxLanding = calcMaxLandingSpeed(_cD) -- at last!
	-- Extract the dampening values for each axis from the axisDampener vector
	-- _cD.axisDampener = getGravityInfluencedAvailableDeceleration(_cD)
	-- _cD.xDamp = vec3(_cD.axisDampener.x, 0, 0)
	-- _cD.yDamp = vec3(0, _cD.axisDampener.y, 0)
	-- _cD.zDamp = vec3(0, 0, _cD.axisDampener.z)
    -- _cD.xDampForce = _cD.xDamp:dot(_cD.wVel)
    -- _cD.yDampForce = _cD.yDamp:dot(_cD.wVel)
    -- _cD.zDampForce = _cD.zDamp:dot(_cD.wVel)

	_cD.counterGravForce = -(_cD.mass * localGrav:dot(_cD.wFwd))
	return _cD
end

function getAccAllAxes(cD, acc)
    -- Normalize the orientation vectors
    local fN = cD.wFwd:normalize()
    local rN = cD.wRight:normalize()
    local uN = cD.wVert:normalize()
    -- Decompose the world acceleration vector into components along the construct's local axes
	acc = acc or cD.acceleration
    local fA = fN * acc:dot(fN)
    local rA = rN * acc:dot(rN)
    local uA = uN * acc:dot(-uN)
    -- Combine the components to form the acceleration vector in the construct's local frame
    return vec3(fA, rA, uA)
end

-- function calcMaxLandingSpeed(cD)
-- 	local brakeDist = 100
-- 	if cD.GrndDist and cD.GrndDist <= brakeDist then
-- 		brakeDist = cD.GrndDist
-- 	end
-- 	local deceleration = (cD.maxBrake or cD.MaxKinematics.Up) / (cD.mass * 1.1)
-- 	return -math.sqrt(2 * (deceleration + cD.G) * brakeDist)
-- end

function getBrakes(cD)
	local brakeforce = cD.maxBrake or 5000000
	if cD.inAtmo then
		brakeforce = brakeforce / clamp(cD.constructSpeed/100, 0.1, 1)
	end

	local c  = 50000 * 2000 / 3600
	local c2 = c * c
	local forwardV = cD.constructSpeed
	if forwardV < 0.2 then
		return {distance = 0, distKM = 0, distSU = 0, time_s = "00m:00s"}
	end
	local bt = (brakeforce*-1) / cD.mass
	local dist, time = 0, 0
	local k1 = c * math.asin(forwardV / c)
	local k2 = c2 * math.cos(k1 / c) / bt
	local t = (c * math.asin(0 / c) - k1) / bt
	local d = k2 - c2 * math.cos((bt * t + k1) / c) / bt
	dist = dist + d
	time = time + t
	local min = floor(time / 60)
	time = time - 60 * min
	local sec =  floor(time + 0.5)
	local secForm = '00' .. sec
	local secT = secForm:sub(-2, -1)
	local minForm = '00' .. min
	local minT = minForm:sub(-2, -1)
	local time_s = minT .. ':' .. secT

	local distKM = floor(dist) / 1000 -- distance in KM
	local distSU = floor(distKM) / 200  -- distance in SU
	return {distance = round2(dist or 0), distKM = distKM, distSU = distSU, time_s = time_s}
end

function getRPY(forward, up, right, vertical, velocity)
	local yaw = 0
	---@TODO will adjust this to include forward speed to limit large
	-- yaw jumps when falling straight or lifting off.
	if velocity:len() >= 20 then
		yaw = -math.deg(signedRotationAngle(up, velocity, forward))
	end
	return {
		roll = getRoll(vertical, forward, right),
		pitch = getPitch(vertical, forward, right),
		yaw = yaw,}
end

function getPitch(gravityDirection, forward, right)
	local horFwd = gravityDirection:cross(right):normalize_inplace()
	local pitch = acos(clamp(horFwd:dot(-forward), -1, 1))
	if horFwd:cross(-forward):dot(right) < 0 then pitch = -pitch end
	return pitch * constants.rad2deg
end

function getRoll(gravityDirection, forward, right)
	local horRight = gravityDirection:cross(forward):normalize_inplace()
	local roll = acos(clamp(horRight:dot(right), -1, 1))
	if horRight:cross(right):dot(forward) < 0 then roll = -roll end
	return roll * constants.rad2deg
end

function getThrottle(targetSpeed, direction)
	local speed = cData.speedKph-20
	if targetSpeed == nil then
		targetSpeed = cData.burnSpeedKph-100
	end
	if direction ~= nil then
		speed = direction*3.6-20
	end
	local speedDiff = (targetSpeed - speed)
	local minmax = 200
	return clamp((utils.smoothstep(speedDiff, -minmax, minmax) - 0.5) * 2,0,100)
end

function getGravity(body, worldCoordinates)
	if body == nil then return 0 end
	local radial = body.center - vec3(worldCoordinates) -- directed towards body
	local len2 = radial:len2()
	return (body.GM/len2) * radial/math.sqrt(len2)
end

function setThrottle(axLong, axLat, axVert)
	if unit.getControlMode() > 0 then
		unit.cancelCurrentControlMasterMode()
	end
	navCom:setTargetSpeedCommand(axisCommandId.longitudinal, 0)
	navCom:resetCommand(0)
	navCom:resetCommand(1)
	--navCom:resetCommand(2)
	navCom:setThrottleCommand(0, axLong or 0)
	navCom:setThrottleCommand(1, axLat or 0)
	navCom:setThrottleCommand(2, axVert or 0)
	Nav:update()
end

-- -@param cD table getConstructData()
-- -@return vec3 deceleration vector
-- function getGravityInfluencedAvailableDeceleration(cD)
--     -- Calculate the deceleration due to gravity
--     local gravityDecel = (cD.gravityDir:dot(cD.velocityDir) > 0) and cD.G or -cD.G
--     -- Initialize the deceleration vector with gravity influence
--     local decelVec = vec3(0, 0, gravityDecel)
--     -- If in atmosphere, take into account air resistance
--     if cD.inAtmo then
--         -- Calculate the deceleration due to air resistance
--         -- Assuming air resistance is directly proportional to the negative velocity vector
--         local airResistanceDecel = -cD.worldAirFriction:dot(cD.velocityDir)
--         -- Create a vector representing air resistance deceleration
--         local airResistanceVec = cD.worldAirFriction * airResistanceDecel
--         -- Combine gravity and air resistance deceleration vectors
--         decelVec = decelVec + airResistanceVec
--     end
--     -- Ensure the deceleration vector is in the opposite direction of velocity
--     return decelVec * -1
-- end

-- ---@param cD table getConstructData()
-- ---@param axis vec3 axis as vec3() for which to get the dampening factor
-- ---@return vec3 dampening vector for normalized axis
-- function getAxisDampener(cD, axis)
--     -- Get the gravity and air resistance influenced deceleration vector
--     local decelVec = getGravityInfluencedAvailableDeceleration(cD)
--     -- Project the deceleration vector onto the specified axis
--     -- This gives us the dampening value for the given axis
--     local dampeningValue = decelVec:dot(axis)
--     -- Return the dampening factor for the specified axis
--     return axis * dampeningValue
-- end