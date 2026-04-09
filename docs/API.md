# API Specification

This document provides a technical reference for all public modules and data types in ByteFlow v2.1.0.

## 1. Core Modules

### `ByteFlow.defineNamespace`
```luau
function ByteFlow.defineNamespace(name: string, members: () -> { [string]: any }): Namespace
```
Initializes a new networking namespace. The provided function should return a table of packets or invokes.

### `ByteFlow.middleware`
Provides a global pipeline for packet interception.
- **`addIncoming(fn: (id: number, data: any, sender: Player?) -> boolean)`**: Register a listener for inbound packets. Return `false` to drop the packet.
- **`addOutgoing(fn: (id: number, data: any, player: Player?) -> boolean)`**: Register a listener for outbound packets.

### `ByteFlow.bandwidth`
Exposes the `stats` table for tracking traffic.
- **`stats.bytes_in`**: Total bytes received in the last second.
- **`stats.bytes_out`**: Total bytes sent in the last second.
- **`stats.packets_in`**: Total packets received in the last second.
- **`stats.packets_out`**: Total packets sent in the last second.

## 2. Packet API

### `ByteFlow.definePacket`
```luau
function ByteFlow.definePacket<T>(config: {
    value: DataType<T>,
    reliability: "Reliable" | "Unreliable"?
}): Packet<T>
```
Methods:
- **`send(data: T)`**: Client only.
- **`sendTo(data: T, player: Player)`**: Server only.
- **`sendToAll(data: T)`**: Server only.
- **`listen(callback: (data: T, sender: Player?) -> ()): () -> ()`**: Returns a cleanup function to disconnect the listener.

## 3. Data Types (`ByteFlow.t`)

| Type | Description |
|:---|:---|
| `bool` | High-performance boolean. Structs pack consecutive bools into bits. |
| `uint8`, `uint16`, `uint32` | Unsigned integers. |
| `int8`, `int16`, `int32` | Signed integers. |
| `float32`, `float64` | Floating point numbers. |
| `string` | Length-prefixed UTF-8 string. |
| `vec3`, `cframe`, `color3` | Standard Roblox geometric types. |
| `inst` | Instance reference (replicated via RemoteEvent ID). |
| `buff` | Raw buffer payload. |
| `struct({ [string]: DataType })` | Deterministic binary structure with auto bit-packing. |
| `array(DataType)` | Homogeneous list of data types. |
| `optional(DataType)` | Nullable wrapper (adds a 1-bit boolean flag). |

## 4. Stability Settings (Server)

Internal constants enforced at the engine level:
- **`MAX_INCOMING_SIZE`**: 65,536 bytes.
- **`MAX_REFERENCES`**: 64 instances per packet.
- **`RELIABLE_BUFFER_LIMIT`**: 1,048,576 bytes per player.
