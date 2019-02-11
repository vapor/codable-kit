/// Encodes types, detecting coding path for "hi" signal values.
struct HiLoEncoder<Root, Value>: Encoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any] = [:]
    private let ctx: Context
    let keyPath: KeyPath<Root, Value>

    var hi: [CodingKey]? {
        return ctx.hiCodingPath
    }

    init(keyPath: KeyPath<Root, Value>) {
        self.init(.init(), codingPath: [], keyPath: keyPath)
    }

    private init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>) {
        self.ctx = ctx
        self.codingPath = codingPath
        self.keyPath = keyPath
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return .init(KeyedEncoder(ctx, codingPath: codingPath, keyPath: keyPath))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedEncoder(ctx, codingPath: codingPath, keyPath: keyPath)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueEncoder(ctx,  codingPath: codingPath, keyPath: keyPath)
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
        let keyPath: KeyPath<Root, Value>

        init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>) {
            self.ctx = ctx
            self.codingPath = codingPath
            self.keyPath = keyPath
        }

        mutating func encodeNil(forKey key: Key) throws {
            // ignore
        }

        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            var c = SingleValueEncoder(ctx, codingPath: codingPath + [key], keyPath: keyPath)
            try c.encode(value)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return .init(KeyedEncoder<NestedKey>(ctx, codingPath: codingPath + [key], keyPath: keyPath))
        }

        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return UnkeyedEncoder(ctx, codingPath: codingPath + [key], keyPath: keyPath)
        }

        mutating func superEncoder() -> Encoder {
            return HiLoEncoder(ctx, codingPath: codingPath, keyPath: keyPath)
        }

        mutating func superEncoder(forKey key: Key) -> Encoder {
            return HiLoEncoder(ctx, codingPath: codingPath + [key], keyPath: keyPath)
        }
    }

    private struct UnkeyedEncoder: UnkeyedEncodingContainer {
        let codingPath: [CodingKey]
        let ctx: Context
        var count: Int
        let keyPath: KeyPath<Root, Value>

        init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>) {
            self.ctx = ctx
            self.codingPath = codingPath
            self.count = 0
            self.keyPath = keyPath
        }

        mutating func encodeNil() throws {
            // ignore
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            var c = SingleValueEncoder(ctx, codingPath: codingPath, keyPath: keyPath)
            try c.encode(value)
        }

        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return .init(KeyedEncoder(ctx, codingPath: codingPath, keyPath: keyPath))
        }

        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return UnkeyedEncoder(ctx, codingPath: codingPath, keyPath: keyPath)
        }

        mutating func superEncoder() -> Encoder {
            return HiLoEncoder(ctx, codingPath: codingPath, keyPath: keyPath)
        }
    }

    private struct SingleValueEncoder: SingleValueEncodingContainer {
        var codingPath: [CodingKey]
        let ctx: Context
        let keyPath: KeyPath<Root, Value>

        init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>) {
            self.ctx = ctx
            self.codingPath = codingPath
            self.keyPath = keyPath
        }

        mutating func encodeNil() throws {
            // ignore
        }

        mutating func encode<T>(_ value: T) throws where T: Encodable {
            if let custom = T.self as? AnyReflectionDecodable.Type,
                keyPath.valueType == T.self || custom.isBaseType {
                if !custom.anyReflectDecodedIsLeft(value) {
                    ctx.hi(codingPath)
                }
            } else {
                let encoder = HiLoEncoder(ctx, codingPath: codingPath, keyPath: keyPath)
                return try value.encode(to: encoder)
            }
        }
    }
}
