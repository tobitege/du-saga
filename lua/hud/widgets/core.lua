Widgets.core = Widget:new{
	class = 'coreInfo',
	core = links.core,
	shield = links.shield,
	lastUpd = ''
}
function Widgets.core:build()
	if not HUD.Config.coreWidget then return '' end

	local gCache = globals
	if not gCache.updatecore then return self.lastUpd end
	gCache.updatecore = false

	local coreHealth = math.abs((self.core.getCoreStressRatio()*100)-100)
	local coreStress = self.core.getCoreStress()
	local coreMaxStress = self.core.getMaxCoreStress()
	local cD = cData
	if cD.pvpZone then
		self.class = 'coreInfo alert'
	end
	local green = 'springgreen'
	local ored = 'orangered'
	local cColor = green
	if coreHealth <= 20 then
		cColor = ored
	elseif coreHealth <= 50 then
		cColor = 'goldenrod'
	end

	local strings = {}
	strings[#strings+1] = 'Core: '..colorSpan(cColor, coreHealth..'%')
	strings[#strings+1] = 'Core Stress: '..colorSpan(cColor, coreMaxStress - coreStress)..' / '..coreMaxStress
	local ssh = self.shield
	if ssh ~= nil then
		local shp = ssh.getShieldHitpoints()
		local mshp = ssh.getMaxShieldHitpoints()
		local sHealth = ((shp / mshp) * 100)
		local shieldActiveColor = ored
		local shieldColor = green
		if sHealth <= 20 then
			shieldColor = ored
		elseif sHealth <= 50 then
			shieldColor = 'goldenrod'
		end
		if ssh.isActive() == 1 then
			shieldActiveColor = green
		end

		local shieldStateStr = colorSpan(shieldActiveColor,'Shield')
		local shieldHealthStr = colorSpan(shieldColor,sHealth..'%')
		local shieldHpStr = colorSpan(shieldColor,shp)..' / '..mshp
		strings[#strings+1] = shieldStateStr..': '..shieldHealthStr
		strings[#strings+1] = 'Shield Health: '..shieldHpStr
	end
	if cD.pvpZone then
		strings[#strings+1] = 'PvP Timer: '..cD.pvpTimer
	end
	self.rowCount = #strings
	self.lastUpd = table.concat(strings,' | ')
	return self.lastUpd
end