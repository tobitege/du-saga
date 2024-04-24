radarWidgetTemplate = {
	class = 'radar',
	anchor = anchorENUM.bottom,
	width = 280
}
--[[
Widgets.radarAbandoned = Widget:new{ class = radarWidgetTemplate.class, anchor = radarWidgetTemplate.anchor, width = radarWidgetTemplate.width }
function Widgets.radarAbandoned:build()
	return buildContactList(self, 'Abandoned', ContactTypeENUM.abandoned)
end

Widgets.radarStatic = Widget:new{ class = radarWidgetTemplate.class, anchor = radarWidgetTemplate.anchor, width = radarWidgetTemplate.width }
function Widgets.radarStatic:build()
	return buildContactList(self, 'Static', ContactTypeENUM.static)
end

Widgets.radarDynamic = Widget:new{ class = radarWidgetTemplate.class, anchor = radarWidgetTemplate.anchor, width = radarWidgetTemplate.width }
function Widgets.radarDynamic:build()
	return buildContactList(self, 'Dynamic', ContactTypeENUM.dynamic)
end

Widgets.radarTest = Widget:new{ class = radarWidgetTemplate.class, anchor = radarWidgetTemplate.anchor, width = radarWidgetTemplate.width }
function Widgets.radarTest:build()
	return buildContactListTest(self, 'Test', Radar.radarTestList)
end
]]
local function getWidget()
    return Widget:new{ class = radarWidgetTemplate.class, anchor = radarWidgetTemplate.anchor, width = radarWidgetTemplate.width }
end

Widgets.radarDynamic = getWidget()
function Widgets.radarDynamic:build()
	return buildContactListTest(self, 'Dynamic', Radar.radarDynamic)
end
Widgets.radarStatic = getWidget()
function Widgets.radarStatic:build()
	return buildContactListTest(self, 'Static', Radar.radarStatic)
end
Widgets.radarAbandoned = getWidget()
function Widgets.radarAbandoned:build()
	return buildContactListTest(self, 'Abandoned', Radar.radarAbandoned, true)
end
Widgets.radarAlien = getWidget()
function Widgets.radarAlien:build()
	return buildContactListTest(self, 'Alien', Radar.radarAlien)
end
Widgets.radarSpace = getWidget()
function Widgets.radarSpace:build()
	return buildContactListTest(self, 'Space', Radar.radarSpace)
end
Widgets.radarFriend = getWidget()
function Widgets.radarFriend:build()
	return buildContactListTest(self, 'Friend', Radar.radarFriend)
end
Widgets.radarThreat = getWidget()
function Widgets.radarThreat:build()
	return buildContactListTest(self, 'Threat', Radar.radarDynamic)
end

function buildContactListTest(self, headerText, contactList, doPrint)
	local rType = headerText
	local contacts = contactList
	self.rowCount = #contacts + 1
	local count = 0

	local strings = {}
	strings[#strings+1] = headerText .. ' - ' .. #contacts
	for i,contact in ipairs(contacts) do
		if rType == 'Threat' then
			if contacts[i]['targetThreatState'] == 0 then
				goto continue
			end
		end

		local nameText = contact['constructId'] .. ' [' .. contact['size'] .. '] ' .. contact['name']
        if doPrint == true then ---@TODO output coords (needs trilateration!)
            --P(nameText)
        end
		strings[#strings+1] = '<div class="radarRow">'
		strings[#strings+1] = '<div class="radarText" style="left: 0.5vh; width: 5vh;">' .. contact['constructId'] .. '</div>'
		strings[#strings+1] = '<div class="radarText" style="left: 5.5vh; width: 2.5vh;">[' .. contact['size'] .. ']</div>'
		strings[#strings+1] = '<div class="radarText" style="left: 8vh; width: 15vh;">' .. contact['name'] .. '</div>'
		strings[#strings+1] = '<div class="radarText" style="right: 0.5vh;">' .. thousands(math.ceil(contact['distance'])) .. '</div>'
		strings[#strings+1] = '</div>'
		count = count + 1
		if count >= 10 then
			break
		end
		::continue::
	end
	self.visible = count > 0
	return table.concat(strings, '')
end

-- function buildContactList(self, headerText, contactType)
-- 	local contacts = Radar.nearestContacts[contactType]
-- 	self.visible = #contacts > 0
-- 	self.rowCount = #contacts + 1

-- 	local strings = {}
-- 	strings[#strings+1] = headerText .. ' - ' .. Radar.contactCounts[contactType]
-- 	for i,contact in ipairs(contacts) do
-- 		local nameText = contact.id .. ' [' .. contact.coreSize .. '] ' .. contact.name
-- 		strings[#strings+1] = '<div class="radarRow">'
-- 		strings[#strings+1] = '<div class="radarText" style="left: 0.5vh; width: 5vh;">' .. contact.id .. '</div>'
-- 		strings[#strings+1] = '<div class="radarText" style="left: 5.5vh; width: 2.5vh;">[' .. contact.coreSize .. ']</div>'
-- 		strings[#strings+1] = '<div class="radarText" style="left: 8vh; width: 15vh;">' .. contact.name .. '</div>'
-- 		strings[#strings+1] = '<div class="radarText" style="right: 0.5vh;">' .. thousands(math.ceil(contact.distance)) .. '</div>'
-- 		strings[#strings+1] = '</div>'
-- 	end
-- 	return table.concat(strings, '')
-- end