--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Creates a map serializer for the given key and value DataTypes.
	
	@param key DataType<K>
	@param value DataType<V>
	@return DataType<{[K]: V}>
]=]
local function map<K, V>(key: DataType<K>, value: DataType<V>): DataType<{ [K]: V }>
	return table.freeze({
		__T = nil :: any,
		write = function(data: { [K]: V })
			-- Count entries first
			local count = 0
			for _ in data do
				count += 1
			end

			local offset = ChannelState.allocate(2)
			buffer.writeu16(ChannelState.getActive().buff, offset, count)

			for k, v in data do
				key.write(k)
				value.write(v)
			end
		end,
		read = function(b: buffer, cursor: number, refMap: { [number]: Instance }?): ({ [K]: V }, number)
			local count = buffer.readu16(b, cursor)
			local totalRead = 2
			local result: { [K]: V } = {}

			for _ = 1, count do
				local k, kBytes = key.read(b, cursor + totalRead, refMap)
				totalRead += kBytes
				local v, vBytes = value.read(b, cursor + totalRead, refMap)
				totalRead += vBytes
				result[k] = v
			end

			return result, totalRead
		end,
		length = nil,
	})
end

return map
