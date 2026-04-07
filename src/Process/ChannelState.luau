--!strict
--!optimize 2

--[=[
	@class ChannelState
	
	Manages the active write buffer for serialization operations.
	All DataType.write() functions operate on the state set by this module.
	Buffer grows geometrically (2x) when capacity is exceeded.
	
	NOTE: --!native is intentionally omitted. Upvalue mutation
	(active = state) across function boundaries requires caution
	with native codegen. Individual hot functions use @native instead.
]=]

local INITIAL_BUFFER_SIZE: number = 256

--[=[
	@type State
	@within ChannelState
	The channel state internal structure.
]=]
export type State = {
	buff: buffer,
	cursor: number,
	refMap: { [number]: Instance },
	refCount: number,
}

-- The currently active channel state for write operations.
local active: State = {
	buff = buffer.create(INITIAL_BUFFER_SIZE),
	cursor = 0,
	refMap = {},
	refCount = 0,
}

--- Sets the active channel state. Called before packet write operations.
local function setActive(state: State)
	active = state
end

--- Returns the currently active channel state.
local function getActive(): State
	return active
end

--- Creates a fresh channel state with a pre-allocated buffer.
local function createState(): State
	return {
		buff = buffer.create(INITIAL_BUFFER_SIZE),
		cursor = 0,
		refMap = {},
		refCount = 0,
	}
end

--- Ensures the active buffer can hold `bytes` more bytes.
--- Grows geometrically (2×) to amortize allocation cost.
local function ensureCapacity(bytes: number)
	local requiredSize = active.cursor + bytes
	local currentSize = buffer.len(active.buff)

	if requiredSize <= currentSize then
		return
	end

	local newSize = currentSize
	while newSize < requiredSize do
		newSize *= 2
	end

	local newBuff = buffer.create(newSize)
	buffer.copy(newBuff, 0, active.buff, 0, active.cursor)
	active.buff = newBuff
end

--- Reserves `bytes` in the active buffer and returns the write offset.
--- Advances the cursor by the allocated amount.
local function allocate(bytes: number): number
	ensureCapacity(bytes)
	local offset = active.cursor
	active.cursor += bytes
	return offset
end

--- Stores an Instance reference in the active channel's reference map.
--- Returns the numeric reference ID written into the buffer.
local function addReference(inst: Instance): number
	active.refCount += 1
	local id = active.refCount
	active.refMap[id] = inst
	return id
end

--- Extracts written data from a channel state as a trimmed buffer.
--- Returns nil if nothing was written. Resets the state for the next frame.
local function flush(state: State): (buffer?, { [number]: Instance }?)
	if state.cursor == 0 then
		return nil, nil
	end

	local out = buffer.create(state.cursor)
	buffer.copy(out, 0, state.buff, 0, state.cursor)
	local refs = state.refMap

	state.cursor = 0
	state.refMap = {}
	state.refCount = 0

	return out, refs
end

return table.freeze({
	setActive = setActive,
	getActive = getActive,
	createState = createState,
	ensureCapacity = ensureCapacity,
	allocate = allocate,
	addReference = addReference,
	flush = flush,
})
