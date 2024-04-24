-- Table extensions
table = _G['table']

-- function table.copy(t)
-- 	local u = { }
-- 	if t == nil then
-- 		print("table.copy received NIL")
-- 		return u
-- 	end
-- 	for k,v in pairs(t) do
-- 		if type(v) == 'table' then
-- 			u[k] = table.copy(v)
-- 		else
-- 			u[k] = v
-- 		end
-- 	end
-- 	return setmetatable(u, getmetatable(t))
-- end

-- function table.deepcopy(orig)
--	 local orig_type = type(orig)
--	 local copy
--	 if orig_type == 'table' then
--		 copy = {}
--		 for orig_key, orig_value in pairs(orig) do
-- 			if orig_key ~= '__index' then
-- 				copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
-- 			end
--		 end
-- 		--if getmetatable(orig) ~= nil then print(getmetatable(orig), 2) end
-- 		--setmetatable(copy, table.deepcopy(getmetatable(orig)))
--	 else -- number, string, boolean, etc
--		 copy = orig
--	 end
--	 return copy
-- end

-- Add to a table
function table.add(target, source)
	if source == nil then return target end
	for k,v in pairs(source) do
		table.insert(target, v)
	end
	return target
end

-- Search for a needle in a haystack
function table.contains(needle, haystack, asKey)
	if asKey == nil then asKey = false end
	local found = false
	local foundValue = nil
	local foundKey = nil
	for k,h in pairs(haystack) do
		if type(h) == "table" then
			found = table.contains(needle, h)
			if found then break end
		elseif h == needle then
			found = true
			foundValue = h
			foundKey = k
			break
		end
	end
	return ternary(asKey, foundKey, found)
end

function table.find(needle, haystack)
	return table.contains(needle, haystack, true)
end

function table.keys(t)
	local keys = {}
	for k,_ in pairs(t) do
		table.insert(keys, k)
	end
	return keys
end

--local print=system.print
-- function table.count(t)
-- 	local c = 0
-- 	for _,v in pairs(t) do
-- 		c = c + 1
-- 	end
-- 	return c
-- end

-- function table.sum(t)
-- 	local sum = 0
-- 	for i,v in ipairs(t) do
-- 		sum = sum + v
-- 	end
-- 	return sum
-- end

-- function table.avg(t)
-- 	return table.sum(t) / #t
-- end

-- function table.join(left, right)
-- 	if type(left) == 'table' then
-- 		for key,val in pairs(right) do
-- 			if left[key] == nil then
-- 				if type(val) == 'table' then
-- 					if type(right[key]) == 'table' then left[key] = {} end
-- 					left[key] = table.join(left[key], right[key])
-- 				elseif right[key] ~= nil then
-- 					left[key] = right[key]
-- 				end
-- 			end
-- 		end
-- 	else
-- 		print('Error: table.join received ['..type(left)..'] instead of a table')
-- 		print(left)
-- 	end
-- 	return left
-- end

-- function table.max(t)
-- 	local max = -math.huge
-- 	for _,v in pairs(t) do
-- 		if v > max then max = v end
-- 	end
-- 	return max
-- end

-- function table.min(t)
-- 	local min = math.huge
-- 	for _,v in pairs(t) do
-- 		if v < min then min = v end
-- 	end
-- 	return min
-- end

function table.isArray(t)
  local i = 0
  for _ in pairs(t) do
	  i = i + 1
	  if t[i] == nil then return false end
  end
  return true
end