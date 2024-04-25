Widgets.controls = Widget:new{class = 'controlsBox'}
function Widgets.controls:build()
	local ct, s, tos, gC, ap = colIfTrue, {}, tostring, globals, AutoPilot
	s[#s+1] = 'Alt-1| Toggle AP - '..ct(ap.enabled)
	s[#s+1] = 'Alt-2| Altitude Hold - '..ct(gC.altitudeHold)
	s[#s+1] = 'Alt-3| Orbital Hold - '..ct(gC.orbitalHold)
	s[#s+1] = 'Alt-4| Radial Hold - '..tos(gC.radialMode)
	s[#s+1] = 'Alt-5| Engine Mode - '..tos(gC.boostMode)
	s[#s+1] = 'Alt-6| Prev Route'
	s[#s+1] = 'Alt-7| Next Route'
	-- AR mode removed to save code space
	--s[#s+1] = 'Alt-7| AR Mode - '..tos(gC.arMode)
	local damp = ternary(gC.maneuverMode, 'Forward', 'Rotation')
	s[#s+1] = 'Alt-8| '..damp..' Damp. - '..ct(gC.rotationDampening)
	s[#s+1] = 'Alt-9| Flight Mode - '..(gC.maneuverMode and 'Maneuver' or 'Standard')

	s[#s+1] = '<br>Alt-Shift-1| Toggle Main Menu'
	if gC.maneuverMode then
		s[#s+1] = 'Alt-Shift-6| Activate Base'
		s[#s+1] = 'Alt-Shift-7| Set Base'
	else
		s[#s+1] = 'Alt-Shift-2| Follow Mode - '..ct(gC.followMode)
	end
	s[#s+1] = 'Alt-Shift-8| Slow Flat - '..ct(ap.userConfig.slowFlat)
	s[#s+1] = '<br>G| Parking - '..ct(ap.landingMode)
	s[#s+1] = 'Alt + CTRL | Brake Lock - '..ct(inputs.manualBrake)
	self.rowCount = #s
	return table.concat(s, '<br>')
end