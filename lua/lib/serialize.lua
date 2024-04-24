function serialize(v)
	if type(v) == 'table' then -- it's a table
		local tableString = '{'
		if table.isArray(v) then -- it's an array
			for k,v in ipairs(v) do
				tableString = tableString .. serializeValue(v) .. ','
			end
		else -- hashtable
			local tbl = {}
			for k,v in pairs(v) do
				--if type(k) == 'string' then k = '"' .. k .. '"' end
				table.insert(tbl, k .. '=' .. serializeValue(v))
			end
			tableString = tableString .. table.concat(tbl, ',')
		end
		tableString = tableString .. '}'
		return tableString
	else
		return serializeValue(v)
	end
end

function serializeValue(v)
	if v == nil then
		return 'nil'
	elseif type(v) == 'table' then
		return serialize(v)
	elseif type(v) == 'string' then
		return '"' .. v:format("%q") .. '"'
	elseif type(v) == 'number' then
		return v
	elseif type(v) == 'boolean' then
		return ternary(v, 'true', 'false')
	end
end