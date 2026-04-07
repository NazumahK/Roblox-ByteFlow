--!strict
--!optimize 2

--[=[
	@class Invoke
	
	Bidirectional invoke (request-response) system.
	Supports both Client-to-Server and Server-to-Client invocations
	with full generic type safety on request and response payloads.
	
	Uses two packet IDs per invoke channel: one for requests, one for responses.
	Requests carry a uint32 correlation ID for matching responses.
]=]

local RunService = game:GetService("RunService")

local Types = require(script.Parent.Types)
local ChannelState = require(script.Parent.Process.ChannelState)
local Reader = require(script.Parent.Process.Reader)
local Packet = require(script.Parent.Packet)

type DataType<T> = Types.DataType<T>
type Reliability = Types.Reliability

--[=[
	@type Invoke<TReq, TRes>
	@within Invoke
	The invoke object representing the request-response capability.
]=]

export type Invoke<TReq, TRes> = {
	invoke: (self: Invoke<TReq, TRes>, data: TReq, player: Player?) -> TRes,
	onInvoke: (self: Invoke<TReq, TRes>, handler: (data: TReq, sender: Player?) -> TRes) -> (),
}

type Envelope = { _reqId: number, _data: any }

local function getOrCreatePlayerState(store: { [Player]: ChannelState.State }, player: Player): ChannelState.State
	local existing = store[player]
	if existing then
		return existing
	end
	local newState = ChannelState.createState()
	store[player] = newState
	return newState
end

local function getWriteState(reliability: Reliability, player: Player?): ChannelState.State
	local isServer = RunService:IsServer()
	if isServer and player then
		local store = if reliability == "Reliable" then Packet._serverPlayerReliable else Packet._serverPlayerUnreliable
		return getOrCreatePlayerState(store, player)
	end
	return if reliability == "Reliable" then Packet._clientReliable else Packet._clientUnreliable
end

local function writeInvokePacket(packetId: number, reqId: number, dataType: DataType<any>, data: any)
	local offset = ChannelState.allocate(5)
	local b = ChannelState.getActive().buff
	buffer.writeu8(b, offset, packetId)
	buffer.writeu32(b, offset + 1, reqId)
	dataType.write(data)
end

--[=[
	@static defineInvoke
	@within Invoke
	Creates an invoke definition consumed by defineNamespace.
	Returns a table with a special marker for namespace detection.
	
	@param config InvokeConfig<TReq, TRes> -- The configuration table containing request and response types, timeouts, etc.
	@return { _byteFlowType: "invoke", ... }
]=]
local function defineInvoke<TReq, TRes>(config: Types.InvokeConfig<TReq, TRes>)
	local requestType: DataType<TReq> = config.request
	local responseType: DataType<TRes> = config.response
	local reliability: Reliability = config.reliability or "Reliable"
	local timeout: number = config.timeout or 10

	return {
		_byteFlowType = "invoke" :: "invoke",
		_create = function(requestId: number, responseId: number): Invoke<TReq, TRes>
			local nextReqId: number = 0
			local pendingRequests: { [number]: thread } = {}
			local handler: ((data: TReq, sender: Player?) -> TRes)? = nil
			local isServer = RunService:IsServer()

			local requestListeners: { (data: any, sender: Player?) -> () } = {}
			Reader.registerReader(
				requestId,
				function(b: buffer, cursor: number, refMap: { [number]: Instance }?): (any, number)
					local rid = buffer.readu32(b, cursor)
					local d, bytesRead = requestType.read(b, cursor + 4, refMap)
					return { _reqId = rid, _data = d }, 4 + bytesRead
				end,
				requestListeners
			)

			local responseListeners: { (data: any, sender: Player?) -> () } = {}
			Reader.registerReader(
				responseId,
				function(b: buffer, cursor: number, refMap: { [number]: Instance }?): (any, number)
					local rid = buffer.readu32(b, cursor)
					local d, bytesRead = responseType.read(b, cursor + 4, refMap)
					return { _reqId = rid, _data = d }, 4 + bytesRead
				end,
				responseListeners
			)

			table.insert(requestListeners, function(envelope: any, sender: Player?)
				local env: Envelope = envelope
				local currentHandler = handler
				if currentHandler then
					local result = currentHandler(env._data, sender)
					local state = getWriteState(reliability, sender)
					ChannelState.setActive(state)
					writeInvokePacket(responseId, env._reqId, responseType, result)
				else
					warn(`[ByteFlow] No handler registered for invoke (requestId={requestId})`)
				end
			end)

			table.insert(responseListeners, function(envelope: any, _sender: Player?)
				local env: Envelope = envelope
				local waitingThread = pendingRequests[env._reqId]
				if waitingThread then
					pendingRequests[env._reqId] = nil
					task.spawn(waitingThread, env._data)
				end
			end)

			local invoke = {} :: any

			--[=[
				@method invoke
				@within Invoke
				Sends an invocation request across the network and yields until a response is received.
				If called from the server, the `player` argument must be provided.
				
				```lua
				local response = Net.myInvoke:invoke({ someData = 123 }, player)
				```
				
				@param data TReq -- The request payload.
				@param player Player? -- The target player (required on server).
				@yields
				@return TRes
			]=]
			function invoke:invoke(data: TReq, player: Player?): TRes
				nextReqId += 1
				local reqId = nextReqId

				local state: ChannelState.State
				if isServer then
					assert(player, "[ByteFlow] Server must specify target player for invoke")
					state = getWriteState(reliability, player)
				else
					state = getWriteState(reliability, nil)
				end

				ChannelState.setActive(state)
				writeInvokePacket(requestId, reqId, requestType, data)

				local currentThread = coroutine.running()
				pendingRequests[reqId] = currentThread

				task.delay(timeout, function()
					if pendingRequests[reqId] then
						pendingRequests[reqId] = nil
						task.spawn(currentThread, nil)
						warn(`[ByteFlow] Invoke timed out after {timeout}s (reqId={reqId})`)
					end
				end)

				return coroutine.yield()
			end

			--[=[
				@method onInvoke
				@within Invoke
				Registers the handler that listens for incoming requests and produces responses.
				
				```lua
				Net.myInvoke:onInvoke(function(data, sender)
					return { success = true }
				end)
				```
				
				@param fn (data: TReq, sender: Player?) -> TRes -- The function handling the request.
			]=]
			function invoke:onInvoke(fn: (data: TReq, sender: Player?) -> TRes)
				handler = fn
			end

			return invoke :: Invoke<TReq, TRes>
		end,
	}
end

return table.freeze({
	defineInvoke = defineInvoke,
})
