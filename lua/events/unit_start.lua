function init()
	cData = {}
	aggData = {}
	warpData = {}
	playerData = {}

	--SZ Center (13771471,7435803,-128971) --dropping here for use later.

	vector = vec3()
	targetAngularVelocity = vec3()
	local s, latlas = pcall(require, "autoconf/custom/" .. customAtlas)
	if not s then
		latlas = require("atlas")
	end
	atlas = latlas
	initialiseAtlas()
	systemId = 0
end

function onUnitStart()
	system.showHelper(false)

	scanLinks()
	if links.core == nil then
		P"[E] Core not found, did you link it to this control unit?"
		unit.exit()
		return false
	end
	init()
	-- remapAfterInit()
	finaliseLinks()
	validateParms()

	cData = getConstructData(construct, links.core)
	playerData = getPlayerData()
	aggData = getAggData()
	warpData = getWarpData()

	Config:init(links.databanks, 'SagaConf', 'SagaActiveConf')
	RouteDatabase:init(links.databanks, 'SagaRoutes', 'SagaActiveRoutes')
	Radar:init(links.radars)

	local cD, gC = cData, globals
	-- Store the actual desired mode
	gC.desiredMode = Config:getValue(configDatabankMap.maneuverMode, false)
	-- ALWAYS start in Maneuver mode for safe initialization
	gC.maneuverMode = true

	AutoPilot:init()

	initializeTanks()
	initEngines()
	resetAP()

	dynamicSVG()
	HUD:init()
	links.electronics:SwitchesOn()

	-- Main class for Maneuver mode highly customized by @tobitege
	-- Based on Horizon v1.19x flight script by the ShadowTemplar org.
	ship = STEC()

	if unit.isRemoteControlled() then
		player.freeze(true)
	end

	Nav.targetSpeedRanges = {1000, 5000, 10000, 20000, 30000}
	navCom.axisCommands[axisCommandId.longitudinal].throttleMouseStepScale = 1
	navCom:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, Nav.targetSpeedRanges)

	if not cD.vtolCapable then
		P"[W] Low lift for Maneuver mode."
	end
	if gC.maneuverMode then
		setThrottle(1,1,1)
		ship.apply(cD)
	else
		setThrottle()
		Nav.axisCommandManager:setTargetGroundAltitude(0)
		Nav:update()
	end
	if cD.isLanded then
		inputs.brake = 1
		inputs.brakeLock = true
	end
	gC.startup = false

	-- Set up delayed mode switch if we need to go to Standard mode
	if not gC.desiredMode then
		-- Schedule switch to Standard mode after 3 frames
		gC.frameCounter = 0
		gC.pendingModeSwitch = true
	end

	-- Ensure forward axis is neutralized after initialization
	navCom:setTargetSpeedCommand(axisCommandId.longitudinal, 0)
	navCom:resetCommand(axisCommandId.longitudinal)
	navCom:setThrottleCommand(axisCommandId.longitudinal, 0)
end

function printHello()
	P'HUD/Autopilot by Sagacious, Mayumi and CodeInfused'
	P('v4.1.8')
	P'Customized by tobitege (2025-09-12)'
end

function initEngines()
	local gC, ap = globals, AutoPilot
	local primaryTags = 'primary'
	local secondaryTags = 'secondary'
	local tertiaryTags = 'tertiary'
	local defaultTags = 'thrust analog longitudinal'
	local getMaxT = construct.getMaxThrustAlongAxis
	local fwd = {vec3(construct.getForward()):unpack()}
	gC.maxPrimaryKP = getMaxT(primaryTags, fwd)
	gC.maxSecondaryKP = getMaxT(secondaryTags, fwd)
	gC.maxTertiaryKP = getMaxT(tertiaryTags, fwd)
	gC.maxDefaultKP = getMaxT(defaultTags, fwd)

	if not ap.userConfig.spaceCapableOverride then
		gC.spaceCapable = gC.maxDefaultKP[3] > 0
		if not gC.spaceCapable then
			P'[E] Longitudinal Space Thrust not detected - space transfers/orbit disabled'
		end
	else
		gC.spaceCapable = ap.userConfig.spaceCapableOverride
	end

	if boostModeOverride == 'off' then
		if (gC.maxPrimaryKP[1] > 0 and gC.maxSecondaryKP[1] > 0) then
			gC.advAtmoEngines = true
			gC.boostMode = 'hybrid'
			P'Atmo Engine tags detected, advanced Atmo engine control enabled'
		else
			gC.advAtmoEngines = false
			P'Atmo Engine tags not detected, advanced Atmo engine control disabled'
		end
		gC.advSpaceEngines = gC.maxPrimaryKP[3] > 0 and gC.maxSecondaryKP[3] > 0
		if gC.advSpaceEngines then
			gC.boostMode = 'hybrid'
			P'Space Engine tags detected, advanced Space engine control enabled'
		else
			P'Space Engine tags not detected, advanced Space engine control disabled'
		end
	else
		gC.boostMode = boostModeOverride
	end
	local cD = cData
	if not (cD.hasvBoosters or cD.hasHovers) then
		P'[I] No ground engines detected!'
	end
	---@TODO is this of interest on startup? hmmm...
	-- if cD.inAtmo then
	-- 	if tonumber(cD.MaxKinematics.UpGroundAtmo) ~= nil then
	-- 		P('VTOL Atmo Up (kN): '..round2(cD.MaxKinematics.UpGroundAtmo/1000,2))
	-- 	end
	-- 	if tonumber(cD.MaxKinematics.DownAtmo) ~= nil then
	-- 		P('VTOL Atmo Down (kN): '..round2(cD.MaxKinematics.DownAtmo/1000,2))
	-- 	end
	-- else
	-- 	if tonumber(cD.MaxKinematics.UpGroundSpace) ~= nil then
	-- 		P('VTOL Space Up (kN): '..round2(cD.MaxKinematics.UpGroundSpace/1000,2))
	-- 	end
	-- 	if tonumber(cD.MaxKinematics.DownSpace) ~= nil then
	-- 		P('VTOL Space Down (kN): '..round2(cD.MaxKinematics.DownSpace/1000,2))
	-- 	end
	-- end
end
