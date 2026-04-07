# Technical Architecture

This document provides a detailed breakdown of the internal implementation and optimizations of the ByteFlow networking library.

## 1. Frame Aggregation: Batching Logic

Unlike standard `RemoteEvent` fires that incur overhead for every call, ByteFlow utilizes a frame-level aggregation strategy.

- **Aggregation Phase**: Every `:send()`, `:sendTo()`, or `:invoke()` call writes to an environment-specific `ChannelState` buffer.
- **Flush Phase**: On every `Heartbeat`, ByteFlow dumps the aggregated buffers into single `RemoteEvent` fires.
- **Efficiency**: This minimizes the number of actual network transmissions, significantly reducing the overhead on the Roblox engine's task scheduler.

## 2. Resource Management: Coroutine Pooling

To eliminate the cost of thread allocation and garbage collection, the library implements a module-level coroutine reuse pool (`freeThreads`).

- **Reuse Cycle**: After a packet handler completes, the thread yields back to the pool instead of terminating.
- **Performance**: High-frequency network events (e.g., weapon firing or physical synchronization) benefit from zero thread allocation overhead.

```lua
-- Conceptual Coroutine Reuse
local function yielder()
    while true do
        local fn, data, sender = coroutine.yield()
        fn(data, sender)
        table.insert(freeThreads, coroutine.running())
    end
end
```

## 3. Serialization Efficiency: Deterministic ID Mapping

ByteFlow eliminates the need for manual ID management by using alphabetical sorting for all network contracts within a namespace.

1. `defineNamespace` iterates through all definitions.
2. Keys are sorted alphabetically.
3. IDs are assigned sequentially starting from 0.
4. **Conclusion**: As long as server and client scripts share the same factory function, they will always remain in sync without dynamic negotiation or manual ID overhead.

## 4. Binary Layout: Minimal Overhead

ByteFlow minimizes bandwidth consumption by using a compact binary representation for every packet.

### Standard Packet
- **Byte 0**: `uint8` Packet ID.
- **Bytes 1+**: Compressed payload.

### Invoke Packet
- **Byte 0**: `uint8` Packet ID.
- **Bytes 1-4**: `uint32` Correlation ID (Matches responses back to the original request thread).
- **Bytes 5+**: Compressed payload.

## 5. State Management: Zero-Overhead Scoping

The serialization module uses a state-swapping pattern to achieve peak write performance without passing state objects as function arguments.

```lua
-- Conceptual State Swapping
local active: State

function setActive(state: State)
    active = state
end

function writeByte(val: number)
    -- Operates directly on the active upvalue
    buffer.writeu8(active.buff, active.cursor, val)
    active.cursor += 1
end
```

## Summary

The architecture focuses on algorithmic stability ($O(1)$ dispatch) and deterministic resource usage, ensuring that the network layer scales predictably under high load.
