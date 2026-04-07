# API Specification

A formal specification for ByteFlow's networking types and methods.

---

## `ByteFlow (Static)`

The entry point for defining your network contracts.

### Methods

#### `ByteFlow.defineNamespace<T>(name: string, factory: () -> T): T`
Encapsulates a group of packets and invokes. Assigns deterministic IDs based on alphabetical sorting.
```lua
local Net = ByteFlow.defineNamespace("Items", function()
    return {
        buy = ByteFlow.definePacket({ value = ByteFlow.uint32 })
    }
end)
```

#### `ByteFlow.definePacket<T>(config: PacketConfig<T>): (id: number) -> Packet<T>`
Defines a fire-and-forget payload contract.
```lua
local myPacketDef = ByteFlow.definePacket({
    value = ByteFlow.struct({ name = ByteFlow.string }),
    reliability = "Unreliable"
})
```

#### `ByteFlow.defineInvoke<TReq, TRes>(config: InvokeConfig<TReq, TRes>): InvokeDescriptor`
Defines a bidirectional request-response contract.
```lua
local myInvokeDef = ByteFlow.defineInvoke({
    request = ByteFlow.uint32,
    response = ByteFlow.array(ByteFlow.string),
    timeout = 10
})
```

---

## `Packet<T>`

Fire-and-forget messaging between the server and clients.

### Methods

#### `Packet:send(data: T)`
(Client-only) Sends the packet to the server.
```lua
Net.chat:send({ msg = "Hello!" })
```

#### `Packet:sendTo(data: T, player: Player)`
(Server-only) Targets a specific player.
```lua
Net.chat:sendTo({ msg = "Secret message" }, player)
```

#### `Packet:sendToAll(data: T)`
(Server-only) Broadcasts to all connected players.
```lua
Net.chat:sendToAll({ msg = "Global announcement" })
```

#### `Packet:listen(callback: (data: T, sender: Player?) -> ())`
Registers a listener for incoming packets.
```lua
Net.chat:listen(function(data, sender)
    print(`[{sender}]: {data.msg}`)
end)
```

#### `Packet:wait(): (T, Player?)`
Yields the current thread until the packet is received.
```lua
local data, sender = Net.chat:wait()
```

---

## `Invoke<TReq, TRes>`

Synchronous bidirectional request-response system.

### Methods

#### `Invoke:invoke(data: TReq, player: Player?): TRes`
Sends a request and yields for a response. **Player is required on server.**
```lua
local stats = Net.getStats:invoke(userId, somePlayer)
```

#### `Invoke:onInvoke(handler: (data: TReq, sender: Player?) -> TRes)`
Registers a handler that processes requests.
```lua
Net.getStats:onInvoke(function(userId, sender)
    return { kills = 100, deaths = 2 }
end)
```

---

## Data Types Reference

ByteFlow supports a complete suite of serializable primitives and composite wrappers.

### Standard
- `uint8`, `uint16`, `uint32`: Unsigned integers (1, 2, 4 bytes).
- `int8`, `int16`, `int32`: Signed integers.
- `float32`, `float64`: Floating-point numbers.
- `bool`, `string`: Primitives.
- `buff`: Raw Luau `buffer` serialization.

### Roblox
- `inst`: Reliable `Instance` reference.
- `vec2`, `vec3`, `cframe`: Geometric types.
- `color3`, `brickColor`: Visual types.
- `udim`, `udim2`, `rect`: UI types.
- `font`, `tweenInfo`, `pathWaypoint`: Advanced types.

### Composite Wrappers
- `struct({ key = type })`: Fixed-key dictionary (Most efficient).
- `array(type)`: Integer-indexed sequences.
- `map(kType, vType)`: Dynamic-key dictionary.
- `optional(type)`: Wraps a value that may be nil.

---

## Summary

- **Single Frame Batching**: All `send()` calls aggregate into a single frame buffer.
- **Strict Contracts**: Ensure shared modules are identical between server and client.
- **Invoke Responsibility**: Always implement `onInvoke` for both server and client to prevent timeouts.
