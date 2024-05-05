function HUD.constructDebug()
	--local tankData = tankData
	--local warpData = warpData
	local gC, rnd, cD, ap = globals, round2, cData, AutoPilot
	local bDist = cD.brakes.distance
	local cPitch = rnd(cD.rpy.pitch)
	-- local textSize = 1

	updateTanksCo()

	--rdata = activeRadar.getWidgetData()
	--if not radarSpawn then
	--	radarWidgetCreate()
	--	radarSpawn = true
	--end

	local bColor, oRed, br, eDiv = 'ivory', 'orangered', '<br>', '</div>'
	local html = {}
	html[#html+1] = getTDiv("speedBar", 50, 50, HUD.dynamicSVG.speedBar)
	html[#html+1] = getTDiv("throttleBar", 50, 50, HUD.dynamicSVG.throttleBar)

	-- velocity indicators (by Jeronimo)
-- 	if velocityVector then
-- 		local sizeX, sizeY, cAV = 1600, 1000, cD.wVelAbs:normalize()
-- 		local cAVx, cAVz = cAV.x, cAV.z
-- 		local velStrokeColor = oRed
-- 		local Az = deg(atan(cD.xSpeedKPH, cD.ySpeedKPH)) -- drift rot angle in deg
-- 		local Ax = deg(atan(cD.zSpeedKPH, cD.ySpeedKPH)) -- drift pitch angle in deg
-- 		if cD.velMag < 1 then cAVx, cAVz = 0,0 else if abs(Ax) > 45 or abs(Az) > 45 then velStrokeColor = "red" end end
-- 		local ds = 'style="filter: drop-shadow(1px 1px 0px black) drop-shadow(0px 0px 3px black);"'
-- 		local SVGvelocity = [[<circle cx="]].. 800+cAVx*305 ..[[" cy="]].. 450+cAVz*-305 ..[[" r="10" stroke-width="1.5" stroke="]]..velStrokeColor..[[" fill="none"/>
-- <line x1="800" y1="450" x2="]].. 800+cAVx*300 ..[[" y2= "]].. 450+cAVz*-300 ..[[" stroke-width="1" fill="none" stroke="]]..velStrokeColor..[["/>]]
-- 		local SVGfinal = '<div><svg viewBox="0 0 '.. sizeX ..' '.. sizeY ..'" '..ds..'>'..SVGvelocity.. '</svg></div>'
-- 		html[#html+1] = SVGfinal
-- 	end

	local bD2, planetStr = rnd(cD.brakes.distance*1.1,1), ''
	if cD.body then
		local dist = 0
		if cD.body.hasAtmosphere then -- planet
			dist = rnd(cD.body.atmoRadius - vector.dist(cD.body.center,cD.position),1)
			planetStr = 'Atmo Dist = '
		else -- moon
			dist = rnd(vector.dist(cD.body.center,cD.position)-(cD.body.radius*1.05))
			planetStr = 'Surf Dist ~ '
		end
		planetStr = br..planetStr..printDistance(dist)
		if bD2 > dist and dist > 0 then bColor = oRed end
		html[#html+1] = getTDiv("altBar", 50, 50, HUD.dynamicSVG.altitudeBar)
		-- html[#html+1] = [[<div class="altBar" style="transform:translate(50vw,50vh)">]]..HUD.dynamicSVG.altitudeBar..eDiv
	end
	html[#html+1] = [[<div class="atmoAlert">Brake Dist = ]]..
		colorSpan(bColor,printDistance(bD2, true))..planetStr..eDiv
	html[#html+1] = [[<div class="atmoAlert" style="transform:translate(36.2vw,0vh);text-align:right;">Vertical Speed: ]]..
		(rnd(cD.zSpeedKPH,1))..eDiv

	if ap.enabled and not gC.maneuverMode then
		html[#html+1] = getAPDiv("AUTOPILOT")
	elseif ap.landingMode or ship.landingMode or cD.isLanded then
		html[#html+1] = getAPDiv("PARKING MODE")
	elseif ship.takeoff then
		html[#html+1] = getAPDiv("TAKEOFF")
	elseif ship.vertical then
		html[#html+1] = getAPDiv("VERTICAL")
	elseif ship.gotoLock ~= nil then
		html[#html+1] = getAPDiv("TRAVEL")
	end

	if gC.safetyThrottle then
		html[#html+1] = getBrakeDiv("SAFETY THROTTLE", oRed)
	elseif gC.altitudeHold then
		html[#html+1] = getBrakeDiv("HODOR!   "..rnd(ship.holdAltitude or 0,1).."m", oRed)
	elseif inputs.brakeLock then
		html[#html+1] = getBrakeDiv("BRAKE LOCK", oRed)
	elseif inputs.brake == 1 then
		html[#html+1] = getBrakeDiv("BRAKE", oRed)
	end
	--html[#html+1] = getBrakeDiv(tostring(rnd(cD.velocity.z,5)), ored)
	---@TODO "heavy" message?
	--if 0.5 * cData.MaxKinematics.Forward / cData.G < cData.mass then msg("WARNING: Heavy Loads may affect autopilot performance.") end

	local collisionStatus = false
	if gC and type(gC.collision) == 'table' then
		local bDist2 = rnd(bDist*1.2)
		local vSpeed = cD.zSpeedKPH

		if gC.collision and gC.collision.hasAtmosphere then
			local atmoColDist2 = rnd(vector.dist(cD.body.center,cD.position)-(gC.collision.atmoRadius))
			if bDist2 > atmoColDist2 and atmoColDist2 > 0 and vSpeed < 0 and cD.constructSpeed > cD.burnSpeed then
				collisionStatus = true
			end
		else
			local moonColDist = rnd(vector.dist(cD.body.center,cD.position)-(gC.collision.radius*1.1))
			if bDist2 > moonColDist and moonColDist > 0 and vSpeed < 0 then
				collisionStatus = true
			end
		end
		if collisionStatus then
			html[#html+1] = getDiv("collision", "Collision Alert: "..tostring(gC.collision.name or "(unknown)"))
		end
		--Atmo throttle overspeed protection
		--this was apparently missing the check for atmo!
		if ap.userConfig.throttleBurnProtection and not gC.orbitalHold
			and not ap.enabled and not ap.landingMode and cData.inAtmo then
			if collisionStatus then
				gC.safetyThrottle = true
				if controlMode() == 'cruise' then
					swapControl()
				end
				if cPitch < 5 then
					navCom:setThrottleCommand(axisCommandId.longitudinal, 0)
				end
			end
			if gC.safetyThrottle and collisionStatus then
				gC.collisionBrake = true
				brakeCtrl = 30
				inputs.brake = 1
			end
		end
	end
	if not collisionStatus and gC.collisionBrake then
		brakeCtrl = 31
		gC.collisionBrake = false
		if not gC.brakeState then
			inputs.brake = 0
		end
	end
	html[#html+1] = '<style>' .. HUD.staticCSS.css .. '></style>'

	local targetPoint = nil
	if ap.target ~= nil then
		targetPoint = library.getPointOnScreen(getXYZ(ap.target)) -- Target
	end

	-- Crosshair
	--local reticle1 = getReticle(cD.wFwd*cD.constructSpeed)
	local coord =  vec3(cD.wFwd) * 20 + vec3(cD.worldUp) * 2
	local reticle1 = getReticle(coord)
	local point1 = library.getPointOnScreen(reticle1)

	local vector2 = vectorRotated(targetAngularVelocity,cD.wFwd)
	local reticle2 = getReticle(vector2*10)
	-- ManeuverNode (AP/player input), for now just the current TAV
	local point2 = library.getPointOnScreen(reticle2)

	local predict = cD.wVelDir*cD.constructSpeed
	local reticle3 = getReticle(predict)
	local point3 = library.getPointOnScreen(reticle3) --Prograde
	local reticle4 = getReticle(-predict)
	local point4 = library.getPointOnScreen(reticle4) --ManeuverNode - predicted motion

	-- if gC.arMode ~= "none" then
	-- 	for _,planet in pairs(atlas[systemId]) do
	-- 		if cD.body.name ~= planet.name or (cD.body.name ~= planet.name and vector.dist(cD.body.center, cD.position) > 100000) then
	-- 			local planetTrgt = library.getPointOnScreen(getXYZ(planet.center))
	-- 			local scale = clamp(rnd((vector.dist(planet.center,cD.position))/200000),10,500)
	-- 			local scaleMap = (math.abs(utils.map(scale, 10, 500, 0.3, 2) - 2.4))
	-- 			local planetType = HUD.staticSVG.planetsIcon
	-- 			local plan = [[<div class="planets" style="transform:translate(]]
	-- 			if planet.type == 'Planet' and (gC.arMode == 'planets' or gC.arMode == 'both') then
	-- 				planetType = HUD.staticSVG.planetsIcon
	-- 				html[#html+1] = plan..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh) scale(]]..scaleMap..[[)">]]..planetType..eDiv
	-- 				html[#html+1] = [[<div class="ptext" style="transform:translate(]]..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh); font-size: 1vhx; text-shadow: 4px 4px 5px maroon;">]]..tostring(planet.name)..eDiv
	-- 			elseif planet.type == 'Moon' and (gC.arMode == 'moons' or gC.arMode == 'both') then
	-- 				planetType = HUD.staticSVG.moonsIcon
	-- 				html[#html+1] = plan..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh) scale(]]..scaleMap..[[)">]]..planetType..eDiv
	-- 				html[#html+1] = [[<div class="mtext" style="transform:translate(]]..(planetTrgt[1]*100)..[[vw,]]..(planetTrgt[2]*100)..[[vh); font-size: 1vh; text-shadow: 4px 4px 5px midnightblue;">]]..tostring(planet.name)..eDiv
	-- 			end
	-- 		end
	-- 	end
	-- end
	if point1[1] <= 1 and point1[2] <= 1 then
--	<div class="crosshair" style="position:absolute;left:]]..(point1[1]*100)..[[%;top:]]..(point1[2]*100)..[[%;margin-top:0em;margin-left:0em;">
		local crosshair = [[
	<div class="crosshair" style="position:absolute;left:]]..(point1[1]*98)..[[%;top:]]..(point1[2]*101)..[[%;margin-top:0em;margin-left:0em;">
	<svg style="width:2vw;height:2vh;" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
	<path d="M23.6465 37.8683L24.0001 38.2218L24.3536 37.8683L26.3536 35.8684L26.5 35.7219V35.5148V26.5H35.5148H35.7219L35.8684 26.3536L37.8684 24.3536L38.2219 24L37.8684 23.6465L35.8684 21.6465L35.7219 21.5H35.5148H26.5V12.4852V12.2781L26.3536 12.1317L24.3536 10.1317L24.0001 9.77818L23.6465 10.1317L21.6465 12.1318L21.5 12.2782V12.4854V21.5H12.4854H12.2782L12.1318 21.6465L10.1318 23.6465L9.77824 24L10.1318 24.3536L12.1318 26.3536L12.2782 26.5H12.4854H21.5V35.5147V35.7218L21.6465 35.8682L23.6465 37.8683Z" fill="#00dd00" stroke="#333333"/>
	</svg></div>]]
		html[#html+1] = crosshair
	end

	if targetPoint ~= nil then
		html[#html+1] = getTDivP("dot", targetPoint, HUD.staticSVG.targetReticle)
		html[#html+1] = getTDivP("dottext", targetPoint, HUD.dynamicSVG.targetReticle2)
	end
	html[#html+1] = getTDivP("dot", point2, HUD.staticSVG.centerofMass)
	html[#html+1] = getTDivP("dot", point3, HUD.staticSVG.progradeReticle)
	html[#html+1] = getTDivP("dot", point4, HUD.staticSVG.retrogradeReticle)
	-- local szBorder = getSafeZoneBorder()
	-- html[#html+1] = getTDivP("dot", szBorder.arBorder, HUD.staticSVG.skull..printDistance(szBorder.borderDist, true))

	return table.concat(html)
end