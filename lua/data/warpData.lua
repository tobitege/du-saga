function getWarpData()
	if links.warpdrive == nil then
		return { status = 'Not Ready', warpDistance = 0,warpDestination = 'No Destination', warpCells = 0, warpCellsNeeded = 0 }
	end
	local status = links.warpdrive.getStatus()
	-- if status == 1 then
	--	 status = 'No Warpdrive'
	-- elseif status == 2 then
	--	 status = 'Broken'
	-- elseif status == 3 then
	--	 status = 'Warping'
	-- elseif status == 4 then
	--	 status = 'Parent Warping'
	-- elseif status == 5 then
	--	 status = 'Not Seated'
	-- elseif status == 6 then
	--	 status = 'Warp Cooldown'
	-- elseif status == 7 then
	--	 status = 'PvP Cooldown'
	-- elseif status == 8 then
	--	 status = 'Moving Docked Ship'
	-- elseif status == 9 then
	--	 status = 'No Container Linked'
	-- elseif status == 10 then
	--	 status = 'Planet Too Close'
	-- elseif status == 11 then
	--	 status = 'Destination Not Set'
	-- elseif status == 12 then
	--	 status = 'Destination Too Close'
	-- elseif status == 13 then
	--	 status = 'Destination Too Far'
	-- elseif status == 14 then
	--	 status = 'Not Enough Cells'
	-- elseif status == 15 then
	--	 status = 'Ready'
	-- end
	if status == 15 then
		status = 'Ready'
	elseif status == 11 then
		status = 'Destination Not Set'
	else
		status = 'Not Ready'
	end
	local warpDistance = links.warpdrive.getDistance()
	local warpDestination = links.warpdrive.getDestinationName()
	if status == 'Destination Not Set' then
		warpDestination = 'No Destination'
	end
	local warpCells = links.warpdrive.getAvailableWarpCells()
	local warpCellsNeeded = links.warpdrive.getRequiredWarpCells()
	return {
		status = status,
		warpDistance = warpDistance,
		warpDestination = warpDestination,
		warpCells = warpCells,
		warpCellsNeeded = warpCellsNeeded
	}
end