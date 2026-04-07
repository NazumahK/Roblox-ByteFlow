--!strict
--!optimize 2
--!native

--[=[
	@class PhysicsTypes
	
	Geometric/physics value type serializers:
	Ray, Region3, NumberRange, PhysicalProperties.
]=]

local Types = require(script.Parent.Parent.Types)
local CS = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Ray. 24 bytes (Origin + Direction, 6 x float32).
]=]
local ray: DataType<Ray> = table.freeze({
	__T = nil :: any,
	write = function(v: Ray)
		local o = CS.allocate(24)
		local b = CS.getActive().buff
		local orig, dir = v.Origin, v.Direction
		buffer.writef32(b, o, orig.X)
		buffer.writef32(b, o + 4, orig.Y)
		buffer.writef32(b, o + 8, orig.Z)
		buffer.writef32(b, o + 12, dir.X)
		buffer.writef32(b, o + 16, dir.Y)
		buffer.writef32(b, o + 20, dir.Z)
	end,
	read = function(b: buffer, c: number): (Ray, number)
		return Ray.new(
			Vector3.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8)),
			Vector3.new(buffer.readf32(b, c + 12), buffer.readf32(b, c + 16), buffer.readf32(b, c + 20))
		),
			24
	end,
	length = 24,
})

--[=[
	Region3. 24 bytes (Position + Size, 6 x float32).
]=]
local region3: DataType<Region3> = table.freeze({
	__T = nil :: any,
	write = function(v: Region3)
		local o = CS.allocate(24)
		local b = CS.getActive().buff
		local pos, size = v.CFrame.Position, v.Size
		buffer.writef32(b, o, pos.X)
		buffer.writef32(b, o + 4, pos.Y)
		buffer.writef32(b, o + 8, pos.Z)
		buffer.writef32(b, o + 12, size.X)
		buffer.writef32(b, o + 16, size.Y)
		buffer.writef32(b, o + 20, size.Z)
	end,
	read = function(b: buffer, c: number): (Region3, number)
		local pos = Vector3.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8))
		local size = Vector3.new(buffer.readf32(b, c + 12), buffer.readf32(b, c + 16), buffer.readf32(b, c + 20))
		local half = size * 0.5
		return Region3.new(pos - half, pos + half), 24
	end,
	length = 24,
})

--[=[
	NumberRange. 8 bytes (Min + Max, 2 x float32).
]=]
local numberRange: DataType<NumberRange> = table.freeze({
	__T = nil :: any,
	write = function(v: NumberRange)
		local o = CS.allocate(8)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.Min)
		buffer.writef32(b, o + 4, v.Max)
	end,
	read = function(b: buffer, c: number): (NumberRange, number)
		return NumberRange.new(buffer.readf32(b, c), buffer.readf32(b, c + 4)), 8
	end,
	length = 8,
})

--[=[
	PhysicalProperties. 20 bytes (5 x float32).
]=]
local physicalProperties: DataType<PhysicalProperties> = table.freeze({
	__T = nil :: any,
	write = function(v: PhysicalProperties)
		local o = CS.allocate(20)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.Density)
		buffer.writef32(b, o + 4, v.Friction)
		buffer.writef32(b, o + 8, v.Elasticity)
		buffer.writef32(b, o + 12, v.FrictionWeight)
		buffer.writef32(b, o + 16, v.ElasticityWeight)
	end,
	read = function(b: buffer, c: number): (PhysicalProperties, number)
		return PhysicalProperties.new(
			buffer.readf32(b, c),
			buffer.readf32(b, c + 4),
			buffer.readf32(b, c + 8),
			buffer.readf32(b, c + 12),
			buffer.readf32(b, c + 16)
		),
			20
	end,
	length = 20,
})

return table.freeze({
	ray = ray,
	region3 = region3,
	numberRange = numberRange,
	physicalProperties = physicalProperties,
})
