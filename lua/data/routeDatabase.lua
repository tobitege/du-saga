RouteDatabase = (
function()
	local this = {}

	this.dbDataKey = nil
	this.databank = nil
	this.databanks = nil
	this.usbDatabank = nil
	this.routes = {}
	this.currentEditId = nil

	function this:init(databanks, dbDataKey)
		this.dbDataKey = dbDataKey
		this.databanks = databanks

		EventSystem:register('ConfigDBChanged', this.applyConfig, this)
		this:applyConfig()
	end

	function this:applyConfig()
		-- Update databank names
		for _, databank in pairs(this.databanks) do
			databank.name = links.core.getElementNameById(databank.id)
		end

		-- Figure out the route databank
		this.databank = nil
		local selectedDbPriority = 0
		local routeDbName = Config:getValue(configDatabankMap.routeDatabankName)

		if routeDbName ~= nil then -- Config had a route databank selected
			for _, databank in pairs(this.databanks) do
				if databank.name == routeDbName then
					this.databank = databank
					selectedDbPriority = 3
					break
				end
			end
		end

		if this.databank == nil then
			for _, databank in pairs(this.databanks) do
				-- Select first by default
				if this.databank == nil then this.databank = databank end
				-- Overwrite selection if the db contains relevant data
				local keysOnDb = databank.getKeyList()
				if table.contains(this.dbDataKey, keysOnDb) and selectedDbPriority <= 1 then
					this.databank = databank
					selectedDbPriority = 1
				end
			end
		end

		-- Figure out the usb databank
		local usbDbName = Config:getValue(configDatabankMap.usbDatabankName)
		if usbDbName ~= nil then -- Config had a usb databank selected
			for _, databank in pairs(this.databanks) do
				if databank.name == usbDbName then
					this.usbDatabank = databank
					break
				end
			end
		end

		this:load()
	end

	function this:selectDb(databank)
		this.databank = databank
		local dbName = links.core.getElementNameById(this.databank.id)
		Config:setValue(configDatabankMap.routeDatabankName, dbName)
		this:load()
	end

	function this:selectUsbDb(databank)
		this.usbDatabank = databank
		local dbName = links.core.getElementNameById(this.usbDatabank.id)
		Config:setValue(configDatabankMap.usbDatabankName, dbName)
	end

	function this:save()
		EventSystem:trigger('RoutesUpdated')
		if this.databank == nil then return end
		this.databank.setStringValue(this.dbDataKey, serialize(this.routes))
	end

	function this:load()
		if this.databank == nil then return end
		this.routes = {}
		local dbStringValue = this.databank.getStringValue(this.dbDataKey)
		if dbStringValue ~= '' then
			local dbLoad, err = load('return ' .. dbStringValue)
			if dbLoad == nil or this.routes == nil then
				P('[E] Error loading routes from databank!')
				P(dbStringValue)
				P(err)
			else
				local routesOnDatabank = dbLoad()
				if routesOnDatabank ~= nil then
					this.routes = routesOnDatabank
					table.sort(this.routes, function(a,b)
						local an = (a and a.name) or ''
						local bn = (b and b.name) or ''
						return tostring(an) < tostring(bn)
					end)
				end
			end
		end
		EventSystem:trigger('RoutesUpdated')
	end

	function this:beforeRoutesChanged()
		if this.currentEditId ~= nil then
			this.shouldFindEdit = true
			this.routes[this.currentEditId].edit = true
		end
		if AutoPilot.currentRouteIndex ~= nil then
			this.shouldFindActive = true
			this.routes[AutoPilot.currentRouteIndex].active = true
		end
	end

	function this:routesChanged()
		local foundEdit, foundActive = false, false
		if this.routes == nil then return end

		table.sort(this.routes, function(a,b) return a.name < b.name end)

		for i,route in ipairs(this.routes) do
			-- Automatically "open" fresh routes
			if route.fresh == true then
				route.fresh = nil
				this.currentEditId = i
			end
			-- Fix the current edit
			if route.edit == true then
				route.edit = nil
				this.currentEditId = i
				foundEdit = true
			end
			-- Fix the AP route index
			if route.active == true then
				route.active = nil
				AutoPilot.currentRouteIndex = i
				foundActive = true
				Config:setDynamicValue(configDatabankMap.currentTarget, {AutoPilot.currentRouteIndex,AutoPilot.currentPointIndex,this.databank.name})
			end
		end

		-- The edit route wasn't found
		if this.shouldFindEdit and not foundEdit then
			this.currentEditId = nil
		end
		-- The active route wasn't found
		if this.shouldFindActive and not foundActive then
			AutoPilot:onRouteUnloaded()
		end

		this.shouldFindEdit = false
		this.shouldFindActive = false

		this:save()
	end

	function this:newRoute()
		local route = {
			name = 'Route ' .. (#this.routes + 1),
			points = {},
			fresh = true
		}
		this:beforeRoutesChanged()
		table.insert(this.routes, route)
		this:routesChanged()
		return route
	end

	function this:addPoint(index, point)
		table.insert(this.routes[index].points, point)
		this:save()
	end

	function this:deleteRoute(index)
		this:beforeRoutesChanged()
		table.remove(this.routes, index)
		this:routesChanged()
	end

	function this:deletePoint(routeIndex, pointIndex)
		if this.routes[routeIndex] == nil then return end
		if this.routes[routeIndex].points == nil then return end
		if this.routes[routeIndex].points[pointIndex] == nil then return end
		if AutoPilot.currentRouteIndex == routeIndex and AutoPilot.currentPointIndex >= pointIndex then
			AutoPilot.currentPointIndex = AutoPilot.currentPointIndex - 1
		end
		table.remove(this.routes[routeIndex].points, pointIndex)
		this:save()
	end

	function this:renameRoute(index, name)
		if this.routes[index] == nil then return end
		this:beforeRoutesChanged()
		this.routes[index].name = name
		this:routesChanged()
	end

	function this:renamePoint(rtIdx, ptIdx, name)
		if this.routes[rtIdx] == nil then return end
		if this.routes[rtIdx].points == nil then return end
		if this.routes[rtIdx].points[ptIdx] == nil then return end
		this.routes[rtIdx].points[ptIdx].name = name
		this:save()
	end

	function this:movePoint(routeIndex, oldPointIndex, newPointIndex)
		if this.routes[routeIndex] == nil or this.routes[routeIndex].points == nil then return end
		local pointCount = #this.routes[routeIndex].points
		local point = table.remove(this.routes[routeIndex].points, oldPointIndex)
		newPointIndex = clamp(newPointIndex, 1, pointCount)
		table.insert(this.routes[routeIndex].points, newPointIndex, point)
		local ap = AutoPilot
		if ap.currentRouteIndex == routeIndex then
			local idx = ap.currentPointIndex
			if idx == oldPointIndex then
				ap.currentPointIndex = newPointIndex
			elseif idx == newPointIndex then
				ap.currentPointIndex = oldPointIndex
			end
		end
		this:save()
		return newPointIndex
	end

	function this:getRoutePointCount(rIdx)
		local route = this.routes[rIdx]
		if route == nil or route.points == nil then return 0 end
		return #route.points
	end

	function this.getPoint(rIdx, pIdx)
		local route = this.routes[rIdx]
		if route == nil or route.points == nil then return end
		local pnts = route.points
		if pnts == nil or pnts[pIdx] == nil then return end
		return pnts[pIdx]
	end

	function this:getPointCoordinates(rIdx, pIdx)
		local point = this.getPoint(rIdx, pIdx)
		if point == nil then return nil end
		local sysId, bodyId = 0, 0
		if tonumber(point.systemId) ~= nil and point.systemId > 0 then
			sysId = point.systemId
		end
		if tonumber(point.bodyId) ~= nil and point.bodyId > 0 then
			bodyId = point.bodyId
		end
		local worldPos = mapPosToWorldPos({
			latitude	= point.coordinates.x,
			longitude	= point.coordinates.y,
			altitude	= point.coordinates.z,
			bodyId		= bodyId,
			systemId	= sysId
		})
		return worldPos
	end

	function this:getPointPosString(rIdx, pIdx)
		local point = this.getPoint(rIdx, pIdx)
		if point == nil then return nil end
		local sysId, bodyId = 0, 0
		if tonumber(point.systemId) ~= nil then sysId = point.systemId end
		if tonumber(point.bodyId) ~= nil then bodyId = point.bodyId end
		local c = point.coordinates
		local pointConcat = table.concat({sysId,bodyId,c.x,c.y,c.z}, ',')
		return '::pos{' .. pointConcat .. '}'
	end

	function this:getDatabankName()
		return ternary(this.databank == nil, nil, this.databank.name)
	end

	return this
end
)()