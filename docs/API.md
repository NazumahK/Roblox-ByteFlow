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

ByteFlow supports a complete suite of serializable primitives and composite wrappers. Choosing the correct type is critical for minimizing bandwidth.

### Numeric Primitives

#### Integers (Discrete)
- **`uint8`, `uint16`, `uint32`**: Unsigned integers (1, 2, 4 bytes). Use for counts, IDs, or non-negative values.
- **`int8`, `int16`, `int32`**: Signed integers. Use for values that can be negative.

#### Floating Point (Continuous)
- **`float32`**: Standard precision (4 bytes). Sufficient for most game logic (Positions, Health).
- **`float64`**: High precision (8 bytes). Use for extremely large numbers or precise timestamps.

### Geometric & Roblox Types

- **`inst`**: A reliable reference to a Roblox `Instance`. Ensures the instance exists on the receiver.
- **`vec2`, `vec3`**: `Vector2` and `Vector3` types (8 and 12 bytes respectively).
- **`cframe`**: A coordinate frame. Serialized as a position and a compressed rotation (16+ bytes).
- **`color3`, `color3uint8`**: Standard `Color3` and a more efficient 3-byte variant.
- **`brickColor`**: Efficient serialization of the `BrickColor` enum.

### UI & Interaction

- **`udim`, `udim2`, `rect`**: Standards for UI layout and dimensions.
- **`font`, `tweenInfo`**: Used for synchronizing visual properties.
- **`dateTime`**: Serialized `DateTime` objects for synchronized game clocks.

### Composite Generic Wrappers

These special types allow you to define complex, nested data structures.

#### `ByteFlow.struct(descriptor: { [string]: DataType<any> })`
Serializes a fixed-key dictionary. Highly efficient because keys are **not** transmitted; only the ordered values are.
```lua
local profileType = ByteFlow.struct({
    name = ByteFlow.string,
    level = ByteFlow.uint32,
    isAdmin = ByteFlow.bool
})
```

#### `ByteFlow.array(dataType: DataType<any>)`
Serializes a sequence of values of a specific type.
```lua
local scoresType = ByteFlow.array(ByteFlow.uint32)
```

#### `ByteFlow.map(keyType: DataType<any>, valueType: DataType<any>)`
Serializes a dynamic dictionary. Use this only when keys are variable; otherwise, `struct` is faster.
```lua
local metadataType = ByteFlow.map(ByteFlow.string, ByteFlow.uint32)
```

#### `ByteFlow.optional(dataType: DataType<any>)`
Wraps a value that may be `nil`. Uses exactly 1 byte for the nil-check flag.
```lua
local nicknameType = ByteFlow.optional(ByteFlow.string)
```

#### `ByteFlow.enum(enumItem: Enum)`
Serializes any Roblox `Enum` value efficiently as a numeric index.
```lua
local stateType = ByteFlow.enum(Enum.HumanoidStateType)
```

---

## Best Practices

- **Prefer Structs over Maps**: Maps transmit keys as strings/data, whereas Structs transmit zero key data.
- **Use the Smallest Integer**: If a value never exceeds 255, use `uint8` instead of `uint32` to save 3 bytes per fire.
- **Reliability Choice**: Use `Unreliable` for data that changes every frame (like positions) to avoid network congestion.
