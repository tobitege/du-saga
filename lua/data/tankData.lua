tankData = {
	-- Atmo XS
	["34191163"] = 130,
	["590217537"] = 170,
	["590217536"] = 220,
	["590217543"] = 290,

	-- Atmo S
	["3510956948"] = 520,
	["4068567109"] = 680,
	["4068567110"] = 880,
	["4068567111"] = 1140,

	-- Atmo M
	["103319202"] = 2080,
	["801882806"] = 2700,
	["801882807"] = 3510,
	["801882804"] = 4560,

	-- Atmo L
	["681896062"] = 16640,
	["4181605365"] = 21632,
	["4181605362"] = 28120,
	["4181605363"] = 36560,

	-- Rocket
	["1663412227"] = 400,
	["3126840739"] = 800,
	["2477859329"] = 6400,
	["4180073139"] = 50000,

	-- Space XS
	["2723679405"] = 130,
	["4270367994"] = 170,
	["4270367989"] = 220,
	["4270367988"] = 290,

	-- Space S
	["3660622849"] = 520,
	["3135113517"] = 680,
	["3135113516"] = 880,
	["3135113519"] = 1140,

	-- Space M
	["2717114417"] = 2080,
	["3797917193"] = 2700,
	["3797917192"] = 3510,
	["3797917195"] = 4560,

	-- Space L
	["1567224122"] = 16640,
	["1298642304"] = 21632,
	["1298642305"] = 28120,
	["1298642310"] = 36560,

	-- Default By size
	["xs"] = 100,
	["s"] = 400,
	["m"] = 1600,
	["l"] = 12800,
}
local fuelmodifiers = {
    ["2078334942"] = 0.9,
    ["2216300178"] = 0.9,
    ["2199218873"] = 0.9,
    ["2268129307"] = 0.9,
    ["4106743733"] = 0.9,
    ["637265250"] = 0.9,
    ["3580444026"] = 0.9,
    ["319251893"] = 0.9,
    ["3464984253"] = 0.81,
    ["1104915586"] = 0.81,
    ["121825379"] = 0.81,
    ["185422505"] = 0.81,
    ["4188179628"] = 0.81,
    ["55848614"] = 0.81,
    ["4169669296"] = 0.81,
    ["2010490156"] = 0.81,
    ["3464984250"] = 0.729,
    ["1104915587"] = 0.729,
    ["121825378"] = 0.729,
    ["185422504"] = 0.729,
    ["4188179631"] = 0.729,
    ["55848615"] = 0.729,
    ["4169669297"] = 0.729,
    ["2010490159"] = 0.729,
    ["3464984251"] = 0.6561,
    ["1104915584"] = 0.6561,
    ["121825381"] = 0.6561,
    ["185422511"] = 0.6561,
    ["4188179630"] = 0.6561,
    ["55848612"] = 0.6561,
    ["4169669302"] = 0.6561,
    ["2010490158"] = 0.6561,
}

function initializeTanks()
	local tankData = tankData
	local fuelWeightMod = (((100 - (5 * fuelTankOptimization)) / 100)) - 1
	local contWeightMod = (((100 - (5 * containerOptimization)) / 100)) - 1
	fuelWeights = {
		['atmo'] = (4 - (4 * (math.abs(fuelWeightMod) + math.abs(contWeightMod)))),
		['space'] = (6 - (6 * (math.abs(fuelWeightMod) + math.abs(contWeightMod)))),
		['rocket'] = (0.8 - (0.8 * (math.abs(fuelWeightMod) + math.abs(contWeightMod))))
	}

	local curTime = system.getArkTime()
	local isInClass = system.isItemInClass
	local function GetMaxVolume(itemId, size)
		return tankData[itemId .. ""] or tankData[size .. ""] or 0
	end
	local function GetFuelTankModifier(itemId)
		return fuelmodifiers[itemId .. ""] or 1
	end
	local replacements = {
		{ "Optimized",   "Opt." },
		{ "Uncommon",    "Unc." },
		{ "Advanced",    "Adv." },
		{ "Exotic",      "Exo." },
		{ "Atmospheric", "Atmo." },
	}

	fuels = {
		['atmo'] = {},
		['space'] = {},
		['rocket'] = {}
	}

	elemIDs = links.core.getElementIdList()
	for i = 1, #elemIDs, 1 do
		local item = system.getItem(links.core.getElementItemIdById(elemIDs[i]))
		if isInClass(item.id, "FuelContainer") then
			elem = {
				uid = elemIDs[i],
				uMass = item.unitMass,
				name = links.core.getElementNameById(elemIDs[i]),
				mass = links.core.getElementMassById(elemIDs[i]) - item.unitMass,
				percent = 0,
				lastMass = 0,
				timeLeft = 0,
				lastTimeLeft = 0,
				lastTime = curTime
			}
			if isInClass(item.id, "AtmoFuelContainer") then
				elem.tankType = "atmo"
				elem.maxMass = GetMaxVolume(item.id, item.size) * (1 + (0.2 * atmoTankHandling)) * fuelWeights['atmo'] * GetFuelTankModifier(item.id)
				table.insert(fuels['atmo'], elem)
			elseif isInClass(item.id, "RocketFuelContainer") then
				elem.tankType = "rocket"
				elem.maxMass = GetMaxVolume(item.id, item.size) * (1 + (0.1 * rocketTankHandling)) * fuelWeights['rocket'] * GetFuelTankModifier(item.id)
				table.insert(fuels['rocket'], elem)
			elseif isInClass(item.id, "SpaceFuelContainer") then
				elem.tankType = "space"
				elem.maxMass = GetMaxVolume(item.id, item.size) * (1 + (0.2 * spaceTankHandling)) * fuelWeights['space'] * GetFuelTankModifier(item.id)
				table.insert(fuels['space'], elem)
			end
			local ri = 1
			while ri <= #replacements and elem.name:len() > 30 do
				elem.name = elem.name:gsub(replacements[ri][1], replacements[ri][2])
				ri = ri + 1
			end
		end
	end
end

function updateTanks()
	local tankData, curTime, ii = tankData, system.getArkTime(), 0
	for key, list in pairs(fuels) do
		for _, tank in ipairs(list) do
			tank.name = tank.name
			tank.mass = links.core.getElementMassById(tank.uid) - tank.uMass
			if tank.mass ~= tank.lastMass then
				tank.percent = utils.round((tank.mass / tank.maxMass) * 100, 0.1)
				tank.lastTimeLeft = tank.timeLeft
				tank.timeLeft = math.floor(tank.mass / ((tank.lastMass - tank.mass) / (curTime - tank.lastTime)))
				tank.lastTime = curTime
			end
			tank.lastMass = tank.mass
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
