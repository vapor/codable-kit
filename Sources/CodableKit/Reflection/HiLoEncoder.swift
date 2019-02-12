/// Encodes types, detecting coding path for "hi" signal values.
struct HiLoEncoder<Root, Value>: Encoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any] = [:]
    private let ctx: Context
    let keyPath: KeyPath<Root, Value>?

    var hi: [CodingKey]? {
        return ctx.hiCodingPath
    }

    init(keyPath: KeyPath<Root, Value>?) {
        self.init(.init(), codingPath: [], keyPath: keyPath)
    }

    private init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>?) {
        self.ctx = ctx
        self.codingPath = codingPath
        self.keyPath = keyPath
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return .init(KeyedEncoder(ctx, codingPath: codingPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedEncoder(ctx, codingPath: codingPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueEncoder(ctx,  codingPath: codingPath)
    }

    // MARK: Private

    private final class Context {
        var hiCodingPath: [CodingKey]?

        init() { }

        func hi(_ codingPath: [CodingKey]) {
            assert(hiCodingPath == nil, "Multiple hi coding paths.")
            hiCodingPath = codingPath
        }
    }

    private struct KeyedEncoder<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
        let codingPath: [CodingKey]
        let ctx: Context

        init(_ ctx: Context, codingPath: [CodingKey]) {
            self.ctx = ctx
            self.codingPath = codingPath
        }

        mutating func encodeNil(forKey key: Key) throws {
            // ignore
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            var c = SingleValueEncoder(ctx, codingPath: codingPath + [key])
            try c.encode(value)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return .init(KeyedEncoder<NestedKey>(ctx, codingPath: codingPath + [key]))
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return UnkeyedEncoder(ctx, codingPath: codingPath + [key])
        }

        mutating func superEncoder() -> Encoder {
            return HiLoEncoder<Root, Value>(ctx, codingPath: codingPath, keyPath: nil)
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            return HiLoEncoder<Root, Value>(ctx, codingPath: codingPath + [key], keyPath: nil)
        }
    }

    private struct UnkeyedEncoder: UnkeyedEncodingContainer {
        let codingPath: [CodingKey]
        let ctx: Context
        var count: Int

        init(_ ctx: Context, codingPath: [CodingKey]) {
            self.ctx = ctx
            self.codingPath = codingPath
            self.count = 0
        }

        mutating func encodeNil() throws {
            // ignore
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            var c = SingleValueEncoder(ctx, codingPath: codingPath)
            try c.encode(value)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return .init(KeyedEncoder(ctx, codingPath: codingPath))
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return UnkeyedEncoder(ctx, codingPath: codingPath)
        }

        mutating func superEncoder() -> Encoder {
            return HiLoEncoder<Root, Value>(ctx, codingPath: codingPath, keyPath: nil)
        }
    }

    private struct SingleValueEncoder: SingleValueEncodingContainer {
        var codingPath: [CodingKey]
        let ctx: Context

        init(_ ctx: Context, codingPath: [CodingKey]) {
            self.ctx = ctx
            self.codingPath = codingPath
        }

        mutating func encodeNil() throws {
            // ignore
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            if let custom = T.self as? AnyReflectionDecodable.Type,
                custom.isBaseType || value is Value {
                if !custom.anyReflectDecodedIsLeft(value) {
                    ctx.hi(codingPath)
                }
            } else {
                let encoder = HiLoEncoder<Root, Value>(ctx, codingPath: codingPath, keyPath: nil)
                return try value.encode(to: encoder)
            }
        }
    }
}
