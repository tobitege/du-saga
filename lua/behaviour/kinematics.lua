--@class Kinematics
function Kinematics()

local Kinematic = {} -- just a namespace

local ITERATIONS = 100 -- iterations over engine "warm-up" period

-- computeAccelerationTime - solve vf = vi + a*t for t
---@param initial number [in]: initial (positive) speed in meters per second.
---@param acceleration number [in]: constant acceleration until 'finalSpeed' is reached.
---@param final number [in]: the speed at the end of the time interval.
---@return number the time in seconds to reach the "final" velocity
function Kinematic.computeAccelerationTime(initial, acceleration, final)
	-- ans: t = (vf - vi)/a
	return (final - initial) / acceleration
end

-- computeBrakingDistance - Calculate the maximum speed that can be reached within the given distance and
-- the distance from the target at which braking must start to ensure the construct stops at the target location.
-- initialSpeed[in]: Vertical speed in meters per second at the time of the call.
-- distance[in]: Distance to the final location above, where the speed must be 0.
-- brakes[in]: Maximum brake force in Newtons that can be utilized in addition to gravity.
-- return: Maximum speed that can be reached (in m/s), and the remaining distance to the target
-- at which braking must start (in meters).
-- function Kinematic.computeBrakingDistanceV1(initialSpeed, distance, brakes, axis)
-- 	local mass, G = cData.mass, cData.G
-- 	local airFriction = -axis:dot(cData.worldAirFriction)

-- 	-- Determine the direction of flight using utils.sign()
-- 	-- local direction = utils.sign(axis.z)
-- 	local direction = utils.sign(distance)

-- 	-- Get the appropriate maximum thrust based on the direction of flight
-- 	local maxThrust = ternary(direction > 0, cData.MaxKinematics.Up, cData.MaxKinematics.Down)

-- 	-- Adjust the total deceleration based on the direction of flight
-- 	local totalDecel = (brakes or 0) + direction * mass * G + airFriction

-- 	-- Calculate the effective acceleration considering gravity
-- 	local accel
-- 	if direction > 0 then -- Ascent
-- 		accel = (maxThrust - direction * mass * G) / mass
-- 	else -- Descent
-- 		accel = (maxThrust + direction * mass * G) / mass
-- 	end

-- 	-- Calculate the maximum speed that can be reached with the available thrust.
-- 	local maxSpeed = math.sqrt(2 * accel * distance + initialSpeed ^ 2)

-- 	-- Ensure that the initial speed is not greater than the maximum speed.
-- 	initialSpeed = math.min(initialSpeed, maxSpeed)

-- 	-- Calculate the braking distance required to come to a stop from the maximum speed.
-- 	local brakingDistance = (maxSpeed ^ 2 - initialSpeed ^ 2) / (2 * totalDecel)

-- 	-- Calculate the remaining distance to the target at which braking must start.
-- 	local remainingDistance = distance - brakingDistance

-- 	-- If the remaining distance is negative, it means we cannot reach the maximum speed safely.
-- 	if remainingDistance < 0 then
-- 		maxSpeed = math.sqrt(initialSpeed ^ 2 + 2 * totalDecel * distance)
-- 		remainingDistance = 0
-- 	end
-- 	return maxSpeed, remainingDistance
-- end

function Kinematic.computeBrakingDistance(initialSpeed, distance, brakes, axis)
	local mass, G = cData.mass, cData.G
	local airFriction = -axis:dot(cData.worldAirFriction)

	-- Determine the direction of flight using utils.sign
	local direction = utils.sign(distance)

	-- Get the appropriate maximum thrust based on the direction of flight and axis
	local maxThrust
	if axis == cData.wFwd then
		maxThrust = ternary(direction > 0, cData.MaxKinematics.Forward, cData.MaxKinematics.Backward)
	else
		maxThrust = ternary(direction > 0, cData.MaxKinematics.Up, cData.MaxKinematics.Down)
	end

	-- Adjust the total deceleration based on the direction of flight and axis
	local gravityComponent
	if axis == cData.wFwd then
		gravityComponent = 0 -- Gravity does not affect longitudinal motion directly
	else
		gravityComponent = direction * mass * G
	end
	local totalDecel = (brakes or 0) + gravityComponent + airFriction

	-- Calculate the effective acceleration considering gravity and axis
	local accel
	if direction > 0 then -- Ascent or Forward
		accel = (maxThrust - gravityComponent) / mass
	else -- Descent or Backward
		accel = (maxThrust + gravityComponent) / mass
	end

	-- Calculate the maximum speed that can be reached with the available thrust
	local maxSpeed = math.sqrt(2 * accel * distance + initialSpeed ^ 2)

	-- Ensure that the initial speed is not greater than the maximum speed
	initialSpeed = math.min(initialSpeed, maxSpeed)

	-- Calculate the braking distance required to come to a stop from the maximum speed
	local brakingDistance = (maxSpeed ^ 2 - initialSpeed ^ 2) / (2 * totalDecel)

	-- Calculate the remaining distance to the target at which braking must start
	local remainingDistance = distance - brakingDistance

	-- If the remaining distance is negative, it means we cannot reach the maximum speed safely
	if remainingDistance < 0 then
		maxSpeed = math.sqrt(initialSpeed ^ 2 + 2 * totalDecel * distance)
		remainingDistance = 0
	end
	return maxSpeed, remainingDistance
end

-- computeDistanceAndTime - Return distance & time needed to reach final speed.
-- initial[in]: Initial speed in meters per second.
-- final[in]:	Final speed in meters per second.
-- mass[in]:	Mass of the construct in Kg.
-- thrust[in]:	Engine's maximum thrust in Newtons.
-- t50[in]:		(default: 0) Time interval to reach 50% thrust in seconds.
-- brakeThrust[in]: (default: 0) Constant thrust term when braking.
-- return: Distance (in meters), time (in seconds) required for change.
function Kinematic.computeDistanceAndTime(initial, final, mass, thrust, t50, brakeThrust)
	-- This function assumes that the applied thrust is colinear with the
	-- velocity. Furthermore, it does not take into account the influence
	-- of gravity, not just in terms of its impact on velocity, but also
	-- its impact on the orientation of thrust relative to velocity.
	-- These factors will introduce (usually) small errors which grow as
	-- the length of the trip increases.
	t50 = t50 or 0
	brakeThrust	= brakeThrust or 0 -- usually zero when accelerating

	local speedUp  = initial < final
	local a0	   = thrust / (speedUp and mass or -mass)
	local b0	   = -brakeThrust/mass
	local totA	 = a0+b0

	if initial == final then
		return 0, 0   -- trivial
	elseif speedUp and totA <= 0 or not speedUp and totA >= 0 then
		return -1, -1 -- no solution
	end

	local distanceToMax, timeToMax = 0, 0

	-- If, the T50 time is set, then assume engine is at zero thrust and will
	-- reach full thrust in 2*T50 seconds. Thrust curve is given by:
	-- Thrust: F(z)=(m*a0*(1+sin(z))+2*m*b0)/2 where z=pi*(t/t50 - 1)/2
	-- Acceleration is given by F(z)/m
	-- or v(z)' = (a0*(1+sin(z))+2*b0)/2

	if a0 ~= 0 and t50 > 0 then
		-- Closed form solution for velocity exists (t <= 2*t50):
		-- v(t) = a0*(t/2 - t50*sin(pi*(t/2)/t50)/pi)+b0*t)+c
		-- @ t=0, v(0) = vi => c=vi

		local c1  = math.pi/t50/2

		local v = function(t)
			return a0*(t/2 - t50*math.sin(c1*t)/math.pi) + b0*t + initial
		end

		local speedchk = speedUp and function(s) return s >= final end or
									 function(s) return s <= final end
		timeToMax = 2*t50

		if speedchk(v(timeToMax)) then
			local lastTime = 0
			while math.abs(timeToMax - lastTime) > 0.25 do
				local t = (timeToMax + lastTime)/2
				if speedchk(v(t)) then
					timeToMax = t
				else
					lastTime = t
				end
			end
		end

		-- Closed form solution for distance exists (t <= 2*t50):
		local K = 2*a0*t50^2/math.pi^2
		distanceToMax = K*(math.cos(c1*timeToMax) - 1) +
						(a0+2*b0)*timeToMax^2/4 + initial*timeToMax

		if timeToMax < 2*t50 then
			return distanceToMax, timeToMax
		end
		initial = v(timeToMax)
	end
	-- At full thrust, motion follows Newton's formula:
	local a = a0+b0
	local t = Kinematic.computeAccelerationTime(initial, a, final)
	local d = initial*t + a*t*t/2
	return distanceToMax+d, timeToMax+t
end

-- computeTravelTime - solve d=vi*t+a*t**2/2 for t
-- initialSpeed [in]: initial (positive) speed in meters per second
-- acceleration [in]: constant acceleration until 'distance' is traversed
-- distance [in]: the distance traveled in meters
-- return: the time in seconds spent in traversing the distance
function Kinematic.computeTravelTime(initial, acceleration, distance)
	-- quadratic equation: t=(sqrt(2ad+v^2)-v)/a
	if distance == 0 then return 0 end

	if acceleration ~= 0 then
		return (math.sqrt(2*acceleration*distance+initial^2) - initial)/acceleration
	end
	assert(initial > 0, 'Acceleration and initial speed are both zero.')
	return distance/initial
end

return Kinematic

end