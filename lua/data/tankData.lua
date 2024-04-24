tankData = {
	fuelStr = 'Loading',
	sizes = {
		['atmo'] = {
			['xs'] = {35.03,100},
			['s'] = {182.67,400},
			['m'] = {988.67,1600},
			['l'] = {5480,12800}
		},
		['space'] = {
			['xs'] = {35.03,100},
			['s'] = {182.67,400},
			['m'] = {988.67,1600},
			['l'] = {5480,12800}
		},
		['rocket'] = {
			['xs'] = {173.42,400},
			['s'] = {886.72,800},
			['m'] = {4720,6400},
			['l'] = {25740,50000}
		}
	},

	maxHps = {
		['atmo'] = {
			['xs'] = 50,
			['s'] = 163,
			['m'] = 1315,
			['l'] = 10461,
		},
		['space'] = {
			['xs'] = 50, -- must check this
			['s'] = 187,
			['m'] = 1496,
			['l'] = 15933,
		},
		['rocket'] = {
			['xs'] = 366,
			['s'] = 736,
			['m'] = 6231,
			['l'] = 68824,
		},
	},

	types = { -- Helps map the element class to the correct tank data above
		['atmospheric fuel tank'] = 'atmo',
		['space fuel tank'] = 'space',
		['rocket fuel tank'] = 'rocket',
	}
}

function initializeTanks()
	local tankData = tankData
	local fuelWeightMod = (((100-(5*fuelTankOptimization))/100))-1
	local contWeightMod = (((100-(5*containerOptimization))/100))-1
	fuelWeights = {
		['atmo'] = (4 - (4 * (math.abs(fuelWeightMod) + math.abs(contWeightMod)))),
		['space'] = (6 - (6 * (math.abs(fuelWeightMod) + math.abs(contWeightMod)))),
		['rocket'] = (0.8 - (0.8 * (math.abs(fuelWeightMod) + math.abs(contWeightMod))))
	}

	local curTime = system.getArkTime()

	fuels = {
		['atmo'] = {},
		['space'] = {},
		['rocket'] = {}
	}

	elemIDs = links.core.getElementIdList()
	for i=1,#elemIDs,1 do
		elem = {
			uid = elemIDs[i],
			name = links.core.getElementNameById(elemIDs[i]),
			kind = links.core.getElementDisplayNameById(elemIDs[i]),
			mass = links.core.getElementMassById(elemIDs[i]),
			maxHp = links.core.getElementMaxHitPointsById(elemIDs[i]),
		}
		elem.tankType = tankData.types[elem.kind:lower()]
		if elem.tankType ~= nil then

			if elem.maxHp >= tankData.maxHps[elem.tankType]['l'] then elem.size = 'l'
			elseif elem.maxHp >= tankData.maxHps[elem.tankType]['m'] then elem.size = 'm'
			elseif elem.maxHp >= tankData.maxHps[elem.tankType]['s'] then elem.size = 's'
			elseif elem.maxHp >= tankData.maxHps[elem.tankType]['xs'] then elem.size = 'xs'
			end

			if elem.size then
				elem.percent = 0
				elem.lastMass = 1
				elem.timeLeft = 0
				elem.lastTimeLeft = 0
				if elem.tankType == 'atmo' then
					elem.lastTime = curTime;
					elem.maxMass = tankData.sizes['atmo'][elem.size][2] * (1 + (0.2 * atmoTankHandling)) * fuelWeights['atmo']
					table.insert(fuels['atmo'], elem)
				elseif(elem.tankType == 'space') then
					elem.lastTime = curTime
					elem.maxMass = tankData.sizes['space'][elem.size][2] * (1 + (0.2 * spaceTankHandling)) * fuelWeights['space']
					table.insert(fuels['space'], elem)
					--P( elem.size:upper()..": max mass: "..elem.maxMass )
				elseif(elem.tankType == 'rocket') then
					elem.lastTime = curTime;
					elem.maxMass = tankData.sizes['rocket'][elem.size][2] * (1 + (0.2 * rocketTankHandling)) * fuelWeights['rocket']
					table.insert(fuels['rocket'], elem)
				end
			else
				P("Could not determine tank size for ["..(elem.kind).."] ["..(elem.maxHp).."]")
			end
		end
	end
	--P(tostring(elem.kind))
end

function updateTanks()
	local tankData = tankData
	local curTime = system.getArkTime()
	local ii = 0
	for key, list in pairs(fuels) do
		for _, tank in ipairs(list) do
			tank.name = tank.name
		   	tank.lastMass = tank.mass
		   	tank.mass = links.core.getElementMassById(tank.uid) - tankData.sizes[key][tank.size][1]
		   	if(tank.mass ~= tank.lastMass) then
			  	tank.percent = utils.round((tank.mass / tank.maxMass)*100,0.1)
			   	tank.lastTimeLeft = tank.timeLeft
			 	tank.timeLeft = math.floor(tank.mass / ((tank.lastMass - tank.mass) / (curTime - tank.lastTime)))
			   	tank.lastTime = curTime
		   	end
			ii = ii + 1
			if ii > 5 then
				coroutine.yield()
			end
		end
	end
end

function updateTanksCo()
	local cont = coroutine.status(updTankCo)
	if cont == "dead" then
		updTankCo = coroutine.create(updateTanks)
	end
	coroutine.resume(updTankCo)
end
updTankCo = coroutine.create(updateTanks)