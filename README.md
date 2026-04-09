# ByteFlow

A high-performance, buffer-based binary serialization networking engine for Roblox. ByteFlow v2.1.0 introduces industry-leading optimizations including Auto Bit-Packing and Transactional Writes.

## Core Features

- **Geometric Buffer Allocation**: Minimizes memory reallocations by doubling buffer capacity as needed.
- **Auto Bit-Packing Engine**: Automatically compresses consecutive boolean fields within structs into single bits, reducing bandwidth usage for state flags by up to 800%.
- **Transactional Consistency**: Packets are written atomically. If a serialization error occurs, the engine rolls back the buffer cursor to ensure subsequent packets remain intact.
- **Dirty Flag Dispatch**: On the server, the Heartbeat loop only iterates over players who have pending data, moving dispatch complexity from $O(N_{players})$ to $O(N_{dirty})$.
- **Advanced Observability**: Built-in support for real-time bandwidth monitoring and a robust incoming/outgoing middleware pipeline.
- **DoS Protection**: Enforcement of payload size limits and instance reference counts to harden the server against malicious input.
- **Deterministic Hashing**: Alphabetical namespace sorting and FNV-1a hashing ensure consistent packet IDs across the network barrier.

## Installation

Add to your `wally.toml`:

```toml
[dependencies]
ByteFlow = "nazumahk/byteflow@2.1.0"
```

## Quick Start

```luau
local ByteFlow = require(Packages.ByteFlow)
local t = ByteFlow.t

local Net = ByteFlow.defineNamespace("Shared", function()
    return {
        -- Automatically packed into 1 byte instead of 8 bytes
        UpdateUI = ByteFlow.definePacket({
            value = t.struct({
                showLabels = t.bool,
                showIcons = t.bool,
                isInteractive = t.bool,
                isAnimating = t.bool,
                isVisible = t.bool,
                isDisabled = t.bool,
                isHovered = t.bool,
                isSelected = t.bool,
            }),
            reliability = "Reliable"
        })
    }
end)

-- Transactional write
Net.UpdateUI:send({
    showLabels = true,
    showIcons = true,
    -- ... and so on
})
```

## Advanced Usage

### Bandwidth Monitoring
```luau
local stats = ByteFlow.bandwidth.stats
print("Outgoing bytes this second:", stats.bytes_out)
```

### Middleware Pipeline
```luau
ByteFlow.middleware.addIncoming(function(id, data, sender)
    -- Filter or log incoming packets
    return true -- Return false to drop the packet
end)
```

## Documentation

- [Technical Architecture](docs/Architecture.md) -- Buffer Management & Dispatch Logic
- [API Specification](docs/API.md) -- Type & Method Reference

## License

MIT
