function onSystemFlush()
	if links.core == nil or construct == nil then return end
	cData = getConstructData(construct, links.core)
	globals.dbgTxt = ''
    if globals.maneuverMode then
        ship.apply(cData)
    else
	    applyShipInputs()
    end
    shipLandingTask(cData)
end