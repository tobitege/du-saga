tankData = {
	fuelStr = 'Loading',
	-- below values are mass (kg), capacity (L) with 0 talents:
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
	local fw = 1 - (math.abs(fuelWeightMod) + math.abs(contWeightMod))
	fuelWeights = { ['atmo'] = 4*fw, ['space'] = 6*fw, ['rocket'] = 0.8*fw }

	local curTime = system.getArkTime()

	fuels = {
		['atmo'] = {},
		['space'] = {},
		['rocket'] = {}
	}

	local handling = { atmo = atmoTankHandling, space = spaceTankHandling, rocket = rocketTankHandling }
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
				elem.lastTime = curTime
				elem.maxMass = tankData.sizes[elem.tankType][elem.size][2] * (1 + (0.2 * handling[elem.tankType])) * fuelWeights[elem.tankType]
				table.insert(fuels[elem.tankType], elem)
			else
				P("Unknown tank size for ["..(elem.kind).."] ["..(elem.maxHp).."]")
			end
		end
	end
end

function updateTanks()
	local tankData, curTime, ii = tankData, system.getArkTime(), 0
	for key, list in pairs(fuels) do
		for _, tank in ipairs(list) do
		   	tank.lastMass = tank.mass
		   	tank.mass = links.core.getElementMassById(tank.uid) - tankData.sizes[key][tank.size][1]
		   	if tank.mass ~= tank.lastMass then
			  	tank.percent = utils.round((tank.mass / tank.maxMass)*100,0.1)
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