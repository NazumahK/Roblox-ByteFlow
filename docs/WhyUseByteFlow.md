# Why Use ByteFlow?

This document outlines the practical benefits of implementing ByteFlow for Roblox networking.

## 1. Bandwidth Efficiency: Binary Compression

Native `RemoteEvent` and `RemoteFunction` objects use an internal encoding that serializes property names and metadata. This results in larger payloads than necessary for most data transfers.

- **ByteFlow's Advantage**: By pre-defining your data schema (`struct`, `array`, etc.), ByteFlow only sends raw bytes. 
- **Bandwidth Reduction**: Payloads can be up to 90% smaller than standard RemoteEvent data, providing lower latency for players with less optimized internet.

## 2. Prediction Performance: Batching

Firing numerous `RemoteEvents` in a single frame can cause significant engine-level performance degradation.

- **Frame Aggregation**: ByteFlow aggregates all outgoing network traffic into single buffers per frame, fired once on `Heartbeat`.
- **Latency Control**: This ensures a consistent networking throughput and minimizes the overhead on the Roblox engine's task scheduler.

## 3. Resource Stability: Thread Pooling

Most networking libraries create a new thread for every incoming message, increasing memory churn and GC pressure.

- **Coroutine Reuse Pool**: ByteFlow utilizes a built-in pool of idle coroutines for packet dispatch. 
- **Peak Performance**: This results in near-zero thread allocation costs, making it ideal for high-frequency networking systems (e.g., combat or movement synchronization).

## 4. Operational Safety: Reliable Invokes

Standard `RemoteFunctions` are notoriously dangerous because they can yield indefinitely if a client disconnects or an error occurs during execution.

- **Strict Invocations**: ByteFlow's `Invoke` system is built on a non-blocking `RemoteEvent` foundation with a mandatory 10-second timeout.
- **Safety**: Developers can safely await a response, knowing their thread will always be resumed with either data or a timeout warning.

## 5. Developer Productivity: Type Integrity

ByteFlow is built to be a robust foundation for large-scale projects.

- **Strict Type Safety**: Full Luau `--!strict` compliance ensures your networking contracts are validated at compile-time.
- **Deterministic ID Mapping**: Alphabetical sorting automates packet ID assignment, removing the risk of manual ID collisions or management fatigue.

---

For technical implementation details, see the [Architecture Guide](Architecture.md).
