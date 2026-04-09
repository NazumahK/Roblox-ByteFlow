--!strict
--!optimize 2

--[=[
	@class ByteFlow

	High-performance binary serialization networking library for Roblox.
	Buffer-based packet system with minimal bandwidth overhead.
	Supports fire-and-forget packets AND bidirectional invoke (request-response).

	## Packets (fire-and-forget)
	```luau
	local Net = ByteFlow.defineNamespace("Game", function()
		return {
			chat = ByteFlow.definePacket({
				value = ByteFlow.struct({ message = ByteFlow.string, sender = ByteFlow.uint32 }),
			}),
		}
	end)
	Net.chat:sendToAll({ message = "Hello!", sender = 1 })
	Net.chat:listen(function(data, sender) print(data.message) end)
	```

	## Invoke (request-response)
	```luau
	local Net = ByteFlow.defineNamespace("Game", function()
		return {
			getStats = ByteFlow.defineInvoke({
				request = ByteFlow.struct({ playerId = ByteFlow.uint32 }),
				response = ByteFlow.struct({ kills = ByteFlow.uint16, deaths = ByteFlow.uint16 }),
			}),
		}
	end)
	-- Server handler:
	Net.getStats:onInvoke(function(data, player) return { kills = 10, deaths = 3 } end)
	-- Client caller:
	local stats = Net.getStats:invoke({ playerId = 1 })
	```
]=]

local Types = require(script.Types)
local DataTypes = require(script.DataTypes)
local PacketModule = require(script.Packet)
local InvokeModule = require(script.Invoke)
local Process = require(script.Process)
local Middleware = require(script.Process.Middleware)
local Bandwidth = require(script.Process.Bandwidth)

export type DataType<T> = Types.DataType<T>
export type Packet<T> = PacketModule.Packet<T>
export type Invoke<TReq, TRes> = InvokeModule.Invoke<TReq, TRes>

--- FNV-1a hash over a string → uint16 (0..65535).
--- Deterministic across server and client: same name = same ID, always.
local function fnv1a16(str: string): number
	local h: number = 2166136261 -- FNV offset basis
	for i = 1, #str do
		h = bit32.bxor(h, string.byte(str, i))
		h = bit32.band(h * 16777619, 0xFFFFFFFF) -- FNV prime, wrap to 32-bit
	end
	return bit32.band(h, 0xFFFF) -- truncate to 16-bit
end

local function defineNamespace<T>(name: string, factory: () -> T): T
	local definitions = factory()

	-- Sort keys for deterministic iteration order (though IDs are hash-based,
	-- sorting avoids any subtle issues with duplicate detection below).
	local sorted: { string } = {}
	for key in definitions :: any do
		table.insert(sorted, key)
	end
	table.sort(sorted)

	for _, key in sorted do
		local def = (definitions :: any)[key]
		local fullName = name .. "/" .. key

		if type(def) == "function" then
			-- definePacket factory: function(id) -> Packet<T>
			local id = fnv1a16(fullName)
			;(definitions :: any)[key] = def(id)
		elseif type(def) == "table" and (def :: any)._byteFlowType == "invoke" then
			-- defineInvoke: uses two IDs, one for request and one for response
			local reqId = fnv1a16(fullName .. "_req")
			local resId = fnv1a16(fullName .. "_res")
			;(definitions :: any)[key] = (def :: any)._create(reqId, resId)
		else
			error(`[ByteFlow] Namespace "{name}": key "{key}" is not a definePacket() or defineInvoke() result`)
		end
	end

	return definitions
end

-- Auto-start the process loop on first require
Process.start()

return table.freeze({
	-- Namespace & Definitions
	defineNamespace = defineNamespace,
	definePacket = PacketModule.definePacket,
	defineInvoke = InvokeModule.defineInvoke,

	-- Primitive data types
	uint8 = DataTypes.uint8,
	uint16 = DataTypes.uint16,
	uint32 = DataTypes.uint32,
	int8 = DataTypes.int8,
	int16 = DataTypes.int16,
	int32 = DataTypes.int32,
	float32 = DataTypes.float32,
	float64 = DataTypes.float64,
	bool = DataTypes.bool,
	string = DataTypes.string,

	-- Geometric types
	vec2 = DataTypes.vec2,
	vec3 = DataTypes.vec3,
	cframe = DataTypes.cframe,

	-- Reference types
	inst = DataTypes.inst,
	buff = DataTypes.buff,

	-- Colors
	color3 = DataTypes.color3,
	color3uint8 = DataTypes.color3uint8,
	brickColor = DataTypes.brickColor,

	-- UI types
	udim = DataTypes.udim,
	udim2 = DataTypes.udim2,
	rect = DataTypes.rect,

	-- Geometric / Physics
	ray = DataTypes.ray,
	region3 = DataTypes.region3,
	numberRange = DataTypes.numberRange,
	physicalProperties = DataTypes.physicalProperties,

	-- Sequences
	numberSequenceKeypoint = DataTypes.numberSequenceKeypoint,
	numberSequence = DataTypes.numberSequence,
	colorSequenceKeypoint = DataTypes.colorSequenceKeypoint,
	colorSequence = DataTypes.colorSequence,

	-- Bit flags
	axes = DataTypes.axes,
	faces = DataTypes.faces,

	-- Temporal / Misc
	dateTime = DataTypes.dateTime,
	tweenInfo = DataTypes.tweenInfo,
	font = DataTypes.font,
	pathWaypoint = DataTypes.pathWaypoint,

	-- Factories
	enum = DataTypes.enum,

	-- Void type
	nothing = DataTypes.nothing,

	-- Generic wrappers
	optional = DataTypes.optional,
	array = DataTypes.array,
	map = DataTypes.map,
	struct = DataTypes.struct,

	-- Middleware & Monitoring
	middleware = Middleware,
	bandwidth = Bandwidth,
})
