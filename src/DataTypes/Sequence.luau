--!strict
--!optimize 2
--!native

--[=[
	@class SequenceTypes
	
	Sequence value type serializers:
	NumberSequenceKeypoint, NumberSequence, ColorSequenceKeypoint, ColorSequence.
]=]

local Types = require(script.Parent.Parent.Types)
local CS = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	NumberSequenceKeypoint. 12 bytes (3 x float32).
]=]
local numberSequenceKeypoint: DataType<NumberSequenceKeypoint> = table.freeze({
	__T = nil :: any,
	write = function(v: NumberSequenceKeypoint)
		local o = CS.allocate(12)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.Time)
		buffer.writef32(b, o + 4, v.Value)
		buffer.writef32(b, o + 8, v.Envelope)
	end,
	read = function(b: buffer, c: number): (NumberSequenceKeypoint, number)
		return NumberSequenceKeypoint.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8)), 12
	end,
	length = 12,
})

--[=[
	NumberSequence. Variable (uint16 count + count x 12 bytes).
]=]
local numberSequence: DataType<NumberSequence> = table.freeze({
	__T = nil :: any,
	write = function(v: NumberSequence)
		local kps = v.Keypoints
		local count = #kps
		local o = CS.allocate(2 + count * 12)
		local b = CS.getActive().buff
		buffer.writeu16(b, o, count)
		for i = 1, count do
			local base = o + 2 + (i - 1) * 12
			local kp = kps[i]
			buffer.writef32(b, base, kp.Time)
			buffer.writef32(b, base + 4, kp.Value)
			buffer.writef32(b, base + 8, kp.Envelope)
		end
	end,
	read = function(b: buffer, c: number): (NumberSequence, number)
		local count = buffer.readu16(b, c)
		local kps = table.create(count) :: { NumberSequenceKeypoint }
		for i = 1, count do
			local base = c + 2 + (i - 1) * 12
			kps[i] = NumberSequenceKeypoint.new(
				buffer.readf32(b, base),
				buffer.readf32(b, base + 4),
				buffer.readf32(b, base + 8)
			)
		end
		return NumberSequence.new(kps), 2 + count * 12
	end,
	length = nil,
})

--[=[
	ColorSequenceKeypoint. 16 bytes (float32 Time + Color3).
]=]
local colorSequenceKeypoint: DataType<ColorSequenceKeypoint> = table.freeze({
	__T = nil :: any,
	write = function(v: ColorSequenceKeypoint)
		local o = CS.allocate(16)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.Time)
		buffer.writef32(b, o + 4, v.Value.R)
		buffer.writef32(b, o + 8, v.Value.G)
		buffer.writef32(b, o + 12, v.Value.B)
	end,
	read = function(b: buffer, c: number): (ColorSequenceKeypoint, number)
		return ColorSequenceKeypoint.new(
			buffer.readf32(b, c),
			Color3.new(buffer.readf32(b, c + 4), buffer.readf32(b, c + 8), buffer.readf32(b, c + 12))
		),
			16
	end,
	length = 16,
})

--[=[
	ColorSequence. Variable (uint16 count + count x 16 bytes).
]=]
local colorSequence: DataType<ColorSequence> = table.freeze({
	__T = nil :: any,
	write = function(v: ColorSequence)
		local kps = v.Keypoints
		local count = #kps
		local o = CS.allocate(2 + count * 16)
		local b = CS.getActive().buff
		buffer.writeu16(b, o, count)
		for i = 1, count do
			local base = o + 2 + (i - 1) * 16
			local kp = kps[i]
			buffer.writef32(b, base, kp.Time)
			buffer.writef32(b, base + 4, kp.Value.R)
			buffer.writef32(b, base + 8, kp.Value.G)
			buffer.writef32(b, base + 12, kp.Value.B)
		end
	end,
	read = function(b: buffer, c: number): (ColorSequence, number)
		local count = buffer.readu16(b, c)
		local kps = table.create(count) :: { ColorSequenceKeypoint }
		for i = 1, count do
			local base = c + 2 + (i - 1) * 16
			kps[i] = ColorSequenceKeypoint.new(
				buffer.readf32(b, base),
				Color3.new(buffer.readf32(b, base + 4), buffer.readf32(b, base + 8), buffer.readf32(b, base + 12))
			)
		end
		return ColorSequence.new(kps), 2 + count * 16
	end,
	length = nil,
})

return table.freeze({
	numberSequenceKeypoint = numberSequenceKeypoint,
	numberSequence = numberSequence,
	colorSequenceKeypoint = colorSequenceKeypoint,
	colorSequence = colorSequence,
})
