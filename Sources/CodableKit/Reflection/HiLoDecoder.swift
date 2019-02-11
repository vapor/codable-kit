// MARK: Internal

/// Decodes types as either "hi" or "lo" signal.
struct HiLoDecoder<Root, Value>: Decoder {
    enum Signal { case hi, lo }

    private let ctx: Context
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any] = [:]
    let keyPath: KeyPath<Root, Value>?

    init(signal: Signal, keyPath: KeyPath<Root, Value>? = nil) {
        self.init(.init(signal: signal), codingPath: [], keyPath: keyPath)
    }

    var properties: [ReflectedProperty] {
        return ctx.properties
    }

    private init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>?) {
        self.ctx = ctx
        self.codingPath = codingPath
        self.keyPath = keyPath
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try singleValueContainer().decode(T.self)
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return .init(KeyedDecoder(ctx, codingPath: codingPath, keyPath: keyPath))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedDecoder(ctx, codingPath: codingPath, keyPath: keyPath)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueDecoder(ctx, codingPath: codingPath, keyPath: keyPath)
    }

    // MARK: Private

    private final class Context {
        let signal: Signal
        var properties: [ReflectedProperty]
        var nextIsOptional: Bool
        init(signal: Signal) {
            self.signal = signal
            self.properties = []
            nextIsOptional = false
        }

        func add<T>(_ type: T.Type, at codingPath: [CodingKey]) {
            let property: ReflectedProperty
            print(type, codingPath)
            let path = codingPath.map { $0.stringValue }
            if nextIsOptional {
                nextIsOptional = false
                property = .init(T?.self, at: path)
            } else {
                property = .init(T.self, at: path)
            }
            properties.append(property)
        }
    }

    private struct KeyedDecoder<Key>: KeyedDecodingContainerProtocol where Key: CodingKey {
        let allKeys: [Key] = []
        let ctx: Context
        let codingPath: [CodingKey]
        let keyPath: KeyPath<Root, Value>?

        init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>?) {
            self.ctx = ctx
            self.codingPath = codingPath
            self.keyPath = keyPath
        }

        func contains(_ key: Key) -> Bool {
            ctx.nextIsOptional = true
            return true
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            ctx.nextIsOptional = true
            return false
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            return try SingleValueDecoder(ctx, codingPath: codingPath + [key], keyPath: keyPath).decode(T.self)
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return .init(KeyedDecoder<NestedKey>(ctx, codingPath: codingPath + [key], keyPath: keyPath))
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return UnkeyedDecoder(ctx, codingPath: codingPath + [key], keyPath: keyPath)
        }

        func superDecoder() throws -> Decoder {
            return HiLoDecoder(ctx, codingPath: codingPath, keyPath: keyPath)
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            return HiLoDecoder(ctx, codingPath: codingPath + [key], keyPath: keyPath)
        }
    }

    private struct UnkeyedDecoder: UnkeyedDecodingContainer {
        var count: Int?
        var isAtEnd: Bool
        var currentIndex: Int
        var key: CodingKey {
            return BasicCodingKey.int(currentIndex)
        }
        let ctx: Context
        let codingPath: [CodingKey]
        let keyPath: KeyPath<Root, Value>?

        init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>?) {
            self.ctx = ctx
            self.codingPath = codingPath
            self.isAtEnd = false
            self.currentIndex = 0
            self.keyPath = keyPath
        }

        mutating func decodeNil() throws -> Bool {
            ctx.nextIsOptional = true
            return false
        }

        mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            isAtEnd = true
            return try SingleValueDecoder(ctx, codingPath: codingPath + [key], keyPath: keyPath).decode(T.self)
        }

        mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return .init(KeyedDecoder<NestedKey>(ctx, codingPath: codingPath + [key], keyPath: keyPath))
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return UnkeyedDecoder(ctx, codingPath: codingPath + [key], keyPath: keyPath)
        }

        mutating func superDecoder() throws -> Decoder {
            return HiLoDecoder(ctx, codingPath: codingPath + [key], keyPath: keyPath)
        }
    }

    private struct SingleValueDecoder: SingleValueDecodingContainer {
        let ctx: Context
        let codingPath: [CodingKey]
        let keyPath: KeyPath<Root, Value>?

        init(_ ctx: Context, codingPath: [CodingKey], keyPath: KeyPath<Root, Value>?) {
            self.ctx = ctx
            self.codingPath = codingPath
            self.keyPath = keyPath
        }

        func decodeNil() -> Bool {
            ctx.nextIsOptional = true
            return false
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            ctx.add(T.self, at: codingPath)

            if let custom = T.self as? AnyReflectionDecodable.Type,
                keyPath?.valueType == T.self || custom.isBaseType {
                switch ctx.signal {
                case .hi: return custom.anyReflectDecoded().1 as! T
                case .lo: return custom.anyReflectDecoded().0 as! T
                }
            }

            let decoder = HiLoDecoder(ctx, codingPath: codingPath, keyPath: nil)
            return try T.init(from: decoder)
        }
    }
}
