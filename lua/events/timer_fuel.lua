function onTimerFuelUpdate()
    local curTime = system.getArkTime()
    for _, list in pairs(fuels) do
        for _, tank in ipairs(list) do
            tank.lastMass = tank.mass
            tank.mass = links.core.getElementMassById(tank.uid) - tank.uMass
            if tank.mass ~= tank.lastMass then
                tank.percent = round2((tank.mass / tank.maxMass)*100,2)
                tank.lastTimeLeft = tank.timeLeft
                tank.timeLeft = math.floor(tank.mass / ((tank.lastMass - tank.mass) / (curTime - tank.lastTime)))
                tank.lastTime = curTime;
            end
        end
    end
end