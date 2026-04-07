# Why Use ByteFlow?

Networking is at the heart of any Roblox game. While standard `RemoteEvent` and `RemoteFunction` objects work for small interactions, they quickly become a performance bottleneck as your game grows. ByteFlow is designed to bridge the gap between high-level convenience and low-level performance.

---

## 1. Drastic Bandwidth Savings

Roblox's standard networking sends property names and metadata alongside your data. ByteFlow eliminates this entirely by serializing only the raw values into a compressed binary buffer.

- **Outcome**: A message that might take 100 bytes via `RemoteEvent` can occupy as little as 10 bytes in ByteFlow. This directly translates to lower ping and smoother experiences for players with limited internet connection.

## 2. Advanced Performance Engineering

Most networking libraries focus only on serialization. ByteFlow focuses on the entire lifecycle of a network packet.

- **Thread Reuse Pool**: ByteFlow's built-in coroutine pool is a rarity in Roblox networking frameworks. By reusing idle coroutines instead of creating new ones on every receipt, ByteFlow provides a stable, low-latency dispatch system that won't cause CPU spikes during high network traffic.

## 3. High-Performance Frame Batching

Firing many `RemoteEvents` in a single frame is a major performance drain. ByteFlow's batching system flushes all outgoing data exactly once per `Heartbeat`. This ensures that your network throughput remains optimal and your engine's task scheduler isn't overwhelmed.

## 4. Bulletproof Invocations (Requests)

Standard `RemoteFunctions` are risky; they can yield indefinitely if the client disconnects or if the script errors on the other side. 

- **The ByteFlow Solution**: ByteFlow's `Invoke` system is built on top of `RemoteEvents` with an enforced 10-second timeout. This ensures that your logic never hangs and your server/client remains responsive, regardless of network conditions.

## 5. Developer-First Experience

Writing network code shouldn't be tedious. ByteFlow's `defineNamespace` approach provides:

- **Strict Type Safety**: Full Luau autocomplete and compile-time validation for your network payloads.
- **Automatic ID Assignment**: Never manually assign a packet ID again. Alphabetical sorting handles it all for you deterministically.
- **Centralized Contracts**: A single shared module becomes the authoritative source of truth for your game's entire networking layer.

---

## Conclusion
Whether you're developing a competitive shooter where every millisecond counts, or a complex RPG with frequent data synchronization, ByteFlow gives you the tools to build a fast, safe, and scalable network infrastructure.
