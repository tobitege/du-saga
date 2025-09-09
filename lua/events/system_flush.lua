function onSystemFlush()
	if links.core == nil or construct == nil then return end
	cData = getConstructData(construct, links.core)
	--globals.dbgTxt = '' -- only for development!

	-- Handle delayed mode switch
	local gC = globals
	if gC.pendingModeSwitch then
		gC.frameCounter = (gC.frameCounter or 0) + 1
		if gC.frameCounter >= 3 then
			-- Switch to Standard mode now that initialization is safe
			gC.maneuverMode = false
			gC.pendingModeSwitch = false
			-- Force proper landing mode for Standard
			if cData.isLanded then
				AutoPilot:toggleLandingMode(true)
			end
		end
	end

	-- Handle G-key landing/takeoff mode restoration
	if gC.pendingModeRestore then
		local shouldRestore = false

		-- Handle takeoff restoration (timer-based)
		if gC.modeRestoreTimer and gC.modeRestoreTimer > 0 then
			gC.modeRestoreTimer = gC.modeRestoreTimer - 1
			if gC.modeRestoreTimer <= 0 then
				shouldRestore = true
			end
		end

		-- Handle landing restoration (condition-based - wait for actual landing completion)
		if gC.waitingForLanding then
			-- Check if ship has actually landed and landing operation is complete
			if cData.isLanded and not ship.landingMode then
				-- Add small delay to ensure ship is fully settled
				if not gC.landingSettleTimer then
					gC.landingSettleTimer = 30 -- Wait 30 frames (~1.5 seconds) after engines off
				else
					gC.landingSettleTimer = gC.landingSettleTimer - 1
					if gC.landingSettleTimer <= 0 then
						shouldRestore = true
						gC.waitingForLanding = false
						gC.landingSettleTimer = nil
					end
				end
			end
		end

		-- Restore mode when conditions are met
		if shouldRestore then
			gC.maneuverMode = gC.originalMode or false
			gC.pendingModeRestore = false
			gC.modeRestoreTimer = nil
			gC.waitingForLanding = false
			-- Properly set up Standard mode state after operation
			if not gC.maneuverMode then
				if cData.isLanded then
					-- Ship landed - preserve the landed state carefully
					-- First ensure all systems are off/reset
					setThrottle() -- Clear all throttles
					navCom:resetCommand(axisCommandId.longitudinal)
					navCom:resetCommand(axisCommandId.vertical)
					navCom:setTargetGroundAltitude(-1) -- Disable altitude stabilization
					navCom:deactivateGroundEngineAltitudeStabilization()
					Nav:update()
					-- Now set up proper landing mode
					AutoPilot.landingMode = true -- Set directly to avoid triggering hover logic
					inputs.brake = 1
					inputs.brakeLock = true
				else
					-- Ship is airborne after takeoff - set up hover mode
					setThrottle() -- Reset throttle control
					navCom:setTargetGroundAltitude(AutoPilot.userConfig.hoverHeight)
					navCom:activateGroundEngineAltitudeStabilization()
					Nav:update()
					AutoPilot:toggleLandingMode(false) -- Ensure hover mode
				end
			end
		end
	end

    if globals.maneuverMode then
        ship.apply(cData)
    else
	    applyShipInputs()
    end
    shipLandingTask(cData)
end