--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)

type DataType<T> = Types.DataType<T>

--[=[
	Creates a struct serializer from a descriptor table.
	Each key in the descriptor maps to the DataType for that field.
	Keys are sorted alphabetically for deterministic binary ordering.
]=]
local function struct<T>(descriptor: { [string]: DataType<any> }): DataType<T>
	local sortedKeys: { string } = {}
	local sortedTypes: { DataType<any> } = {}

	for key in descriptor do
		table.insert(sortedKeys, key)
	end
	table.sort(sortedKeys)

	for _, key in sortedKeys do
		table.insert(sortedTypes, descriptor[key])
	end

	local fieldCount = #sortedKeys

	local totalLength: number? = 0
	for _, dt in sortedTypes do
		local dtLength = dt.length
		if dtLength == nil then
			totalLength = nil
			break
		end
		totalLength = (totalLength :: number) + dtLength
	end

	return table.freeze({
		__T = nil :: any,
		write = function(value: any)
			for i = 1, fieldCount do
				sortedTypes[i].write(value[sortedKeys[i]])
			end
		end,
		read = function(b: buffer, cursor: number, refMap: { [number]: Instance }?): (any, number)
			local result: { [string]: any } = {}
			local totalRead = 0

			for i = 1, fieldCount do
				local v, bytesRead = sortedTypes[i].read(b, cursor + totalRead, refMap)
				result[sortedKeys[i]] = v
				totalRead += bytesRead
			end

			return result, totalRead
		end,
		length = totalLength,
	})
end

return struct
