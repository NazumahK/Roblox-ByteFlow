--!strict
--!optimize 2

--[=[
	@class Client
	
	Client-side process loop.
	Waits for server-created remotes, listens for incoming server buffers,
	and flushes client channel states on Heartbeat.
]=]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChannelState = require(script.Parent.ChannelState)
local Reader = require(script.Parent.Reader)
local Packet = require(script.Parent.Parent.Packet)

local REMOTE_RELIABLE = "ByteFlowReliable"
local REMOTE_UNRELIABLE = "ByteFlowUnreliable"

local function start()
	-- Wait for server-created remotes
	local reliableRemote = ReplicatedStorage:WaitForChild(REMOTE_RELIABLE) :: RemoteEvent
	local unreliableRemote = ReplicatedStorage:WaitForChild(REMOTE_UNRELIABLE) :: UnreliableRemoteEvent

	-- Listen for incoming server buffers
	reliableRemote.OnClientEvent:Connect(function(data: buffer, refs: { [number]: Instance }?)
		Reader.processBuffer(data, refs, nil)
	end)

	unreliableRemote.OnClientEvent:Connect(function(data: buffer, refs: { [number]: Instance }?)
		Reader.processBuffer(data, refs, nil)
	end)

	-- Heartbeat flush loop
	RunService.Heartbeat:Connect(function()
		-- Flush reliable channel
		local relData, relRefs = ChannelState.flush(Packet._clientReliable)
		if relData then
			reliableRemote:FireServer(relData, relRefs)
		end

		-- Flush unreliable channel
		local unrelData, unrelRefs = ChannelState.flush(Packet._clientUnreliable)
		if unrelData then
			unreliableRemote:FireServer(unrelData, unrelRefs)
		end
	end)
end

return table.freeze({ start = start })
