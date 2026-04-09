--!strict
--!optimize 2
--!native

--[=[
	@class Reader
	
	Incoming buffer deserialization pipeline.
	Reads packet IDs and dispatches to registered listeners.
	
	Improvements over v1:
	- pcall wrapping: one bad packet won't crash the entire frame
	- bytesRead range validation: prevents buffer overruns
	- Middleware integration: packets can be filtered before dispatch
	- Bandwidth tracking: record incoming traffic
	- Coroutine pool: thread reuse for listener dispatch
]=]

local Bandwidth = require(script.Parent.Bandwidth)
local Middleware = require(script.Parent.Middleware)

type PacketReader = {
	read: (b: buffer, cursor: number, refMap: { [number]: Instance }?) -> (any, number),
	listeners: { (data: any, sender: Player?) -> () },
}

local registeredReaders: { [number]: PacketReader } = {}

--== Thread Pool (Coroutine Reuse) ==--
local freeThreads: { thread } = {}

local function yielder()
	while true do
		local fn: any, data: any, sender: any = coroutine.yield()
		fn(data, sender)
		table.insert(freeThreads, coroutine.running())
	end
end

local function dispatch(fn: (any, Player?) -> (), data: any, sender: Player?)
	local thread: thread
	if #freeThreads > 0 then
		thread = table.remove(freeThreads, #freeThreads) :: thread
	else
		thread = coroutine.create(yielder)
		coroutine.resume(thread)
	end
	task.spawn(thread, fn, data, sender)
end

--== Public API ==--

local function registerReader(
	id: number,
	readFn: (b: buffer, cursor: number, refMap: { [number]: Instance }?) -> (any, number),
	listeners: { (data: any, sender: Player?) -> () }
)
	registeredReaders[id] = {
		read = readFn,
		listeners = listeners,
	}
end

local function processBuffer(b: buffer, refMap: { [number]: Instance }?, sender: Player?)
	local length = buffer.len(b)
	if length == 0 then
		return
	end

	Bandwidth.recordIn(length)

	local cursor = 0

	while cursor + 2 <= length do
		local packetId = buffer.readu16(b, cursor)
		cursor += 2

		local reader = registeredReaders[packetId]
		if not reader then
			warn(`[ByteFlow] Unknown packet ID: {packetId}, discarding remaining {length - cursor} bytes`)
			return
		end

		-- pcall: one malformed packet won't crash the rest of the frame
		local ok, data, bytesRead = pcall(reader.read, b, cursor, refMap)
		if not ok then
			warn(`[ByteFlow] Deserialization error on packet {packetId}: {data}`)
			return
		end

		-- Validate bytesRead to prevent buffer overruns
		if type(bytesRead) ~= "number" or bytesRead < 0 or cursor + bytesRead > length then
			warn(`[ByteFlow] Invalid read length from packet {packetId}: {bytesRead}`)
			return
		end

		cursor += bytesRead

		-- Middleware gate: drop packet if middleware rejects
		if not Middleware.runIncoming(packetId, data, sender) then
			continue
		end

		local listeners = reader.listeners
		for i = 1, #listeners do
			dispatch(listeners[i], data, sender)
		end
	end
end

return table.freeze({
	registerReader = registerReader,
	processBuffer = processBuffer,
})
