--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

local bool: DataType<boolean> = table.freeze({
	__T = nil :: any,
	_isBool = true,
	write = function(value: boolean)
		local offset = ChannelState.allocate(1)
		buffer.writeu8(ChannelState.getActive().buff, offset, if value then 1 else 0)
	end,
	read = function(b: buffer, cursor: number): (boolean, number)
		return buffer.readu8(b, cursor) ~= 0, 1
	end,
	length = 1,
})

return bool
