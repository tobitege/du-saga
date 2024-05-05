local dockPanelId, dockWdgId = nil, nil

HUD = {}
HUD.Config = {
	coreWidget = false,
	dockWidget = false,
	mainMenuVisible = false,
	mainHue = 240,
	mainHueShiftRight = 245,
	mainHueShiftLeft = 235,
	nativeScaleMultiplier = nil,
	saturation = 0,
	scaleMultiplier = nil,
	unitWidgetVisible = false,
}

function HUD:init()
	local cfg, cfgMap = Config.defaults, configDatabankMap
	cfg[cfgMap.hudScale] = 1
	cfg[cfgMap.unitWidgetVisible] = self.Config.unitWidgetVisible
	cfg[cfgMap.mainMenuVisible] = self.Config.mainMenuVisible
	cfg[cfgMap.coreWidget] = self.Config.coreWidget
	cfg[cfgMap.dockWidget] = self.Config.dockWidget

	EventSystem:register('ConfigDBChanged', self.applyConfig, self)

	system.showScreen(1)
	self.updateScale()
	self:applyConfig()

	Widgets = {}
	require('widgets/aggInfo')
	require('widgets/controls')
	require('widgets/core')
	-- require('widgets/debugInfo')
	require('widgets/fuelInfo')
	require('widgets/infos')
	require('widgets/mainMenu')
	require('widgets/radarContacts')
	require('widgets/warpInfo')
	for _,widget in pairs(Widgets) do
		widget:init()
	end
end

function HUD:applyConfig()
	self.Config.unitWidgetVisible = Config:getValue(configDatabankMap.unitWidgetVisible)
	self.Config.mainMenuVisible = Config:getValue(configDatabankMap.mainMenuVisible)
	self.Config.coreWidget = Config:getValue(configDatabankMap.coreWidget)
	self.Config.dockWidget = Config:getValue(configDatabankMap.dockWidget)
	self.applyDockWidget()
	self.applyUnitWidget()
end

function HUD.updateScale()
	HUD.screenWidth = system.getScreenWidth()
	HUD.screenHeight = system.getScreenHeight()
	local newScaleMultiplier = HUD.screenHeight / 1080 * (Config:getValue(configDatabankMap.hudScale) or 1)
	local newNativeScaleMultiplier = HUD.screenHeight / 1080
	if newScaleMultiplier ~= nil and HUD.Config.scaleMultiplier ~= newScaleMultiplier then
		HUD.Config.scaleMultiplier = newScaleMultiplier
		HUD.Config.nativeScaleMultiplier = newNativeScaleMultiplier
		HUD.refreshStaticCss()
	end
end

function HUD.update()
	HUD.updateScale()
	local rendered, gC = '', globals

	if HUD.dynamicSVG == nil then
		dynamicSVG()
	end
	rendered = HUD.constructDebug()

	local widgets = {}

	-- commented out to save space!
	-- if gC.debug and Widgets.debugInfo then
	-- 	table.insert(widgets, Widgets.debugInfo)
	-- 	Widgets.debugInfo.anchor = anchorENUM.topLeft
	-- end

	table.insert(widgets, Widgets.controls)
	Widgets.controls.anchor = anchorENUM.topRight
	Widgets.controls.width = 180
	if HUD.Config.mainMenuVisible then
		table.insert(widgets, Widgets.mainMenu)
	end
	table.insert(widgets, Widgets.fuelInfo)
	Widgets.fuelInfo.anchor = anchorENUM.topLeft
	Widgets.fuelInfo.width = 220
	table.insert(widgets, Widgets.infos)
	Widgets.infos.width = 150
	Widgets.infos.anchor = anchorENUM.topLeft
	-- core panel has fps impact, that's why a timer is used now!
	if HUD.Config.coreWidget then
		table.insert(widgets, Widgets.core)
	end

	Widgets.core.anchor = anchorENUM.top
	Widgets.core.width = 800
	if links.antigrav then
		table.insert(widgets, Widgets.aggInfo)
		Widgets.aggInfo.anchor = anchorENUM.topLeft
		Widgets.aggInfo.width = 150
	end
	if links.warpdrive ~= nil then
		table.insert(widgets, Widgets.warpInfo)
		Widgets.warpInfo.anchor = anchorENUM.topLeft
		Widgets.warpInfo.width = 180
	end
	gC.radarD = #Radar.radarDynamic > 0
	gC.radarSt = #Radar.radarStatic > 0
	gC.radarA = #Radar.radarAbandoned > 0
	gC.radarAl = #Radar.radarAlien > 0
	gC.radarSp = #Radar.radarSpace > 0
	gC.radarF = #Radar.radarFriend > 0
	if Radar.radar ~= nil and Radar.boxesVisible then
		if gC.radarA then table.insert(widgets, Widgets.radarAbandoned) end
		if gC.radarSt then table.insert(widgets, Widgets.radarStatic) end
		if gC.radarD then table.insert(widgets, Widgets.radarDynamic) end
		if gC.radarF then table.insert(widgets, Widgets.radarFriend) end
		if gC.radarAl then table.insert(widgets, Widgets.radarAlien) end
		if gC.radarSp then table.insert(widgets, Widgets.radarSpace) end
		table.insert(widgets, Widgets.radarThreat)
	end

	-- Widget rendering, should probably be somewhere else but eh
	local sizeString = 'width:' .. HUD.screenWidth .. 'px; height:' .. HUD.screenHeight .. 'px;'
	rendered = rendered .. '<div style="position:fixed; top:0; left:0; ' .. sizeString .. '">'
	local anchorUsedWidth = {}
	local anchorMaxWidth = {}
	for _,widget in ipairs(widgets) do
		if anchorMaxWidth[widget.anchor] == nil then anchorMaxWidth[widget.anchor] = 0 end
		if anchorMaxWidth[widget.anchor] > 0 then anchorMaxWidth[widget.anchor] = anchorMaxWidth[widget.anchor] + widget.margin end
		anchorMaxWidth[widget.anchor] = anchorMaxWidth[widget.anchor] + widget.width
	end
	for _, widget in ipairs(widgets) do
		if widget.update ~= nil then widget:update() end
		if anchorUsedWidth[widget.anchor] == nil then anchorUsedWidth[widget.anchor] = 0 end
		rendered = rendered .. widget:render(anchorUsedWidth[widget.anchor], anchorMaxWidth[widget.anchor])
		anchorUsedWidth[widget.anchor] = anchorUsedWidth[widget.anchor] + widget.width + widget.margin
	end
	rendered = rendered..'</div>'

	--if type(HUD.renderButtons) == "function" then
	--	rendered = rendered .. HUD.renderButtons()
	--end

	system.setScreen(rendered)
end

function HUD.toggleMainMenu(state)
	if state == nil then state = not HUD.Config.mainMenuVisible end
	HUD.Config.mainMenuVisible = state
	Config:setValue(configDatabankMap.mainMenuVisible, HUD.Config.mainMenuVisible)
end

function HUD.toggleCoreWidget(state)
	if state == nil then state = not HUD.Config.coreWidget end
	HUD.Config.coreWidget = state
	Config:setValue(configDatabankMap.coreWidget, HUD.Config.coreWidget)
end

function HUD.toggleDockWidget(state)
	if state == nil then state = not HUD.Config.dockWidget end
	HUD.Config.dockWidget = state
	Config:setValue(configDatabankMap.dockWidget, HUD.Config.dockWidget)
	HUD.applyDockWidget()
end

function HUD.toggleUnitWidget(state)
	if state == nil then state = not HUD.Config.unitWidgetVisible end
	HUD.Config.unitWidgetVisible = state
	Config:setValue(configDatabankMap.unitWidgetVisible, HUD.Config.unitWidgetVisible)
	HUD.applyUnitWidget()
end

function HUD.applyDockWidget()
	if not HUD.Config.dockWidget and dockWdgId ~= nil then
		system.destroyWidget(dockWdgId)
		system.destroyWidgetPanel(dockPanelId)
		dockWdgId = nil
		dockPanelId = nil
	elseif HUD.Config.dockWidget then
		dockPanelId = system.createWidgetPanel("Docking")
		dockWdgId = system.createWidget(dockPanelId,"parenting")
		system.addDataToWidget(unit.getWidgetDataId(),dockWdgId)
	end
end

function HUD.applyUnitWidget()
	if HUD.Config.unitWidgetVisible then
		unit.showWidget()
	else
		unit.hideWidget()
	end
end

require('debug') -- this is NOT for debugInfo, but constructDebug!
require('widget')
require('menuSystem')
require('mainMenuActions')
require('static_svg')
--require('buttons') ---@TODO testing for mouse interactions; CSS is kaputt
require('static_css')
require('dynamic_svg')