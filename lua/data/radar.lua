Radar = (
function()
	local this = {}

	this.contacts = {}
	this.contactsById = {}
	this.coroutines = {}
    this.radar = nil
    this.radars = {}
    this.panelId = nil
    this.widgetId = nil
    this.dataId = nil

    function this:init(radars)
        this.radars = radars
        --table.insert(this.coroutines, Coroutine:new(function() this:updateContactCounts() end))
        --table.insert(this.coroutines, Coroutine:new(function() this:scanForNewContacts() end))
        --table.insert(this.coroutines, Coroutine:new(function() this:updateContacts() end))
        --table.insert(this.coroutines, Coroutine:new(function() this:updateNearestContacts(ContactTypeENUM.abandoned, 10) end))
        --table.insert(this.coroutines, Coroutine:new(function() this:updateNearestContacts(ContactTypeENUM.dynamic, 10) end))
        --table.insert(this.coroutines, Coroutine:new(function() this:updateNearestContacts(ContactTypeENUM.static, 10) end))
        this:updateActiveRadar()

        Config.defaults[configDatabankMap.radarBoxes] = true
        Config.defaults[configDatabankMap.radarWidget] = radarOn

        this.contactCounts = {
            [ContactTypeENUM.abandoned] = 0,
            [ContactTypeENUM.dynamic] = 0,
            [ContactTypeENUM.static] = 0,
        }

        this.nearestContacts = {
            [ContactTypeENUM.abandoned] = {},
            [ContactTypeENUM.dynamic] = {},
            [ContactTypeENUM.static] = {},
        }

        this.radarTestList = {}
        this.radarDynamic = {}
        this.radarSpace = {}
        this.radarStatic = {}
        this.radarAbandoned = {}
        this.radarFriend = {}
        this.radarAlien = {}

        EventSystem:register('ConfigDBChanged', this.applyConfig, this)
        this:applyConfig()
    end

    function this:applyConfig()
        this:toggleBoxes(Config:getValue(configDatabankMap.radarBoxes))
        this:toggleWidget(Config:getValue(configDatabankMap.radarWidget))
    end

    function this:update()
        if this.boxesVisible then
            for i,radarCoroutine in ipairs(this.coroutines) do
                radarCoroutine:resume()
            end
        end
        this:radarConstructsTest()
        this:updateActiveRadar()
    end

    function this:updateActiveRadar()
        if this.radar ~= nil then
            if this.radar.getOperationalState() == 1 then return
            else this.radar = nil end
        end
        for i,radar in pairs(this.radars) do
            if radar.getOperationalState() == 1 and radar ~= this.radar then
                this.radar = radar
                --P('Active radar switched to ' .. radar.slotName)
                if this.widgetId ~= nil then
                    system.removeDataFromWidget(this.dataId, this.widgetId)
                    this.dataId = this.radar.getWidgetDataId()
                    system.addDataToWidget(this.dataId, this.widgetId)
                end
            end
        end
    end

    function this:toggleBoxes(state)
        if state == nil then state = not this.boxesVisible end
        this.boxesVisible = state
        Config:setValue(configDatabankMap.radarBoxes, this.boxesVisible)
    end

    function this:toggleWidget(state)
        if this.radar == nil then return end
        if state == nil then state = this.widgetId == nil end
        -- Destroy existing widget
        if this.widgetId ~= nil then
            system.destroyWidget(this.widgetId)
            system.destroyWidgetPanel(this.panelId)
            this.widgetId = nil
        end
        -- Create a new one
        if state then
            this.panelId = system.createWidgetPanel("RADAR")
            this.widgetId = system.createWidget(this.panelId, "radar")
            this.dataId = this.radar.getWidgetDataId()
            system.addDataToWidget(this.dataId, this.widgetId)
        end
        Config:setValue(configDatabankMap.radarWidget, state)
    end

    function this:radarConstructsTest()
        if this.radar == nil then return end   --(Offset,count,filter,matching,kind,size,abandoned)
        this.radarTestList = this.radar.getConstructs(0,1,nil,nil,nil,nil,nil)
        this.radarDynamic = this.radar.getConstructs(0,0,{['constructKind'] = 5})
        this.radarSpace = this.radar.getConstructs(0,0,{['constructKind'] = 6})
        this.radarStatic = this.radar.getConstructs(0,0,{['constructKind'] = 4})
        this.radarAbandoned = this.radar.getConstructs(0,0,{['isAbandoned'] = true})
        this.radarFriend = this.radar.getConstructs(0,0,{['isMatching'] = true})
        this.radarAlien = this.radar.getConstructs(0,0,{['constructKind'] = 7})
    end

    -- Ran as a coroutine
    function this:scanForNewContacts()
        if this.radar == nil then return end

        -- Scan for new contacts
        local contactIds = this.radar.getConstructIds()
        local newContacts = 0
        if #contactIds > 2500 then return end
        for i,contactId in ipairs(contactIds) do
            if this.contactsById[contactId] == nil then
                local contact = {}
                contact.id = contactId
                contact.name = this.radar.getConstructName(contactId)
                contact.size = this.radar.getConstructSize(contactId)
                contact.kind = this.radar.getConstructKind(contactId)
                contact.distance = this.radar.getConstructDistance(contactId)
                contact.coreSize = this.radar.getConstructCoreSize(contactId)
                contact.isAbandoned = this.radar.isConstructAbandoned(contactId) == 1
                contact.getThreatRateFrom = this.radar.getThreatRateFrom(contactId)
                this.contacts[#this.contacts+1] = contact
                this.contactsById[contact.id] = contact
                newContacts = newContacts + 1
                if newContacts % 10 == 0 then coroutine.yield() end
            end
            if i % 50 == 0 then coroutine.yield() end
        end
    end
    --[[
    function this:updateContacts()
        -- Update existing contacts
        for i,contact in ipairs(this.contacts) do
            if i % 25 == 0 then coroutine.yield() end
            local distanceToContact = this.radar.getConstructDistance(contact.id)
            if distanceToContact > 0 then
                contact.distance = distanceToContact
                contact.getThreatRateFrom = this.radar.getThreatRateFrom(contact.id)
            else
                this.contactsById[contact.id] = nil
                table.remove(this.contacts, i)
            end
        end
        coroutine.yield()
        table.sort(this.contacts, function(a,b) return a.distance < b.distance end)
    end
    ]]
--[[
    function this:updateNearestContacts(contactType, limit)
        if contactType == nil then return 'No contact type supplied' end
        if limit == nil then limit = 10 end
        local selectedContacts = {}
        for i,contact in ipairs(this.contacts) do
            if i % 25 == 0 then coroutine.yield() end
            local filterPassed = false
            if contactType == ContactTypeENUM.abandoned and contact.isAbandoned then filterPassed = true
            elseif contactType == ContactTypeENUM.dynamic and (contact.kind == 5) then filterPassed = true
            elseif contactType == ContactTypeENUM.static and (contact.kind == 4 or contact.kind == 6 or contact.kind == 7) then filterPassed = true
            end

            if filterPassed then
                table.insert(selectedContacts, contact)
                if #selectedContacts >= limit then break end
            end
        end


        this.nearestContacts[contactType] = selectedContacts
    end
    ]]
--[[
    function this:updateContactCounts()
        local contactCounts = {
            [ContactTypeENUM.abandoned] = 0,
            [ContactTypeENUM.dynamic] = 0,
            [ContactTypeENUM.static] = 0,
        }
        for i,contact in ipairs(this.contacts) do
            if i % 50 == 0 then coroutine.yield() end

            local contactType = nil
            if contact.isAbandoned then contactType = ContactTypeENUM.abandoned
            elseif contact.kind == 5 then contactType = ContactTypeENUM.dynamic
            elseif contact.kind == 4 or contact.kind == 6 or contact.kind == 7 then contactType = ContactTypeENUM.static
            end

            if contactType ~= nil then
                contactCounts[contactType] = contactCounts[contactType] + 1
            end
        end
        this.contactCounts = contactCounts
    end
    ]]

	return this
end
)()

-- Ended up being kind of unnecessary, only used for getContactsOfType
ContactTypeENUM = {
    static = 'static',
    dynamic = 'dynamic',
    abandoned = 'abandoned'
}