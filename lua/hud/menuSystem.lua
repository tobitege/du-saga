local mfloor, tinsert, tconcat = math.floor, table.insert, table.concat
local svgBox = '<svg viewBox="0 0 100 100" x="'
MenuSystem = {
	config = {
		optionWidth = 50,
		headerHeight = 20,
		optionHeight = 20,
		optionMargin = 0,
		visOptCnt = 12,
		activeOption = 0,
		activeCategory = nil,
		legendVisible = true
	},
	rowCount = 0,
	options = {},
	optionCategories = {},
	confirmCount = 0,
	lastOptionChangeTime = 0,
	lastInputs = {},
	lastInputTimes = {},

	addCategory = function(this, categoryText, categoryKey, parentCategoryKey, actions, permanent)
		local category = {
			text = categoryText,
			key = categoryKey,
			parentKey = parentCategoryKey,
			actions = actions,
			state = {
				hovering = false,
				active = false
			},
			permanent = permanent
		}
		tinsert(this.optionCategories, category)
		return category
	end,

	addOption = function(this, optionText, categoryKey, actions, permanent)
		local option = {
			text = optionText,
			category = categoryKey,
			actions = actions,
			state = {
				hovering = false,
				active = false
			},
			permanent = permanent
		}
		tinsert(this.options, option)
		return option
	end,

	clearCategory = function(this, categoryKey)
		for i = #this.options,1,-1 do
			local option = this.options[i]
			if option.category == categoryKey and option.permanent ~= true then
				table.remove(this.options, i)
			end
		end
		for i = #this.optionCategories,1,-1 do
			local category = this.optionCategories[i]
			if category.parentKey == categoryKey and category.permanent ~= true then
				table.remove(this.optionCategories, i)
			end
		end
	end,

	-- Override this as wanted
	onClose = function(this)
	end,

	toggleLegend = function(this)
		this.config.legendVisible = not this.config.legendVisible
		Config:setValue(configDatabankMap.menuKeyLegend, this.config.legendVisible)
	end,

	updateState = function(this, option, hovering)
		if option.actions ~= nil and option.actions.getActive ~= nil then
			option.state.active = option.actions.getActive.func(option, option.actions.getActive.arg)
		end
		option.state.hovering = hovering
	end,

	openCategory = function(this, categoryKey, currentCategory)
		this.config.activeOption = 0
		this.config.activeCategory = categoryKey
		local i = 0
		for _, category in ipairs(this.optionCategories) do
			if category.parentKey == categoryKey then
				if currentCategory ~= nil and category.key == currentCategory.key then
					this.config.activeOption = i
					break
				end
				i = i + 1
			end
		end
	end,

	render = function(this)
		local html = {}
		this.rowCount = 0
		this.hoveredEntry = nil

		local entryCount = 0
		for _, category in ipairs(this.optionCategories) do
			if category.parentKey == this.config.activeCategory and category.key ~= this.config.activeCategory then
				entryCount = entryCount + 1
			end
		end
		for _, option in ipairs(this.options) do
			if option.category == this.config.activeCategory then
				entryCount = entryCount + 1
			end
		end

		-- Clamp activeOption
		if entryCount - 1 < this.config.activeOption then
			this.config.activeOption = entryCount - 1
		elseif this.config.activeOption < 0 then
			this.config.activeOption = 0
		end

		html[#html+1] = this:renderCategory(this:getCategory(this.config.activeCategory))

		return tconcat(html)
	end,

	setActiveOption = function(this, entry)
		local categoryCount = 0
		--local OptCnt = 0
		local isCategory = type(entry) == 'table' and entry.key ~= nil
		--local isOption = type(entry) == 'table' and entry.category ~= nil
		for _, category in ipairs(this.optionCategories) do
			if category.parentKey == this.config.activeCategory and category.key ~= this.config.activeCategory then
				categoryCount = categoryCount + 1
				if isCategory and category.key == entry.key then
					this.config.activeOption = categoryCount
					return
				end
			end
		end
		if type(entry) == 'number' then
			this.config.activeOption = categoryCount + entry
		end
	end,

	renderCategory = function(this, renderCategory)
		local html = {}

		-- Find parents recursively until there are none
		local parents = {}
		if renderCategory ~= nil and renderCategory.key ~= nil then
			local parentCategory = this:getCategory(renderCategory.key)
			tinsert(parents, 1, parentCategory)
			while parentCategory.parentKey ~= nil and parentCategory.parentKey ~= parentCategory.key do
				parentCategory = this:getCategory(parentCategory.parentKey)
				tinsert(parents, 1, parentCategory)
			end
		end

		-- Make a string from the parents
		local parentNames = {}
		for _, parentCategory in ipairs(parents) do
			tinsert(parentNames, parentCategory.text)
		end
		if #parentNames == 0 then tinsert(parentNames, 'Main Menu') end
		local parentString = tconcat(parentNames, ' > ')

		-- Show the parent string
		local HUDScale = HUD.Config.scaleMultiplier
		local optionHeight = this.config.optionHeight * HUDScale
		local optionMargin = this.config.optionMargin * HUDScale
		local optionOuterHeight = optionHeight + optionMargin
		local headerHeight = this.config.headerHeight * HUDScale
		local headerPadding = 4 * HUDScale
		--local headerXStart = mfloor(headerPadding)
		local headerYMidFirst = mfloor(optionHeight / 2)
		--local headerYMidSecond = mfloor(optionHeight / 2 + optionHeight)
		local headerYEnd = mfloor(headerHeight - headerPadding)
		html[#html+1] = '<text class="outlined" x="' .. headerPadding .. '" y="' .. (headerYMidFirst) .. '">' .. parentString .. '</text>'
		html[#html+1] = '<rect class="separator" x=' .. headerPadding .. '" y="' .. (headerYEnd) .. '" width="' .. (this.config.optionWidth * HUDScale) .. '" height="1" />'

		-- Define the 'window' into the option list,
		-- The 'window' can be 'scrolled' by modifying the indexes appropriately
		local visibleIndexMin = 0
		local visibleIndexMax = this.config.visOptCnt
		if this.config.activeOption > this.config.visOptCnt then
			visibleIndexMin = this.config.activeOption - this.config.visOptCnt
			visibleIndexMax = this.config.activeOption
		end

		local categoryCount = 0
		local visCatCnt = 0
		-- Render visible member categories
		for _, category in ipairs(this.optionCategories) do
			if category.parentKey == renderCategory.key and category.key ~= renderCategory.key then
				if categoryCount <= visibleIndexMax and categoryCount >= visibleIndexMin then
					local hovering = categoryCount == this.config.activeOption
					if hovering then this.hoveredEntry = category end
					this:updateState(category, hovering)
					html[#html+1] = this:renderEntry(category, visCatCnt)
					visCatCnt = visCatCnt + 1
				end
				categoryCount = categoryCount + 1
			end
		end

		local OptCnt = 0
		local visOptCnt = 0
		-- Render visible member options
		for _, option in ipairs(this.options) do
			if option.category == renderCategory.key then
				local effectiveIndex = OptCnt + categoryCount
				if effectiveIndex <= visibleIndexMax and effectiveIndex >= visibleIndexMin then
					local hovering = effectiveIndex == this.config.activeOption
					if hovering then this.hoveredEntry = option end
					this:updateState(option, hovering)
					html[#html+1] = this:renderEntry(option, visOptCnt + visCatCnt)
					visOptCnt = visOptCnt + 1
				end
				OptCnt = OptCnt + 1
			end
		end

		local totalEntryCount = OptCnt + categoryCount
		local visibleEntryCount = visCatCnt + visOptCnt
		this.rowCount = this.rowCount + visibleEntryCount

		if this.config.visOptCnt < totalEntryCount then
			html[#html+1] = this:renderScrollBar(headerYEnd, totalEntryCount, visibleEntryCount, visibleIndexMin, visibleIndexMax)
		end

		local tooltipY = 0
		if this.config.legendVisible then
			local legendY = headerYEnd + optionOuterHeight * this.rowCount + optionOuterHeight
			local legendHtml, legendHeight = this:renderActionLegend(legendY)
			tooltipY = legendY + legendHeight
			html[#html+1] = legendHtml
		else
			tooltipY = headerYEnd + optionOuterHeight * this.rowCount + 10 * HUDScale
		end
		if this.hoveredEntry ~= nil then
			html[#html+1] = this:renderTooltip(tooltipY, this.config.legendVisible)
		end
		return tconcat(html)
	end,

	renderScrollBar = function(this, yPos, totalEntryCount, visibleEntryCount, visibleIndexMin, visibleIndexMax)
		local html = {}
		local HUDScale = HUD.Config.scaleMultiplier
		local optionHeight = this.config.optionHeight * HUDScale
		local optionMargin = this.config.optionMargin * HUDScale
		local optionOuterHeight = optionHeight + optionMargin
		local barYMargin = 10 * HUDScale
		local barY = yPos + optionMargin / 2 + barYMargin / 2
		local barX = -12 * HUDScale
		local barFullHeight = visibleEntryCount * optionOuterHeight - barYMargin
		local barWidth = 5 * HUDScale
		local barWidthTrack = 2 * HUDScale
		local barVisibleYStart = barY + visibleIndexMin / totalEntryCount * barFullHeight
		local barVisibleYEnd = barY + (visibleIndexMax + 1) / totalEntryCount * barFullHeight
		local barHeight = barVisibleYEnd - barVisibleYStart

		local arrowMargin = 5 * HUDScale
		local arrowSize = 10 * HUDScale

		html[#html+1] = svgBox .. (barX - arrowSize / 2) .. '" y="' .. (barY - arrowSize - arrowMargin) .. '" width="' .. arrowSize .. '" height="' .. arrowSize .. '">'
		html[#html+1] = HUD.staticSVG.upKey..'</svg>'

		html[#html+1] = svgBox .. (barX - arrowSize / 2) .. '" y="' .. (barY + barFullHeight + arrowMargin ) .. '" width="' .. arrowSize .. '" height="' .. arrowSize .. '">'
		html[#html+1] = HUD.staticSVG.downKey..'</svg>'

		html[#html+1] = '<rect class="separator" x="' .. (barX - barWidthTrack / 2) .. '" y="' .. barY .. '" width="' .. barWidthTrack .. '" height="' .. barFullHeight .. '"/>'
		html[#html+1] = '<rect class="separator" x="' .. (barX - barWidth / 2) .. '" y="' .. barVisibleYStart .. '" width="' .. barWidth .. '" height="' .. barHeight .. '"/>'

		return tconcat(html)
	end,

	renderActionLegend = function(this, yPos)
		local hoveredEntry = this.hoveredEntry
		local html = {}
		actions = {}
		if hoveredEntry ~= nil then
			actions.back = {}
			if hoveredEntry.key ~= nil then -- force 'main' for categories
				actions.main = {}
			end
			if hoveredEntry.actions ~= nil then
				if hoveredEntry.actions.back ~= nil then
					actions.back = hoveredEntry.actions.back
				end
				if hoveredEntry.actions.main ~= nil then
					actions.main = hoveredEntry.actions.main
				end
				if hoveredEntry.actions.alt ~= nil then
					actions.alt = hoveredEntry.actions.alt
				end
				if hoveredEntry.actions.shift ~= nil then
					actions.shift = hoveredEntry.actions.shift
				end
				if hoveredEntry.actions.altUpDown ~= nil then
					actions.altUpDown = hoveredEntry.actions.altUpDown
				end
				if hoveredEntry.actions.input ~= nil then
					actions.input = hoveredEntry.actions.input
				end
			end
		end

		local actionsArr = {
			{action = actions.back},
			{action = actions.main},
			{action = actions.alt},
			{action = actions.shift},
		}
		if actions.altUpDown ~= nil then actionsArr[#actionsArr+1] = {action = actions.altUpDown} end
		if actions.input ~= nil then actionsArr[#actionsArr+1] = {action = actions.input} end

		local HUDScale = HUD.Config.scaleMultiplier
		-- local optionHeight = this.config.optionHeight * HUDScale
		-- local optionWidth = this.config.optionWidth * HUDScale
		local optionMargin = this.config.optionMargin * HUDScale
		local rowHeight = 10 * HUDScale
		local keyX = 50 * HUDScale
		local textX = keyX + 12 * HUDScale
		for i,actionArr in ipairs(actionsArr) do
			local active = false
			if i == 3 and inputs.alt then active = true
			elseif i == 5 and inputs.alt then active = true
			elseif i == 4 and inputs.shift and not inputs.alt then active = true
			end
			html[#html+1] = '<g class="menuLegend" data-active="' .. tostring(active) .. '">'
			local action = actionArr.action
			local keyY = yPos + rowHeight * (i - 1)
			local keySize = rowHeight * 0.55
			if i <= 5 then
				html[#html+1] = '<svg class="menuLegendGlyph" viewBox="0 0 100 100" x="' .. keyX .. '" y="' .. (keyY - (rowHeight - keySize)) .. '" width="' .. keySize .. '" height="' .. keySize .. '">'
				local keyGlyph = HUD.staticSVG.leftKey
				if i > 1 then keyGlyph = HUD.staticSVG.rightKey end
				if i == 5 and actions.altUpDown ~= nil then keyGlyph = HUD.staticSVG.upDownKey end
				html[#html+1] = keyGlyph
				html[#html+1] = '</svg>'
			end
			local t = '<text class="menuLegendKey" x="'.. (keyX - optionMargin) .. '" y=' .. keyY
			if i == 3 then
				html[#html+1] = t .. '>alt +</text>'
			elseif i == 4 then
				html[#html+1] = t .. '>shift +</text>'
			elseif i == 5 and actions.altUpDown ~= nil then
				html[#html+1] = t .. '>alt +</text>'
			end
			if action ~= nil then
				local actionText = 'Open'
				if hoveredEntry and hoveredEntry.key == nil then actionText = 'Select' end
				if i == 1 then actionText = 'Back' end
				if i == #actionsArr then actionText = 'Lua chat input is active' end
				if action.text ~= nil then actionText = action.text end
				html[#html+1] = '<text class="menuLegendText" x="' .. textX .. '" y=' .. keyY .. '>' .. actionText .. '</text>'
			end
			html[#html+1] = '</g>'
		end
		return tconcat(html), #actionsArr * rowHeight
	end,

	renderEntry = function(this, option, index)
		local html = {}

		local HUDScale = HUD.Config.scaleMultiplier
		local hovering = option.state.hovering
		local active = option.state.active

		local dataParams = {}
		if hovering then
			tinsert(dataParams, 'data-hover="true"')
		end
		if active then
			tinsert(dataParams, 'data-active="true"')
		end
		local dataString = ' ' .. tconcat(dataParams, ' ')
		local classString = class('menuOption')

		-- todo: These should be recalculated and cached when the scale changes
		local optionWidth = this.config.optionWidth * HUDScale
		local optionHeight = this.config.optionHeight * HUDScale
		local optionMargin = this.config.optionMargin * HUDScale
		local optionOuterHeight = optionHeight + optionMargin
		local headerHeight = this.config.headerHeight * HUDScale
		local cornerLength = mfloor(5 * HUDScale)
		local lineWidth = 1 * HUDScale

		local optionYStart = mfloor(optionOuterHeight * index + headerHeight)
		local optionYMid = mfloor(optionYStart + optionHeight / 2)
		local optionYEnd = mfloor(optionYStart + optionHeight)
		local optionXStart = 0
		local optionXStartPad = mfloor(optionMargin)
		--local optionXMid = mfloor(optionXStart + optionWidth / 2)
		local optionXEnd = mfloor(optionWidth)
		local optionXEndPad = mfloor(optionWidth - optionMargin)

		html[#html+1] = '<g' .. classString .. dataString .. '>'

		local valueXPad, cornerPadding, now = 0, 0, system.getArkTime()

		-- It's a category 'folder'
		if option.category == nil then
			valueXPad = mfloor(optionHeight)
			local indicatorSize = mfloor(optionHeight * 0.75)
			local indicatorY = mfloor((optionHeight - indicatorSize) / 2)
			html[#html+1] = svgBox .. (optionXEnd - indicatorSize) .. '" y="' .. (optionYStart + indicatorY) .. '" width="' .. indicatorSize .. '" height="' .. indicatorSize .. '">' .. HUD.staticSVG.categoryIndicator .. '</svg>'
		end

		-- The option is being hovered
		if hovering then
			local tweenTime = 0.2
			local optionChangeT = (now - this.lastOptionChangeTime) / tweenTime -- Results in 0...1 during tweenTime
			optionChangeT = clamp(optionChangeT, 0, 1)

			-- Pad the corners
			cornerPadding = 2 * (1 - optionChangeT)

			-- Background box when hovering
			local heightNow = optionChangeT * optionHeight
			local heightMid = optionYMid - heightNow / 2
			html[#html+1] = '<rect x="0" y="' .. heightMid .. '" width="' .. (optionWidth - valueXPad) .. '" height="' .. heightNow .. '" />'

			if inputs.mr and this.holdAction ~= nil and not this.holdActionTriggered then
				local timeSinceHoldStart = (now - this.lastInputTimes.right) / this.holdAction.hold
				html[#html+1] = '<rect class="inputHold" x="0" y="' .. heightMid .. '" width="' .. ((optionWidth - valueXPad) * timeSinceHoldStart) .. '" height="' .. heightNow .. '" />'
			end
		end

		-- The option is active
		if active then
			cornerLength = cornerLength * 2
			--lineWidth = lineWidth * 2
		end

		--local boxCornerLines = generateRectCorners(optionXStart, optionYStart, optionXEnd, optionYEnd, cornerLength, lineWidth)
		local boxCornerLinesInner = generateRectCorners(
			optionXStart + cornerPadding, -- x1
			optionYStart + cornerPadding, -- y1
			optionXEnd - cornerPadding - valueXPad, -- x2
			optionYEnd - cornerPadding, -- y2
			cornerLength, -- length
			lineWidth -- width
		)

		if active or hovering then
			html[#html+1] = boxCornerLinesInner
		end

		-- Display option.text
		html[#html+1] = '<text x="' .. optionXStartPad .. '" y="' .. optionYMid .. '">' .. option.text .. '</text>'

		if option.actions ~= nil and option.actions.input ~= nil and hovering then
			local indicatorSize = mfloor(optionHeight * 0.6)
			local indicatorMargin = mfloor((optionHeight - indicatorSize) / 2)
			html[#html+1] = svgBox .. (optionXEnd - valueXPad - indicatorSize - indicatorMargin) .. '" y="' .. (optionYStart + indicatorMargin) .. '" width="' .. indicatorSize .. '" height="' .. indicatorSize .. '">'
			html[#html+1] = HUD.staticSVG.editableBg
			if system.getArkTime() / 0.75 % 1 > 0.5 then html[#html+1] = HUD.staticSVG.editableGlyph end
			html[#html+1] = '</svg>'
			valueXPad = valueXPad + indicatorSize + indicatorMargin
		end

		-- Show the results of 'actions.getValue.func()'
		if option.actions ~= nil and option.actions.getValue ~= nil then
			local valueResult = nil
			if type(option.actions.getValue) == 'table' then
				valueResult = option.actions.getValue.func(option, option.actions.getValue.arg)
			elseif type(option.actions.getValue) == 'boolean' then
				valueResult = option.actions.getValue
			elseif type(option.actions.getValue) == 'string' or type(option.actions.getValue) == 'number' then
				valueResult = option.actions.getValue
			end

			if type(valueResult) == 'boolean' then
				local indicatorSize = mfloor(optionHeight * 0.6)
				local indicatorMargin = mfloor((optionHeight - indicatorSize) / 2)
				html[#html+1] = svgBox .. (optionXEnd - valueXPad - indicatorSize - indicatorMargin) .. '" y="' .. (optionYStart + indicatorMargin) .. '" width="' .. indicatorSize .. '" height="' .. indicatorSize .. '">'
				html[#html+1] = ternary(valueResult, HUD.staticSVG.checkBoxChecked, HUD.staticSVG.checkBoxUnchecked)
				html[#html+1] = '</svg>'
			elseif valueResult ~= nil then
				html[#html+1] = '<text class="valueText" x="' .. (optionXEndPad - valueXPad) .. '" y="' .. optionYMid .. '">' .. valueResult .. '</text>'
			end
		end

		html[#html+1] = '</g>'

		return tconcat(html)
	end,

	renderTooltip = function(this, yPos, showSeparator)
		if this.hoveredEntry.actions == nil or this.hoveredEntry.actions.tooltip == nil then return end

		--local hoveredEntry = this.hoveredEntry
		local html = {}

		local HUDScale = HUD.Config.scaleMultiplier
		local optionWidth = this.config.optionWidth * HUDScale
		--local optionHeight = this.config.optionHeight * HUDScale
		--local optionMargin = this.config.optionMargin * HUDScale
		local rowHeight = 11 * HUDScale
		local startY = 10 * HUDScale + yPos
		local textX = 10 * HUDScale
		local separatorMargin = 5 * HUDScale

		html[#html+1] = '<g class="menuTooltip">'
		if showSeparator then
			html[#html+1] = '<rect class="separator" x="' .. separatorMargin .. '" y="' .. yPos .. '" width="' .. (optionWidth - separatorMargin * 2) .. '" height="1"/>'
		end

		local tooltipRows = this.hoveredEntry.actions.tooltip
		if type(this.hoveredEntry.actions.tooltip) == 'string' then tooltipRows = {this.hoveredEntry.actions.tooltip} end

		for i,tooltip in ipairs(tooltipRows) do
			local rowY = startY + rowHeight * (i - 1)
			html[#html+1] = '<text class="menuTooltipText" x="' .. textX .. '" y="' .. rowY .. '">' .. tooltip .. '</text>'
		end
		html[#html+1] = '</g>'
		return tconcat(html)
	end,

	updateInputs = function(this)
		local inputs = inputs
		local now = system.getArkTime()
		local inputRepeatDelay = 0.2
		local holdNil = this.holdAction == nil
		local upTriggered = inputs.mu and (not this.lastInputs.up or holdNil and (now - this.lastInputTimes.up > inputRepeatDelay))
		local downTriggered = inputs.md and (not this.lastInputs.down or holdNil and (now - this.lastInputTimes.down > inputRepeatDelay))
		local leftTriggered = inputs.ml and (not this.lastInputs.left or holdNil and (now - this.lastInputTimes.left > inputRepeatDelay))
		local rightTriggered = inputs.mr and (not this.lastInputs.right or holdNil and (now - this.lastInputTimes.right > inputRepeatDelay))

		this.lastInputs = {
			up = inputs.mu,
			down = inputs.md,
			left = inputs.ml,
			right = inputs.mr
		}
		local hoveredEntry = this.hoveredEntry
		if upTriggered then
			if inputs.alt and hoveredEntry ~= nil and hoveredEntry.actions ~= nil and hoveredEntry.actions.altUpDown ~= nil then
				hoveredEntry.actions.altUpDown.func(true, hoveredEntry.actions.altUpDown.arg)
			else
				this.config.activeOption = this.config.activeOption - 1
			end
			this.lastOptionChangeTime = now
			this.lastInputTimes.up = now
		end
		if downTriggered then
			if inputs.alt and hoveredEntry ~= nil and hoveredEntry.actions ~= nil and hoveredEntry.actions.altUpDown ~= nil then
				hoveredEntry.actions.altUpDown.func(false, hoveredEntry.actions.altUpDown.arg)
			else
				this.config.activeOption = this.config.activeOption + 1
			end
			this.lastOptionChangeTime = now
			this.lastInputTimes.down = now
		end
		if leftTriggered then
			this.lastInputTimes.left = now
			-- Back out of the menu category
			local currentCategory = this:getCategory(this.config.activeCategory)
			if currentCategory.previousCategoryKey ~= nil then
				this:openCategory(currentCategory.previousCategoryKey, currentCategory)
			elseif currentCategory.parentKey ~= nil then
				this:openCategory(currentCategory.parentKey, currentCategory)
			else
				this:openCategory(nil, currentCategory)
				-- if this.config.activeCategory == nil then this:onClose() end
			end

			-- Apply custom actions
			if hoveredEntry ~= nil and hoveredEntry.actions ~= nil and hoveredEntry.actions.back ~= nil then
				currentCategory.actions.back.func(currentCategory, currentCategory.actions.back.arg)
				hoveredEntry.actions.back.func(hoveredEntry, hoveredEntry.actions.back.arg)
			elseif currentCategory.actions ~= nil and currentCategory.actions.back ~= nil then
				currentCategory.actions.back.func(currentCategory, currentCategory.actions.back.arg)
			end
		end
		if rightTriggered then
			this.lastInputTimes.right = now
			-- Find the currently active menu option and trigger it
			-- This is ugly, should probably find a better way
			local hoveredEntry = this.hoveredEntry
			if hoveredEntry ~= nil then
				if hoveredEntry.actions == nil and hoveredEntry.key ~= nil then
					this:openCategory(hoveredEntry.key)
				else
					if inputs.alt and hoveredEntry.actions.alt ~= nil then
						if hoveredEntry.actions.alt.hold ~= nil then this.holdAction = hoveredEntry.actions.alt this.holdActionTriggered = false
						else hoveredEntry.actions.alt.func(hoveredEntry, hoveredEntry.actions.alt.arg) end
					elseif inputs.shift and hoveredEntry.actions.shift ~= nil then
						if hoveredEntry.actions.shift.hold ~= nil then this.holdAction = hoveredEntry.actions.shift this.holdActionTriggered = false
						else hoveredEntry.actions.shift.func(hoveredEntry, hoveredEntry.actions.shift.arg) end
					elseif hoveredEntry.actions.main ~= nil then
						if hoveredEntry.actions.main.hold ~= nil then this.holdAction = hoveredEntry.actions.main this.holdActionTriggered = false
						else hoveredEntry.actions.main.func(hoveredEntry, hoveredEntry.actions.main.arg) end
					elseif hoveredEntry.key ~= nil then
						this:openCategory(hoveredEntry.key)
					elseif hoveredEntry.actions.input ~= nil then
						P('[I] Enter any text here in chat to input a new value')
					end
				end
			end
		elseif inputs.mr and this.holdAction ~= nil then
			local timeSinceHoldStart = now - this.lastInputTimes.right
			if this.holdAction.hold < timeSinceHoldStart and not this.holdActionTriggered then
				this.holdActionTriggered = true
				this.holdAction.func(this.hoveredEntry, this.holdAction.arg)
			end
		elseif this.holdAction ~= nil then
			this.holdAction = nil
		end
	end,

	setPreviousCategoryKey = function(this, categoryKey, previousCategoryKey)
		local category = this:getCategory(categoryKey)
		if category ~= nil then
			category.previousCategoryKey = previousCategoryKey
		end
	end,

	getCategory = function(this, categoryKey)
		if categoryKey == nil then return { key = nil, parentKey = nil } end
		for _, category in ipairs(this.optionCategories) do
			if category.key == categoryKey then
				return category
			end
		end
	end,

	getHoveredEntry = function(this)
		local i = 0
		for _, category in ipairs(this.optionCategories) do
			if category.parentKey == this.config.activeCategory and category.parentKey ~= category.key then
				if this.config.activeOption == i then
					return category
				end
				i = i + 1
			end
		end

		for _, option in ipairs(this.options) do
			if option.category == this.config.activeCategory then
				if this.config.activeOption == i then
					return option
				end
				i = i + 1
			end
		end
	end
}

function generateRectCorners(x1, y1, x2, y2, cornerLength, lineWidth)
	if lineWidth == nil then lineWidth = 1 end
	local html, rct, wdt, ht, ct, y = {}, '<rect class="separator" x="', '" width="', '" height="', '" />', '" y="'
	html[#html+1] = rct .. x1 .. y .. y1 .. wdt .. cornerLength .. ht .. lineWidth .. ct
	html[#html+1] = rct .. x1 .. y .. y1 .. wdt .. lineWidth .. ht .. cornerLength .. ct
	html[#html+1] = rct .. x1 .. y .. (y2 - lineWidth) .. wdt .. cornerLength .. ht .. lineWidth .. ct
	html[#html+1] = rct .. x1 .. y .. (y2 - cornerLength) .. wdt .. lineWidth .. ht .. cornerLength .. ct
	html[#html+1] = rct .. (x2 - cornerLength) .. y .. y1 .. wdt .. cornerLength .. ht .. lineWidth .. ct
	html[#html+1] = rct .. (x2 - lineWidth) .. y .. y1 .. wdt .. lineWidth .. ht .. cornerLength .. ct
	html[#html+1] = rct .. (x2 - cornerLength) .. y .. (y2 - lineWidth) .. wdt .. cornerLength .. ht .. lineWidth .. ct
	html[#html+1] = rct .. (x2 - lineWidth) .. y .. (y2 - cornerLength) .. wdt .. lineWidth .. ht .. cornerLength .. ct
	return tconcat(html)
end