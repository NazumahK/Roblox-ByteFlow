# Internal Architecture

ByteFlow is not merely a wrapper around RemoteEvents; it is a full-featured binary serialization pipeline. This document provides a technical deep-dive into the optimizations that allow ByteFlow to outperform standard networking solutions.

---

## 1. Frame Aggregation and Single-Fire Flushing
ByteFlow eliminates the high cost of multiple `RemoteEvent` fires by aggregating all network traffic into frame-scoped buffers.

- **Aggregation Phase**: Every `:send()`, `:sendTo()`, or `:invoke()` call writes to an internal `ChannelState`.
- **Flush Phase**: On every `Heartbeat`, ByteFlow iterates through all dirty channel states (per-player reliable/unreliable and global reliable/unreliable) and fires them through a single batch `RemoteEvent` or `UnreliableRemoteEvent`.
- **Latency Optimization**: This ensures that even hundreds of network calls in a single frame result in only a handful of actual network transmissions.

## 2. Coroutine Dispatch Pool (Thread Reuse)
To avoid the CPU-intensive cost of creating a new `thread` for every incoming packet, ByteFlow maintains a dedicated coroutine reuse pool.

- **Yielder Pattern**: ByteFlow pre-creates a pool of `yielder` coroutines that stay suspended on a `coroutine.yield()`.
- **Reuse Cycle**: When an incoming packet is processed, an idle thread is popped from the pool, resumed with the listener function, and automatically returned to the pool after execution.
- **Benefits**: Significant reduction in memory churn and GC pressure during high-throughput scenarios.

## 3. High-Performance Channel Swapping
ByteFlow uses a state-swapping pattern to maintain zero-overhead serialization.

- **Upvalue Mutation**: During a `write` operation, the `ChannelState.setActive()` function updates an internal upvalue in the serialization module.
- **Direct Access**: All `DataType.write()` functions operate directly on the active buffer without needing to pass state objects as function arguments, minimizing stack overhead on the networking hot-path.

## 4. Geometric Buffer Allocation
ByteFlow avoids frequent memory reallocations by using geometric (2×) buffer growth. When a write operation exceeds the current buffer capacity, the buffer size is doubled, amortizing the cost of allocation over time.

## 5. Binary Layout Specification

### Standard Packet
- **Byte 0**: `uint8` Packet ID (Deterministic via namespace sorting).
- **Bytes 1+**: Compressed payload (Variable length).

### Invoke Packet
- **Byte 0**: `uint8` Packet ID.
- **Bytes 1-4**: `uint32` Correlation ID (Maps responses to the waiting request thread).
- **Bytes 5+**: Compressed payload.

## 6. Deterministic Namespace Identity
ByteFlow guarantees that server and client agree on packet IDs without any runtime negotiation.

1. `defineNamespace` extracts all keys from the definition factory.
2. Keys are sorted alphabetically.
3. Every packet is assigned exactly 1 ID, and every invite is assigned exactly 2 IDs (Request and Response).
4. **Key Requirement**: The namespace factory function must be shared and produce identical keys on both sides for deterministic ID mapping.
