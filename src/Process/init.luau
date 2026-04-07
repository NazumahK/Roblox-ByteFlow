--!strict
--!optimize 2

--[=[
	@class Process
	
	Auto-detects server/client context and starts the appropriate process loop.
	Called once from the main init module on require.
]=]

local RunService = game:GetService("RunService")

local function start()
	if RunService:IsServer() then
		require(script.Server).start()
	else
		require(script.Client).start()
	end
end

return table.freeze({ start = start })
