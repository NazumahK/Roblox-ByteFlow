--!strict
--!optimize 2

--[=[
	@class Server
	
	Server-side process loop.
	On each Heartbeat, flushes all accumulated per-player and global
	channel states, firing buffers through RemoteEvent and UnreliableRemoteEvent.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChannelState = require(script.Parent.ChannelState)
local Reader = require(script.Parent.Reader)
local Packet = require(script.Parent.Parent.Packet)

local REMOTE_RELIABLE = "ByteFlowReliable"
local REMOTE_UNRELIABLE = "ByteFlowUnreliable"

local function start()
	-- Create remotes under ReplicatedStorage
	local reliableRemote: RemoteEvent = Instance.new("RemoteEvent")
	reliableRemote.Name = REMOTE_RELIABLE
	reliableRemote.Parent = ReplicatedStorage

	local unreliableRemote: UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
	unreliableRemote.Name = REMOTE_UNRELIABLE
	unreliableRemote.Parent = ReplicatedStorage

	-- Listen for incoming client buffers
	reliableRemote.OnServerEvent:Connect(function(player: Player, data: buffer, refs: { [number]: Instance }?)
		Reader.processBuffer(data, refs, player)
	end)

	unreliableRemote.OnServerEvent:Connect(function(player: Player, data: buffer, refs: { [number]: Instance }?)
		Reader.processBuffer(data, refs, player)
	end)

	-- Clean up per-player states on disconnect
	Players.PlayerRemoving:Connect(function(player: Player)
		Packet._serverPlayerReliable[player] = nil
		Packet._serverPlayerUnreliable[player] = nil
	end)

	-- Heartbeat flush loop
	RunService.Heartbeat:Connect(function()
		-- Flush per-player reliable
		for player, state in Packet._serverPlayerReliable do
			local data, refs = ChannelState.flush(state)
			if data then
				reliableRemote:FireClient(player, data, refs)
			end
		end

		-- Flush per-player unreliable
		for player, state in Packet._serverPlayerUnreliable do
			local data, refs = ChannelState.flush(state)
			if data then
				unreliableRemote:FireClient(player, data, refs)
			end
		end

		-- Flush global reliable (broadcast)
		local globalRelData, globalRelRefs = ChannelState.flush(Packet._serverGlobalReliable)
		if globalRelData then
			reliableRemote:FireAllClients(globalRelData, globalRelRefs)
		end

		-- Flush global unreliable (broadcast)
		local globalUnrelData, globalUnrelRefs = ChannelState.flush(Packet._serverGlobalUnreliable)
		if globalUnrelData then
			unreliableRemote:FireAllClients(globalUnrelData, globalUnrelRefs)
		end
	end)
end

return table.freeze({ start = start })
