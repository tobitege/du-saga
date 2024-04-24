Electronics = (
function()
    local this = {}

    this.doors = {}
    this.forcefields = {}
    this.switches = {}
    this.queue = {}

    function this:update(state, elements)
        while #this.queue > 0 do
            table.remove(this.queue)()
        end
    end

    function this:SetElement(state, elements)
        if state == nil then state = true end
        for _,element in pairs(elements) do
            if state then
                element.deactivate()
                table.insert(this.queue, element.activate)
            else
                element.activate()
                table.insert(this.queue, element.deactivate)
            end
        end
    end

    function this:OpenDoors() this:SetElement(true, this.doors) end
    function this:CloseDoors() this:SetElement(false, this.doors) end

    function this:ForcefieldsOn() this:SetElement(true, this.forcefields) end
    function this:ForcefieldsOff() this:SetElement(false, this.forcefields) end

    function this:SwitchesOn() this:SetElement(true, this.switches) end
    function this:SwitchesOff() this:SetElement(false, this.switches) end

    return this
end
)()