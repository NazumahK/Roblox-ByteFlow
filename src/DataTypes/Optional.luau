--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Creates an optional serializer for the given inner DataType.
	Writes: 1 byte (0 = nil, 1 = present) + inner value if present.
	
	@param inner DataType<T>
	@return DataType<T?>
]=]
local function optional<T>(inner: DataType<T>): DataType<T?>
	return table.freeze({
		__T = nil :: any,
		write = function(value: T?)
			local offset = ChannelState.allocate(1)
			local buff = ChannelState.getActive().buff

			if value ~= nil then
				buffer.writeu8(buff, offset, 1)
				inner.write(value)
			else
				buffer.writeu8(buff, offset, 0)
			end
		end,
		read = function(b: buffer, cursor: number, refMap: { [number]: Instance }?): (T?, number)
			local present = buffer.readu8(b, cursor)

			if present ~= 0 then
				local value, bytesRead = inner.read(b, cursor + 1, refMap)
				return value, 1 + bytesRead
			end

			return nil, 1
		end,
		length = nil,
	})
end

return optional
