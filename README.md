# ByteFlow

ByteFlow is a high-performance binary serialization networking framework for Roblox, engineered from the ground up to provide maximum bandwidth efficiency and structural integrity. By utilizing Luau's `buffer` type and a sophisticated frame-aggregation system, ByteFlow scales seamlessly from simple prototypes to complex, data-heavy production environments.

## Core Philosophical Tenets

- **Minimalism**: Every byte transmitted must serve a purpose. ByteFlow eliminates the overhead of property names and repetitive metadata.
- **Performance**: High-frequency network operations utilize a built-in coroutine reuse pool and geometric buffer growth to minimize memory churn and CPU spikes.
- **Safety**: Strict Luau typing is enforced throughout the API, ensuring that network contracts are validated at compile-time rather than failing silently at runtime.
- **Reliability**: Primary support for both Reliable and Unreliable transport, with a robust request-response (Invoke) system featuring mandatory timeouts.

## System Highlights

### 1. Frame Aggregation
Instead of firing a `RemoteEvent` for every individual action, ByteFlow aggregates all outgoing data into an environment-specific buffer. This buffer is flushed exactly once per `Heartbeat`, dramatically reducing the overhead on the engine’s network task scheduler.

### 2. Coroutine Dispatch Pool
To avoid the cost of thread creation during high-frequency packet processing, ByteFlow maintains a pool of idle coroutines. Incoming packets are dispatched through this pool, ensuring peak performance even under heavy network load.

### 3. Deterministic Identity
ByteFlow uses alphabetical namespace sorting to assign packet IDs. This deterministic approach eliminates the need for manual ID management or complex handshaking, ensuring that the server and client always remain in biological sync as long as they share the same contract definitions.

---

## Installation

### Wally
Add ByteFlow to your project via [Wally](https://wally.run/):
```toml
ByteFlow = "your-scope/byteflow@version"
```

---

## Usage Overview

### Defining Contracts
Contracts should be defined in a shared module accessible by both Server and Client.

```luau
local ByteFlow = require(Packages.ByteFlow)

local Net = ByteFlow.defineNamespace("SharedNet", function()
    return {
        -- Fire-once notification
        notifyPlayer = ByteFlow.definePacket({
            value = ByteFlow.struct({
                title = ByteFlow.string,
                duration = ByteFlow.uint8
            }),
            reliability = "Unreliable"
        }),

        -- Bidirectional request
        fetchInventory = ByteFlow.defineInvoke({
            request = ByteFlow.uint32,
            response = ByteFlow.array(ByteFlow.string),
            timeout = 10
        }),
    }
end)

return Net
```

### Communication Examples

**Server (Broadcast & Response):**
```luau
-- Broadcast a notification
Net.notifyPlayer:sendToAll({ title = "Game Starting", duration = 5 })

-- Handle inventory requests
Net.fetchInventory:onInvoke(function(userId, player)
    return { "Sword", "Shield", "Potion" }
end)
```

**Client (Requesting):**
```luau
-- Yielding for server response
local items = Net.fetchInventory:invoke(game.Players.LocalPlayer.UserId)
print("Received items:", #items)
```

---

License: MIT
