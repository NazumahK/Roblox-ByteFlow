--!strict
--!optimize 2
--!native

--[=[
	@class UITypes
	
	UI value type serializers:
	UDim, UDim2, Rect.
]=]

local Types = require(script.Parent.Parent.Types)
local CS = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	UDim. 8 bytes (float32 Scale + int32 Offset).
]=]
local udim: DataType<UDim> = table.freeze({
	__T = nil :: any,
	write = function(v: UDim)
		local o = CS.allocate(8)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.Scale)
		buffer.writei32(b, o + 4, v.Offset)
	end,
	read = function(b: buffer, c: number): (UDim, number)
		return UDim.new(buffer.readf32(b, c), buffer.readi32(b, c + 4)), 8
	end,
	length = 8,
})

--[=[
	UDim2. 16 bytes (2 x UDim).
]=]
local udim2: DataType<UDim2> = table.freeze({
	__T = nil :: any,
	write = function(v: UDim2)
		local o = CS.allocate(16)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.X.Scale)
		buffer.writei32(b, o + 4, v.X.Offset)
		buffer.writef32(b, o + 8, v.Y.Scale)
		buffer.writei32(b, o + 12, v.Y.Offset)
	end,
	read = function(b: buffer, c: number): (UDim2, number)
		return UDim2.new(
			buffer.readf32(b, c),
			buffer.readi32(b, c + 4),
			buffer.readf32(b, c + 8),
			buffer.readi32(b, c + 12)
		),
			16
	end,
	length = 16,
})

--[=[
	Rect. 16 bytes (4 x float32).
]=]
local rect: DataType<Rect> = table.freeze({
	__T = nil :: any,
	write = function(v: Rect)
		local o = CS.allocate(16)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.Min.X)
		buffer.writef32(b, o + 4, v.Min.Y)
		buffer.writef32(b, o + 8, v.Max.X)
		buffer.writef32(b, o + 12, v.Max.Y)
	end,
	read = function(b: buffer, c: number): (Rect, number)
		return Rect.new(
			buffer.readf32(b, c),
			buffer.readf32(b, c + 4),
			buffer.readf32(b, c + 8),
			buffer.readf32(b, c + 12)
		),
			16
	end,
	length = 16,
})

return table.freeze({
	udim = udim,
	udim2 = udim2,
	rect = rect,
})
