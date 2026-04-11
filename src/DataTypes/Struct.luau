--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

-- Internally represented as an "OpCode" list to minimize branches during hot path
type Op = {
	key: string?,
	dt: DataType<any>?,
	isBits: boolean,
	bitKeys: { string }?, -- for bit groups
}

local function struct<T>(descriptor: { [string]: any }): DataType<T>
	local sortedKeys: { string } = {}
	for key in descriptor do
		table.insert(sortedKeys, key)
	end
	table.sort(sortedKeys)

	local ops: { Op } = {}
	local i = 1
	while i <= #sortedKeys do
		local key = sortedKeys[i]
		local dt = descriptor[key]

		-- Check for consecutive bools to apply bit-packing optimization
		if dt._isBool then
			local bitKeys = { key }
			local j = i + 1
			-- Group up to 8 bools into a single byte
			while j <= #sortedKeys and j < i + 8 do
				local nextKey = sortedKeys[j]
				local nextDt = descriptor[nextKey]
				if nextDt._isBool then
					table.insert(bitKeys, nextKey)
					j += 1
				else
					break
				end
			end

			if #bitKeys > 1 then
				-- Multiple bools found, pack them!
				table.insert(ops, {
					isBits = true,
					bitKeys = bitKeys,
				})
				i = j
				continue
			end
		end

		-- Standard field (or single bool)
		table.insert(ops, {
			key = key,
			dt = dt,
			isBits = false,
		})
		i += 1
	end

	local opCount = #ops

	-- Pre-calculate fixed length if possible
	local totalLength: number? = 0
	for _, op in ops do
		if op.isBits then
			totalLength = (totalLength :: number) + 1
		else
			local dtLen = (op.dt :: any).length
			if dtLen == nil then
				totalLength = nil
				break
			end
			totalLength = (totalLength :: number) + dtLen
		end
	end

	return table.freeze({
		__T = nil :: any,
		write = function(value: any)
			for idx = 1, opCount do
				local op = ops[idx]
				if op.isBits then
					local bitKeys = op.bitKeys :: { string }
					local packed = 0
					for b = 1, #bitKeys do
						if value[bitKeys[b]] then
							packed = bit32.bor(packed, bit32.lshift(1, b - 1))
						end
					end
					local offset = ChannelState.allocate(1)
					buffer.writeu8(ChannelState.getActive().buff, offset, packed)
				else
					(op.dt :: any).write(value[op.key :: string])
				end
			end
		end,
		read = function(b: buffer, cursor: number, refMap: { [number]: Instance }?): (any, number)
			local result: { [string]: any } = {}
			local totalRead = 0

			for idx = 1, opCount do
				local op = ops[idx]
				if op.isBits then
					local bitKeys = op.bitKeys :: { string }
					local packed = buffer.readu8(b, cursor + totalRead)
					totalRead += 1
					for v = 1, #bitKeys do
						result[bitKeys[v]] = bit32.band(packed, bit32.lshift(1, v - 1)) ~= 0
					end
				else
					local v, bytesRead = (op.dt :: any).read(b, cursor + totalRead, refMap)
					result[op.key :: string] = v
					totalRead += bytesRead
				end
			end

			return result, totalRead
		end,
		length = totalLength,
	})
end

return struct
