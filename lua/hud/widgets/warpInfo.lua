Widgets.warpInfo = Widget:new{
	class = 'warpInfo',
	warpData = warpData
}
function Widgets.warpInfo:build()
	self.warpData = warpData
	local cs = colorSpan
	local isReady, cells = self.warpData.status == 'Ready', self.warpData.warpCells >= self.warpData.warpCellsNeeded
	local cColor = ternary(cells, 'springgreen', 'orangered')
	local tColor = ternary(isReady and cells, 'springgreen', 'orangered')

	local s = {}
	s[#s+1] = boldSpan('WARP DRIVE INFO')
	s[#s+1] = 'Status : '..cs(tColor,self.warpData.status)
	s[#s+1] = 'Destination : ' .. self.warpData.warpDestination
	s[#s+1] = 'Distance : ' .. printDistance(self.warpData.warpDistance, true)
	s[#s+1] = 'Cells: ' .. cs(cColor,self.warpData.warpCellsNeeded) .. ' ('..self.warpData.warpCells..')'
	s[#s+1] = cs(tColor,'ENGAGE WARP: ALT-J')
	self.rowCount = #s
	return table.concat(s, '<br>')
end