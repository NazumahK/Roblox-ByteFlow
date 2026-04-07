--!strict
--!optimize 2

--[=[
	@class Reader
	
	Incoming buffer deserialization pipeline.
	Reads packet IDs and dispatches to registered listeners.
	Instance references are resolved during the read phase for peak performance.
]=]

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
	local cursor = 0
	local length = buffer.len(b)

	while cursor < length do
		local packetId = buffer.readu8(b, cursor)
		cursor += 1

		local reader = registeredReaders[packetId]
		if not reader then
			warn(`[ByteFlow] Unknown packet ID: {packetId}`)
			return
		end

		local data, bytesRead = reader.read(b, cursor, refMap)
		cursor += bytesRead

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
