-- called within system.onUpdate!
function onTimerAPU()
	local gCache = globals
	local axisLong = axisCommandId.longitudinal
	local axisVert = axisCommandId.vertical
	local ap = AutoPilot
	local aggData = aggData
	local cData = cData

	gCache.collision, gCache.farSide, gCache.nearSide = castIntersections()
	--gCache.collisionAlert = false
	local curAltitude = cData.altitude
	local curTargAlt = ap.targetAltitude

	-- if gCache.collision ~= nil then
	-- 	if gCache.collision.bodyId ~= targetBody.bodyId then
	-- 		if gCache.collision.hasAtmosphere then
	-- 			local atmoColDist = vector.dist(gCache.collision.center,cData.position)-(gCache.collision.atmoRadius*1.05)
	-- 			if cData.brakes.distance*1.4 >= atmoColDist and getAltitude() > gCache.collision.atmoAltitude*1.05 then
	-- 				gCache.collisionAlert = true
	-- 			end
	-- 		else
	-- 			local moonColDist = vector.dist(gCache.collision.center,cData.position)-(gCache.collision.radius*1.5)
	-- 			if cData.brakes.distance*1.4 >= moonColDist and getAltitude() > gCache.collision.radius*1.2 then
	-- 				gCache.collisionAlert = true
	-- 			end
	-- 		end
	-- 	end
	-- end

	if gCache.followMode then
		local shipDist = vector.dist(cData.position,playerData.playerPosition)
		local playerSpeed = playerData.playerVelocity:len()*3.6
		local shipSpd = 20 + playerSpeed - (20 - math.min(shipDist-50,20))
		if playerSpeed == 0 then
			shipSpd = 20
		end
		if shipDist > 200 then
			gCache.followReposition = true
			navCom:setTargetGroundAltitude(ap.userConfig.hoverHeight)
			if ap.landingMode then
				ap:toggleLandingMode(false)
			end
		end

		if gCache.followReposition then
			navCom:setThrottleCommand(axisLong, getThrottle(shipSpd))
			if cData.speedKph > shipSpd+10 then
				inputs.brake = 1
			else
				inputs.brake = 0
			end
		end

		if gCache.followReposition and shipDist < 50 and playerSpeed < 30 then
			navCom:setThrottleCommand(axisLong, getThrottle(0))
			if not ap.landingMode then
				ap:toggleLandingMode(true)
			end
			gCache.followReposition = false
		end
	end

	if gCache.safetyThrottle and (system.getMouseWheel() ~= 0 or gCache.orbitalHold) then
		if not inputs.manualBrake then
			inputs.brake = 0
		end
		gCache.safetyThrottle = false
	end

	if ap.enabled then
		inputs.brake = 0
		navCom:setTargetGroundAltitude(ap.userConfig.hoverHeight)
	else
		gCache.apMode = 'Off'
	end

	if ap.userConfig.throttleBurnProtection then --Atmo throttle overspeed protection
		if not ap.enabled and not ap.landingMode and not gCache.orbitalHold and not inputs.manualBrake then
			local cPitch = utils.round(cData.rpy.pitch)
			if cData.atmoDensity >= 0.05 or (cData.inAtmo and cData.zSpeedKPH < -100) then
				if cData.speedKph > cData.burnSpeedKph or gCache.safetyThrottle then
					gCache.safetyThrottle = true
					if controlMode() == 'cruise' then
						swapControl()
					end
					if cData.atmoDensity < 0.05 and cPitch > 5 then
					else navCom:setThrottleCommand(axisLong, getThrottle(cData.burnSpeedKph-100)) end
				end
				if gCache.safetyThrottle then
					if cData.speedKph > (cData.burnSpeedKph-50) then
						brakeCtrl = 32
						inputs.brake = 1
					else
						brakeCtrl = 33
						inputs.brake = 0
					end
				end
			end
		else
			gCache.safetyThrottle = false
		end
	end

	if links.shield ~= nil and ap.userConfig.shieldManage == true then
        local shld = links.shield ---@type ShieldGenerator
		local srp = shld.getResistancesPool()
		local csr = shld.getResistances() --CurrentShieldResistances
		local rcd = shld.getResistancesCooldown() --ResistanceCooldown
		local shp = shld.getShieldHitpoints() --shield hitpoints
		--local mshp = shld.getMaxShieldHitpoints()
		--local sHealth = ((shp/mshp)*100)

		if shld.getStressHitpointsRaw() == 0 then
			srp = srp / 4
			-- Set shield resistances evenly.
			-- Returns 0 on fail and 1 on success
			if (csr[1] == srp and csr[2] == srp and csr[3] == srp and csr[4] == srp) or rcd ~= 0 then --if resistances are already balanced, dont waste the resistance timer.
			--do nothing
			else
				shld.setResistances(srp,srp,srp,srp) --if they need to be balanced and timer is up, do so.
			end
		else
			-- Get damage type ratios out of 100%
			local srr = shld.getStressRatioRaw()
			-- Set shield resistances based on damage type percentages
			if (csr[1] == (srp*srr[1]) and csr[2] == (srp*srr[2]) and csr[3] == (srp*srr[3]) and csr[4] == (srp*srr[4])) or rcd ~= 0 then -- If ratio hasent change, or timer is not up, dont waste the resistance change timer.
				--do nothing
			else --If stress ratio has changed, and the reset timer is up, update resistances.
				shld.setResistances(srp*srr[1],srp*srr[2],srp*srr[3],srp*srr[4])
			end
		end

		if shp == 0 and shld.getVentingCooldown() == 0 then --vent if shield goes down and venting is available
			shld.startVenting()
		end

		if cData.pvpZone and not shld.isActive() then
			shld.activate()
		elseif not cData.pvpZone and shld.isActive() then
			shld.deactivate()
		end
	end

	if inputs.pitch ~= 0 and not ap.enabled then
		gCache.holdAltitude = curAltitude
	end

	gCache.aggAP = false
	---@TODO review AGG target altitude change
	-- if links.antigrav ~= nil then
	-- 	if aggData.aggState and ap.userConfig.autoAGG == true and ap.targetLoc == 'surface' then
	-- 		gCache.aggAP = true
	-- 	end
	-- end

	--TODO customizable max speed / or burnSpeed
	if ap.enabled or gCache.altitudeHold then
		altHold()
	end

	if not gCache.orbitalHold or gCache.apMode ~= 'Orbit' then
		gCache.inOrbit = false
	end

	if gCache.orbitalHold or gCache.apMode == 'Orbit' then
		--local atmoAlt = cData.body.atmoRadius - cData.body.radius
		local surfaceAlt = cData.body.surfaceMaxAltitude
		local orbitAltT = cData.orbitFocus.orbitAltTarget
		local orbitSpd = cData.orbitFocus.orbitSpeed * 3.6
		local apo = cData.orbitalParameters.apoapsis.altitude
		local peri = cData.orbitalParameters.periapsis.altitude
		local tApo = cData.orbitalParameters.timeToApoapsis
		local tPer = cData.orbitalParameters.timeToPeriapsis
		brakeCtrl = 0
		inputs.brake = 0

		if gCache.apMode == 'Orbit' then
			if math.abs(getVelocityTargetAngle()) > 2 then
				brakeCtrl = 0.1
				inputs.brake = 1
			end
		end

		if not cData.inAtmo and curAltitude >= gCache.targetOrbitAlt and not gCache.inOrbit then
			if cData.speedKph >= orbitSpd then
				brakeCtrl = 1
				inputs.brake = 1
			end
		end
		if not gCache.inOrbit and cData.zSpeedKPH < -400 then
			brakeCtrl = 2
			inputs.brake = 1
		end

		gCache.inOrbit = (apo > surfaceAlt and peri > surfaceAlt)

		if controlMode() == 'cruise' then
			swapControl()
		end

		if gCache.inOrbit then
			if apo < gCache.targetOrbitAlt-100 then
				if tPer < 5 then
					apoUp = true
				end
			end
			-- if peri < gCache.targetOrbitAlt-100 and periUp == true then
			-- 	navCom:setThrottleCommand(axisLong, 1)
			-- else
			-- 	periUp = false
			-- 	navCom:setThrottleCommand(axisLong, 0)
			-- end

			if (apo < gCache.targetOrbitAlt-100 and apoUp == true) or (peri < gCache.targetOrbitAlt-100 and periUp == true) then
				SpdControl = '2'
				navCom:setThrottleCommand(axisLong, 0.1)
			else
				periUp = false
				apoUp = false
				SpdControl = '3'
				navCom:setThrottleCommand(axisLong, 0)
			end
			if apo > gCache.targetOrbitAlt+100 then
				if tPer < 5 then
					lastPeri = peri
					apoDown = true
				end
			end
			if apoDown then
				if lastPeri > peri + 50 then
					apoDown = false
				end
			end
			if apo > gCache.targetOrbitAlt+100 and apoDown == true then
				brakeCtrl = 'apoDwn'
				inputs.brake = 1
			else
				lastPeri = peri+1000
				apoDown = false
			end

			if peri < gCache.targetOrbitAlt-100 then
				if tApo < 5 then
					periUp = true
				end
			end
			if peri > gCache.targetOrbitAlt+100 then
				if tApo < 5 then
				   lastApo = apo
					periDown = true
				end
			end

			if periDown then
				if lastApo > apo + 50 then
					periDown = false
				end
			end

			if peri > gCache.targetOrbitAlt+100 and periDown == true then
				brakeCtrl = 3
				inputs.brake = 1
			else
				lastApo = apo+1000
				periDown = false
			end
			return
		end
		-- not in orbit:
		local tavCheck = {x = math.abs(targetAngularVelocity.x), y = math.abs(targetAngularVelocity.y), z = math.abs(targetAngularVelocity.z)}
		local aligned = false
		if (tavCheck.x < 0.008 and  tavCheck.y < 0.008 and tavCheck.z < 0.008) then
			aligned = true
		end
		if unit.getAtmosphereDensity() > 0.05 then
			SpdControl = '4'
			navCom:setThrottleCommand(axisLong, getThrottle())
		else
			--if curAltitude > gCache.targetOrbitAlt+500 and orbitAltT < 0 then
			--   if controlMode() == 'travel' then
			--	   swapControl()
			--   end
			--	navCom:setTargetSpeedCommand(axisLong, orbitSpeed*3.6)
			if orbitAltT > gCache.targetOrbitAlt-100 and curAltitude < gCache.targetOrbitAlt-5 then
				SpdControl = '5'
				navCom:setThrottleCommand(axisLong, 0)
			elseif orbitAltT < (gCache.targetOrbitAlt-100)  then
				SpdControl = '6'
				if aligned or cData.zSpeedKPH < 0 then
					navCom:setThrottleCommand(axisLong, getThrottle(orbitSpd))
				else
					navCom:setThrottleCommand(axisLong, 0.1)
				end
			--elseif orbitAltT > (gCache.targetOrbitAlt-400) then
				-- if controlMode() == 'travel' then
				--	swapControl()
				--end
				-- navCom:setTargetSpeedCommand(axisLong, (orbitSpd))
			else
				-- navCom:setTargetSpeedCommand(axisLong, (orbitSpd))
				SpdControl = '7'
				navCom:setThrottleCommand(axisLong, getThrottle(orbitSpd))
			end
		end
	end

	if (ap.enabled or gCache.altitudeHold or gCache.orbitalHold)
		and cData.inAtmo and getVelocityAngle() > ap.userConfig.wingStallAngle then
		gCache.stallProtect = true
	else
		gCache.stallProtect = false
	end

	if ap.enabled and not ap.target then
		ap:toggleState(false)
		P('No AP target set!')
	elseif ap.enabled and ap.target then
		inputs.brakeLock = false
		local body = cData.body
		local targetBody = ap.targetBody
		local projDist = projectedDistance(ap.target)
		gCache.safetyThrottle = false
		setTargetOrbitAlt()
		--[[if gCache.waitForBubble then
			if controlMode() == 'travel' then
				swapControl()
			end
		elseif SpdControl ~= '9.4' then
			if controlMode() == 'cruise' then
				swapControl()
			end
		end]]
		local behindPlanet = false
		if not ap.targetIsLastPoint then
			if ap.targetLoc == 'space' then
				if vector.dist(ap.target,cData.position) < 10000 then
					ap:onPointReached()
				end
			elseif ap.targetLoc == 'surface' then
				if sameBody and projDist < 1000 then
					ap:onPointReached()
				end
			end
		end

		if gCache.apMode ~= 'Orbit' then
			brakeCtrl = 4
			inputs.brake = 0
		end

		if gCache.aggAP then
			gCache.holdAltitude = aggData.aggAltitude
		elseif body then
			if body.hasAtmosphere then
				gCache.holdAltitude = math.max(math.max(body.surfaceMaxAltitude+1500,curTargAlt+1000), body.atmoAltitude*0.5)
			else
				gCache.holdAltitude = math.max(body.surfaceMaxAltitude+3000,curTargAlt+1000)
			end
		end

		sameBody = false
		if targetBody and body then
			if targetBody.bodyId ~= body.bodyId and not gCache.spaceCapable then
				P('Ship not space capable, shutting down AP')
				ap:toggleState(false)
			end
			sameBody = body.bodyId == targetBody.bodyId
		end
		--if gCache.aggAP then
		--	links.antigrav.setTargetAltitude((targetBody.atmoRadius - targetBody.radius)+1000)
		--end

		if not gCache.spaceCapable then
			if not sameBody or curTargAlt > (targetBody.atmoRadius - targetBody.radius) then
				P('point on other planet, ship currently set to not space capable.')
				ap:toggleState(false)
			end
		end

		local reEntryTrigger = false
		if gCache.apMode == 'reEntry' then
			reEntryTrigger = true
		end

		if sameBody and ap.targetLoc == 'surface' then
			if getTargetWorldAngle() > 18 then
				behindPlanet = true
			end
		else
			if getTargetWorldAngle() > 80 and vector.dist(body.center,cData.position) < body.radius*2 then
				behindPlanet = true
			end
		end

		if (math.abs(cData.forwardSpeed) + math.abs(cData.lateralSpeed)) < 3 then
			gCache.horizontalStopped = true
		else
			gCache.horizontalStopped = false
		end
		if not gCache.brakeTrigger then
			local longSurfaceTrip = sameBody and ap.targetLoc == 'surface' and projDist >= 100000
			if (sameBody and cData.inAtmo and not behindPlanet and not gCache.aggAP and ap.targetLoc == 'surface' and not longSurfaceTrip) or not gCache.spaceCapable then
				gCache.apMode = 'Atmo Travel'
			elseif (not sameBody or ap.targetLoc == 'space') and cData.inAtmo and gCache.smoothClimb then
				gCache.apMode = 'Transition'
			elseif (((not sameBody or ap.targetLoc == 'space') and not behindPlanet and not gCache.spaceBrakeTrigger) or (sameBody and curAltitude > gCache.targetOrbitAlt+1000 and not gCache.spaceBrakeTrigger) or (longSurfaceTrip and not gCache.spaceBrakeTrigger)) and not aggData.aggBubble or gCache.apMode == 'standby' then
				gCache.apMode = 'Transfer'
				gCache.orbitLock = false
			elseif gCache.aggAP and aggData.aggBubble then
				gCache.spaceBrakeTrigger = false
				gCache.apMode = 'agg'
			elseif (not cData.inAtmo and (cData.brakes.distance*1.5 >= projDist) and ((curAltitude < gCache.targetOrbitAlt+5000 and sameBody) or reEntryTrigger or (sameBody and gCache.inOrbit))) and not gCache.aggAP and body.hasAtmosphere and ap.targetLoc == 'surface' then --TODO do a check for if moon/asteroid or space points later and have different reaction since you cant reenter.
				gCache.orbitLock = false
				gCache.apMode = 'reEntry'
			elseif ((behindPlanet and sameBody and curAltitude < gCache.targetOrbitAlt+2000) or (behindPlanet and not sameBody) or gCache.orbitLock) or (sameBody and curAltitude < gCache.targetOrbitAlt+2000 and not targetBody.hasAtmosphere)and not gCache.aggAP and gCache.spaceCapable then
				gCache.orbitLock = true
				gCache.apMode = 'Orbit'
			elseif gCache.spaceBrakeTrigger and not cData.inAtmo then
				gCache.apMode = 'Space Braking'
			end
		end

		if links.antigrav ~= nil and ap.userConfig.autoAGGAdjust then
			if aggData.aggState and ap.targetLoc == 'surface' then
				--[[if body.name ~= targetBody.name and inAtmo and inBubble then
					if aggData.aggTarget ~= body.atmoAltitude+1000 then
						inks.antigrav.setTargetAltitude( body.atmoAltitude+1000 )
					end
				end]]
				--[[if body.name ~= targetBody.name and inAtmo and not inBubble then
					if curAltitude <= 1000 then
						if aggData.aggTarget ~= 1000 then
							links.antigrav.setTargetAltitude( 1000 )
						end
					elseif curAltitude > 1000 then
						if aggData.aggTarget ~= curAltitude then
						links.antigrav.setTargetAltitude( curAltitude )
						end
					end
				end]]
				--if body.name ~= targetBody.name then
				if targetBody ~= nil then
					if targetBody.hasAtmosphere and not aggData.aggBubble or not sameBody then
						if aggData.aggTarget ~= targetBody.atmoAltitude then
							links.antigrav.setTargetAltitude(targetBody.atmoAltitude)
						end
					elseif sameBody and aggData.aggBubble then
						if curTargAlt == 0 then
							if aggData.aggTarget ~= math.max(math.max(curTargAlt+500,1000), targetBody.surfaceMaxAltitude) then
								links.antigrav.setTargetAltitude(math.max(math.max(curTargAlt+500, 1000), targetBody.surfaceMaxAltitude))
							end
						else
							if aggData.aggTarget ~= math.max(curTargAlt+500,1000) then
								links.antigrav.setTargetAltitude(math.max(curTargAlt+500, 1000))
							end
						end
					end
				end
			end
		end

		if links.antigrav ~= nil and gCache.apMode == 'agg' then
			local tavCheck = {x = math.abs(targetAngularVelocity.x), y = math.abs(targetAngularVelocity.y), z = math.abs(targetAngularVelocity.z)}
			local aligned = false
			if (tavCheck.x < 0.005 and  tavCheck.y < 0.005 and tavCheck.z < 0.005) or cData.speedKph < 4000 or (cData.G > 0.5 and not sameBody) then
				aligned = true
			end
			local wTargetAngle = getTargetWorldAngle()
			local orbitSpd = cData.orbitFocus.orbitSpeed*3.6
			--local aggDist = ((vector.dist(targetBody.center,cData.position) - targetBody.radius) - aggData.aggAltitude)
			--if aggData.aggBubble and math.abs(cData.zSpeedKPH) > 25 then
			-- 	brakeCtrl = 5
			-- 	inputs.brake = 1
			-- end
			-- SpdControl = 'agg waiting'
			if wTargetAngle >= 0.5 and wTargetAngle < 5 and aligned then
				--gCache.spaceBrakeTrigger = false
				SpdControl = 'agg 1'
				navCom:setThrottleCommand(axisLong, getThrottle(300))
				--if cData.speedKph > 320 then
				--  brakeCtrl = 6
				--	inputs.brake = 1
				--end
			end
			if wTargetAngle >= 5 and aligned then
				--gCache.spaceBrakeTrigger = false
				SpdControl = 'agg 2'
				navCom:setThrottleCommand(axisLong, getThrottle(orbitSpd))
			end
		end

		local planetDist = vector.dist(cData.position, targetBody.center)
		if targetBody.hasAtmosphere then
			planetDist = utils.round(planetDist - (targetBody.atmoRadius*1.05))
		else
			planetDist = planetDist - (targetBody.radius*1.5)
		end

		if gCache.apMode == 'Transfer' or gCache.apMode == 'Space Braking' then
			local tavCheck = {x = math.abs(targetAngularVelocity.x), y = math.abs(targetAngularVelocity.y), z = math.abs(targetAngularVelocity.z)}
			local aligned = false
			if ap.targetLoc == 'surface' then
				if (tavCheck.x < 0.008 and  tavCheck.y < 0.008 and tavCheck.z < 0.008) or cData.speedKph < 4000 or
					(cData.G > 0.5 and not sameBody and cData.speedKph < ap.maxSpaceSpeed) then
					aligned = true
				end
			end
			if ap.targetLoc == 'space' then
				if (tavCheck.x < 0.008 and  tavCheck.y < 0.008 and tavCheck.z < 0.008) or cData.speedKph < 500
					or (cData.G > 0.5 and not sameBody and cData.speedKph < ap.maxSpaceSpeed) then
					aligned = true
				end
			end

			if gCache.aggAP and ap.targetLoc ~= 'space' then
				local aggDist = ((vector.dist(targetBody.center,cData.position) - targetBody.radius) - aggData.aggTarget)
				if gCache.aggAP and cData.brakes.distance*1.5 >= aggDist then
					gCache.spaceBrakeTrigger = true
					brakeCtrl = 9
					inputs.brake = 1
				end
				if gCache.aggAP and sameBody and curAltitude <= aggData.aggTarget+100 and not aggData.aggBubble then
					gCache.waitForBubble = true
					SpdControl = 'agg 5'
					navCom:setThrottleCommand(axisLong, 0)
					brakeCtrl = 10
					inputs.brake = 1
				else
					gCache.waitForBubble = false
				end
			end

			if (ap.targetLoc == 'surface' and cData.brakes.distance*1.4 >= curAltitude - gCache.targetOrbitAlt and sameBody
				and gCache.apMode ~= 'Landing' and cData.speedKph > 1000)
				or (ap.targetLoc == 'surface' and cData.brakes.distance*1.4 >= planetDist and not sameBody) then --TODO if target is on planet, or if mmon or space target. etc.
				gCache.spaceBrakeTrigger = true
				brakeCtrl = 11
				inputs.brake = 1
			end

			if ap.targetLoc == 'space' and cData.brakes.distance*1.4 >= vector.dist(ap.target,cData.position)-1000 then
				gCache.spaceBrakeTrigger = true
				if vector.dist(ap.target,cData.position) < 1000 then
					if cData.speedKph > 110 then
					brakeCtrl = 11.1
					inputs.brake = 1
					end
				else
					brakeCtrl = 11.2
					inputs.brake = 1
				end
			end

			if getSpaceVelocityTargetAngle() > 50 and gCache.apMode ~= 'Space Braking' and not cData.inAtmo then
				brakeCtrl = 12
				inputs.brake = 1
			end

			if not gCache.spaceBrakeTrigger then

				if cData.speedKph < ap.maxSpaceSpeed and aligned or cData.speedKph < 3000 then
					SpdControl = '8'
					navCom:setThrottleCommand(axisLong, getThrottle(ap.maxSpaceSpeed))
				elseif cData.speedKph < ap.maxSpaceSpeed then
					SpdControl = '8.1'
					navCom:setThrottleCommand(axisLong, 0.3)
				else
					SpdControl = '8.1.1'
					navCom:setThrottleCommand(axisLong, 0)
				end
				if getSpaceVelocityTargetAngle() > 0.05 and aligned and cData.speedKph >= ap.maxSpaceSpeed then
					SpdControl = '8.2'
					navCom:setThrottleCommand(axisLong, clamp((getSpaceVelocityTargetAngle()*0.1)-0.01,0,1))
				end
				if cData.atmoDensity > 0.05 then
					SpdControl = '8.3'
					navCom:setThrottleCommand(axisLong, getThrottle())
				end
			else
				if ap.targetLoc == 'surface' then
					if not gCache.aggAP then
						if getTargetWorldAngle() > 0.5 and cData.ySpeedKPH < 500 and aligned then
							SpdControl = '9'
							navCom:setThrottleCommand(axisLong, getThrottle(500,cData.forwardSpeed))
						else
							SpdControl = '9.1'
							navCom:setThrottleCommand(axisLong, 0)
						end
					else
						if getTargetWorldAngle() > 0.5 and cData.ySpeedKPH < 500 and aligned and curAltitude > aggData.aggTarget+200 then
							SpdControl = '9.2'
							navCom:setThrottleCommand(axisLong, getThrottle(500,cData.forwardSpeed))
						else
							SpdControl = '9.3'
							navCom:setThrottleCommand(axisLong, 0)
						end
					end
				else
					if not gCache.spaceBrakeTrigger then
						SpdControl = '9.4'
						navCom:setThrottleCommand(axisLong, getThrottle(ap.maxSpaceSpeed))
					else
						SpdControl = '9.5'
						if getSpaceVelocityTargetAngle() > 10 then
							navCom:setThrottleCommand(axisLong, getThrottle(ap.maxSpaceSpeed))
							brakeCtrl = 12.1
							inputs.brake = 1
						else
							navCom:setThrottleCommand(axisLong, getThrottle(100,cData.forwardSpeed))
						end
					end
				end
			end
		end

		if (ap.targetLoc == 'surface' and cData.brakes.distance*1.4 >= planetDist and not sameBody)
			and cData.speedKph * 1000 then --TODO if target is on planet, or if mmon or space target. etc.
			gCache.spaceBrakeTrigger = true
			brakeCtrl = 11.5
			inputs.brake = 1
		end

		--if gCache.apMode == 'Orbit' and sameBody or gCache.apMode == 'reEntry' or gCache.apMode == 'Atmo Travel' then
		if (sameBody and cData.inAtmo and gCache.apMode ~= 'Orbit' and gCache.apMode ~= 'Landing' and ap.targetLoc ~= 'space' ) or gCache.apMode == 'reEntry' then
			if (projDist < 5000 and not gCache.brakeTrigger) then
				SpdControl = '10'
				navCom:setThrottleCommand(axisLong, getThrottle(math.min(utils.round(projDist/2),500),cData.forwardSpeed))
				if cData.ySpeedKPH > math.min(utils.round(projDist/2),500)+100 and gCache.apMode == 'reEntry' then
					brakeCtrl = 13
					inputs.brake = 1
				end
			end
			if gCache.apMode == 'reEntry' then
				if projDist < 300 then
				gCache.brakeTrigger = true
				end
			end
			if cData.inAtmo and not ap.waitForBubble then
				SpdControl = '11'
					navCom:setThrottleCommand(axisLong, getThrottle(cData.burnSpeedKph-150))
					if math.abs(getVelocityTargetAngle()) > 5 then
						brakeCtrl = 13.1
						inputs.brake = 1
					end

					if cData.speedKph > cData.burnSpeedKph-100 then
						brakeCtrl = 14
						inputs.brake = 1
					end
					if cData.brakes.distance*1.5 >= projDist or projDist < 300 then
						gCache.brakeTrigger = true
					end
			end
		end

		if gCache.apMode == 'reEntry' then
			if getTargetWorldAngle() > 1 then
				if cData.zSpeedKPH < -200 then
					SpdControl = '12'
				navCom:setThrottleCommand(axisLong, getThrottle(1000,cData.forwardSpeed))
				else
					SpdControl = '13'
				navCom:setThrottleCommand(axisLong, getThrottle())
				end
				if cData.speedKph >= cData.burnSpeedKph-300 then
					brakeCtrl = 15
					inputs.brake = 1
				end
			else
				gCache.brakeTrigger = true
			end
		end

		if gCache.apMode == 'Orbit' and (sameBody and not targetBody.hasAtmosphere or gCache.aggAP) then

			if math.abs(getVelocityTargetAngle()) > 5 then
				brakeCtrl = 15.1
				inputs.brake = 1
			end

			if (cData.brakes.distance*1.4 >= (projDist)) then
				gCache.brakeTrigger = true
			end
		end

		if (gCache.apMode == 'reEntry' or (sameBody and curAltitude < gCache.targetOrbitAlt + 2000)) and ap.targetLoc ~= 'space' then
			if gCache.brakeTrigger then
				gCache.orbitLock = false
				if projDist > 1000 then
					gCache.brakeTrigger = false
				end
				gCache.apMode = 'Landing'
				if gCache.lastProjectedDistance > projDist then
					gCache.lastProjectedDistance = projDist
				end
				SpdControl = '14'
				navCom:setThrottleCommand(axisLong, 0)

				if  ((not gCache.horizontalStopped) and (cData.brakes.distance*1.4 >= (gCache.lastProjectedDistance - 150))) or (cData.zSpeedKPH < -1000) then
					brakeCtrl = 16
					inputs.brake = 1
				end
				if curTargAlt == 0 or ap.target == targetBody.center then
					curTargAlt = targetBody.surfaceMaxAltitude
				end
				if links.antigrav ~= nil then
					if aggData.aggState and ap.targetLoc == 'surface' then
						curTargAlt = aggData.aggAltitude
					end
				end
				if gCache.horizontalStopped then
					if (cData.brakes.distance*3 >= (curAltitude - curTargAlt)+300)
						or (cData.zSpeedKPH < -100 and (curAltitude - curTargAlt) < 400)
						or cData.speedKph > 1000 then
						brakeCtrl = 17
						inputs.brake = 1
					end
					if curAltitude < curTargAlt+500 and cData.zSpeedKPH < -75 then
						brakeCtrl = 18
						inputs.brake = 1
					end
				end
				if curAltitude <= curTargAlt and cData.vertSpeed >= 0 then
					ap:onPointReached()
				end

				if gCache.horizontalStopped and projDist > 300 then --TODO system to make sure you dont over pitch to return to target while braking.
					gCache.missedTarget = true
				end
			end
		end
		if ap.targetLoc == 'space' then
			if vector.dist(ap.target,cData.position) <= 1500 then
				ap:onPointReached()
			end
		end

		if gCache.initTurn then
			SpdControl = 'turn'
			if math.abs(getTargetAngle()) > 90 and cData.constructSpeed < 30 then
				navCom:setThrottleCommand(axisLong, 0)
			else
				gCache.initTurn = false
			end
		end
	end

	gCache.waterMode = cData.inAtmo and curAltitude < 0
	if gCache.waterMode then
		if inputs.pitch ~= 0 or gCache.verticalState then
			gCache.waterAlt = curAltitude
		end
		if not gCache.verticalState and not ap.landingMode then
			if (cData.zSpeedKPH < -5) or (curAltitude < gCache.waterAlt and cData.zSpeedKPH < 5) then
				gCache.waterState = true
				navCom:deactivateGroundEngineAltitudeStabilization()
				navCom:resetCommand(axisVert)
				navCom:updateCommandFromActionStart(axisVert, 1.0)
			else
				gCache.waterState = false
				navCom:resetCommand(axisVert)
				navCom:activateGroundEngineAltitudeStabilization()
				navCom:setTargetGroundAltitude(-1)
			end
		else
			navCom:deactivateGroundEngineAltitudeStabilization()
		end
	end

	if inputs.brakeLock then
		inputs.brake = 1
	end
end