Widgets.controls = Widget:new{class = 'controlsBox'}
function Widgets.controls:build()
	local s, tos, gC, ap = {}, tostring, globals, AutoPilot
	s[#s+1] = 'Alt-1| Toggle AP - '..colIfTrue(ap.enabled)
	s[#s+1] = 'Alt-2| Altitude Hold - '..colIfTrue(gC.altitudeHold)
	s[#s+1] = 'Alt-3| Orbital Hold - '..colIfTrue(gC.orbitalHold)
	s[#s+1] = 'Alt-4| Radial Hold - '..tos(gC.radialMode)
	s[#s+1] = 'Alt-5| Engine Mode - '..tos(gC.boostMode)
	s[#s+1] = 'Alt-6| Prev Route'
	s[#s+1] = 'Alt-7| Next Route'
	-- AR mode removed to save code space
	--s[#s+1] = 'Alt-7| AR Mode - '..tos(gC.arMode)
	local damp = ternary(gC.maneuverMode, 'Forward', 'Rotation')
	s[#s+1] = 'Alt-8| '..damp..' Damp. - '..colIfTrue(gC.rotationDampening)
	s[#s+1] = 'Alt-9| Flight Mode - '..(gC.maneuverMode and 'Maneuver' or 'Standard')

	s[#s+1] = '<br>Alt-Shift-1| Toggle Main Menu'
	if not gC.maneuverMode then
		s[#s+1] = 'Alt-Shift-2| Follow Mode - '..colIfTrue(gC.followMode)
	end
	s[#s+1] = 'Alt-Shift-8| Slow Flat - '..colIfTrue(ap.userConfig.slowFlat)
	s[#s+1] = '<br>G| Parking - '..colIfTrue(ap.landingMode)
	s[#s+1] = 'Alt + Ctrl | Brake Lock - '..colIfTrue(inputs.manualBrake)
	self.rowCount = #s
	return table.concat(s, '<br>')
end