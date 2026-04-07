--!strict
--!optimize 2
--!native

--[=[
	@class MiscTypes
	
	Miscellaneous Roblox value type serializers:
	Axes, Faces, DateTime, TweenInfo, Font, PathWaypoint, EnumItem.
	
	NOTE: Enum deserialization uses GetEnumItems() iteration lookup since
	Roblox Luau does not expose a public Enum:FromValue() API.
]=]

local Types = require(script.Parent.Parent.Types)
local CS = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--== Helper: Build enum value→item lookup table ==--

local function buildEnumLookup(enumType: Enum): { [number]: EnumItem }
	local lookup: { [number]: EnumItem } = {}
	for _, item in enumType:GetEnumItems() do
		lookup[item.Value] = item
	end
	return lookup
end

-- Pre-built lookups for known enums used in TweenInfo, Font, PathWaypoint
local easingStyleLookup = buildEnumLookup(Enum.EasingStyle)
local easingDirectionLookup = buildEnumLookup(Enum.EasingDirection)
local fontWeightLookup = buildEnumLookup(Enum.FontWeight)
local fontStyleLookup = buildEnumLookup(Enum.FontStyle)
local pathActionLookup = buildEnumLookup(Enum.PathWaypointAction)

--== Bit-Flag Types ==--

--[=[
	Axes. 1 byte (bit flags: X=1, Y=2, Z=4).
]=]
local axes: DataType<Axes> = table.freeze({
	__T = nil :: any,
	write = function(v: Axes)
		local flags = 0
		if v.X then
			flags += 1
		end
		if v.Y then
			flags += 2
		end
		if v.Z then
			flags += 4
		end
		local o = CS.allocate(1)
		buffer.writeu8(CS.getActive().buff, o, flags)
	end,
	read = function(b: buffer, c: number): (Axes, number)
		local flags = buffer.readu8(b, c)
		local enumX, enumY, enumZ = Enum.Axis.X, Enum.Axis.Y, Enum.Axis.Z
		local hasX = bit32.band(flags, 1) ~= 0
		local hasY = bit32.band(flags, 2) ~= 0
		local hasZ = bit32.band(flags, 4) ~= 0

		if hasX and hasY and hasZ then
			return Axes.new(enumX, enumY, enumZ), 1
		elseif hasX and hasY then
			return Axes.new(enumX, enumY), 1
		elseif hasX and hasZ then
			return Axes.new(enumX, enumZ), 1
		elseif hasY and hasZ then
			return Axes.new(enumY, enumZ), 1
		elseif hasX then
			return Axes.new(enumX), 1
		elseif hasY then
			return Axes.new(enumY), 1
		elseif hasZ then
			return Axes.new(enumZ), 1
		end
		-- flags == 0: no axes set, still need valid return
		return Axes.new(enumX), 1
	end,
	length = 1,
})

--[=[
	Faces. 1 byte (bit flags: Right=1, Top=2, Back=4, Left=8, Bottom=16, Front=32).
]=]
local faces: DataType<Faces> = table.freeze({
	__T = nil :: any,
	write = function(v: Faces)
		local flags = 0
		if v.Right then
			flags += 1
		end
		if v.Top then
			flags += 2
		end
		if v.Back then
			flags += 4
		end
		if v.Left then
			flags += 8
		end
		if v.Bottom then
			flags += 16
		end
		if v.Front then
			flags += 32
		end
		local o = CS.allocate(1)
		buffer.writeu8(CS.getActive().buff, o, flags)
	end,
	read = function(b: buffer, c: number): (Faces, number)
		local flags = buffer.readu8(b, c)
		local faceList: { Enum.NormalId } = {}
		if bit32.band(flags, 1) ~= 0 then
			table.insert(faceList, Enum.NormalId.Right)
		end
		if bit32.band(flags, 2) ~= 0 then
			table.insert(faceList, Enum.NormalId.Top)
		end
		if bit32.band(flags, 4) ~= 0 then
			table.insert(faceList, Enum.NormalId.Back)
		end
		if bit32.band(flags, 8) ~= 0 then
			table.insert(faceList, Enum.NormalId.Left)
		end
		if bit32.band(flags, 16) ~= 0 then
			table.insert(faceList, Enum.NormalId.Bottom)
		end
		if bit32.band(flags, 32) ~= 0 then
			table.insert(faceList, Enum.NormalId.Front)
		end

		-- Faces.new() accepts variadic NormalId args; use explicit branching
		local n = #faceList
		if n == 1 then
			return Faces.new(faceList[1]), 1
		elseif n == 2 then
			return Faces.new(faceList[1], faceList[2]), 1
		elseif n == 3 then
			return Faces.new(faceList[1], faceList[2], faceList[3]), 1
		elseif n == 4 then
			return Faces.new(faceList[1], faceList[2], faceList[3], faceList[4]), 1
		elseif n == 5 then
			return Faces.new(faceList[1], faceList[2], faceList[3], faceList[4], faceList[5]), 1
		elseif n == 6 then
			return Faces.new(faceList[1], faceList[2], faceList[3], faceList[4], faceList[5], faceList[6]), 1
		end
		-- flags == 0: no faces set, still need valid return
		return Faces.new(Enum.NormalId.Front), 1
	end,
	length = 1,
})

--== Temporal / Misc Types ==--

--[=[
	DateTime. 8 bytes (float64 UnixTimestampMillis).
]=]
local dateTime: DataType<DateTime> = table.freeze({
	__T = nil :: any,
	write = function(v: DateTime)
		local o = CS.allocate(8)
		buffer.writef64(CS.getActive().buff, o, v.UnixTimestampMillis)
	end,
	read = function(b: buffer, c: number): (DateTime, number)
		return DateTime.fromUnixTimestampMillis(buffer.readf64(b, c)), 8
	end,
	length = 8,
})

--[=[
	TweenInfo. 15 bytes (f32 time + u8 style + u8 dir + i32 repeat + u8 reverses + f32 delay).
]=]
local tweenInfo: DataType<TweenInfo> = table.freeze({
	__T = nil :: any,
	write = function(v: TweenInfo)
		local o = CS.allocate(15)
		local b = CS.getActive().buff
		buffer.writef32(b, o, v.Time)
		buffer.writeu8(b, o + 4, v.EasingStyle.Value)
		buffer.writeu8(b, o + 5, v.EasingDirection.Value)
		buffer.writei32(b, o + 6, v.RepeatCount)
		buffer.writeu8(b, o + 10, if v.Reverses then 1 else 0)
		buffer.writef32(b, o + 11, v.DelayTime)
	end,
	read = function(b: buffer, c: number): (TweenInfo, number)
		local style = easingStyleLookup[buffer.readu8(b, c + 4)]
		local direction = easingDirectionLookup[buffer.readu8(b, c + 5)]
		return TweenInfo.new(
			buffer.readf32(b, c),
			style :: any,
			direction :: any,
			buffer.readi32(b, c + 6),
			buffer.readu8(b, c + 10) ~= 0,
			buffer.readf32(b, c + 11)
		),
			15
	end,
	length = 15,
})

--[=[
	Font. Variable (string family + uint16 weight + uint8 style).
]=]
local font: DataType<Font> = table.freeze({
	__T = nil :: any,
	write = function(v: Font)
		local family = v.Family
		local famLen = #family
		local o = CS.allocate(2 + famLen + 3)
		local b = CS.getActive().buff
		buffer.writeu16(b, o, famLen)
		buffer.writestring(b, o + 2, family)
		buffer.writeu16(b, o + 2 + famLen, v.Weight.Value)
		buffer.writeu8(b, o + 4 + famLen, v.Style.Value)
	end,
	read = function(b: buffer, c: number): (Font, number)
		local famLen = buffer.readu16(b, c)
		local family = buffer.readstring(b, c + 2, famLen)
		local weight = fontWeightLookup[buffer.readu16(b, c + 2 + famLen)]
		local style = fontStyleLookup[buffer.readu8(b, c + 4 + famLen)]
		return Font.new(family, weight :: any, style :: any), 5 + famLen
	end,
	length = nil,
})

--[=[
	PathWaypoint. 13 bytes (Vector3 position + uint8 action).
]=]
local pathWaypoint: DataType<PathWaypoint> = table.freeze({
	__T = nil :: any,
	write = function(v: PathWaypoint)
		local o = CS.allocate(13)
		local b = CS.getActive().buff
		local pos = v.Position
		buffer.writef32(b, o, pos.X)
		buffer.writef32(b, o + 4, pos.Y)
		buffer.writef32(b, o + 8, pos.Z)
		buffer.writeu8(b, o + 12, v.Action.Value)
	end,
	read = function(b: buffer, c: number): (PathWaypoint, number)
		local pos = Vector3.new(buffer.readf32(b, c), buffer.readf32(b, c + 4), buffer.readf32(b, c + 8))
		local action = pathActionLookup[buffer.readu8(b, c + 12)]
		return PathWaypoint.new(pos, action :: any), 13
	end,
	length = 13,
})

--[=[
	EnumItem (generic factory). Creates a serializer for a specific Enum.
	4 bytes (uint32 EnumItem.Value).
	Usage: `ByteFlow.enum(Enum.Material)`
	
	@param enumType Enum
	@return DataType<EnumItem>
]=]
local function enum(enumType: Enum): DataType<EnumItem>
	local valueLookup = buildEnumLookup(enumType)

	return table.freeze({
		__T = nil :: any,
		write = function(v: EnumItem)
			local o = CS.allocate(4)
			buffer.writeu32(CS.getActive().buff, o, v.Value)
		end,
		read = function(b: buffer, c: number): (EnumItem, number)
			local val = buffer.readu32(b, c)
			local item = valueLookup[val]
			assert(item, `[ByteFlow] Unknown enum value {val} for {enumType}`)
			return item, 4
		end,
		length = 4,
	})
end

return table.freeze({
	axes = axes,
	faces = faces,
	dateTime = dateTime,
	tweenInfo = tweenInfo,
	font = font,
	pathWaypoint = pathWaypoint,
	enum = enum,
})
