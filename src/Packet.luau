--!strict
--!optimize 2

--[=[
	@class Packet
	
	Packet definition and runtime implementation.
	Uses closure-based API (not metatables) for maximum hot-path performance.
	
	Server methods: `sendTo`, `sendToList`, `sendToAll`, `sendToAllExcept`
	Client methods: `send`
	Shared methods: `listen`, `wait`
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Types)
local ChannelState = require(script.Parent.Process.ChannelState)
local Reader = require(script.Parent.Process.Reader)

type DataType<T> = Types.DataType<T>
type Reliability = Types.Reliability

--[=[
	@type Packet<T>
	@within Packet
	The packet object handling serialization and networking logic.
]=]

--- Unified packet type. Methods available depend on runtime context.
--- On server: sendTo, sendToList, sendToAll, sendToAllExcept, listen, wait
--- On client: send, listen, wait
export type Packet<T> = {
	sendTo: (self: Packet<T>, data: T, player: Player) -> (),
	sendToList: (self: Packet<T>, data: T, players: { Player }) -> (),
	sendToAll: (self: Packet<T>, data: T) -> (),
	sendToAllExcept: (self: Packet<T>, data: T, except: Player) -> (),
	send: (self: Packet<T>, data: T) -> (),
	listen: (self: Packet<T>, callback: (data: T, sender: Player?) -> ()) -> (),
	wait: (self: Packet<T>) -> (T, Player?),
}

--== Server/Client Channel State Stores ==--

-- Server: per-player channel states
local serverPlayerReliable: { [Player]: ChannelState.State } = {}
local serverPlayerUnreliable: { [Player]: ChannelState.State } = {}
local serverGlobalReliable: ChannelState.State = ChannelState.createState()
local serverGlobalUnreliable: ChannelState.State = ChannelState.createState()

-- Client: single pair of channel states
local clientReliable: ChannelState.State = ChannelState.createState()
local clientUnreliable: ChannelState.State = ChannelState.createState()

--- Returns the per-player channel state, creating it if necessary.
local function getPlayerState(store: { [Player]: ChannelState.State }, player: Player): ChannelState.State
	local state = store[player]
	if not state then
		state = ChannelState.createState()
		store[player] = state
	end
	return state
end

--- Writes a packet header (1-byte ID) + payload into the active channel state.
local function writePacket(id: number, dataType: DataType<any>, data: any)
	local offset = ChannelState.allocate(1)
	buffer.writeu8(ChannelState.getActive().buff, offset, id)
	dataType.write(data)
end

--== Packet Factory ==--

--- Returns a factory closure that accepts a packet ID and produces the runtime Packet object.
--- Called by `defineNamespace` which assigns deterministic IDs.
--[=[
	@static definePacket
	@within Packet
	Returns a factory closure that accepts a packet ID and produces the runtime Packet object.
	Called by `defineNamespace` which assigns deterministic IDs.
	
	@param config PacketConfig<T> -- Packet properties like value DataType and reliability.
	@return (id: number) -> Packet<T>
]=]
local function definePacket<T>(config: Types.PacketConfig<T>): (id: number) -> Packet<T>
	local reliability: Reliability = config.reliability or "Reliable"
	local dataType = config.value

	return function(id: number): Packet<T>
		local listeners: { (data: any, sender: Player?) -> () } = {}

		-- Register this packet's reader with the global reader
		Reader.registerReader(id, dataType.read, listeners)

		local packet = {} :: any
		local isServer = RunService:IsServer()

		--[=[
			@method listen
			@within Packet
			Registers a listener callback for incoming packets.
			
			```lua
			Net.myPacket:listen(function(data, sender)
			    print(data)
			end)
			```
			
			@param callback (data: T, sender: Player?) -> ()
		]=]
		function packet:listen(callback: (data: T, sender: Player?) -> ())
			table.insert(listeners, callback :: any)
		end

		--[=[
			@method wait
			@within Packet
			Yields the current thread until this packet is received once.
			
			```lua
			local data, sender = Net.myPacket:wait()
			```
			
			@yields
			@return T -- The received data.
			@return Player? -- The sender player, if any.
		]=]
		function packet:wait(): (T, Player?)
			local thread = coroutine.running()
			local function resume(data: any, sender: Player?)
				-- Remove this one-shot listener
				local idx = table.find(listeners, resume)
				if idx then
					table.remove(listeners, idx)
				end
				task.spawn(thread, data, sender)
			end
			table.insert(listeners, resume)
			return coroutine.yield()
		end

		if isServer then
			--[=[
				@method sendTo
				@within Packet
				Sends the packet to a specific player (Server-only).
				
				@param data T -- Data payload.
				@param player Player -- Target player.
			]=]
			function packet:sendTo(data: T, player: Player)
				local state = if reliability == "Reliable"
					then getPlayerState(serverPlayerReliable, player)
					else getPlayerState(serverPlayerUnreliable, player)
				ChannelState.setActive(state)
				writePacket(id, dataType, data)
			end

			--[=[
				@method sendToList
				@within Packet
				Sends the packet to a list of players (Server-only).
				
				@param data T -- Data payload.
				@param players { Player } -- Target players.
			]=]
			function packet:sendToList(data: T, players: { Player })
				for _, player in players do
					packet:sendTo(data, player)
				end
			end

			--[=[
				@method sendToAll
				@within Packet
				Sends the packet to all connected players (Server-only).
				
				@param data T -- Data payload.
			]=]
			function packet:sendToAll(data: T)
				local state = if reliability == "Reliable" then serverGlobalReliable else serverGlobalUnreliable
				ChannelState.setActive(state)
				writePacket(id, dataType, data)
			end

			--[=[
				@method sendToAllExcept
				@within Packet
				Sends the packet to all players except the specified player (Server-only).
				
				@param data T -- Data payload.
				@param except Player -- Player to exclude.
			]=]
			function packet:sendToAllExcept(data: T, except: Player)
				for _, player in Players:GetPlayers() do
					if player ~= except then
						packet:sendTo(data, player)
					end
				end
			end

			-- Client-only methods throw on server
			setmetatable(packet, {
				__index = function(_self: any, key: string)
					if key == "send" then
						error("[ByteFlow] Cannot call :send() on the server. Use :sendTo(), :sendToAll(), etc.")
					end
					return nil
				end,
			})
		else
			--[=[
				@method send
				@within Packet
				Sends the packet to the server (Client-only).
				
				@param data T -- Data payload.
			]=]
			function packet:send(data: T)
				local state = if reliability == "Reliable" then clientReliable else clientUnreliable
				ChannelState.setActive(state)
				writePacket(id, dataType, data)
			end

			-- Server-only methods throw on client
			setmetatable(packet, {
				__index = function(_self: any, key: string)
					if key == "sendTo" or key == "sendToAll" or key == "sendToList" or key == "sendToAllExcept" then
						error(`[ByteFlow] Cannot call :{key}() on the client. Use :send() instead.`)
					end
					return nil
				end,
			})
		end

		return packet :: Packet<T>
	end
end

--== Exported State Accessors (used by Process/Server.luau and Process/Client.luau) ==--

return table.freeze({
	definePacket = definePacket,

	-- Internal: channel state stores for the process layer
	_serverPlayerReliable = serverPlayerReliable,
	_serverPlayerUnreliable = serverPlayerUnreliable,
	_serverGlobalReliable = serverGlobalReliable,
	_serverGlobalUnreliable = serverGlobalUnreliable,
	_clientReliable = clientReliable,
	_clientUnreliable = clientUnreliable,
})
