anchorENUM = {
	top = 'top',
	topLeft = 'topLeft',
	topRight = 'topRight',
	bottom = 'bottom',
	bottomLeft = 'bottomLeft',
	bottomRight = 'bottomRight',
}
Widget = {
	anchor = nil,
	width = 200, -- Widget width
	edgeMargin = 45, -- Widget margin to screen edges
	margin = 10, -- Margin to other widgets
	headerHeight = 0, -- Widget margin to screen edges
	padding = 0, -- Padding inside the widget
	rowCount = 0, -- Row count and measurements are useful for svg widgets
	rowHeight = 0,
	rowMargin = 0, -- Margin between rows ()
	visible = true
}

function Widget:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Widget:init()
	-- Override this per widget
end

function Widget:build()
	-- Override this per widget
end

function Widget:render(anchorUsedWidth, anchorMaxWidth)
	if self.build ~= nil and type(self.build) == 'function' then
		if anchorUsedWidth == nil then anchorUsedWidth = 0 end

		local scaleMultiplier = HUD.Config.scaleMultiplier
		local nativeScaleMultiplier = HUD.Config.nativeScaleMultiplier
		local content = self:build()

		if not self.visible then return '' end

		-- Build the class string
		local classes = {}
		if self.class ~= nil then classes = { self.class } end
		table.insert(classes, 'widget')
		local classStr = ' class="' .. table.concat(classes, ' ') .. '"'

		-- Figure out positioning
		local anchorWidth = anchorMaxWidth * scaleMultiplier
		local widgetWidth = self.width * scaleMultiplier
		local widgetContentHeight = self.rowCount * (self.rowHeight + self.rowMargin) - self.rowMargin + self.headerHeight
		local widgetHeight = (widgetContentHeight + self.padding * 2) * scaleMultiplier
		local edgeMargin = self.edgeMargin * scaleMultiplier
		local xOffset = anchorUsedWidth * scaleMultiplier
		local yOffset = edgeMargin
		local anchorStr = ''
		if self.anchor == anchorENUM.top then
			yOffset = 4 * scaleMultiplier
			xOffset = xOffset + HUD.screenWidth / 2 - widgetWidth / 2
			anchorStr = 'top: ' .. yOffset .. 'px; left: ' .. xOffset .. 'px;'
		elseif self.anchor == anchorENUM.topLeft then
			xOffset = xOffset + edgeMargin
			anchorStr = 'top: ' .. yOffset .. 'px; left: ' .. xOffset .. 'px;'
		elseif self.anchor == anchorENUM.topRight then
			xOffset = xOffset + edgeMargin
			xOffset = xOffset + 440 * nativeScaleMultiplier
			anchorStr = 'top: ' .. yOffset .. 'px; right: ' .. xOffset .. 'px;'
		elseif self.anchor == anchorENUM.bottom then
			xOffset = xOffset + HUD.screenWidth / 2 - anchorWidth / 2
			anchorStr = 'bottom: ' .. yOffset .. 'px; left: ' .. xOffset .. 'px;'
		elseif self.anchor == anchorENUM.bottomLeft then
			xOffset = xOffset + edgeMargin
			anchorStr = 'bottom: ' .. yOffset .. 'px; left: ' .. xOffset .. 'px;'
		elseif self.anchor == anchorENUM.bottomRight then
			xOffset = xOffset + edgeMargin
			anchorStr = 'bottom: ' .. yOffset .. 'px; right: ' .. xOffset .. 'px;'
		else
			anchorStr = 'top: 50%; left: ' .. xOffset .. 'px;'
		end

		local borderWidth = 2 -- 1px on both sides
		local sizeString = 'width:' .. (widgetWidth + borderWidth) .. 'px;'
		if widgetHeight > 0 then
			sizeString = 'width:' .. (widgetWidth + borderWidth) .. 'px;height:' .. (widgetHeight + borderWidth) .. 'px;'
		end

		--P('<div' .. classStr .. ' style="' .. anchorStr .. sizeString .. '">' .. content .. '</div>')
		return '<div' .. classStr .. ' style="' .. anchorStr .. sizeString .. '">' .. content .. '</div>'
	end
end