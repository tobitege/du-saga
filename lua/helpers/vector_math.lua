local uround, r2d = utils.round, constants.rad2deg
spcVector = 'none'

function signedRotationAngle(normal, vecA, vecB)
	vecA = vecA:project_on_plane(normal)
	vecB = vecB:project_on_plane(normal)
	return atan(vecA:cross(vecB):dot(normal), vecA:dot(vecB))
end

function vectorRotated(vector, direction)
	return vec3(vector):cross(vec3(direction))
end

function projectedDistance(point, position)
	if not point then return 0 end
	if position == nil then
		position = cData.position
	end
	position = position:project_on_plane(cData.wVert)
	return uround(vec3(position - (point:project_on_plane(cData.wVert))):len(),0.01)
end

function vectorToPoint(point, position)
	local pos = position or cData.position
	return vec3(pos - point):normalize()
end

function vectorToPoint2(point, position)
	local pos = position or cData.position
	return vec3(point - pos):normalize()
end

-- Vector to target level with the planet surface at any altitude.
--@TODO ==inAtmo + sameBody ONLY=============
function circleNormal(point)
	local body = findClosestBody(cData.position)
	if not body then return vec3() end
	local vecToA = cData.position - body.center
	local vecToB = point - body.center
	local circleNormal = vecToB:cross(vecToA):normalize()
	return (circleNormal:cross(vecToA)):normalize()
end

function variousVectors(vector)
	local gL, cD = globals, cData
	local autoPilot = AutoPilot
	local angleToPoint = -cD.wVelDir:angle_between(vector) * r2d
	local v90 = (vector - (-cD.wVelDir))
	local vecHalf = (v90 + vector):normalize()
	local vecMain = v90 + vector + v90
	if gL.apMode == 'Transfer' or gL.apMode == 'standby' then
		if cD.speedKph >= autoPilot.maxSpaceSpeed then
			spcVector = 'ninety'
			vecMain = (vector:normalize() - (-cD.wVelDir:normalize()))
		elseif cD.speedKph > (autoPilot.maxSpaceSpeed/3) and cD.speedKph < autoPilot.maxSpaceSpeed then
			spcVector = 'main'
			vecMain = v90 + (vector + (v90 * (20 * (1 - clamp(getSpaceVelocityTargetAngle()/45,0,1)))))
		else
			spcVector = 'main2'
			vecMain = v90 + vector + v90 + v90
		end
	else
		spcVector = 'none'
		vecMain = v90 + vector + v90
	end
	return {angleToPoint = angleToPoint, ninety = v90,vecHalf = vecHalf, vecMain = vecMain}
end

function getVelocityAngle()
	if cData.constructSpeed < 1 then return 0 end
	return uround(((cData.wFwd):angle_between(cData.wVelDir))*r2d,0.0001)
end

function getVelocityWorldAngle()
	if cData.constructSpeed < 1 then return 0 end
	return uround(((cData.wVelDir:project_on_plane(cData.wVert)):angle_between(cData.wVelDir))*r2d,0.0001)
end

function targetAngularVelocityAngle()
	if globals.apMode == 'Transfer' and cData.constructSpeed > 1 then
		--return uround(-variousVectors(target).vecMain:angle_between(cData.wFwd)*r2d,0.0001)
		return uround(vectorToPoint(variousVectors(AutoPilot.target).vecMain):angle_between(vectorToPoint(cData.wFwd))*r2d,0.0001)
	end
	return 0
end

function getTargetWorldAngle()
	local cD, ap = AutoPilot, cData
	if sameBody and ap.targetBody ~= nil then
		return uround(vectorToPoint(ap.targetBody.center,ap.target):angle_between(vectorToPoint(ap.targetBody.center,cD.position))*r2d,0.0001)
	end
	if not cD.body then return 0 end
	return uround(vectorToPoint(ap.target,cD.body.center):angle_between(vectorToPoint(cD.position,cD.body.center))*r2d,0.0001)
end

function getTargetAngle(target, inRad)
	local t = target or AutoPilot.target
	if t == nil then return 0 end
	local rad = signedRotationAngle(cData.worldUp, -cData.wFwd, vectorToPoint(t):project_on_plane(cData.wVert))
	return uround(ternary(inRad, rad, -deg(rad)),0.0001)
end

function getVelocityTargetAngle(target)
	local t = target or AutoPilot.target
	return uround(-deg(signedRotationAngle(cData.worldUp, -cData.wVelDir:project_on_plane(cData.wVert), circleNormal(t):project_on_plane(cData.wVert))),0.0001)
end

function getSpaceVelocityTargetAngle(target)
	if cData.constructSpeed < 1 then return 0 end
	local t = target or AutoPilot.target
	return uround(cData.wVelDir:angle_between(-vectorToPoint(t))*r2d,0.0001)
end

function getReticle(vector)
	return {cData.position.x + vector.x, cData.position.y + vector.y, cData.position.z + vector.z}
end

function getXYZ(vector)
	return {vector.x, vector.y, vector.z}
end

-- function getSafeZoneBorder()
-- 	local pos = cData.position
--	 local body = findClosestBody(pos).center
-- 	local mainSafe = vec3(13771471,7435803,-128971)
-- 	local safeTarget, safeSize, planetDist = mainSafe, 18000000, 400000
-- 	local mainDist = vector.dist(mainSafe,pos) - safeSize
-- 	local secDist = vector.dist(body,pos) - planetDist
-- 	local insideSafe = false
-- 	local borderDist, borderVec = 0, vec3()
-- 	if mainDist < secDist then
-- 		safeTarget = mainSafe --bodySize = safeSize
-- 		borderDist = abs(mainDist)
-- 	else
-- 		safeTarget = body --bodySize = planetDist
-- 		borderDist = abs(secDist)
-- 	end
-- 	if mainDist < 0 or secDist < 0 then
-- 		insideSafe = true
-- 	end
-- 	if insideSafe then
-- 		borderVec = (vectorToPoint(safeTarget,pos):normalize())*borderDist
-- 	else
-- 		borderVec = -(vectorToPoint(safeTarget,pos):normalize())*borderDist
-- 	end
-- 	return {arBorder = library.getPointOnScreen(getReticle(borderVec)), borderDist = borderDist}
-- end