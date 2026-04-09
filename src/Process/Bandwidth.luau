--!strict
--!optimize 2

--[=[
	@class Bandwidth
	
	Real-time bandwidth monitoring for ByteFlow.
	Tracks bytes and packet counts for both incoming and outgoing traffic.
]=]

local stats = {
	bytes_in = 0,
	bytes_out = 0,
	packets_in = 0,
	packets_out = 0,
}

local function recordIn(bytes: number)
	stats.bytes_in += bytes
	stats.packets_in += 1
end

local function recordOut(bytes: number)
	stats.bytes_out += bytes
	stats.packets_out += 1
end

local function reset()
	stats.bytes_in = 0
	stats.bytes_out = 0
	stats.packets_in = 0
	stats.packets_out = 0
end

return table.freeze({
	stats = stats,
	recordIn = recordIn,
	recordOut = recordOut,
	reset = reset,
})
