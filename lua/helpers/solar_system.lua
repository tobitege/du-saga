local sin, cos, acos, atan, pi, sqrt, huge, uround =
math.sin, math.cos, math.acos, math.atan, math.pi, math.sqrt, math.huge, utils.round

-- function findClosestBodyId(coordinates)
-- 	local closest = findClosestBody(coordinates)
--	 if closest == nil then return 0 end
-- 	return closest.bodyId
-- end

function findClosestBody(coordinates)
	local minDistance = huge
	local closestBody = nil
	for _,planet in pairs(atlas[systemId]) do
		local distance = vector.dist(coordinates, planet.center)
		if distance < minDistance then
			minDistance = distance
			closestBody = planet
		end
	end
	return closestBody, minDistance
end

function parsePosString(posString)
	local num = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
	local systemId, bodyId, latitude, longitude, altitude =
		string.match(posString, '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' .. num ..  ',' .. num .. '}')
	local tN = tonumber
	systemId	= tN(systemId)
	bodyId		= tN(bodyId)
	latitude	= tN(latitude)
	longitude	= tN(longitude)
	altitude	= tN(altitude)
	return {
		latitude	= latitude,
		longitude   = longitude,
		altitude	= altitude,
		bodyId		= bodyId,
		systemId	= systemId
	}
end

-- Convert a ::pos string to world coordinates
function convertToWorldCoordinates(pos)
	local mapPosition = parsePosString(pos)
	return mapPosToWorldPos(mapPosition)
end

function mapPosToWorldPos(mapPosition)
	if mapPosition.altitude == nil then return nil end
	if mapPosition.bodyId == nil or mapPosition.bodyId == 0 then -- support deep space map position
		return vec3(mapPosition.latitude,
					mapPosition.longitude,
					mapPosition.altitude)
	end
	local lat = constants.deg2rad*clamp(mapPosition.latitude, -90, 90)
	local lon = constants.deg2rad*(mapPosition.longitude % 360)
	local xproj = cos(lat)
	local planet = atlas[mapPosition.systemId][mapPosition.bodyId]
	return vec3(planet.center) + (planet.radius + mapPosition.altitude) *
		   vec3(xproj*cos(lon), xproj*sin(lon), sin(lat))
end

function bodyPosFromWorldPos(body, position)
	-- We need to extract the "local" coordinate (offset from planet center) here
	-- and then normalize it to do math with it
	local offset = position - vec3(body.center)
	local oNormalized = offset:normalize()
	return {
		systemId = body.systemId,
		bodyId = body.bodyId,
		latitude = 90 - (acos(oNormalized.z) * 180 / pi),
		longitude = atan(oNormalized.y, oNormalized.x) / pi * 180,
		altitude = offset:len() - body.radius
	}
end

function worldToMapStr(wPos)
	return mapPos2String(worldToMapPos(wPos))
end

function worldToMapPos(v)
	local body = findClosestBody(v)
	if not body or not body.center or not body.radius then
		return { systemId = 0, bodyId = 0, latitude = v.x, longitude = v.y, altitude = v.z }
	end
	return bodyPosFromWorldPos(body, v)
end

function mapPos2String(mPos)
	local sf = string.format
	if type(mPos) ~= "table" then return "" end
	return '::pos{' .. (mPos.systemId or 0).. ',' .. (mPos.bodyId or 0) .. ',' ..
			sf("%.4f", (mPos.latitude or 0)) .. ',' ..
			sf("%.4f", (mPos.longitude or 0)) ..  ',' ..
			sf("%.4f", (mPos.altitude or 0)) .. '}'
end

function initialiseAtlas()
	for _,systemData in pairs(atlas) do
		for bodyId,planet in pairs(systemData) do
			planet.bodyId = bodyId
			planet.name = planet['name'][1]
			planet.type = planet['type'][1]
			planet.atmoRadius = planet['atmosphereRadius']
			planet.center = vec3(planet['center'])
			planet.atmoAltitude = 0
			if planet.hasAtmosphere then
				planet.atmoAltitude = planet.atmoRadius - planet.radius
			end
		end
	end
	for system,syData in pairs(atlas) do
		for bodyId,p in pairs(syData) do
			if p.satellites ~= nil then
				for _,satId in pairs(p.satellites) do
					atlas[system][satId].parentBodyId = bodyId
				end
			end
		end
	end
end

function castIntersections()
	if cData.atmoDensity > 0.1 then return nil,nil,nil end
	local origin = cData.position
	local dir = cData.wVelDir
	local a = atlas[systemId]
	for _,p in pairs(a) do
		local size = 0
		if p.hasAtmosphere then
			size = p.atmoRadius*1.2
		else
			size = p.radius*1.4
		end
		local c_oV3 = p.center - origin
		local dot = c_oV3:dot(dir)
		local desc = dot ^ 2 - (c_oV3:len2() - size ^ 2)
		if desc >= 0 then
			local root = sqrt(desc)
			local farSide = dot + root
			local nearSide = dot - root
			if nearSide > 0 then
				return p, farSide, nearSide
			elseif farSide > 0 then
				return p, farSide, nil
			end
		end
	end
	return nil, nil, nil
end

function checkLOS(vector)
	local worldPos = cData.position
	local body = findClosestBody(worldPos)
	local size = 0
	if body == nil then return nil, nil end
	if body.hasAtmosphere then
		size = body.atmoRadius*1.05
	else
		size = body.radius*1.2
	end
	local intersectBody, farSide, nearSide = castIntersections(worldPos, vector, size) --no longer needed? refined castIntersectons function
	local atmoDistance = farSide
	if nearSide ~= nil and farSide ~= nil then
		atmoDistance = min(nearSide,farSide)
	end
	if atmoDistance ~= nil then
		return intersectBody, atmoDistance
	end
	return nil, nil
end

function getAltitude(coords)
	local dist = 0
	if coords == nil then
		dist = links.core.getAltitude()
		if dist == 0 then
            local b = cData.body
            if b == nil then return 0 end
			coords = cData.position
            dist = vector.dist(vec3(b.center), coords) - b.radius
		end
	else
		coord = vec3(coords)
		local body = findClosestBody(coords)
		if body == nil then return 0 end
		dist = vector.dist(vec3(body.center), coords) - body.radius
	end
	return round2(dist,2)
end

function getOrbitalParameters(cData)
	local body = findClosestBody(cData.position)
	if body == nil then return {} end
	local pos = cData.position
	local v = cData.wVel
	local r = pos - body.center
	local v2 = v:len2()
	local d = r:len()
	local mu = body.GM
	local e = ((v2 - mu / d) * r - r:dot(v) * v) / mu
	local a = mu / (2 * mu / d - v2)
	local ecc = e:len()
	local dir = e:normalize()
	local pd = a * (1 - ecc)
	local ad = a * (1 + ecc)
	local per = pd * dir + body.center
	local apo = ecc <= 1 and -ad * dir + body.center or nil
	local trm = sqrt(a * mu * (1 - ecc * ecc))
	local Period = apo and 2 * pi * sqrt(a ^ 3 / mu)
	-- These are great and all, but, I need more.
	local trueAnomaly = acos((e:dot(r)) / (ecc * d))
	if r:dot(v) < 0 then
		trueAnomaly = -(trueAnomaly - 2 * pi)
	end
	-- Apparently... cos(EccentricAnomaly) = (cos(trueAnomaly) + eccentricity)/(1 + eccentricity * cos(trueAnomaly))
	local EccentricAnomaly = acos((cos(trueAnomaly) + ecc) / (1 + ecc * cos(trueAnomaly)))
	-- Then.... apparently if this is below 0, we should add 2pi to it
	-- I think also if it's below 0, we're past the apoapsis?
	local timeTau = EccentricAnomaly
	if timeTau < 0 then
		timeTau = timeTau + 2 * pi
	end
	-- So... time since periapsis...
	-- Is apparently easy if you get mean anomly.  t = M/n where n is mean motion, = 2*pi/Period
	local MeanAnomaly = timeTau - ecc * sin(timeTau)
	local TimeSincePeriapsis = 0
	local TimeToPeriapsis = 0
	local TimeToApoapsis = 0
	if Period ~= nil then
		TimeSincePeriapsis = MeanAnomaly / (2 * pi / Period)
		-- Mean anom is 0 at periapsis, positive before it... and positive after it.
		-- I guess this is why I needed to use timeTau and not EccentricAnomaly here

		TimeToPeriapsis = Period - TimeSincePeriapsis
		TimeToApoapsis = TimeToPeriapsis + Period / 2
		if trueAnomaly - pi > 0 then -- TBH I think something's wrong in my formulas because I needed this.
			TimeToPeriapsis = TimeSincePeriapsis
			TimeToApoapsis = TimeToPeriapsis + Period / 2
		end
		if TimeToApoapsis > Period then
			TimeToApoapsis = TimeToApoapsis - Period
		end
	end
	return {
		periapsis = {
			position = per,
			speed = trm / pd,
			circularOrbitSpeed = uround(sqrt(mu / pd)),
			altitude = uround(pd - body.radius)
		},
		apoapsis = {
			position = apo,
			speed = trm / ad,
			circularOrbitSpeed = uround(sqrt(mu / ad)),
			altitude = uround(ad - body.radius)
		},
		currentVelocity = v,
		currentPosition = pos,
		eccentricity = ecc,
		period = Period,
		eccentricAnomaly = EccentricAnomaly,
		meanAnomaly = MeanAnomaly,
		timeToPeriapsis = uround(TimeToPeriapsis),
		timeToApoapsis = uround(TimeToApoapsis),
		trueAnomaly = trueAnomaly
	}
end

function getOrbitalSpeed(altitude, planet)
	-- P = -GMm/r and KE = mv^2/2 (no lorentz factor used)
	-- mv^2/2 = GMm/r
	-- v^2 = 2GM/r
	-- v = sqrt(2GM/r1)
	local distance = altitude + planet.radius

	if distance > 0 then
		local orbit = sqrt(planet.GM/distance)
		return orbit
	end
	return nil
end

function getOrbitFocus(cData)
	local apo = cData.orbitalParameters.apoapsis.altitude
	local peri = cData.orbitalParameters.periapsis.altitude
	local timeApo = cData.orbitalParameters.timeToApoapsis
	local timePer = cData.orbitalParameters.timeToPeriapsis
	local orbitSpeed = 0
	if timeApo <= timePer then
		orbitAltTarget = apo
		orbitSpeed = cData.orbitalParameters.apoapsis.circularOrbitSpeed
	else
		orbitAltTarget = peri
		orbitSpeed = cData.orbitalParameters.periapsis.circularOrbitSpeed
	end

	return {orbitAltTarget = orbitAltTarget, orbitSpeed = orbitSpeed}
end