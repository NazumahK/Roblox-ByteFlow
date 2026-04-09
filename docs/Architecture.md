# Technical Architecture

This document details the internal design and performance optimizations of the ByteFlow engine (v2.1.0).

## 1. Loop Efficiency: The Dirty Flag System

Traditional networking engines often iterate over every connected player during the `Heartbeat` cycle to flush pending buffers. This leads to an $O(N)$ CPU cost relative to the player count.

ByteFlow eliminates this bottleneck by maintaining **Dirty Sets** for both Reliable and Unreliable channels. If a player state is mutated during a frame, the player is marked as "dirty." The flush loop then only iterates over this set, resulting in an $O(N_{active\_players})$ complexity.

## 2. Memory Management: Geometric Buffer Expansion

To minimize the high cost of memory reallocations in Luau, ByteFlow employs a geometric growth strategy for its internal buffers. When a buffer's capacity is reached, its size is doubled rather than incrementally increased. 

Furthermore, the `ensureCapacity` mechanism pre-calculates the required space for complex structures, ensuring that only a single allocation (or copy) occurs even when writing deeply nested data.

## 3. Transactional Integrity

ByteFlow v2.1.0 introduces **Transactional Packet Writing**. Unlike other buffer-based libraries where a serialization error might leave the buffer cursor at an offset position (corrupting the entire stream), ByteFlow records the starting cursor before each write.

If the `DataType.write` method throws an error (e.g., trying to write an incorrect Luau type to a specific binary field), the engine catches the error, restores the cursor to its previous position, and issues a warning. This ensures the packet stream remains synchronized and valid for all subsequent writes in the same frame.

## 4. Stability: Defensive Pre-Processing

Before any payload is processed:
1.  **Size Validation**: Payloads exceeding the `MAX_INCOMING_SIZE` (64KB default) are dropped immediately.
2.  **Referential Bounds**: Reference maps (Instances) are capped to prevent memory exhaustion via reference spam.
3.  **Range Validation**: The reader ensures that the packet ID and header can be safely read before even attempting to look up the reader function.
4.  **Error Isolation**: Deserialization is wrapped in `pcall`. A malformed packet from a client will only result in that specific packet being skipped, without interrupting the rest of the frame's processing.

## 5. Automated Bit-Level Optimization

The `Struct` serializer includes a pre-compilation step that generates an optimized execution plan. This plan identifies consecutive boolean types and groups them into bit-fields. At runtime, these are handled via bitwise operations (`bor`, `lshift`) rather than individual byte writes, optimizing both bandwidth and CPU cache locality.
