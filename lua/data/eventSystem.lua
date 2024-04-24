EventSystem = (
function()
	local this = {}
	this.events = {}
	function this:register(eventName, func, arg)
		if this.events[eventName] == nil then this.events[eventName] = {} end
		table.insert(this.events[eventName], { func = func, arg = arg })
	end
	function this:trigger(eventName)
		if this.events[eventName] ~= nil then
			for _,event in ipairs(this.events[eventName]) do
				event.func(event.arg)
			end
		end
	end
	return this
end
)()