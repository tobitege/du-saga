
Widgets.fuelInfo = Widget:new{class = 'fuelInfo'}
function Widgets.fuelInfo:build()
    local strings = {}
    strings[#strings+1] = 'Fuel Tanks'

    for key, tanks in pairs(fuels) do
		if #tanks > 0 then
            strings[#strings+1] = ''
            strings[#strings+1] = key
        end
        for i, tank in ipairs(tanks) do
            local pColor = 'ivory'
			if tank.percent <= 20 then
				pColor = 'orangered'
			elseif tank.percent <= 50 then
				pColor = 'goldenrod'
			end
			strings[#strings+1] = tank.name..' - <span style="color: '..pColor..'">'..tank.percent..'%</span>'
        end
    end
    self.rowCount = #strings
    return table.concat(strings, '<br>')
end