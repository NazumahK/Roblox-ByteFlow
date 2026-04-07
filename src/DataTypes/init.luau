--!strict
--!optimize 2

--[=[
	@class DataTypes
	
	Central re-export hub for all data type serializers.
	
	Organized by category:
	- Numeric - uint8/16/32, int8/16/32, float32/64
	- Bool / String / Nothing - primitive types
	- Vector / CFrame - geometric types
	- Instance / Buffer - reference types
	- Color - Color3, Color3uint8, BrickColor
	- UI - UDim, UDim2, Rect
	- Physics - Ray, Region3, NumberRange, PhysicalProperties
	- Sequence - NumberSequence/Keypoint, ColorSequence/Keypoint
	- Misc - Axes, Faces, DateTime, TweenInfo, Font, PathWaypoint, EnumItem
	- Generic - Optional, Array, Map, Struct
]=]

local Numeric = require(script.Numeric)
local Vector = require(script.Vector)
local Color = require(script.Color)
local UI = require(script.UI)
local Physics = require(script.Physics)
local Sequence = require(script.Sequence)
local Misc = require(script.Misc)

return table.freeze({
	uint8 = Numeric.uint8,
	uint16 = Numeric.uint16,
	uint32 = Numeric.uint32,
	int8 = Numeric.int8,
	int16 = Numeric.int16,
	int32 = Numeric.int32,
	float32 = Numeric.float32,
	float64 = Numeric.float64,

	bool = require(script.Bool),
	string = require(script.String),
	nothing = require(script.Nothing),

	vec2 = Vector.vec2,
	vec3 = Vector.vec3,
	cframe = require(script.CFrame),

	inst = require(script.Instance),
	buff = require(script.Buffer),

	color3 = Color.color3,
	color3uint8 = Color.color3uint8,
	brickColor = Color.brickColor,

	udim = UI.udim,
	udim2 = UI.udim2,
	rect = UI.rect,

	ray = Physics.ray,
	region3 = Physics.region3,
	numberRange = Physics.numberRange,
	physicalProperties = Physics.physicalProperties,

	numberSequenceKeypoint = Sequence.numberSequenceKeypoint,
	numberSequence = Sequence.numberSequence,
	colorSequenceKeypoint = Sequence.colorSequenceKeypoint,
	colorSequence = Sequence.colorSequence,

	axes = Misc.axes,
	faces = Misc.faces,
	dateTime = Misc.dateTime,
	tweenInfo = Misc.tweenInfo,
	font = Misc.font,
	pathWaypoint = Misc.pathWaypoint,
	enum = Misc.enum,

	optional = require(script.Optional),
	array = require(script.Array),
	map = require(script.Map),
	struct = require(script.Struct),
})
