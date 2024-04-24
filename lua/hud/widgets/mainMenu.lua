Widgets.mainMenu = Widget:new{
	class = 'mainMenu',
	anchor = anchorENUM.topRight,
	padding = 4,
	rowHeight = 16,
	rowMargin = 4,
	headerHeight = 20
}

-- This is used to trigger the minifier, to reduce code footprint
categoryENUM = {
	RouteList = 'RouteList',
	RouteListAll = 'RouteListAll',
	RouteListByPlanet = 'RouteListByPlanet',
	EditRoute = 'EditRoute',
	Autopilot = 'Autopilot',
	Settings = 'Settings',
	AutopilotConfig = 'AutopilotConfig',
	Databanks = 'Databanks',
	DatabanksConfig = 'DatabanksConfig',
	DatabanksRoute = 'DatabanksRoute',
	DatabanksUSB = 'DatabanksUSB',
	Scale = 'Scale',
	HUD = 'HUD'
	--,Sounds = 'Sounds',
}

function Widgets.mainMenu:init()
	local categoryENUM = categoryENUM
	self.optionMenu = MenuSystem

	self.tooltips = {
		maxSpaceSpeed = {'Maximum space travel speed', 'Set to 0 for automatic detection', maxSpaceSpeed .. ' Default'},
		maxPitch = {'How steep to pitch in atmo in degrees', maxPitch .. ' Default'},
		maxRoll = {'How steep to roll in atmo in degrees', maxRoll .. ' Default'},
		wingStallAngle = {'Degrees from your trajectory your ship', 'stalls at, based on majority of airfoil', 'type used for lift (Ailerons 35,', 'Wings 50, Stabilizers 70)', wingStallAngle .. ' Default'},
		hoverHeight = {'Hover height in meters', hoverHeight .. ' Default'},
		throttleBurnProtection = {'Will take over throttle/brakes to prevent', 'burning in atmosphere. Use brakes or', 'change throttle to take manual control again.'},
		shieldManage = {'Automatic shield state and resistance control'},
		radarBoxes = {'Show radar contacts in the HUD'},
		radarWidget = {'Show the default radar widget'},
		slowFlat = {'Levels the ship when','below 100km / hr and in atmo'},
		spaceCapableOverride = {'Rarely used, only if engines are angled', 'in a way where space capability isnt', 'detected automatically correctly.'},
		travelAlt = {'Maneuver Mode only!','Default altitude at which to travel via Autopilot targets.','Default: 1500m'}
	}

	Config.defaults[configDatabankMap.menuKeyLegend] = self.optionMenu.config.legendVisible
	EventSystem:register('ConfigDBChanged', self.applyConfig, self)
	self:applyConfig()

	--self.optionMenu.config.activeCategory = categoryENUM.Scale
	self.optionMenu.config.optionWidth = self.width - self.padding * 2
	self.optionMenu.config.optionHeight = self.rowHeight
	self.optionMenu.config.optionMargin = self.rowMargin
	self.optionMenu.config.headerHeight = self.headerHeight

	self.optionMenu:addCategory('Routes', categoryENUM.RouteList)
	self.optionMenu:addCategory('All Routes', categoryENUM.RouteListAll, categoryENUM.RouteList)
	--self.optionMenu:addCategory('By Planet', categoryENUM.RouteListByPlanet, categoryENUM.RouteList)

	self.optionMenu:addCategory('Autopilot Controls', categoryENUM.Autopilot)

	self.optionMenu:addCategory('Settings', categoryENUM.Settings)
	self.optionMenu:addCategory('Autopilot Configuration', categoryENUM.AutopilotConfig, categoryENUM.Settings)
	self.optionMenu:addCategory('Databanks', categoryENUM.Databanks, categoryENUM.Settings)
	self.optionMenu:addCategory('Visuals', categoryENUM.HUD, categoryENUM.Settings)
	self.optionMenu:addCategory('Scale', categoryENUM.Scale, categoryENUM.HUD, { getValue = {
		func = function() return (Config:getValue(configDatabankMap.hudScale) * 100) .. '%' end },
		input = { func = setConfigInput, arg = configDatabankMap.hudScale,
		filter = function(input) return clamp(tonumber(input), 30, 250) / 100 end } } )

	self.optionMenu:addCategory('Config DB', categoryENUM.DatabanksConfig, categoryENUM.Databanks, { getValue = { func = getActiveDbName, arg = 'config' } })
	self.optionMenu:addCategory('Route DB', categoryENUM.DatabanksRoute, categoryENUM.Databanks, { getValue = { func = getActiveDbName, arg = 'routes' } })
	self.optionMenu:addCategory('USB DB', categoryENUM.DatabanksUSB, categoryENUM.Databanks, { getValue = { func = getActiveDbName, arg = 'usb' } })

	self.optionMenu:addOption('Toggle On/Off', categoryENUM.Autopilot, { main = { func = AutoPilot.toggleState }, getValue = { func = function() return AutoPilot.enabled end } })
	self.optionMenu:addOption('New Route', categoryENUM.RouteList, { main = { func = newRoute } })

	self.optionMenu:addCategory('Route', categoryENUM.EditRoute, categoryENUM.EditRoute, { back = { func = unEditRoute, arg = i } }, true)
	self.optionMenu:addOption('Name', categoryENUM.EditRoute, { input = { func = editRouteName }, getValue = { func = getEditRouteName } }, true)
	self.optionMenu:addOption('Add Current Position', categoryENUM.EditRoute, { main = { func = addCurrentPos } }, true)
	self.optionMenu:addOption('Add ::pos{} Location', categoryENUM.EditRoute, { input = { func = addCustomPos } }, true)

	for i = 0, 22 do
		local multiplier = i + 3
		local scaleStr = (multiplier * 10) .. '%'
		self.optionMenu:addOption(scaleStr, categoryENUM.Scale, {
			getActive = { func = function(option, multi) return Config:getValue(configDatabankMap.hudScale) == multi end, arg = multiplier / 10 },
			main = { func = setConfig, arg = { key = configDatabankMap.hudScale, value = multiplier / 10 } }
		})
	end
	EventSystem:register('ConfigChange' .. configDatabankMap.hudScale, HUD.updateScale)
	EventSystem:register('RoutesUpdated', self.updateRoutes, self)

	self.optionMenu:addOption('Core Widget', categoryENUM.HUD, { main = { func = function() HUD.toggleCoreWidget() end }, getValue = { func = function() return HUD.Config.coreWidget end } })
	self.optionMenu:addOption('Docking Widget', categoryENUM.HUD, { main = { func = function() HUD.toggleDockWidget() end }, getValue = { func = function() return HUD.Config.dockWidget end } })
	self.optionMenu:addOption('Unit Widget', categoryENUM.HUD, { main = { func = function() HUD.toggleUnitWidget() end }, getValue = { func = function() return HUD.Config.unitWidgetVisible end } })
	if #links.radars > 0 then
		self.optionMenu:addOption('Radar Boxes', categoryENUM.HUD, { main = { func = function() Radar.toggleBoxes(nil) end }, getValue = { func = function() return Radar.boxesVisible == true end }, tooltip = self.tooltips.radarBoxes })
		self.optionMenu:addOption('Radar Widget', categoryENUM.HUD, { main = { func = function() Radar.toggleWidget(nil) end }, getValue = { func = function() return Radar.widgetId ~= nil end }, tooltip = self.tooltips.radarWidget })
	end
	self.optionMenu:addOption('Menu Action Legend', categoryENUM.HUD, { main = { func = function() self.optionMenu:toggleLegend() end }, getValue = { func = function() return self.optionMenu.config.legendVisible end } })

	self.optionMenu:addOption('Max Space Speed', categoryENUM.AutopilotConfig, { input = { func = function(text) Config:setValue(configDatabankMap.maxSpaceSpeed, tonumber(text)) AutoPilot:applyConfig() end }, getValue = { func = function() return AutoPilot.userConfig.maxSpaceSpeed end }, tooltip = self.tooltips.maxSpaceSpeed })
	self.optionMenu:addOption('Max Pitch', categoryENUM.AutopilotConfig, { input = { func = function(text) Config:setValue(configDatabankMap.maxPitch, tonumber(text)) AutoPilot:applyConfig() end }, getValue = { func = function() return AutoPilot.userConfig.maxPitch end }, tooltip = self.tooltips.maxPitch })
	self.optionMenu:addOption('Max Roll', categoryENUM.AutopilotConfig, { input = { func = function(text) Config:setValue(configDatabankMap.maxRoll, tonumber(text)) AutoPilot:applyConfig() end }, getValue = { func = function() return AutoPilot.userConfig.maxRoll end }, tooltip = self.tooltips.maxRoll })
	self.optionMenu:addOption('Wing Stall Angle', categoryENUM.AutopilotConfig, { input = { func = function(text) Config:setValue(configDatabankMap.wingStallAngle, tonumber(text)) AutoPilot:applyConfig() end }, getValue = { func = function() return AutoPilot.userConfig.wingStallAngle end }, tooltip = self.tooltips.wingStallAngle })
	self.optionMenu:addOption('Hover Height', categoryENUM.AutopilotConfig, { input = { func = function(text) Config:setValue(configDatabankMap.hoverHeight, tonumber(text)) AutoPilot:applyConfig() end }, getValue = { func = function() return AutoPilot.userConfig.hoverHeight end }, tooltip = self.tooltips.hoverHeight })
	self.optionMenu:addOption('Shield Management', categoryENUM.AutopilotConfig, { main = { func = AutoPilot.toggleShieldManage }, getValue = { func = function() return AutoPilot.userConfig.shieldManage end }, tooltip = self.tooltips.shieldManage })
	self.optionMenu:addOption('Burn Protection', categoryENUM.AutopilotConfig, { main = { func = AutoPilot.toggleThrottleBurnProtection }, getValue = { func = function() return AutoPilot.userConfig.throttleBurnProtection end }, tooltip = self.tooltips.throttleBurnProtection })
	self.optionMenu:addOption('Slow Flat', categoryENUM.AutopilotConfig, { main = { func = AutoPilot.toggleSlowFlat }, getValue = { func = function() return AutoPilot.userConfig.slowFlat end }, tooltip = self.tooltips.slowFlat })
	self.optionMenu:addOption('Space Capable Override', categoryENUM.AutopilotConfig, { main = { func = AutoPilot.toggleSpaceCapableOverride }, getValue = { func = function() return AutoPilot.userConfig.spaceCapableOverride end },tooltip = self.tooltips.spaceCapableOverride })
	self.optionMenu:addOption('Travel Altitude', categoryENUM.AutopilotConfig, { input = { func = function(text) Config:setValue(configDatabankMap.travelAlt, tonumber(text)) AutoPilot:applyConfig() end }, getValue = { func = function() return AutoPilot.userConfig.travelAlt end }, tooltip = self.tooltips.travelAlt })

	-- Overriding menuSystem onClose
	self.optionMenu.onClose = function()
		HUD.Config.mainMenuVisible = false
	end

	self:updateDatabanks()
	self:updateRoutes()
end

function Widgets.mainMenu:applyConfig()
	self.optionMenu.config.legendVisible = Config:getValue(configDatabankMap.menuKeyLegend)
end

function Widgets.mainMenu:update()
	self.optionMenu:updateInputs()
end

function Widgets.mainMenu:build()
	local rendered = ''

	local screenWidth = HUD.screenWidth
	local screenHeight = HUD.screenHeight
	local padding = self.padding * HUD.Config.scaleMultiplier
	-- Head
	rendered = rendered .. '<style>' .. HUD.staticCSS.menuCss .. '></style>'

	-- Choose one to determine scaling type
	rendered = rendered .. '<svg style="position:absolute;top:' .. padding .. ';left:' .. padding .. ';" height="100vh" viewBox="0 0 '..screenWidth..' '..screenHeight..'" preserveAspectRatio="xMidYMid" overflow="visible" xmlns="http://www.w3.org/2000/svg">\n'

	rendered = rendered .. '<defs>' .. HUD.staticCSS.gradientDefs .. '</defs>'..
		'<g class="mainMenu">' .. self.optionMenu:render() .. '</g></svg>'

	-- Update the widget row count to match the menu row count
	self.rowCount = self.optionMenu.rowCount
	return rendered
end

function Widgets.mainMenu:updateDatabanks()
	self.optionMenu:clearCategory(categoryENUM.DatabanksConfig)
	self.optionMenu:clearCategory(categoryENUM.DatabanksRoute)
	self.optionMenu:clearCategory(categoryENUM.DatabanksUSB)
	for _, databank in ipairs(links.databanks) do
		self.optionMenu:addOption(databank.name, categoryENUM.DatabanksConfig, {
			main = { func = selectDatabank, arg = { type = 'config', databank = databank } },
			getActive = { func = function(option, dbk) return Config.databank == dbk end, arg = databank },
		})
		self.optionMenu:addOption(databank.name, categoryENUM.DatabanksRoute, {
			main = { func = selectDatabank, arg = { type = 'route', databank = databank } },
			getActive = { func = function(option, dbk) return RouteDatabase.databank == dbk end, arg = databank },
		})
		self.optionMenu:addOption(databank.name, categoryENUM.DatabanksUSB, {
			main = { func = selectDatabank, arg = { type = 'usb', databank = databank } }
		})
	end
end

function Widgets.mainMenu:onEditedRouteChanged()
	-- Clear the current point menu options
	self.optionMenu:clearCategory(categoryENUM.EditRoute)

	-- Guard clauses
	local invalidRoute = RouteDatabase.routes[RouteDatabase.currentEditId] == nil
	local routeIsEmpty = #RouteDatabase.routes[RouteDatabase.currentEditId].points == 0
	if invalidRoute or routeIsEmpty then return end

	-- Add points from edited route to the option menu
	for i, point in pairs(RouteDatabase.routes[RouteDatabase.currentEditId].points) do
		local actions = {
			main = { func = setPointDestination, arg = i, text = 'Set Destination' },
			shift = { func = deletePoint, arg = i, text = 'Delete', hold = 2 },
			alt = { func = printPoint, arg = i, text = 'Print Coordinates' },
			altUpDown = { func = movePoint, arg = i, text = 'Change point order' },
			input = { func = editPointName, arg = i },
			getActive = { func = function(option, arg) return AutoPilot.currentPointIndex == arg end, arg = i },
		}
		self.optionMenu:addOption(point.name, categoryENUM.EditRoute, actions)
	end
end

function Widgets.mainMenu:updateRoutes()
	self.optionMenu:clearCategory(categoryENUM.RouteListAll)
	for i, route in ipairs(RouteDatabase.routes) do
		local pointCount = RouteDatabase:getRoutePointCount(i)
		if pointCount == 0 then pointCount = '-' end
		local actions = {
			main = { func = setRouteDestination, arg = i, text = 'Set Destination' },
			shift = { func = deleteRoute, arg = i, text = 'Delete', hold = 2 },
			alt = { func = editRoute, arg = i, text = 'Open' },
			getValue = '( ' .. pointCount .. ' )',
			getActive = { func = function(option, arg) return AutoPilot.currentRouteIndex == arg end, arg = i },
		}
		self.optionMenu:addOption(route.name, categoryENUM.RouteListAll, actions)
	end

	-- self.optionMenu:clearCategory(categoryENUM.RouteListByPlanet)
	-- local routesByBodyId = {}
	-- for i, route in pairs(RouteDatabase.routes) do
	-- 	local routeBodyId = 0
	-- 	if #route.points == 0 then
	-- 		local lastPoint = route.points[#route.points]
	-- 		routeBodyId = findClosestBodyId(route.points[#route.points])
	-- 	end
	-- 	if routesByBodyId[routeBodyId] == nil then
	-- 		routesByBodyId[routeBodyId] = {}
	-- 	end
	-- 	table.insert(routesByBodyId[routeBodyId], route)
	-- end

	-- table.sort(routesByBodyId, function(a,b) return a.bodyId < b.bodyId end)
	-- for i,bodyRoutes in ipairs(routesByBodyId) do
	-- 	self.optionMenu:addCategory(atlas[systemId][routeBodyId].name, categoryENUM.RouteList, categoryENUM.RouteListByPlanet)
	-- 	table.sort(bodyRoutes, function(a,b) return a.bodyId < b.bodyId end)
	-- 	for j,route in ipairs(bodyRoutes) do

	-- 	end
	-- end
end