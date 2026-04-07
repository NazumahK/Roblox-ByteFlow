--!strict
--!optimize 2
--!native

--[=[
	@class NumericTypes
	
	Fixed-size numeric data type serializers.
	All types use little-endian byte order matching Luau's buffer API.
]=]

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Unsigned 8-bit integer (0 to 255). 1 byte.
]=]
local uint8: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(1)
		buffer.writeu8(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readu8(b, cursor), 1
	end,
	length = 1,
})

--[=[
	Unsigned 16-bit integer (0 to 65,535). 2 bytes.
]=]
local uint16: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(2)
		buffer.writeu16(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readu16(b, cursor), 2
	end,
	length = 2,
})

--[=[
	Unsigned 32-bit integer (0 to 4,294,967,295). 4 bytes.
]=]
local uint32: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(4)
		buffer.writeu32(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readu32(b, cursor), 4
	end,
	length = 4,
})

--[=[
	Signed 8-bit integer (-128 to 127). 1 byte.
]=]
local int8: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(1)
		buffer.writei8(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readi8(b, cursor), 1
	end,
	length = 1,
})

--[=[
	Signed 16-bit integer (-32,768 to 32,767). 2 bytes.
]=]
local int16: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(2)
		buffer.writei16(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readi16(b, cursor), 2
	end,
	length = 2,
})

--[=[
	Signed 32-bit integer (-2,147,483,648 to 2,147,483,647). 4 bytes.
]=]
local int32: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(4)
		buffer.writei32(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readi32(b, cursor), 4
	end,
	length = 4,
})

--[=[
	32-bit IEEE 754 floating point. 4 bytes.
]=]
local float32: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(4)
		buffer.writef32(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readf32(b, cursor), 4
	end,
	length = 4,
})

--[=[
	64-bit IEEE 754 floating point. 8 bytes.
]=]
local float64: DataType<number> = table.freeze({
	__T = nil :: any,
	write = function(value: number)
		local offset = ChannelState.allocate(8)
		buffer.writef64(ChannelState.getActive().buff, offset, value)
	end,
	read = function(b: buffer, cursor: number): (number, number)
		return buffer.readf64(b, cursor), 8
	end,
	length = 8,
})

return table.freeze({
	uint8 = uint8,
	uint16 = uint16,
	uint32 = uint32,
	int8 = int8,
	int16 = int16,
	int32 = int32,
	float32 = float32,
	float64 = float64,
})
