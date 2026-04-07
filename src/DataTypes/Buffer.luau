--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

local buff: DataType<buffer> = table.freeze({
	__T = nil :: any,
	write = function(value: buffer)
		local len = buffer.len(value)
		local offset = ChannelState.allocate(4 + len)
		local activeBuff = ChannelState.getActive().buff
		buffer.writeu32(activeBuff, offset, len)
		buffer.copy(activeBuff, offset + 4, value, 0, len)
	end,
	read = function(b: buffer, cursor: number): (buffer, number)
		local len = buffer.readu32(b, cursor)
		local out = buffer.create(len)
		buffer.copy(out, 0, b, cursor + 4, len)
		return out, 4 + len
	end,
	length = nil,
})

return buff
