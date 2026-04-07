--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Creates an array serializer for the given element DataType.
	
	@param element DataType<T>
	@return DataType<{T}>
]=]
local function array<T>(element: DataType<T>): DataType<{ T }>
	return table.freeze({
		__T = nil :: any,
		write = function(value: { T })
			local count = #value
			local offset = ChannelState.allocate(2)
			buffer.writeu16(ChannelState.getActive().buff, offset, count)

			for i = 1, count do
				element.write(value[i])
			end
		end,
		read = function(b: buffer, cursor: number, refMap: { [number]: Instance }?): ({ T }, number)
			local count = buffer.readu16(b, cursor)
			local totalRead = 2
			local result: { T } = table.create(count) :: any

			for i = 1, count do
				local value, bytesRead = element.read(b, cursor + totalRead, refMap)
				result[i] = value
				totalRead += bytesRead
			end

			return result, totalRead
		end,
		length = nil,
	})
end

return array
