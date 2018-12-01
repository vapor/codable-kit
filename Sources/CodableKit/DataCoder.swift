import Foundation

/// A type capable of decoding `Decodable` types from `Data`.
///
///     print(data) /// Data
///     let user = try JSONDecoder().decode(User.self, from: data)
///     print(user) /// User
///
public protocol DataDecoder {
    /// Decodes an instance of the supplied `Decodable` type from `Data`.
    ///
    ///     print(data) /// Data
    ///     let user = try JSONDecoder().decode(User.self, from: data)
    ///     print(user) /// User
    ///
    /// - parameters:
    ///     - decodable: Generic `Decodable` type (`D`) to decode.
    ///     - from: `Data` to decode a `D` from.
    /// - returns: An instance of the `Decodable` type (`D`).
    /// - throws: Any error that may occur while attempting to decode the specified type.
    func decode<D>(_ decodable: D.Type, from data: Data) throws -> D where D: Decodable
}

/// A type capable of encoding `Encodable` objects to `Data`.
///
///     print(user) /// User
///     let data = try JSONEncoder().encode(user)
///     print(data) /// Data
///
public protocol DataEncoder {
    /// Encodes the supplied `Encodable` object to `Data`.
    ///
    ///     print(user) /// User
    ///     let data = try JSONEncoder().encode(user)
    ///     print(data) /// Data
    ///
    /// - parameters:
    ///     - encodable: Generic `Encodable` object (`E`) to encode.
    /// - returns: Encoded `Data`
    /// - throws: Any error taht may occur while attempting to encode the specified type.
    func encode<E>(_ encodable: E) throws -> Data where E: Encodable
}

/// A type capable of encoding `Encodable` objects to `Data` and decoding `Data` to `Decodable` objects.
public protocol DataCoder: DataEncoder, DataDecoder {}

/// MARK: Default Conformances
extension JSONDecoder: DataDecoder { }
extension JSONEncoder: DataEncoder { }

extension PropertyListDecoder: DataDecoder { }
extension PropertyListEncoder: DataEncoder { }
