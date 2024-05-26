-- Initialize globals and constants
--print = system.print
P = system.print

-- (average ships do not need this) is your ship space capable with a gyro?
-- Space capability is auto detected from rear facing engines. if you use a
-- gyro to get to space, the auto detection may not work, so set this to true
-- if the ship says your not space capable when using AP, when you really are.
spaceCapableOverride = false --export: (Space Capable Ship Override) true/false
hoverHeight = 40 --export: Hover Height: 0-50 default hover height (G key)
-- takes over the throttle/braking when you are going to exceed your ships
-- burn speed in atmo. (only when already in atmo, it does not prevent you
-- from coming in to atmo too fast if manually transitioning from space to atmo)
throttleBurnProtection = true --export: (Auto Throttle Burn Protection) true/false
maxPitch = 35 --export: (Max Pitch) set between 5-80, 35 is default.
maxRoll = 45 --export: (Max Roll) set between 5-80, 45 is default.
-- what angle do a majority of your wings stall? 25-60. Ailerons 30, Wings 55,
-- Stabilizers 70. Set slightly below the stall angle of your main lift source.
-- or split the difference if a mix. if you notice your ship "skids" in atmo,
-- your wings are stalling, reduce this number.
wingStallAngle = 35 --export: (Wing Stall Angle) 25-60.
-- let the ship handle shield control on off/resistance management/venting.
shieldManage = true --export: (Auto Shield Management) true/false
-- (max speed you want to go in space, not ships capable max speed) 0 for ships
-- max capable speed, or if your selected speed exceeds ships capability, ships
-- max speed will be used.
maxSpaceSpeed = 0 --export: Max Space Speed in km/h
-- if radar attached, start with radar widget open (toggle widget with /radar command)
radarOn = false --export: (Radar Widget) true/false
-- (higher value may be unstable) Valid values: Superior or equal to 0.01
pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis
-- (higher value may be unstable) Valid values: Superior or equal to 0.01
yawSpeedFactor =  1 --export: This factor will increase/decrease the player input along the yaw axis
-- (higher value may be unstable) Valid values: Superior or equal to 0.01
rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis
-- by brakeSpeedFactor * velocity Valid values: Superior or equal to 0.01
brakeSpeedFactor = 3 --export: When braking, this factor will increase the brake force
-- this factor will increase the brake force by a flat brakeFlatFactor * velocity direction
-- (higher value may be unstable) Valid values: Superior or equal to 0.01
brakeFlatFactor = 1 --export: Flat braking factor (0.01+)
--When the pilot stops rolling,  flight model will try to get back to horizontal (no roll)
autoRoll = true --export: [Only in atmosphere]
-- When autoRoll is engaged, this factor will increase to strength of the roll back to 0
-- Valid values: Superior or equal to 0.01
autoRollFactor = 2 --export: [Only in atmosphere]

-- When the pilot is rolling, the flight model will try to add yaw and pitch to
-- make the construct turn better The flight model will start by adding more
-- yaw the more horizontal the construct is and more pitch the more vertical it is
turnAssist = true --export: [Only in atmosphere]
-- This factor will increase/decrease the turnAssist effect (higher value may
-- be unstable) Valid values: Superior or equal to 0.01
turnAssistFactor = 2 --export: [Only in atmosphere]

-- (higher value may be unstable) Valid values: Superior or equal to 0.01
torqueFactor = 2 --export: Force factor applied to reach rotationSpeed

-- Skill level of person who deployed tanks, or highest talents applied to construct
-- with reapply Talents.
atmoTankHandling = 5 --export: (Atmospheric Fuel Tank Handling) 0-5
-- Skill level of person who deployed tanks, or highest talents applied to construct
-- with reapply Talents.
spaceTankHandling = 5 --export: (Space Fuel Tank Handling) 0-5
-- Skill level of person who deployed tanks, or highest talents applied to construct
-- with reapply Talents.
rocketTankHandling = 0 --export: (Rocket Fuel Tank Handling) 0-5
-- Skill level of person who deployed tanks, or highest talents applied to construct
-- with reapply Talents.
fuelTankOptimization = 5 --export: Talents Fuel Tank Optimization: 0-5
-- Skill level of person who deployed tanks, or highest talents applied to construct
-- with reapply Talents.
containerOptimization = 5 --export: Talents Container Optimization: 0-5

-- IF using engine tags (see instructions), default engine control mode when activating control unit.
boostModeOverride = 'off' --export: (Engine Throttle Mode Override) 'off' , 'all' , 'hybrid', 'primary'

-- (no real limit but beyond these values has less/no effect or may cause problems)
-- if your ship often swings past where it's trying to aim and wobbles back and forth,
-- reduce this. if you want it to snap at a point faster/stronger(smaller nimble ships)
-- increase it.
aimStrength = 0.3 --export: Aim Strength (0.05 to ~3)
coreWidget = false --export: Show Core info panel. Only needed for PvP (FPS impact!)
agl = 0 --export: Above ground landed (in m): Ground distance when landed
dockingMode = 1 --export: Docking mode (1 = manual, 2 = Automatic, 3 = Owner)
dockWidget = true --export: Show docking widget (toggle with /dock command)
--velocityVector = true --export: Display velocity indicator

maxLandingSpeedHigh = 200 --export Maneuver mode: Max landing speed above 1 km altitude. Default: 200
maxLandingSpeedLow = 100 --export Maneuver mode: Max landing speed below 1 km altitude. Default: 100
travelAlt = 900 --export Maneuver mode: default travel altitude for AP targets. Default: 900
DEBUG = false -- only for development!

globals = {
	advAtmoEngines = false,
	advSpaceEngines = false,
	aggAP = false,
	aimTarget = 'none',
	altitudeHold = false,
	apMode = 'standby',
	arMode = 'none',
	boostMode = 'all',
	brakeState = false,
	brakeTrigger = false,
	cameraAim = false,
	collision = nil,
	collisionAlert = false,
	collisionBrake = false,
	dbgTxt = '', -- debug output
	debug = DEBUG, -- debug widget toggle (if included)
	farSide = nil,
	followMode = false,
	followReposition = false,
	holdAltitude = 2500,
	horizontalStopped = false,
	inAtmo = false,
	inOrbit = false,
	initTurn = nil,
	lastProjectedDistance = 10000000,
	lenTest = 0,
	manualOrbitAlt = 0,
	maxDefaultKP = {0,0,0,0},
	maxPrimaryKP = {0,0,0,0},
	maxSecondaryKP = {0,0,0,0},
	maxTertiaryKP = {0,0,0,0},
	missedTarget = false,
	nearSide = nil,
	orbitLock = false,
	orbitPitch = 0,
	orbitalHold = false,
	radarA = false,
	radarAl = false,
	radarD = false,
	radarF = false,
	radarSp = false,
	radarSt = false,
	radialIn = false,
	radialMode = 'none',
	radialOut = false,
	rotationDampening = true,
	safetyThrottle = false,
	smoothClimb = false,
	spaceBrakeTrigger = false,
	spaceCapable = spaceCapable,
	stallProtect = false,
	tankData = tankData,
	target = vec3(),
	targetOrbitAlt = 100000,
	targetPitch = 0,
	targetThrottleOne = 0,
	targetThrottleThree = 0,
	targetThrottleTwo = 0,
	verticalState = false,
	waitForBubble = false,
	waterAlt = -10000000,
	waterMode = false,
	waterState = false,
	updatecore = true,
	startup = true
}

links = {}
cData = {}
Axis = {}
scrnData = {}
deltaTime = system.getUtcTime()
lastTime = deltaTime

-- load DU scripts
require('cpml/vec3')
require('cpml/pid')
require('AxisCommand')
require('Navigator')
---@class Navigator
Nav = Navigator.new(system, links.core, unit)
---@class AxisCommandManager
navCom = Nav.axisCommandManager

-- this will load most source parts
-- require('data/remap')
require('data/links')
require('libmain')
kinematics = Kinematics()

printHello()

system:onEvent('onActionStart', function (self, action) onActionStart(action) end)
system:onEvent('onActionStop', function (self, action) onActionEnd(action) end)
system:onEvent('onActionLoop', function (self, action) onActionLoop(action) end)
system:onEvent('onInputText', function (self, text) onInput(text) end)

system:onEvent('onFlush', function (self) onSystemFlush() end)
system:onEvent('onUpdate', function (self) onSystemUpdate() end)
unit:onEvent('onStop', function ()
	if links.electronics ~= nil then links.electronics:SwitchesOff() end
end)
unit:onEvent('onTimer', function (unit, id)
	if id == "SYSUPDATE" then
		dynamicSVG()
		if not globals.maneuverMode then onTimerAPU() end
	elseif id == "FUELUPDATE" then
		onTimerFuelUpdate()
	elseif id == "BRAKEUPD" then
		local tmpB = construct.getMaxBrake()
		if tmpB and tmpB > 1 then
			globals.maxBrake = tmpB
		end
	elseif id == "COREUPDATE" then
		globals.updatecore = true
		Radar:update()
	end
end)
onUnitStart()
unit.setTimer("FUELUPDATE", 3)
unit.setTimer("COREUPDATE", 0.5)
unit.setTimer("BRAKEUPD", 0.1)
unit.setTimer("SYSUPDATE", 0.0166)