# ByteFlow

A high-performance, buffer-based binary serialization networking framework for Roblox.

## Features

- **Binary Serialization**: Zero-overhead buffer operations for minimal bandwidth consumption.
- **Deterministic Namespaces**: Alphabetical ID assignment ensures automated server-client synchronization.
- **Bidirectional Invocations**: Native request-response system with mandatory timeouts and correlation tracking.
- **Coroutine Pooling**: Reuses threads for packet dispatch to minimize allocation overhead.
- **Type Strict**: Full Luau `--!strict` compliance with robust generic support.

## Installation

Add to your `wally.toml`:

```toml
[dependencies]
ByteFlow = "nazumahk/byteflow@1.0.0"
```

## Quick Start

```lua
local ByteFlow = require(path.to.ByteFlow)

local Net = ByteFlow.defineNamespace("Shared", function()
    return {
        chat = ByteFlow.definePacket({
            value = ByteFlow.struct({ message = ByteFlow.string }),
            reliability = "Unreliable"
        }),
        getRank = ByteFlow.defineInvoke({
            request = ByteFlow.uint32,
            response = ByteFlow.string
        })
    }
end)

-- Fire-and-forget
Net.chat:send({ message = "Hello!" })

-- Request-response
local rank = Net.getRank:invoke(12345)
```

## Documentation

- [Why Use ByteFlow?](docs/WhyUseByteFlow.md) -- Efficiency and Stability Advantages
- [Technical Architecture](docs/Architecture.md) -- Internal Buffering & Dispatch Logic
- [API Specification](docs/API.md) -- Detailed Method & Type Reference

## License
MIT
