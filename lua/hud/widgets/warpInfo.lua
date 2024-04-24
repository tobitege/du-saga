Widgets.warpInfo = Widget:new{
	class = 'warpInfo',
	warpData = warpData
}
function Widgets.warpInfo:build()
	self.warpData = warpData
	local tColor = ternary(self.warpData.status ~= 'Ready', 'springgreen', 'orangered')
	local cColor = ternary(self.warpData.warpCells >= self.warpData.warpCellsNeeded, 'springgreen', 'orangered')

	local strings = {}
	strings[#strings+1] = boldSpan('WARP DRIVE INFO')
	strings[#strings+1] = 'Status : '..colorSpan(tColor,self.warpData.status)
	strings[#strings+1] = 'Distance : ' .. printDistance(self.warpData.warpDistance, true)
	strings[#strings+1] = 'Destination : ' .. self.warpData.warpDestination
	strings[#strings+1] = 'Cells Available : ' .. colorSpan(cColor,self.warpData.warpCells)
	strings[#strings+1] = 'Cells Needed : ' .. self.warpData.warpCellsNeeded
	strings[#strings+1] = colorSpan(cColor,'ENGAGE WARP: ALT-J')
	self.rowCount = #strings
	return table.concat(strings, '<br>')
end