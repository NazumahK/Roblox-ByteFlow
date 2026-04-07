--!strict
--!optimize 2

--[=[
	@class Types
	@within ByteFlow

	Core type definitions for the ByteFlow binary serialization framework.
]=]

--[=[
	@type DataType<T>
	@within ByteFlow
	The core data type descriptor.
]=]
export type DataType<T> = {
	__T: T,
	write: (value: T) -> (),
	read: (b: buffer, cursor: number, refMap: { [number]: Instance }?) -> (T, number),
	length: number?,
}

export type Reliability = "Reliable" | "Unreliable"

--[=[
	@type PacketConfig<T>
	@within ByteFlow
	Configuration for defining a packet.
]=]
export type PacketConfig<T> = {
	value: DataType<T>,
	reliability: Reliability?,
}

--[=[
	@type InvokeConfig<TReq, TRes>
	@within ByteFlow
	Configuration for defining an invoke channel.
]=]
export type InvokeConfig<TReq, TRes> = {
	request: DataType<TReq>,
	response: DataType<TRes>,
	reliability: Reliability?,
	timeout: number?,
}

export type Infer<D> = any

local Types = {}
return Types
