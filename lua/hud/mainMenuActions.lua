function addCustomPos(input)
	local pos = parsePosString(input)
	if pos.altitude == nil then
		return P('[E] Invalid ::pos{...} string')
	end
	addPos(pos)
end

function addCurrentPos()
	-- original code rounded to only 2 decimals, which was bad
	-- when using world coords!
	local pos = {
		latitude	= round2(cData.position.x, 5),
		longitude	= round2(cData.position.y, 5),
		altitude	= round2(cData.position.z, 5),
	}
	addPos(pos)
end

function addPos(pos)
	local worldCoords = mapPosToWorldPos(pos)
	if worldCoords == nil then return P('[E] Invalid ::pos string') end
	-- Only store body and system if non-zero
	-- edit: we only have system 0 for time being, so commented that out!
	--local systemId = ternary(pos.systemId == 0, nil, pos.systemId)
	local bodyId =  ternary(pos.bodyId == 0, nil, pos.bodyId)
	local coordinates = { x = pos.latitude, y = pos.longitude, z = pos.altitude }
	local coordBody = findClosestBody(worldCoords)
	local coordAlt = getAltitude(worldCoords)
	local coordLoc = getLoc(coordBody, coordAlt)
	local name = (coordBody ~= nil and coordBody.name or 'Space') ..
		' ' .. coordLoc .. ' [' .. math.ceil(coordAlt) .. 'm]'
	local point = {
		name = name,
		coordinates = coordinates,
		systemId = nil, --systemId,
		bodyId = bodyId
	}
	RouteDatabase:addPoint(RouteDatabase.currentEditId, point)
	Widgets.mainMenu:onEditedRouteChanged()
end

function printPoint(option, arg)
	local routeIndex = tonumber(RouteDatabase.currentEditId)
	if arg ~= nil and routeIndex ~= nil then
		P(RouteDatabase:getPointPosString(routeIndex, arg))
	end
end

function setRouteDestination(option, arg)
	AutoPilot:setActiveRoute(arg)
end

function setPointDestination(option, arg)
	AutoPilot:setActiveRoute(RouteDatabase.currentEditId, arg)
end

function newRoute(option, arg)
	RouteDatabase:newRoute()
	Widgets.mainMenu:onEditedRouteChanged()
	Widgets.mainMenu.optionMenu:setPreviousCategoryKey(categoryENUM.EditRoute, categoryENUM.RouteList)
	Widgets.mainMenu.optionMenu:openCategory(categoryENUM.EditRoute)
end

function editRouteName(input, arg)
	RouteDatabase:renameRoute(RouteDatabase.currentEditId, input)
end

function editPointName(input, arg)
	local rdb = RouteDatabase
	rdb:renamePoint(rdb.currentEditId, arg, input)
	P('Renamed [' .. rdb.currentEditId .. '] point [' .. arg .. '] to ' .. input)
	Widgets.mainMenu:onEditedRouteChanged()
end

function getEditRouteName(option, arg)
	local rdb = RouteDatabase
	if rdb.currentEditId ~= nil and rdb.routes[rdb.currentEditId] ~= nil then
		return rdb.routes[rdb.currentEditId].name
	end
	return 'Invalid route id'
end

function editRoute(option, arg)
	--P('Editing route [' .. arg .. ']')
	RouteDatabase.currentEditId = arg
	Widgets.mainMenu:onEditedRouteChanged()
	Widgets.mainMenu.optionMenu:setPreviousCategoryKey(categoryENUM.EditRoute, categoryENUM.RouteListAll)
	Widgets.mainMenu.optionMenu:openCategory(categoryENUM.EditRoute)
end

function unEditRoute(option, arg)
	Widgets.mainMenu.optionMenu:setActiveOption(RouteDatabase.currentEditId - 1)
	RouteDatabase.currentEditId = nil
end

function deleteRoute(option, arg)
	RouteDatabase:deleteRoute(arg)
end

function deletePoint(option, arg)
	RouteDatabase:deletePoint(RouteDatabase.currentEditId, arg)
	Widgets.mainMenu:onEditedRouteChanged()
end

function movePoint(up, arg)
	local newPointIndex = RouteDatabase:movePoint(RouteDatabase.currentEditId, arg, ternary(up, arg - 1, arg + 1))
	Widgets.mainMenu.optionMenu:setActiveOption(newPointIndex + 2)
	Widgets.mainMenu:onEditedRouteChanged()
end

function selectDatabank(option, arg)
	if arg.type == 'config' then
		Config:selectDb(arg.databank)
	elseif arg.type == 'route' then
		RouteDatabase:selectDb(arg.databank)
	elseif arg.type == 'usb' then
		RouteDatabase:selectUsbDb(arg.databank)
	end
end

function setConfig(option, arg)
	Config:setValue(arg.key, arg.value)
end

function setConfigInput(input, arg)
	Config:setValue(arg, input)
end

function getActiveDbName(option, arg)
	if arg == 'config' and Config.databank ~= nil then
		return Config.databank.name
	elseif arg == 'routes' and RouteDatabase.databank ~= nil then
		return RouteDatabase.databank.name
	elseif arg == 'usb' and RouteDatabase.usbDatabank ~= nil then
		return RouteDatabase.usbDatabank.name
	end
	return '-'
end

function menuActionTemplate(option, arg)
end