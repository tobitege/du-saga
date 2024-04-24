Coroutine = {
    func = nil,
    coroutine = nil
}

function Coroutine:new(func)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.func = func
    return o
end

function Coroutine:resume()
    local status = 'dead'
    if self.coroutine ~= nil then status = coroutine.status(self.coroutine) end
    if status == 'suspended' then
        coroutine.resume(self.coroutine)
    elseif status == 'dead' then
        self.coroutine = coroutine.create(self.func)
        coroutine.resume(self.coroutine)
    end
end