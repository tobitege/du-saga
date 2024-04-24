-- function rx(v) if v == nil then return '' end return ' rx="'..v..'" ry="'..v..'"' end

-- svg = { }

-- AlignEnum = { }
-- AlignEnum.Middle = 'middle'

-- Input parameters
-- bool			data.visible		Button visibility
-- number		data.x				Button x coordinate
-- number		data.y				Button y coordinate
-- string		data.text			Button text content
-- number		data.height			Button height
-- number		data.width			Button width
-- number		data.padding		Inner padding to offset contents by -- Why isn't this a vec2?
-- AlignEnum	data.align			Text alignment - Only AlignEnum.Middle supported atm
-- number		data.fontSize		Font size in %
-- number		data.activeUpdate	Function to call every update which returns button active bool
-- number		data.rounding		The background rectangle rounding (numeric)
-- bool			data.active			Button active state
-- bool			data.hover			Button hover state
-- [str,bool]	data.dataAttributes	Array of additional data attributes with bool states
-- string		data.svg			Custom svg

-- Output parameters (written to)
-- number		data.screenX		Screen x position
-- number		data.screenY		Screen y position
-- function svg.BuildButton(data)
-- 	local svgTag = ''
-- 	-- Back out if not visible
-- 	if data.visible == false then return svgTag end

-- 	-- Set some defaults in case nils
-- 	data.height = data.height or 3
-- 	data.width = data.width or 3
-- 	data.padding = data.padding or 1
-- 	data.x = data.x or 0
-- 	data.y = data.y or 0

-- 	-- Update screen position
-- 	data.screenX = data.x
-- 	data.screenY = data.y

-- 	-- Content position
-- 	local btx = data.screenX + data.padding
-- 	local bty = data.screenY + data.padding

-- 	-- Call .activeUpdate if it exists
-- 	if data.activeUpdate ~= nil then
-- 		data.active = data.activeUpdate(data)
-- 	end

-- 	-- Classes
-- 	local class = 'uiButton'
-- 	if data.disabled then class = class .. ' disabled' end
-- 	if data.class then class = class .. ' ' .. data.class end

-- 	-- Text anchor
-- 	local textAnchor = '' -- via CSS!
-- 	if data.align ~= nil then
-- 		textAnchor = 'text-anchor: start;'
-- 		if data.align == AlignEnum.Middle then
-- 			btx = data.screenX + data.width / 2
-- 			textAnchor = 'text-anchor: middle;'
-- 		end
-- 	end

-- 	-- Font size
-- 	local fontSize = ''
-- 	if data.fontSize ~= nil then
-- 		fontSize = 'font-size: '..data.fontSize..'em; '
-- 	end

-- 	-- Rounding
-- 	local rndg = rx(data.rounding)

-- 	-- Data-attributes
-- 	local active = 'data-active="'.. ternary(data.active, 'true', 'false') .. '"'
-- 	local hover = 'data-hover="'.. ternary(data.hover, 'true', 'false') .. '"'

-- 	-- Additional data-attributes
-- 	local dataStrings = {}
-- 	if data.dataAttributes ~= nil then
-- 		for dataName,state in pairs(data.dataAttributes) do
-- 			table.insert(dataStrings, 'data-'..dataName..'="'..ternary(state, 'true', 'false')..'"')
-- 		end
-- 	end
-- 	local dataString = table.concat(dataStrings, ' ')

-- 	-- Build the SVG
-- 	-- Group for easier targeting
-- 	svgTag = svgTag .. '<g class="'..class..'" '..active..' '..hover..' '..dataString..'>'
-- 	-- Background rectangle
-- 	svgTag = svgTag .. '<rect '..rndg..' x="'..(data.screenX)..'" y="'..(data.screenY)..'" width="'..(data.width)..'" height="'..(data.height)..'" />'
-- 	-- Text
-- 	if data.text ~= nil then
-- 		svgTag = svgTag .. '<text style="'..fontSize..textAnchor..'" x="'..(btx*0.54)..'%" y="'..(bty)..'%">'..(data.text)..'</text>'
-- 	end
-- 	-- Custom SVG
-- 	if data.svg ~= nil then
-- 		svgTag = svgTag .. '<svg x="'..(data.screenX)..'" y="'..(data.screenY)..'">'..(data.svg)..'</svg>'
-- 	end
-- 	return svgTag .. '</g>\n'
-- end

-- used by below rect() and text()
-- function dataString(dataParameters)
-- 	local data = {}
-- 	if dataParameters == nil then return '' end
-- 	for dataName,dataValue in pairs(dataParameters) do
-- 		local dataVal = dataValue
-- 		if type(dataValue) == 'boolean' then
-- 			dataVal = ternary(dataValue, 'true', 'false')
-- 		end
-- 		table.insert(data, ' data-'..dataName..'="'..dataVal..'"')
-- 	end
-- 	return table.concat(data, ' ')
-- end

-- function text(data)
-- 	if data == nil then data = {} end
-- 	data.x = data.x or 0
-- 	data.y = data.y or 0
-- 	local dataString = dataString(data.dataParameters)
-- 	local class = class(data.class)
-- 	local svgTag = '<text'..class..''..dataString..' x="'..(data.x)..'%" y="'..(data.y)..'%">'..(data.text)..'</text>'
-- 	if data.outlined then
-- 		class = class('outlined')
-- 		svgTag = svgTag .. '<text'..class..''..dataString..' x="'..(data.x)..'%" y="'..(data.y)..'%">'..(data.text)..'</text>'
-- 	end
-- 	return svgTag
-- end

-- Create a <rect> svg element
-- function rect(data)
-- 	data.x = data.x or 0
-- 	data.y = data.y or 0
-- 	data.width = data.width or 3
-- 	data.height = data.height or 3
-- 	local dataString = dataString(data.dataParameters)
-- 	local class = class(data.class)
-- 	return '<rect'..class..''..dataString..' x="'..(data.x)..'vh" y="'..(data.y)..'vh" width="'..(data.width)..'vh" height="'..(data.height)..'vh" />'
-- end

function class(class) -- used by menuSystem
	local classes = {}
	if class ~= nil then
		if type(class) == 'table' then
			table.add(classes, class)
		elseif type(class) == 'string' then
			table.insert(classes, class)
		end
	end
	local s = ternary(#classes > 0, ' class="'..(table.concat(classes, ' '))..'"', '')
	return s
end

function gradient(id, data, vertical) -- used by static_css.lua
	local coords = ternary(vertical,'x1="0%" y1="0%" x2="0%" y2="100%"', 'x1="0%" y1="0%" x2="100%" y2="0%"')
	local def = '<linearGradient id="'..id..'"'..coords..'>'
	local stopKeys = table.keys(data)
	table.sort(stopKeys)
	for i,k in ipairs(stopKeys) do
		local stop, val = k, data[k]
		local pre = '<stop offset="'..stop..'%" stop-color="'
		if type(val) == 'table' then
			val = data[k][1]
			def = def..pre..val..'" stop-opacity="'..data[k][2]..'"/>'
		else
			def = def..pre..val..'"/>'
		end
	end
	def = def..'</linearGradient>'
	return def
end

-- EXAMPLE code to iterate a locations list to be displayed as buttons (unused!)
-- Define a table of location names or any other relevant strings
-- local locations = {"Home", "Office", "Park", "Cafe", "Library", "Store", "Museum", "Gym", "School", "Hospital"}

-- -- Base y-coordinate for the first button
-- local baseY = 100  -- Starting position for the first button

-- -- Height of each button including some space for separation
-- local buttonHeight = 60  -- Height of the button plus some margin

-- -- Iterate over the locations table to create a button for each location
-- for index, location in ipairs(locations) do
--     -- Define the data table for the button with dynamic y position
--     local buttonData = {
--         visible = true,
--         x = 960,  -- Centered horizontally
--         y = baseY + (buttonHeight * (index - 1)),  -- Increment y position for each button
--         text = location,  -- Use location name as button text
--         height = 50,
--         width = 150,
--         padding = 10,
--         align = AlignEnum.Middle,
--         fontSize = 12,
--         activeUpdate = function(data)
--             return true  -- Always active for this example
--         end,
--         rounding = 10,
--         active = true,
--         hover = false,
--         dataAttributes = {
--             ["custom-attr"] = true
--         },
--         svg = nil
--     }
--     -- Call the BuildButton function from the SVG module
--     local svgOutput = svg.BuildButton(buttonData)
--     -- Print the resulting SVG tag to see the output
--     P(svgOutput)
-- end