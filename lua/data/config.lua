Config = (
function()
	local this = {}

	this.config = {}
	this.dynamicIndicator = '_' -- this marks a dynamic databank key
	this.defaults = {}
	this.dbDataKey = nil
	this.databank = nil
	this.databanks = nil

	function this:init(databanks, dbDataKey, dbActiveKey)
		this.dbDataKey = dbDataKey
		this.dbActiveKey = dbActiveKey
		this.databanks = databanks
		local selectedDbPriority = 0
		for _, databank in ipairs(databanks) do
			-- Select first by default
			if this.databank == nil then this.databank = databank end

			-- Overwrite selection if the db contains relevant data
			local keysOnDb = databank.getKeyList()
			if table.contains(this.dbActiveKey, keysOnDb) then
				this.databank = databank
				selectedDbPriority = 2
			elseif table.contains(this.dbDataKey, keysOnDb) and selectedDbPriority < 2 then
				this.databank = databank
				selectedDbPriority = 1
			end
		end

		this:cleanNonActives()
		this:load()
	end

	function this:selectDb(databank)
		this:prepareForMigration() -- Cache dynamics from the old config
		if this.databank ~= nil then
			this.databank.clearValue(this.dbActiveKey)
			this:save(false) -- Purge dynamic keys from the old db
		end
		this.databank = databank
		this.databank.setIntValue(this.dbActiveKey, 1)
		this:load()
		this:migrate() -- Restore dynamics to the new db
		this:save() -- Purge dynamic keys from the old db
		EventSystem:trigger('ConfigDBChanged')
	end

	function this:getValue(key, defaultValue)
		if key == nil then P('Config:getValue(nil) error') return end
		if this.config[key] ~= nil then
			return this.config[key]
		end
		if this.defaults[key] ~= nil then
			return this.defaults[key]
		end
		return defaultValue
	end

	function this:getDynamicValue(key, defaultValue)
		return this:getValue(this.dynamicIndicator .. key, defaultValue)
	end

	function this:setValue(key, value, save)
		this:set(key, value, save)
	end

	function this:setDynamicValue(key, value, save)
		this:set(this.dynamicIndicator .. key, value, save)
	end

	function this:set(key, value, save)
		if save == nil then save = true end -- Save by default
		this.config[key] = value
		if save then this:save() end
		EventSystem:trigger('ConfigChange')
		EventSystem:trigger('ConfigChange' .. key)
	end

	function this:save(includeDynamic)
		if this.databank == nil then return end
		if includeDynamic == nil then includeDynamic = true end

		local configToSave = {}
		for key,value in pairs(this.config) do
			if includeDynamic or (key:find(this.dynamicIndicator) == nil) then
				configToSave[key] = value
			end
		end
		local serialized = serialize(configToSave)
		this.databank.setStringValue(this.dbDataKey, serialized)
	end

	function this:load()
		if this.databank == nil then return end
		local dbStringValue = this.databank.getStringValue(this.dbDataKey)
		if dbStringValue == '' then return end
		local dbLoad, err = load('return ' .. dbStringValue)
		if dbLoad == nil then
			P('Error loading config from databank, resetting to default!')
			P(dbStringValue)
			P(err)
			this.databank.clearValue(this.dbDataKey)
		else
			this.config = dbLoad()
		end
	end

	function this:prepareForMigration()
		local migrationArk = {}
		for key,value in pairs(this.config) do
			local isDynamic = key:find(this.dynamicIndicator) ~= nil
			if isDynamic then
				migrationArk[key] = value
			end
		end
		this.migrationArk = migrationArk
	end

	function this:migrate()
		for key,value in pairs(this.migrationArk) do
			this.config[key] = value
		end
	end

	function this:cleanNonActives()
		for i, databank in pairs(this.databanks) do
			if databank ~= this.databank then
				databank.clearValue(this.dbActiveKey)
			end
		end
	end

	-- doesn't care about other types of databanks atm
	function this:cleanDb(databank)
		local keysOnDb = databank.getKeyList()
		for i, keyOnDb in ipairs(keysOnDb) do
			if keyOnDb ~= this.dbDataKey and keyOnDb ~= this.dbActiveKey then
				databank.clearValue(keyOnDb)
			end
		end
	end

	return this
end
)()