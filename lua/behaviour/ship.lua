-- call below methods only in onFlush()!
function getTargetAngularVelocity(finalPitchInput, finalRollInput, finalYawInput)
	local gC, ap = globals, AutoPilot
	local cData = cData
	local finalInput = finalPitchInput * pitchSpeedFactor * cData.wRight
		+ finalRollInput * rollSpeedFactor * cData.wFwd
		+ finalYawInput * yawSpeedFactor * cData.worldUp
	targetRoll = 0
	local horizontalRight = cData.wVert:cross(cData.wFwd):normalize()
	local horizontalForward = cData.wVert:cross(-cData.wRight):normalize()
	if (pitchPID2 == nil) then
		pitchPID2 = pid.new(0.02, 0, 0.2)
		rollPID2 = pid.new(0.1, 0, 0.1)
		yawPID2 = pid.new(0.1, 0, 0.1)
	end
	local tav = vec3()
	if  cData.speedKph < 100 and (cData.inAtmo or (not cData.body.hasAtmosphere and cData.altitude < cData.body.surfaceMaxAltitude+1000)) and not ap.enabled and ap.userConfig.slowFlat then
		gC.aimTarget = 'Flat'
		tav = cData.wVert:cross(cData.worldUp) + finalInput
	else
		tav = finalInput
	end

	-- In atmosphere?
	if cData.wVert:len() > 0.01 and unit.getAtmosphereDensity() > 0.0 then
		local autoRollRollThreshold = 1.0
		-- autoRoll on AND cData.cRD is big enough AND player is not rolling
		if autoRoll == true and cData.currentRollDegAbs > autoRollRollThreshold and finalRollInput == 0 then
			local targetRollDeg = clamp(0,cData.currentRollDegAbs-30, cData.currentRollDegAbs+30);  -- we go back to 0 within a certain limit
			if (rollPID == nil) then
				rollPID = pid.new(autoRollFactor * 0.01, 0, autoRollFactor * 0.1) -- magic number tweaked to have a default factor in the 1-10 range
			end
			rollPID:inject(targetRollDeg - cData.currentRollDeg)
			local autoRollInput = rollPID:get()

			tav = tav + autoRollInput * cData.wFwd
		end
		local turnAssistRollThreshold = 20.0
		-- turnAssist AND cData.cRD is big enough AND player is not pitching or yawing
		if turnAssist and cData.currentRollDegAbs > turnAssistRollThreshold and finalPitchInput == 0 and finalYawInput == 0 then
			local rollToPitchFactor = turnAssistFactor * 0.1 -- magic number tweaked to have a default factor in the 1-10 range
			local rollToYawFactor = turnAssistFactor * 0.025 -- magic number tweaked to have a default factor in the 1-10 range

			-- rescale (turnAssistRollThreshold -> 180) to (0 -> 180)
			local rescaleRollDegAbs = ((cData.currentRollDegAbs - turnAssistRollThreshold) / (180 - turnAssistRollThreshold)) * 180
			local rollVerticalRatio = 0
			if rescaleRollDegAbs < 90 then
				rollVerticalRatio = rescaleRollDegAbs / 90
			elseif rescaleRollDegAbs < 180 then
				rollVerticalRatio = (180 - rescaleRollDegAbs) / 90
			end

			rollVerticalRatio = rollVerticalRatio * rollVerticalRatio

			local turnAssistYawInput = - cData.currentRollDegSign * rollToYawFactor * (1.0 - rollVerticalRatio)
			local turnAssistPitchInput = rollToPitchFactor * rollVerticalRatio

			tav = tav + turnAssistPitchInput * cData.wRight + turnAssistYawInput * cData.worldUp
		end
	end

	if ap.enabled or gC.altitudeHold or gC.orbitalHold then
		local speedCheck = utils.map(clamp(cData.constructSpeed,80,150), 80, 150, 0, 1)
		if ap.enabled and cData.constructSpeed > 80 then
			if not cData.inAtmo or gC.altitudeHold then
				targetRoll = 0
			--targetRoll = clamp(utils.round(-math.deg(signedRotationAngle(cData.worldUp, -cData.wFwd, vectorToPoint(ap.target):project_on_plane(cData.wVert))),0.01)*2,-45,45)*speedCheck
			elseif math.abs(getVelocityTargetAngle()) < 2 or math.abs(getVelocityTargetAngle()) > 170 then
				targetRoll = 0
			else
				targetRoll = clamp(getVelocityTargetAngle()*2,-ap.userConfig.maxRoll,ap.userConfig.maxRoll)*speedCheck
			end
		end
		--rollPID2:inject(targetRoll-cData.rpy.roll)
		--rollInput2 = rollPID2:get()ee
	end

	if gC.orbitalHold or gC.apMode == 'Orbit' then
		aimStrength = clamp(aimStrength-0.1, 0.2,0.4)
		gC.aimTarget = 'Orbit Hold'

		if not gC.inOrbit then
			--local orbitfwd = circleNormal(vec3(getReticle(vec3(getXYZ(cData.wFwd)))))
			--local orbitright = circleNormal(vec3(getReticle(vec3(getXYZ(-cData.wRight)))))
			if cData.altitude < gC.holdAltitude and cData.vertSpeed < 0 and cData.inAtmo then
				gC.aimTarget = 'Orbit Atmo Pitch'
				--tav = orbitfwd:rotate((orbitHold())*constants.deg2rad, orbitright):cross(cData.wFwd)
				tav = -horizontalForward:rotate((gC.targetPitch)*constants.deg2rad, horizontalRight):cross(cData.wFwd)
				if gC.apMode == 'Orbit' then
					targetAntavgularVelocity = ((circleNormal(ap.target)):rotate((gC.targetPitch)*constants.deg2rad, horizontalRight)):cross(cData.wFwd)
				end
			elseif cData.orbitFocus.orbitAltTarget < (gC.targetOrbitAlt-100) or cData.orbitFocus.orbitAltTarget > (gC.targetOrbitAlt+100) then
				gC.aimTarget = 'Orbit Pitch'
				tav = -horizontalForward:rotate((orbitHold())*constants.deg2rad, horizontalRight):cross(cData.wFwd)
				--tav = orbitfwd:rotate((orbitHold())*constants.deg2rad, orbitright):cross(cData.wFwd)
				if gC.apMode == 'Orbit' then
					tav = (circleNormal(ap.target)):rotate((orbitHold())*constants.deg2rad, horizontalRight):cross(cData.wFwd)
					if  math.abs(getVelocityTargetAngle()) < 30 and math.abs(getVelocityTargetAngle()) > 1 and cData.constructSpeed > 50 then --TODO also Distance Projected maybe?
						gC.aimTarget = 'Orbit T2'
						tav = ((variousVectors((circleNormal(ap.target))).vecMain)):rotate(((orbitHold())*constants.deg2rad)*1.5, horizontalRight):cross(cData.wFwd)
					end
				end
			else
				gC.aimTarget = 'Orbit Flat'
				tav = cData.wVert:cross(cData.worldUp) + cData.wVelDir:cross(-cData.wFwd)
				if gC.apMode == 'Orbit' then
					tav = (circleNormal(ap.target)):cross(cData.wFwd)
					if  math.abs(getVelocityTargetAngle()) < 30 and math.abs(getVelocityTargetAngle()) > 1 then
					tav = ((variousVectors((circleNormal(ap.target))).vecMain)):cross(cData.wFwd) + pitchInput2 * cData.wRight
					end
				end
			end
			if (math.abs(getVelocityTargetAngle()) > 80 or cData.constructSpeed < 10) and gC.apMode == 'Orbit' then
				tav = ((circleNormal(ap.target)):project_on_plane(cData.wFwd)):cross(cData.wFwd) + finalInput
				tav = tav + cData.wVert:cross(cData.worldUp)
			end
		else
			tav =  cData.wVelDir:cross(-cData.wFwd) + finalInput
			if gC.apMode == 'Orbit' then
				tav = (circleNormal(ap.target)):cross(cData.wFwd)
			end
		end
		tav = tav + -horizontalRight:rotate(targetRoll*constants.deg2rad, cData.wFwd):cross(cData.wRight) + finalInput
		tav = vec3{clamp(tav.x,-aimStrength,aimStrength),clamp(tav.y,-aimStrength,aimStrength),clamp(tav.z,-aimStrength,aimStrength)}
	end

	if gC.altitudeHold then
		gC.aimTarget = 'Alt Hold'
		tav = -horizontalForward:rotate((gC.targetPitch)*constants.deg2rad, horizontalRight):cross(cData.wFwd) + finalInput
		tav = tav + -horizontalRight:rotate(targetRoll*constants.deg2rad, cData.wFwd):cross(cData.wRight)
	end

	if ap.enabled then
		if gC.apMode == 'agg' then
			tav = (circleNormal(ap.target)):cross(cData.wFwd) + cData.wVert:cross(cData.worldUp)
		end

		if gC.apMode == 'reEntry' or gC.apMode == 'Space Braking' then
			gC.aimTarget = 'Target'
			tav = ((circleNormal(ap.target))):cross(cData.wFwd) + cData.wVert:cross(cData.worldUp)
		end

		if gC.apMode == 'Atmo Travel' then
			if math.abs(getTargetAngle()) > 90 then
				pitchRotate = 0
			else
				pitchRotate = (gC.targetPitch)*constants.deg2rad
			end

			if (math.abs(getVelocityTargetAngle()) > 90 and cData.constructSpeed > 50) or cData.constructSpeed < 20 then --TODO also Distance Projected maybe?
				gC.aimTarget = 'TargetFlat'
				tav = ((circleNormal(ap.target)):project_on_plane(cData.wFwd)):cross(cData.wFwd)
				tav = tav + cData.wVert:cross(cData.worldUp)
			elseif  math.abs(getVelocityTargetAngle()) < 30 and math.abs(getVelocityTargetAngle()) > 1 and cData.constructSpeed > 50 then --TODO also Distance Projected maybe?
				gC.aimTarget = 'T2'
				tav = ((variousVectors((circleNormal(ap.target))).vecMain)):rotate(math.min(pitchRotate*1.5,90), horizontalRight):cross(cData.wFwd) + pitchInput2 * cData.wRight
			else
				gC.aimTarget = 'Pitch Target'
				tav = ((circleNormal(ap.target)):rotate(pitchRotate, horizontalRight)):cross(cData.wFwd)
			end

			tav = tav + -horizontalRight:rotate(targetRoll*constants.deg2rad, cData.wFwd):cross(cData.wRight)
		end

		if sameBody and ap.targetLoc == 'surface' then
			if gC.brakeTrigger and gC.lastProjectedDistance < 600 then
				gC.aimTarget = 'Brake Landing'
				tav = (circleNormal(ap.target)):cross(cData.wFwd)
				tav = (tav/3) + vectorToPoint(ap.target):cross(-cData.worldUp)-- LandingVec Test

				if (cData.altitude - getAltitude(ap.target)) < 200 or math.abs(getTargetAngle()) > 90 then --or not gC.horizontalStopped
					gC.aimTarget = 'Flat'
					tav = (circleNormal(ap.target)):cross(cData.wFwd) + cData.wVert:cross(cData.worldUp)
				end
				if (cData.altitude - getAltitude(ap.target)) < 100 then
					ap:toggleState(false)
					ap:toggleLandingMode(true)
				end
			end
		end

		if gC.apMode == 'Transfer' or (ap.targetLoc == 'space' and not cData.inAtmo) or (gC.apMode == 'Space Braking' and (cData.body.bodyId ~= ap.targetBody.bodyId or vector.dist(cData.position,ap.targetBody.center) > 200000 )) then
			if math.abs(getSpaceVelocityTargetAngle()) > 60 or (cData.speedKph <= 3000 and ap.targetLoc == 'surface') or (cData.speedKph < 500 and ap.targetLoc == 'space') then
				gC.aimTarget = 'Target'
				tav = vectorToPoint(ap.target):cross(cData.wFwd)
			else
				gC.aimTarget = 'TCross'
				tav = variousVectors(vectorToPoint(ap.target)).vecMain:cross(cData.wFwd)
			end
			if cData.inAtmo then
				tav = tav + -horizontalRight:rotate(targetRoll*constants.deg2rad, cData.wFwd):cross(cData.wRight)
			end
		end
	  if spcVector ~= 'ninety' then
		tav = vec3{clamp(tav.x,-aimStrength,aimStrength),clamp(tav.y,-aimStrength,aimStrength),clamp(tav.z,-aimStrength,aimStrength)} + finalInput
	  else
		tav = tav + finalInput
	  end
	end

	if gC.stallProtect and cData.constructSpeed > 55 and not gC.brakeTrigger then --Stall Protection
		gC.aimTarget = 'Stall Protect'
		tav = -cData.wVelDir:cross(cData.wFwd) + finalInput
		tav = tav + -horizontalRight:rotate(targetRoll*constants.deg2rad, cData.wFwd):cross(cData.wRight)
	end

	if gC.radialOut then
		tav = cData.wVert:cross(cData.wFwd)
		tav = vec3{clamp(tav.x,-aimStrength,aimStrength),clamp(tav.y,-aimStrength,aimStrength),clamp(tav.z,-aimStrength,aimStrength)} + finalInput
	elseif gC.radialIn then
		tav = cData.wVert:cross(-cData.wFwd)
		tav = vec3{clamp(tav.x,-aimStrength,aimStrength),clamp(tav.y,-aimStrength,aimStrength),clamp(tav.z,-aimStrength,aimStrength)} + finalInput
	elseif gC.cameraAim then
		if cData.inAtmo then
			tav = vec3(system.getCameraWorldForward()):cross(-cData.wFwd)
			tav = tav + -horizontalRight:rotate(targetRoll*constants.deg2rad, cData.wFwd):cross(cData.wRight)
			tav = vec3{clamp(tav.x,-aimStrength,aimStrength),clamp(tav.y,-aimStrength,aimStrength),clamp(tav.z,-aimStrength,aimStrength)}
		else
			tav = vec3(system.getCameraWorldForward()):cross(-cData.wFwd)
			tav = vec3{clamp(tav.x,-aimStrength,aimStrength),clamp(tav.y,-aimStrength,aimStrength),clamp(tav.z,-aimStrength,aimStrength)}
		end
	end

	if gC.followMode then
		tav = (circleNormal(playerData.playerPosition)):cross(cData.wFwd)
		tav = tav + -horizontalRight:rotate(targetRoll*constants.deg2rad, cData.wFwd):cross(cData.wRight)
	end
	targetAngularVelocity = tav
	return targetAngularVelocity
end

-- Engine commands (called from applyShipInputs)
function applyEngineCommands(targetAngularVelocity, angularAcceleration, brakeAcceleration)
	local gC, aCache, ap = globals, Axis, AutoPilot
	local keepCollinearity = true -- for easier reading
	local dontKeepCollinearity = false -- for easier reading
	local tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we don't go to the next priorities

	Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
	Nav:setEngineForceCommand('brake', brakeAcceleration)

	-- Autonavigation aka Cruise Control
	local autoNavigationEngineTags = ''
	local autoNavigationAcceleration = vec3()
	local autoNavigationUseBrake = false

	--local longitudinalPrimaryTags = 'primary'
	local longitudinalSecondaryTags = 'secondary'
	local longitudinalTertiaryTags = 'tertiary'
	local longitudinalEngineTags = 'thrust analog longitudinal'
	local lateralStrafeEngineTags = 'thrust analog lateral'
	local verticalStrafeEngineTags = 'thrust analog vertical'
	local verticalAirfoilTags = 'vertical airfoil'
	local lateralAirfoilTags = 'lateral airfoil'
	local longitudinalCruiseIsOn = navCom:getAxisCommandType(axisCommandId.longitudinal) == axisCommandType.byTargetSpeed
	local lateralCruiseIsOn = navCom:getAxisCommandType(axisCommandId.lateral) == axisCommandType.byTargetSpeed
	local verticalCruiseIsOn = navCom:getAxisCommandType(axisCommandId.vertical) == axisCommandType.byTargetSpeed

	if longitudinalCruiseIsOn then
		autoNavigationEngineTags = longitudinalEngineTags
		autoNavigationAcceleration = autoNavigationAcceleration + navCom:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal)
	else
		if aCache.throttle1Axis ~= 0 then
			navCom:setThrottleCommand(axisCommandId.longitudinal, aCache.throttle1Axis)
		end
		local acceleration = navCom:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
		if ((cData.atmoDensity >= 0.1 and gC.advAtmoEngines) or (not cData.inAtmo and gC.advSpaceEngines) or (gC.advSpaceEngines and gC.advAtmoEngines)) and cData.curThrottle > 0 then
			local idx = ternary(cData.inAtmo,1,3)
			if gC.boostMode == 'primary' then
				Nav:setEngineForceCommand(longitudinalSecondaryTags.. ' , ' .. longitudinalTertiaryTags, vec3(), keepCollinearity)
				unit.setEngineThrust('primary', gC.maxPrimaryKP[idx]*cData.curThrottle)
			elseif gC.boostMode == 'all' then
				Nav:setEngineForceCommand(longitudinalEngineTags, acceleration, keepCollinearity)
			elseif gC.boostMode == 'locked' then
				Nav:setEngineForceCommand(longitudinalSecondaryTags.. ' , ' .. longitudinalTertiaryTags, acceleration, keepCollinearity)
				unit.setEngineThrust('primary', gC.maxPrimaryKP[idx])
			elseif gC.boostMode == 'hybrid' then
				local primThrottle = 0
				local secThrottle = 0
				local tertThrottle = 0
				local targetThrottle2 = 0
				local modifierThrottleOne = 0
				local modifierThrottleTwo = 0
				local modifierThrottleThree = 0

				if (cData.inAtmo and gC.maxTertiaryKP[1] > 0) or (not cData.inAtmo and gC.maxTertiaryKP[3] > 0) then
					local umap = utils.map
					targetThrottle2 = cData.curThrottle*3.9
					modifierThrottleOne = (umap(clamp(targetThrottle2,300,330),300,330,0,30))/100
					modifierThrottleTwo = (umap(clamp(targetThrottle2,330,360),330,360,0,30))/100
					modifierThrottleThree = (umap(clamp(targetThrottle2,360,390),360,390,0,30))/100
					primThrottle = ((umap(clamp(targetThrottle2,0,100),0,100,0,70))/100)+modifierThrottleOne
					secThrottle  = ((umap(clamp(targetThrottle2,100,200),100,200,0,70))/100)+modifierThrottleTwo
					tertThrottle = ((umap(clamp(targetThrottle2,200,300),200,300,0,100))/100)+modifierThrottleThree
					else
					targetThrottle2 = cData.curThrottle*2.6
					modifierThrottleOne = (umap(clamp(targetThrottle2,200,230),200,230,0,30))/100
					modifierThrottleTwo = (umap(clamp(targetThrottle2,230,260),230,260,0,30))/100
					primThrottle = ((umap(clamp(targetThrottle2,0,100),0,100,0,70))/100)+modifierThrottleOne
					secThrottle = ((umap(clamp(targetThrottle2,100,200),100,200,0,70))/100)+modifierThrottleTwo
					end
					unit.setEngineThrust('primary', gC.maxPrimaryKP[idx]*primThrottle)
					unit.setEngineThrust('secondary', gC.maxSecondaryKP[idx]*secThrottle)
					unit.setEngineThrust('tertiary', gC.maxTertiaryKP[idx]*tertThrottle)
			end
		else
			Nav:setEngineForceCommand(longitudinalEngineTags, acceleration, keepCollinearity)
		end
	end

	if lateralCruiseIsOn then
		if gC.lateralState then
			autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
		else
			Nav:setEngineForceCommand(lateralStrafeEngineTags, vec3(), dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
			autoNavigationAcceleration = autoNavigationAcceleration + navCom:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
		end
	else
		local acceleration = navCom:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
		if not gC.lateralState then
			acceleration = vec3()
		end
		Nav:setEngineForceCommand(lateralStrafeEngineTags, acceleration, keepCollinearity)
		if ap.enabled and cData.inAtmo then
			local horizontalRight = cData.wVert:cross(cData.wFwd):normalize()
			local horizontalAcceleration = vec3()
			local vta = getVelocityTargetAngle()
			if vta < 0 then
				horizontalAcceleration = -horizontalRight*20
			elseif vta > 0 then
				horizontalAcceleration = horizontalRight*20
			end
			Nav:setEngineForceCommand(lateralAirfoilTags, horizontalAcceleration, keepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
		end
	end

	if verticalCruiseIsOn then
		if gC.verticalState or gC.waterState then
			autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags
		else
			Nav:setEngineForceCommand(verticalStrafeEngineTags, vec3(), dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
		end
		autoNavigationAcceleration = autoNavigationAcceleration + navCom:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
	else
		local acceleration = navCom:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
		if not gC.verticalState and not gC.waterState then
		acceleration = vec3()
		end
		Nav:setEngineForceCommand(verticalStrafeEngineTags, acceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
		if (ap.enabled and cData.inAtmo) or (gC.altitudeHold) or (gC.orbitalHold and cData.inAtmo) then
			local wVert20 = cData.wVert*20
			if gC.apMode == 'Landing' then
				Nav:setEngineForceCommand(verticalAirfoilTags, wVert20, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
			elseif (cData.altitude < gC.holdAltitude or cData.vertSpeed < -10) then
				Nav:setEngineForceCommand(verticalAirfoilTags, -wVert20, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
			elseif (gC.orbitalHold and cData.inAtmo) then
				Nav:setEngineForceCommand(verticalAirfoilTags, -wVert20, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
			else
				Nav:setEngineForceCommand(verticalAirfoilTags, -cData.wVert*5, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)
			end
		end
	end

	-- Cruise control braking
	if (navCom:getTargetSpeed(axisCommandId.longitudinal) == 0 or -- we want to stop
		--navCom:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - navCom:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) -- if the longitudinal velocity would need some braking
		navCom:getTargetSpeed(axisCommandId.longitudinal) < (cData.speedKph - 10))
	then
		autoNavigationUseBrake = true
	end

	-- Cruise control engine commands
	if (autoNavigationAcceleration:len() > constants.epsilon) then
		if (inputs.brake ~= 0 or autoNavigationUseBrake or math.abs(cData.wVelDir:dot(cData.wFwd)) < 0.95)  -- if the velocity is not properly aligned with the forward
		then
			autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
		end
		navCom:updateCommandFromActionLoop(axisCommandId.longitudinal, 0)
		Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
	end

	-- Rockets
	Nav:setBoosterCommand('rocket_engine')
end

function validateParms()
	local max = math.max
	pitchSpeedFactor = max(pitchSpeedFactor, 0.01)
	yawSpeedFactor = max(yawSpeedFactor, 0.01)
	rollSpeedFactor = max(rollSpeedFactor, 0.01)
	torqueFactor = max(torqueFactor, 0.01)
	brakeSpeedFactor = max(brakeSpeedFactor, 0.01)
	brakeFlatFactor = max(brakeFlatFactor, 0.01)
	autoRollFactor = max(autoRollFactor, 0.01)
	turnAssistFactor = max(turnAssistFactor, 0.01)
end

function applyShipInputs()
	local ap, aCache, gC = AutoPilot, Axis, globals

	-- final inputs
	local finalPitchInput = inputs.pitch + aCache.pitchAxis + system.getControlDeviceForwardInput()
	local finalRollInput = inputs.roll + aCache.rollAxis + system.getControlDeviceYawInput()
	local finalYawInput = inputs.yaw + aCache.yawAxis - system.getControlDeviceLeftRightInput()
	local finalBrakeInput = inputs.brake + aCache.brakeAxis

	local targetAngularVelocity = getTargetAngularVelocity(finalPitchInput, finalRollInput, finalYawInput)

	local angularAcceleration = torqueFactor * (targetAngularVelocity - cData.worldAngularVelocity)
	angularAcceleration = angularAcceleration - cData.angularAirFriction -- Try to compensate air friction
	local brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * cData.wVel + brakeFlatFactor * cData.wVelDir)
	if not gC.rotationDampening then
		if inputs.pitch == 0 and inputs.yaw == 0 and inputs.roll == 0 then
			angularAcceleration = vec3()
		end
	end
	if gC.inOrbit and gC.orbitalHold and not gC.brakeTrigger then
		local brakeSensitivity = clamp(((orbitFocus().orbitAltTarget-gC.targetOrbitAlt)*0.0001)*4,0.01,5)
		brakeAcceleration = vec3(clamp(brakeAcceleration.x,-brakeSensitivity,brakeSensitivity), clamp(brakeAcceleration.y,-brakeSensitivity,brakeSensitivity), clamp(brakeAcceleration.z,-brakeSensitivity,brakeSensitivity))
	end
	if ap.enabled and (brakeCtrl == 12.1 or brakeCtrl == 13.1
		or ((brakeCtrl == 0.1) and cData.zSpeedKPH > -100))
		and cData.speedKph < cData.burnSpeedKph-50 then
			local brkSens2 = 2
			brakeAcceleration = vec3(clamp(brakeAcceleration.x,-brkSens2,brkSens2),
				clamp(brakeAcceleration.y,-brkSens2,brkSens2),
				clamp(brakeAcceleration.z,-brkSens2,brkSens2))
	end
	if ap.landingMode then
		brakeAcceleration = brakeAcceleration * 9
	elseif gC.altitudeHold then
		brakeAcceleration = -inputs.brake * cData.wFwd * ((cData.forwardSpeed + cData.lateralSpeed)*3.6)
	end
	applyEngineCommands(targetAngularVelocity, angularAcceleration, brakeAcceleration)
end