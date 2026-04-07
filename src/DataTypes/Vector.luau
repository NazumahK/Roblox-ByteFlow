--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Vector2 serializer. 8 bytes (2 x float32).
]=]
local vec2: DataType<Vector2> = table.freeze({
	__T = nil :: any,
	write = function(value: Vector2)
		local offset = ChannelState.allocate(8)
		local buff = ChannelState.getActive().buff
		buffer.writef32(buff, offset, value.X)
		buffer.writef32(buff, offset + 4, value.Y)
	end,
	read = function(b: buffer, cursor: number): (Vector2, number)
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		return Vector2.new(x, y), 8
	end,
	length = 8,
})

--[=[
	Vector3 serializer. 12 bytes (3 x float32).
]=]
local vec3: DataType<Vector3> = table.freeze({
	__T = nil :: any,
	write = function(value: Vector3)
		local offset = ChannelState.allocate(12)
		local buff = ChannelState.getActive().buff
		buffer.writef32(buff, offset, value.X)
		buffer.writef32(buff, offset + 4, value.Y)
		buffer.writef32(buff, offset + 8, value.Z)
	end,
	read = function(b: buffer, cursor: number): (Vector3, number)
		local x = buffer.readf32(b, cursor)
		local y = buffer.readf32(b, cursor + 4)
		local z = buffer.readf32(b, cursor + 8)
		return Vector3.new(x, y, z), 12
	end,
	length = 12,
})

return table.freeze({
	vec2 = vec2,
	vec3 = vec3,
})
