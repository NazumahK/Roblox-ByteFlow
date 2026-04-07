--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

local str: DataType<string> = table.freeze({
	__T = nil :: any,
	write = function(value: string)
		local len = #value
		local offset = ChannelState.allocate(2 + len)
		local buff = ChannelState.getActive().buff
		buffer.writeu16(buff, offset, len)
		buffer.writestring(buff, offset + 2, value)
	end,
	read = function(b: buffer, cursor: number): (string, number)
		local len = buffer.readu16(b, cursor)
		return buffer.readstring(b, cursor + 2, len), 2 + len
	end,
	length = nil,
})

return str
