-- Databank key map
-- Config.dynamicIndicator, _ (underscore) is atm a reserved character
-- for dynamic values and should not be used otherwise

configDatabankMap = {
	apState = 'ap',
	autoAGGAdjust = 'ag',
	currentTarget = 'cd', -- current destination
	hoverHeight = 'hh',
	hudScale = 'hs',
	landingMode = 'lm',
	mainMenuVisible = 'mv',
	maneuverMode = 'mm',
	maxPitch = 'mp',
	maxRoll = 'mr',
	maxSpaceSpeed = 'ms',
	menuKeyLegend = 'mk',
	radarBoxes = 'rb',
	radarWidget = 'rw',
	routeDatabankName = 'rd',
	shieldManage = 'sm',
	slowFlat = 'sf',
	soundEnabled = 'se',
	spaceCapableOverride = 'sc',
	throttleBurnProtection = 'bp',
	unitWidgetVisible = 'uv',
	usbDatabankName = 'ud',
	wingStallAngle = 'ws',
	agl = 'al',
	coreWidget = 'cw',
	dockMode = 'dm',
	dockWidget = 'dw',
	-- Maneuver mode: maxLandingSpeedHigh: max landing speed > 1 km altitude
	landSpeedHigh = 'mls',
	-- Maneuver mode: maxLandingSpeedLow: max landing speed below 1 km altitude down to ground detection
	landSpeedLow = 'mll',
	-- Maneuver mode: default travel altitude for AP targets
	travelAlt = 'tra',
	-- Base target location
	base = 'bas'
}