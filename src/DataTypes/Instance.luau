--!strict
--!optimize 2

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

local inst: DataType<Instance> = table.freeze({
	__T = nil :: any,
	write = function(value: Instance)
		local refId = ChannelState.addReference(value)
		local offset = ChannelState.allocate(4)
		buffer.writeu32(ChannelState.getActive().buff, offset, refId)
	end,
	read = function(b: buffer, cursor: number, refMap: { [number]: Instance }?): (Instance, number)
		local refId = buffer.readu32(b, cursor)
		local resolved = if refMap then refMap[refId] else nil
		return resolved :: any, 4
	end,
	length = 4,
})

return inst
