--!strict
--!optimize 2
--!native

--[=[
	@class CFrame
	
	CFrame serializer using position (3 x float32) + quaternion (4 x float32).
	28 bytes fixed. Handles all arbitrary rotations without special-casing.
]=]

local Types = require(script.Parent.Parent.Types)
local ChannelState = require(script.Parent.Parent.Process.ChannelState)

type DataType<T> = Types.DataType<T>

--[=[
	Converts a CFrame's rotation to a unit quaternion (w, x, y, z).
	@private
]=]
local function toQuaternion(cf: CFrame): (number, number, number, number)
	local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	local trace = r00 + r11 + r22

	if trace > 0 then
		local s = math.sqrt(trace + 1.0) * 2.0
		return s * 0.25, (r21 - r12) / s, (r02 - r20) / s, (r10 - r01) / s
	elseif r00 > r11 and r00 > r22 then
		local s = math.sqrt(1.0 + r00 - r11 - r22) * 2.0
		return (r21 - r12) / s, s * 0.25, (r01 + r10) / s, (r02 + r20) / s
	elseif r11 > r22 then
		local s = math.sqrt(1.0 + r11 - r00 - r22) * 2.0
		return (r02 - r20) / s, (r01 + r10) / s, s * 0.25, (r12 + r21) / s
	else
		local s = math.sqrt(1.0 + r22 - r00 - r11) * 2.0
		return (r10 - r01) / s, (r02 + r20) / s, (r12 + r21) / s, s * 0.25
	end
end

--[=[
	Reconstructs a CFrame from position + unit quaternion.
	@private
]=]
local function fromQuaternion(
	px: number,
	py: number,
	pz: number,
	qw: number,
	qx: number,
	qy: number,
	qz: number
): CFrame
	local xx, yy, zz = qx * qx, qy * qy, qz * qz
	local xy, xz, yz = qx * qy, qx * qz, qy * qz
	local wx, wy, wz = qw * qx, qw * qy, qw * qz

	return CFrame.new(
		px,
		py,
		pz,
		1.0 - 2.0 * (yy + zz),
		2.0 * (xy - wz),
		2.0 * (xz + wy),
		2.0 * (xy + wz),
		1.0 - 2.0 * (xx + zz),
		2.0 * (yz - wx),
		2.0 * (xz - wy),
		2.0 * (yz + wx),
		1.0 - 2.0 * (xx + yy)
	)
end

local cframe: DataType<CFrame> = table.freeze({
	__T = nil :: any,
	write = function(value: CFrame)
		local offset = ChannelState.allocate(28)
		local buff = ChannelState.getActive().buff
		local pos = value.Position
		buffer.writef32(buff, offset, pos.X)
		buffer.writef32(buff, offset + 4, pos.Y)
		buffer.writef32(buff, offset + 8, pos.Z)

		local qw, qx, qy, qz = toQuaternion(value)
		buffer.writef32(buff, offset + 12, qw)
		buffer.writef32(buff, offset + 16, qx)
		buffer.writef32(buff, offset + 20, qy)
		buffer.writef32(buff, offset + 24, qz)
	end,
	read = function(b: buffer, cursor: number): (CFrame, number)
		local px = buffer.readf32(b, cursor)
		local py = buffer.readf32(b, cursor + 4)
		local pz = buffer.readf32(b, cursor + 8)
		local qw = buffer.readf32(b, cursor + 12)
		local qx = buffer.readf32(b, cursor + 16)
		local qy = buffer.readf32(b, cursor + 20)
		local qz = buffer.readf32(b, cursor + 24)
		return fromQuaternion(px, py, pz, qw, qx, qy, qz), 28
	end,
	length = 28,
})

return cframe
