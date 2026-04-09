--!strict
--!optimize 2

--[=[
	@class Middleware
	
	Incoming/outgoing packet middleware pipeline.
	Middleware functions receive (packetId, data, player?) and return
	true to allow the packet through or false to drop it.
]=]

type MiddlewareFn = (packetId: number, data: any, player: Player?) -> boolean

local incomingMiddleware: { MiddlewareFn } = {}
local outgoingMiddleware: { MiddlewareFn } = {}

local function addIncoming(fn: MiddlewareFn)
	table.insert(incomingMiddleware, fn)
end

local function addOutgoing(fn: MiddlewareFn)
	table.insert(outgoingMiddleware, fn)
end

local function runIncoming(packetId: number, data: any, player: Player?): boolean
	for _, fn in incomingMiddleware do
		if not fn(packetId, data, player) then
			return false
		end
	end
	return true
end

local function runOutgoing(packetId: number, data: any, player: Player?): boolean
	for _, fn in outgoingMiddleware do
		if not fn(packetId, data, player) then
			return false
		end
	end
	return true
end

return table.freeze({
	addIncoming = addIncoming,
	addOutgoing = addOutgoing,
	runIncoming = runIncoming,
	runOutgoing = runOutgoing,
})
