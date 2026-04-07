--!strict
--!optimize 2
--!native

--[=[
	@class ColorTypes
	
	Color value type serializers:
	Color3, Color3uint8 (compact), BrickColor.
]=]

local Types = require(script.Parent.Parent.Types)
local CS = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Color3 (full precision). 12 bytes (3 x float32).
]=]
local color3: DataType<Color3> = table.freeze({
	__T = nil :: any,
	write = function(v: Color3)
		local o = CS.allocate(12)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.R)
		buffer.writef32(b, o + 4, v.G)
		buffer.writef32(b, o + 8, v.B)
	end,
	read = function(b: buffer, c: number): (Color3, number)
		return Color3.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8)), 12
	end,
	length = 12,
})

--[=[
	Color3 compact (8-bit per channel). 3 bytes (3 x uint8).
]=]
local color3uint8: DataType<Color3> = table.freeze({
	__T = nil :: any,
	write = function(v: Color3)
		local o = CS.allocate(3)
		local b = CS.getActive().buff
		buffer.writeu8(b, o, math.floor(v.R * 255 + 0.5))
		buffer.writeu8(b, o + 1, math.floor(v.G * 255 + 0.5))
		buffer.writeu8(b, o + 2, math.floor(v.B * 255 + 0.5))
	end,
	read = function(b: buffer, c: number): (Color3, number)
		return Color3.fromRGB(buffer.readu8(b, c), buffer.readu8(b, c + 1), buffer.readu8(b, c + 2)), 3
	end,
	length = 3,
})

--[=[
	BrickColor. 2 bytes (uint16 Number).
]=]
local brickColor: DataType<BrickColor> = table.freeze({
	__T = nil :: any,
	write = function(v: BrickColor)
		local o = CS.allocate(2)
		buffer.writeu16(CS.getActive().buff, o, v.Number)
	end,
	read = function(b: buffer, c: number): (BrickColor, number)
		return BrickColor.new(buffer.readu16(b, c)), 2
	end,
	length = 2,
})

return table.freeze({
	color3 = color3,
	color3uint8 = color3uint8,
	brickColor = brickColor,
})
