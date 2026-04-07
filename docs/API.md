# API Reference

ByteFlow is an authoritative, type-strict networking API. This document serves as the formal specification for all exported methods and the underlying data type system.

## Namespace & Configuration

### `ByteFlow.defineNamespace<T>`
Encapsulates a logical group of network contracts.
- **`name: string`**: Unique identifier for the namespace.
- **`factory: () -> T`**: A factory function returning a dictionary of packet/invoke definitions.
- **Returns**: `T`.

### `ByteFlow.definePacket<T>`
Defines a fire-and-forget payload contract.
- **`config: PacketConfig<T>`**
- **`reliability: "Reliable" | "Unreliable"`** (Default: "Reliable").
- **`value: DataType<T>`**: The data type schema for the payload.

### `ByteFlow.defineInvoke<TReq, TRes>`
Defines a bidirectional request-response contract.
- **`config: InvokeConfig<TReq, TRes>`**
- **`request: DataType<TReq>`**: The request schema.
- **`response: DataType<TRes>`**: The response schema.
- **`timeout: number?`**: Maximum seconds to yield (Default: 10s).
- **`reliability: "Reliable" | "Unreliable"`**.

---

## Packet Instance Methods

### Shared
- **`listen(callback: (data: T, sender: Player?) -> ())`**: Registers a listener. `sender` is provided on the server when receiving from a client.
- **`wait(): (T, Player?)`**: Yields the current thread until the next receipt.

### Server-Only
- **`sendTo(data: T, player: Player)`**: Targets a specific player.
- **`sendToList(data: T, players: { Player })`**: Parallel distribution to a set of players.
- **`sendToAll(data: T)`**: Global broadcast to all connected players.
- **`sendToAllExcept(data: T, except: Player)`**: Broadcast while excluding a specific recipient.

### Client-Only
- **`send(data: T)`**: Serializes and flushes data to the server.

---

## Invoke Instance Methods

### Shared
- **`onInvoke(handler: (data: TReq, sender: Player?) -> TRes)`**: Registers the primary logic to process requests and return responses.
- **`invoke(data: TReq, player: Player?): TRes`**: Sends the request and yields. **Required: `player` argument on server.** Returns `nil` (and warns) if timed out.

---

## Data Types

### Standard Primitives
- `uint8`, `uint16`, `uint32`
- `int8`, `int16`, `int32`
- `float32`, `float64`
- `bool`, `string`, `buff` (Raw Buffer), `inst` (Instance reference), `nothing` (Void type)

### Geometrics & Physics
- `vec2`, `vec3`, `cframe`, `ray`, `region3`
- `axes`, `faces`, `physicalProperties`

### Visuals & UI
- `color3`, `color3uint8`, `brickColor`
- `udim`, `udim2`, `rect`, `font`
- `numberSequence`, `numberSequenceKeypoint`
- `colorSequence`, `colorSequenceKeypoint`

### Temporal & Interaction
- `dateTime`, `tweenInfo`, `pathWaypoint`, `numberRange`

---

## Generic Wrappers & Factories

### `ByteFlow.struct(descriptor: { [string]: DataType<any> })`
Serializes a fixed-key dictionary. Keys are not transmitted, making this the most efficient composite type.

### `ByteFlow.array(dataType: DataType<any>)`
Serializes a sequence (numeric-indexed table) of the given type.

### `ByteFlow.map(keyType: DataType<any>, valueType: DataType<any>)`
Serializes a dynamic-key dictionary.

### `ByteFlow.optional(dataType: DataType<any>)`
Wraps a field that can be `nil`.

### `ByteFlow.enum(enumItem: Enum)`
Serializes a Roblox `Enum` value.
