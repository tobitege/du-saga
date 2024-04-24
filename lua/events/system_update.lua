-- Event handler for receiving data from the screen
--function onReceiveScreenData(receivedData)
    -- data = deserialize(receivedData)
    -- -- Process received data and update local variables as needed
    -- -- Example: Update elevator stats
    -- if data.stats then
    --     elevatorStats = data.stats
    -- end
--end

deltaTime = system.getUtcTime() - lastTime
lastTime = deltaTime

function onSystemUpdate()
	if links.core == nil or construct == nil then return end
	cData = getConstructData(construct, links.core)
	playerData = getPlayerData()
	aggData = getAggData()
	warpData = getWarpData()
	scrnData = {}

	---@TODO elevator screen handling
	-- -- Check for data from the screen
	-- if links.screen then
	-- 	local data = {}
	-- 	local receivedData = links.screen.getScriptOutput()
	-- 	local tp = type(receivedData)
	-- 	if tp == 'string' then
	-- 		globals.dbgTxt = 'data: '..receivedData
	-- 		if receivedData ~= 'ack' then end
	-- 	end
	-- end

	-- Axis	Description				Dir
	-- Axis0	Roll				+
	-- Axis1	Pitch				+
	-- Axis2	Yaw					+
	-- Axis3	Throttle			-
	-- Axis4	Brake				-
	-- Axis5	Strafe Left/Right	?1
	-- Axis6	Vertical Up/Down	?1
	-- Axis7	Custom2	?1
	-- Axis8	Custom2	?1
	-- Axis9	Custom2	?1
	if AutoPilot.enabled or globals.followMode or globals.orbitalHold then
		Axis = {
			rollAxis = 0,
			pitchAxis = 0,
			yawAxis = 0,
			updownAxis = 0,
			leftrightAxis = 0,
			forwardbackAxis = 0,
			brakeAxis = 0,
			throttle1Axis = 0,
			throttle2Axis = 0,
			throttle3Axis = 0 }
	else
		Axis = {
			rollAxis = -system.getAxisValue(0),
			pitchAxis = -system.getAxisValue(1),
			yawAxis = system.getAxisValue(2),
			throttle1Axis = system.getAxisValue(3),
			brakeAxis = -system.getAxisValue(4),
			leftrightAxis = system.getAxisValue(5),
			updownAxis = system.getAxisValue(6),
			forwardbackAxis = system.getAxisValue(7),
			throttle2Axis = system.getAxisValue(8),
			throttle3Axis = system.getAxisValue(9) }
	end
	Nav:update()
	HUD:update()
	Electronics:update()
end