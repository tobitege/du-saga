Widgets.aggInfo = Widget:new{class = 'aggInfo'}
function Widgets.aggInfo:build()
	local agd, sgrn = aggData, 'springgreen'
	if agd == nil then return "" end
	local agStat = 'Offline'
	local agColor = 'orangered'
	local bCol = agColor
	if agd.aggState then
		agColor = sgrn
		agStat = 'Online'
	end
	if agd.aggBubble then bCol = sgrn end
	local strings = {}
	strings[#strings+1] = boldSpan('AGG INFO')
	strings[#strings+1] = 'Status: '..colorSpan(agColor,agStat)
	strings[#strings+1] = 'Target Alt: '..agd.aggTarget
	strings[#strings+1] = 'Current Alt: '..agd.aggAltitude
	--strings[#strings+1] = 'Pulsors: '..agd.aggPulsor
	--strings[#strings+1] = 'Strength: '..round2(agd.aggStrength,2)..' %'
	--strings[#strings+1] = 'Rate: '..round2(agd.aggRate*100,2)..' %'
	strings[#strings+1] = 'Power: '..round2(agd.aggPower*100,2)..' %'
	strings[#strings+1] = 'In Bubble: '..colorSpan(bCol, tostring(agd.aggBubble))
	self.rowCount = #strings
	return table.concat(strings, '<br>')
end