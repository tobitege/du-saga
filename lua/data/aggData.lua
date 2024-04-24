function getAggData()
	local agg = links.antigrav
	if agg == nil then
		return { aggState = false, aggStrength = 0, aggRate = 0, aggPower = 0,
			aggPulsor = 6, aggTarget = 1000, aggAltitude = 1000, aggBubble = false }
	end
	local inBubble = false
	local curAltitude = cData.altitude
	local aggAlt = agg.getBaseAltitude()
	inBubble = agg.isActive() and curAltitude > aggAlt - 100 and curAltitude < (aggAlt + 100)
	return {
		aggState = agg.isActive(),
		aggStrength = agg.getFieldStrength(),
		aggRate = agg.getCompensationRate(),
		aggPower = agg.getFieldPower(),
		aggPulsor = agg.getPulsorCount(),
		aggTarget = round2(agg.getTargetAltitude(),2),
		aggAltitude = round2(aggAlt,2),
		aggBubble = inBubble
	}
end