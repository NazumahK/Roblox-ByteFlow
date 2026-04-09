--!strict
--!optimize 2

local Types = require(script.Parent.Parent.Types)

type DataType<T> = Types.DataType<T>

--[=[
	DataType representing no payload. Write/read are no-ops.
	Use `nothing` for packets that only signal an event with no associated data.
]=]
local nothing: DataType<nil> = table.freeze({
	__T = nil :: any,
	write = function(_value: nil) end,
	read = function(_b: buffer, _cursor: number): (nil, number)
		return nil, 0
	end,
	length = 0,
})

return nothing
