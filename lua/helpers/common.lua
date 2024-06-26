function deserialize(s) local f=load('t='..s) if f then f() end return t end

function isWithinTolerance(value, target, tolerance)
	return math.abs(value - target) <= tolerance
end

function RoundAlt(altitude, distance)
	local newAltitude = altitude + distance
	if distance > 0 then
		newAltitude = math.ceil(newAltitude / 10) * 10  -- Round up for positive distance
	else
		newAltitude = math.floor(newAltitude / 10) * 10 -- Round down for negative distance
	end
	return newAltitude
end

-- This function calculates the maximum speed by considering the LOCAL velocity
-- component in the direction of cD.worldDown and the influence of gravity
-- over the given distance.
-- The square root term is derived from the kinematic equation for motion
-- under constant acceleration (in this case, gravity):
-- v_final = sqrt(v_initial^2 + 2 * a * d)
-- function calcDownSpeed(distance)
-- 	if type(distance) ~= "number" or distance < 0 then return 0 end
-- 	local grav = cData.gravity:dot(cData.worldDown)
-- 	if grav < 0 then
-- 		-- Gravity is acting in the opposite direction of travel
-- 		return 0
-- 	end
-- 	-- Gravity is acting in the same direction as travel
-- 	return sqrt(2 * distance * grav)
-- end

-- Charts for the different types of dampening functions
-- offered by the `getDampener` function:

-- **Logarithmic (ftype = 'L')**

-- | **Input (x)** | **Logarithmic Output** |
-- | --- | --- |
-- | 100 | 0.00 |
-- | 90 | 0.06 |
-- | 80 | 0.13 |
-- | 70 | 0.21 |
-- | 60 | 0.30 |
-- | 50 | 0.40 |
-- | 40 | 0.51 |
-- | 30 | 0.63 |
-- | 20 | 0.75 |
-- | 10 | 0.87 |
-- | 0 | 1.00 |

-- **Parabolic (ftype = 'P')**

-- | **Input (x)** | **Parabolic Output** |
-- | --- | --- |
-- | 100 | 0.00 |
-- | 90 | 0.19 |
-- | 80 | 0.36 |
-- | 70 | 0.51 |
-- | 60 | 0.64 |
-- | 50 | 0.75 |
-- | 40 | 0.84 |
-- | 30 | 0.91 |
-- | 20 | 0.96 |
-- | 10 | 0.99 |
-- | 0 | 1.00 |

-- **Quadratic (ftype = 'Q')**

-- | **Input (x)** | **Quadratic Output** |
-- | --- | --- |
-- | 100 | 0.00 |
-- | 90 | 0.16 |
-- | 80 | 0.36 |
-- | 70 | 0.51 |
-- | 60 | 0.64 |
-- | 50 | 0.75 |
-- | 40 | 0.84 |
-- | 30 | 0.91 |
-- | 20 | 0.96 |
-- | 10 | 0.99 |
-- | 0 | 1.00 |

-- **Exponential (ftype = 'E')**

-- | **Input (x)** | **Exponential Output** |
-- | --- | --- |
-- | 100 | 0.00 |
-- | 90 | 0.11 |
-- | 80 | 0.23 |
-- | 70 | 0.36 |
-- | 60 | 0.50 |
-- | 50 | 0.64 |
-- | 40 | 0.77 |
-- | 30 | 0.89 |
-- | 20 | 0.95 |
-- | 10 | 0.98 |
-- | 0 | 1.00 |

-- **Sigmoid (ftype = 'S')**

-- | **Input (x)** | **Sigmoid Output** |
-- | --- | --- |
-- | 100 | 0.01 |
-- | 90 | 0.14 |
-- | 80 | 0.31 |
-- | 70 | 0.50 |
-- | 60 | 0.69 |
-- | 50 | 0.84 |
-- | 40 | 0.93 |
-- | 30 | 0.97 |
-- | 20 | 0.99 |
-- | 10 | 0.99 |
-- | 0 | 1.00 |

-- Note that the Sigmoid function is not exactly the same as the traditional Sigmoid function,
-- as it is modified to work with the input range from 100 down to 0.

function getDampener(ftype, x, range)
	-- Ensure the range is greater than 0 to avoid division by zero
	if tonumber(range) == nil or range < 0.01 then return 0.001 end
	if tonumber(x) == nil or x > range then x = range end
	if x < 0 then x = 0.01 end

	-- Normalize x to the range [-1, 1]
	local res, nX = 1, x / range
	-- Clamp the normalized x to the range [0, 1]
	x = math.max(0, math.min(1, nX))
	if ftype == 'L' then -- Logarithmic
		res = 1 - math.log(x + 1) / math.log(range + 1)
	elseif ftype == 'P' then -- Parabolic
		res = 1 - (x * x)
	elseif ftype == 'P2' then -- Parabolic v2 (right parabolic half)
		res = 1 - (x / range)^2
	elseif ftype == 'Q' then -- Quadratic
		res = 1 - (x / range)^2
	elseif ftype == 'E' then -- Exponential
		res = 1 - 2^(-x / range)
	elseif ftype == 'S' then -- Sigmoid
		res = 1 / (1 + math.exp(-x) * (range - x) / range)
	end
	return res
end

function calculateLandingScaleOrg(gDist, ftype, range)
	local x = math.abs(tonumber(gDist) or 100)
	local scale = getDampener(ftype, x, range or 100)
	return clamp(scale, 0.1, 0.99)
end

-- function calculateLandingScale(distance)
--     local startDistance = 600 -- Distance at which the dampener starts to decline
--     local endDistance = 20 -- Distance at which the dampener reaches its minimum value
--     local minDampener = 0.02 -- Minimum value of the dampener

--     if abs(distance) >= startDistance then
--         return 1
--     end
-- 	if abs(distance) <= endDistance then
--         return minDampener
--     end
-- 	local ratio = (abs(distance) - endDistance) / (startDistance - endDistance)
-- 	local res = minDampener + (1 - minDampener) * ratio
-- 	return res
-- end

local function AxisLimiterEx(cD, axis, atmoLimit, distance)
	if not cD then inputs.brakeLock = true; return false end
	axis = axis or "worldDown"
	atmoLimit = tonumber(atmoLimit) or 1000
	distance = tonumber(distance) or 1
	if not vec3.isvector(cD[axis]) then P'Invalid axis' return false end

	local min, abs = math.min, math.abs
	local wAxis, ap, dampener, gC = cD[axis], AutoPilot, 1, globals
	local isVertical = axis == "worldDown" or axis == "worldUp"
	local isLongitudinal = axis == "cFwd" or axis == "cBack"
	if not (isVertical or isLongitudinal) then return false end

	-- Speed and acceleration along the desired axis
	local accel = cD.acceleration:dot(wAxis)
	local currSpeed = isVertical and cD.velocity.z or cD.velocity.y

	local axMax = 1080
	if cD.inAtmo then
		-- if axis == "worldDown" or cD.altitude > atmoLimit then
		if vertical and cD.altitude > atmoLimit then
			axMax = ap.userConfig.landSpeedHigh
		elseif axis == "worldUp" then
			axMax = ap.userConfig.landSpeedLow
		end
	elseif isVertical and cD.altitude > 90000 then
		axMax = ap.userConfig.landSpeedLow*0.5
	end
	-- Convert to m/s
	axMax = axMax / 3.6

	-- Calculate desired max velocity for selected axis
	local targetSpeed, maxSpeed, absDist = 0, 0, abs(distance)

	maxSpeed, brkDist = kinematics.computeBrakingDistance(
			isVertical and cD.vertSpeed or cD.forwardSpeed,
			distance, cD.maxBrake or 0, wAxis)
	maxSpeed = maxSpeed or axMax -- sanity check to avoid "nan"

	-- Calculate dampening factor based on distance and axis
	if absDist <= 50 then
		dampener = calculateLandingScaleOrg(absDist, "S", 50) * (axis == 'worldUp' and 0.90 or 1) * (axis == 'cFwd' and 0.1 or 1)
	elseif absDist <= 200 then
		dampener = calculateLandingScaleOrg(absDist, "S", 200) * (axis == 'cFwd' and 0.33 or 1)
	elseif absDist <= 500 then
		dampener = calculateLandingScaleOrg(absDist, "S", 500) * (axis == 'cFwd' and 0.66 or 1)
	end

	-- minimum speed?
	if cD.isLanded and ship.takeoff then
		targetSpeed = 20 / 3.6
	else
		-- fine-tune maxSpeed a bit as it can be pretty high
		targetSpeed = axMax
		if isVertical then
			targetSpeed = min(maxSpeed/3, axMax)
		end
	end
	-- apply dampener and fix sign for descend
	targetSpeed = targetSpeed * dampener
	-- for space descend, extra speed reduction
	if not cD.inAtmo and ship.landingMode then
		targetSpeed = targetSpeed * 0.75
	end
	if brkDist >= distance then
		targetSpeed = targetSpeed * 0.33
	end

	-- targetSpeed now has same sign as "distance", i.e. negative when landing
	local diffAccel, diffV = 0, 0
	if targetSpeed < 0 and currSpeed ~= targetSpeed then
		diffV = currSpeed - targetSpeed
	else
		diffV = targetSpeed - currSpeed
	end
	-- for simplicity, for vertical axis we just set -1 or 1 as Z axis
	if axis == "worldUp" or axis == "worldDown" then
		if axis == "worldUp" then
			-- counter gravity when moving down
			diffV = diffV + accel * system.getActionUpdateDeltaTime()
		end
		wAxis = vec3(0,0, axis == "worldUp" and 1 or -1)
	end
	diffAccel = diffV / cD.mass
    local thrustVector = diffAccel * wAxis * cD.mass

-- if gC.debug then
-- addDbgVal('<br>distance', round2(ship.targetDist, 3))
-- addDbgVal('axMax', round2(axMax, 3))
-- addDbgVal('maxSpeed', round2(maxSpeed, 3))
-- addDbgVal('dampener', round2(dampener, 3))
-- addDbgVal('targetSpeed', round2(targetSpeed, 3))
-- addDbgVal('currSpeed', round2(currSpeed, 3))
-- addDbgVal('diffV', round2(diffV, 3))
-- addDbgVal('thrustVector', round2(isVertical and thrustVector.z or 0, 3))
-- end
	return thrustVector
end

function AxisLimiter(cD, axis, atmoLimit, distance)
	local success, result = pcall(AxisLimiterEx, cD, axis, atmoLimit, distance)
	if not success or not result then
		P("[E] Error in AxisLimiter!")
		return false
	end
	return result
end

-- function isNumInRange(value, min, max)
-- 	return value >= min and value <= max
-- end

function Vec3ToPosString(v3)
	if type(v3) ~= "table" then return "" end
	local sf = string.format
	return '::pos{0,0,' ..
		sf("%.4f",(v3.x or 0))..','..
		sf("%.4f",(v3.y or 0))..','..
		sf("%.4f",(v3.z or 0))..'}'
end

function ternary(cond, T, F)
	if cond then return T else return F end
end

function localToWorld(pos, up, right, forward)
	local relX = pos.x * right.x + pos.y * forward.x + pos.z * up.x
	local relY = pos.x * right.y + pos.y * forward.y + pos.z * up.y
	local relZ = pos.x * right.z + pos.y * forward.z + pos.z * up.z
	return vec3(relX, relY, relZ)
end

-- The getTravelDistance function calculates the shortest distance you need to
-- travel to reach a target location, taking into account the curvature of a
-- planet's surface if you're moving on or near it. It determines whether to
-- calculate the distance as a straight line in space or along the surface of
-- a planet, depending on whether you provide information about the planet's size.
-- function getTravelDistanceV1(cPos, target, body)
-- 	local msq = math.sqrt
-- 	-- If body and/or radius are nil, calculate the direct distance
-- 	if not body or not body.radius then
-- 		return msq((cPos.x - target.x)^2 + (cPos.y - target.y)^2 + (cPos.z - target.z)^2)
-- 	end

-- 	-- Calculate the distance between the projections of the positions on the planet's surface
-- 	local surfDist = msq((cPos.x - target.x)^2 + (cPos.y - target.y)^2)
-- 	local r = body.radius

-- 	-- Check if cPos.z and target.z are both zero to avoid division by zero
-- 	if cPos.z == 0 and target.z == 0 then
-- 		return surfDist
-- 	end

-- 	-- Calculate the angle between the positions and the planet's center
-- 	local cosAngle = (r^2 + cPos.z^2 + target.z^2 - surfDist^2) / (2 * r * msq(cPos.z^2 + target.z^2))

-- 	-- Check if cosAngle is within the valid range for math.acos
-- 	if cosAngle < -1 or cosAngle > 1 then
-- 		return msq((cPos.x - target.x)^2 + (cPos.y - target.y)^2 + (cPos.z - target.z)^2)
-- 	end

-- 	-- Calculate the distance to be traveled
-- 	return r * math.acos(cosAngle) + surfDist
-- end

function getTravelDistance(cPos, target, body)
	local msqrt, masin = math.sqrt, math.asin

	-- Direct distance calculation if body or radius is not provided
	if not body or not body.radius then
		local dx = cPos.x - target.x
		local dy = cPos.y - target.y
		return msqrt(dx*dx + dy*dy) -- Only horizontal distance
	end

	local r = body.radius + cPos.z -- Assuming cPos.z is the altitude above the body's surface
	local dx = cPos.x - target.x
	local dy = cPos.y - target.y
	local horDist = msqrt(dx*dx + dy*dy)
	-- If the horizontal distance is negligible, return 0
	if horDist < 0.01 then
		return 0
	end

	-- Calculate the arc length on the surface of the planet at the given altitude
	-- Using the formula s = r * theta, where theta is the central angle in radians
	local theta = 2 * masin(horDist / (2 * r))

	-- The arc length is the distance travelled at a fixed altitude
	return r * theta
end

function isDirectlyAbove(vec1, vec2, margin)
	if tonumber(margin) == nil then
		margin = 0.1
	end
	-- Calculate the horizontal distance squared (to avoid square root for efficiency)
	local dx = vec1.x - vec2.x
	local dy = vec1.y - vec2.y
	local dist = dx*dx + dy*dy

	-- Check if the horizontal distance is within the margin squared and vec1 is above vec2
	return dist <= margin*margin and vec1.z > vec2.z
end

function addDbgVal(t, val, clear)
	local gC = globals
	if not gC.debug then return end
	if clear then gC.dbgTxt = '' end
	local out = '<br>'..(t or '')..': '..ternary(tonumber(val) == nil, tostring(val), tonumber(val))
	gC.dbgTxt = gC.dbgTxt..out
	return val
end

function boldSpan(text)
	return '<span style="font-weight:bold">'..text..'</span>'
end

function colorSpan(color, text)
	return '<span style="color:'..color..'">'..text..'</span>'
end

function colIfTrue(bVal, color)
	local out = tostring(bVal)
	return ternary(bVal, colorSpan(color or 'springgreen',out), out)
end
function getDiv(className, txt, color, fontSize)
	color = color or "ivory"
	fontSize = fontSize or 1.7
	return "<div class=\""..className.."\" style=\"font-size:"..tostring(fontSize).."vh;color:"..color..";text-align:center;text-shadow:0.2vh 0.2vh 1vh black\">"..(txt or '').."</div>"
end
function getAPDiv(txt, color)
	return getDiv('apAlert',txt,color,1.5)
end
function getBrakeDiv(txt)
	return getDiv('brakeAlert',txt,'orangered')
end
function getTDiv(className, trw, trh, inner)
	return "<div class=\""..className.."\" style=\"transform:translate("..trw.."vw,"..trh.."vh)\">"..(inner or '').."</div>"
end
function getTDivP(className, pnt, inner)
	return getTDiv(className, pnt[1]*100, pnt[2]*100, inner)
end

-- local _sp = system.print
-- function print(a, depth, k, l)
-- 	if depth ~= nil and l ~= nil and l > depth then return end
-- 	if k == 'unit' or k == 'export' or k == '__index' then return end
-- 	if l == nil then l = 0 end
-- 	ls = string.rep(' - ', l)
-- 	l = l + 1
-- 	if type(a) == "table" then
-- 		if k == nil then
-- 			_sp(ls..'[table]')
-- 		else
-- 			_sp(ls..'['..k..'] [table]')
-- 		end
-- 		for key,val in pairs(a) do
-- 			print(val, depth, key, l)
-- 		end
-- 	else
-- 		local v = ''
-- 		if type(a) == "function" then
-- 			v = "[function]"
-- 		elseif type(a) == "thread" then
-- 			v = "[thread]"
-- 		elseif type(a) == "boolean" then
-- 			v = ternary(a, "TRUE", "FALSE")
-- 		elseif type(a) == "nil" then
-- 			v = "[nil]"
-- 		else
-- 			v = a
-- 		end
-- 		if k == nil then
-- 			_sp(ls..v)
-- 		else
-- 			_sp(ls..'['..k..'] '..tostring(v))
-- 		end
-- 	end
-- end

function printDistance(meters, larger)
	if tonumber(meters) == nil then return 'NaN' end
	local absM = math.abs(meters)
	if absM < ternary(larger, 10000, 1000) then
		return round2(meters,1)..' m'
	elseif absM < 200000 then
		local km = meters / 1000
		return round2(km, ternary(km > 10,1,2))..' km'
	end
	local su = meters / 200000
	return round2(su, ternary(su > 10,1,2))..' su'
end

-- Add thousand separators
function thousands(a)
	local formatted = tostring(a)
	if a == nil then return a end
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
		if (k==0) then
			break
		end
	end
	return formatted
end

function split(str, pat)
	if str == nil then return str end
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t, cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

-- function capitalise(str)
-- 	return (str:gsub("^%l", string.upper))
-- end

function formatTimeString(seconds)
	if type(seconds) ~= 'number' then return seconds end
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds / 60 / 60 % 24)
	local minutes = math.floor(seconds / 60 % 60)
	local seconds = math.floor(seconds % 60)
	if seconds < 0 or hours < 0 or minutes < 0 then
		return "0s"
	end
	if days > 0 then
		return days .. "d " .. hours .."h"
	elseif hours > 0 then
		return hours .. "h " .. minutes .. "m"
	elseif minutes > 0 then
		return minutes .. "m " .. seconds .. "s"
	else
		return seconds .. "s"
	end
end