Widgets.infos = Widget:new{class = 'infos'}
function Widgets.infos:build()
	local gC, cD, ap = globals, cData, AutoPilot
	local s, cs, rnd = {}, colorSpan, round2
	local rpy, gFM = cD.rpy, gC.maneuverMode
    local fm = ternary(gFM, ternary(ship.landingMode,'LANDING','Maneuver'),'Standard')
	s[#s+1] = boldSpan('FLIGHT MODE: ')..cs(ternary(gFM,'orange','springgreen'),fm)

	-- Display route name or target location, if possible
	if ap.target then
		local sT = boldSpan('TARGET: ')
		local rIdx = tonumber(ap.currentRouteIndex)
		if rIdx and rIdx > 0 then
			local tmpR = RouteDatabase.routes[rIdx]
			if tmpR and tmpR.name then
				s[#s+1] = sT..cs('springgreen',tostring(tmpR.name))
			end
		else
			if ap.targetLoc then
				s[#s+1] = sT..cs('springgreen',tostring(ap.targetLoc))
			end
		end
		if gC.maneuverMode and cD.inAtmo then
			s[#s+1] = boldSpan('Travel alt.: ')..cs('springgreen',round2(ap.userConfig.travelAlt,2))
		end
	end

	-- * ##### Sources for commented out values may also be commented out!!!
	-- * ##### Check getConstructData() first before uncommenting!!!

	s[#s+1] = 'Throttle = ' .. rnd(cD.curThrottle,2)
	s[#s+1] = 'Pitch = ' .. rnd(rpy.pitch,2)
	s[#s+1] = 'Yaw = ' .. rnd(rpy.yaw,2)
	s[#s+1] = 'Roll = ' .. rnd(rpy.roll,2)
	--s[#s+1] = 'Wing Stall Angle = ' .. ap.userConfig.wingStallAngle
	--s[#s+1] = 'Velocity Angle = ' .. rnd(getVelocityAngle(),0)
	--s[#s+1] = 'worldAirFriction = ' .. round2(cD.worldAirFriction:len(),3)
	-- s[#s+1] = 'angularAirFriction = ' .. round2(cD.angularAirFriction:len(),3)
	-- s[#s+1] = 'angular Acc. = ' .. round2(cD.worldAngularAcceleration:len(),3)
	-- s[#s+1] = 'angular Vel. = ' .. round2(cD.worldAngularVelocity:len(),3)
	--s[#s+1] = 'Crossection = ' .. round2(cD.crossSection,3)
	-- s[#s+1] = 'G = ' .. round2(cD.G,3)
	s[#s+1] = '<br>Burn Protection = ' .. tostring(ap.userConfig.throttleBurnProtection)
	if not cD.inAtmo then
		s[#s+1] = 'Max Space V = ' .. tostring(rnd(ap.maxSpaceSpeed))
	end
	s[#s+1] = 'Brake Dist = ' .. printDistance(cD.brakes.distance, true)
	s[#s+1] = 'Mass = ' .. rnd(cD.mass/1000, 3) .. ' T'
	if gC.altitudeHold and gC.holdAltitude > 0 then
		s[#s+1] = 'Alt. Hold = ' .. round2(gC.holdAltitude,0)
	end
	-- if cD.maxHoverDist then
	-- 	s[#s+1] = "Max. Hover: "..round2(cD.maxHoverDist or 0,2).."m"
	-- end
	-- if cD.MaxKinematics.Up then
	-- 	s[#s+1] = "Max Up (kN): "..round2(cD.MaxKinematics.Up/1000 or 0,2)
	-- end
	--s[#s+1] = "Max Brake: "..round(cD.maxBrake or 0)
	--s[#s+1] = "Max Landing: "..round2(cD.maxLanding or 0,2)
	if ap.userConfig.hoverHeight then
		s[#s+1] = "Hover: "..round2(ap.userConfig.hoverHeight or 0,2)
	end
	if ap.userConfig.agl then
		s[#s+1] = "AGL: "..round2(ap.userConfig.agl or 0,2)
	end
	s[#s+1] = "Ground: "..round2(cD.GrndDist or 0,2)

	if vec3.isvector(ap.target) then
		local distanceToTarget = vector.dist(ap.target, cD.position)
		s[#s+1] = '<br>Target = ' .. printDistance(distanceToTarget)
		local speed = cD.constructSpeed
		local eta = 'ETA = '
		if speed >= 1 then
			local secondsToTarget = distanceToTarget / speed
			s[#s+1] = eta..formatTimeString(secondsToTarget) .. ' (' .. rnd(speed) .. ' m/s)'
		else
			s[#s+1] = eta..'∞ (0 m/s)'
		end
		if ship.angle then
			s[#s+1] = 'Angle: '..round2(ship.angle,4)
		end
	end
	-- for debugging only:
	-- if tonumber(cD.MaxKinematics.UpGroundSpace) ~= nil then
	-- 	s[#s+1] = 'Up: '..round2(cD.MaxKinematics.UpGroundSpace/1000,2)..' kN'
	-- end
	-- if tonumber(cD.MaxKinematics.DownSpace) ~= nil then
	-- 	s[#s+1] = 'Down: '..round2(cD.MaxKinematics.DownSpace/1000,2)..' kN'
	-- end
	-- s[#s+1] = 'wVert '..tostring(cD.wVert)
	-- s[#s+1] = 'locVert '..tostring(cD.locVert)
	-- if type(gC.dbgTxt) == "string" and gC.dbgTxt ~= "" then
	-- 	s[#s+1] = gC.dbgTxt
	-- end
	self.rowCount = #s
	return table.concat(s, '<br>')
end