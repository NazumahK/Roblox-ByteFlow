--!strict
--!optimize 2
--!native

--[=[
	@class Server
	
	Server-side process loop.
	On each Heartbeat, flushes accumulated channel states for dirty players only.
	
	Improvements over v1:
	- Dirty flag optimization: only iterate players who have pending data
	- Input validation: buffer size limit, reference count limit, type checks
	- Bandwidth tracking on outgoing flushes
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChannelState = require(script.Parent.ChannelState)
local Reader = require(script.Parent.Reader)
local Bandwidth = require(script.Parent.Bandwidth)
local Packet = require(script.Parent.Parent.Packet)

local REMOTE_RELIABLE = "ByteFlowReliable"
local REMOTE_UNRELIABLE = "ByteFlowUnreliable"

-- Security limits
local MAX_INCOMING_SIZE: number = 65536
local MAX_REFERENCES: number = 64

-- Dirty flags: only players in these tables need flushing
local dirtyReliable: { [Player]: boolean } = {}
local dirtyUnreliable: { [Player]: boolean } = {}

--- Marks a player's reliable channel as dirty (has pending data).
local function markDirtyReliable(player: Player)
	dirtyReliable[player] = true
end

--- Marks a player's unreliable channel as dirty.
local function markDirtyUnreliable(player: Player)
	dirtyUnreliable[player] = true
end

--- Validates and processes incoming client data with security checks.
local function onServerEvent(player: Player, data: unknown, refs: unknown)
	-- Type validation
	if typeof(data) ~= "buffer" then
		return
	end

	-- Size limit: prevent DoS via oversized buffers
	if buffer.len(data :: buffer) > MAX_INCOMING_SIZE then
		return
	end

	-- Reference count validation
	local validRefs: { [number]: Instance }? = nil
	if refs ~= nil then
		if typeof(refs) ~= "table" then
			return
		end
		local count = 0
		for _ in refs :: any do
			count += 1
			if count > MAX_REFERENCES then
				return
			end
		end
		validRefs = refs :: any
	end

	Reader.processBuffer(data :: buffer, validRefs, player)
end

local function start()
	-- Create remotes under ReplicatedStorage
	local reliableRemote: RemoteEvent = Instance.new("RemoteEvent")
	reliableRemote.Name = REMOTE_RELIABLE
	reliableRemote.Parent = ReplicatedStorage

	local unreliableRemote: UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
	unreliableRemote.Name = REMOTE_UNRELIABLE
	unreliableRemote.Parent = ReplicatedStorage

	-- Listen for incoming client buffers (with validation)
	reliableRemote.OnServerEvent:Connect(onServerEvent)
	unreliableRemote.OnServerEvent:Connect(onServerEvent)

	-- Initialize per-player states on join
	Players.PlayerAdded:Connect(function(player: Player)
		Packet._serverPlayerReliable[player] = ChannelState.createState()
		Packet._serverPlayerUnreliable[player] = ChannelState.createState()
	end)

	-- Clean up per-player states on disconnect
	Players.PlayerRemoving:Connect(function(player: Player)
		Packet._serverPlayerReliable[player] = nil
		Packet._serverPlayerUnreliable[player] = nil
		dirtyReliable[player] = nil
		dirtyUnreliable[player] = nil
	end)

	-- Heartbeat flush loop
	RunService.Heartbeat:Connect(function()
		-- Flush dirty per-player reliable (NOT all players)
		for player in dirtyReliable do
			local state = Packet._serverPlayerReliable[player]
			if state then
				local data, refs = ChannelState.flush(state)
				if data then
					Bandwidth.recordOut(buffer.len(data))
					reliableRemote:FireClient(player, data, refs)
				end
			end
		end
		table.clear(dirtyReliable)

		-- Flush dirty per-player unreliable
		for player in dirtyUnreliable do
			local state = Packet._serverPlayerUnreliable[player]
			if state then
				local data, refs = ChannelState.flush(state)
				if data then
					Bandwidth.recordOut(buffer.len(data))
					unreliableRemote:FireClient(player, data, refs)
				end
			end
		end
		table.clear(dirtyUnreliable)

		-- Flush global reliable (broadcast)
		local globalRelData, globalRelRefs = ChannelState.flush(Packet._serverGlobalReliable)
		if globalRelData then
			Bandwidth.recordOut(buffer.len(globalRelData))
			reliableRemote:FireAllClients(globalRelData, globalRelRefs)
		end

		-- Flush global unreliable (broadcast)
		local globalUnrelData, globalUnrelRefs = ChannelState.flush(Packet._serverGlobalUnreliable)
		if globalUnrelData then
			Bandwidth.recordOut(buffer.len(globalUnrelData))
			unreliableRemote:FireAllClients(globalUnrelData, globalUnrelRefs)
		end
	end)
end

return table.freeze({
	start = start,
	markDirtyReliable = markDirtyReliable,
	markDirtyUnreliable = markDirtyUnreliable,
})
