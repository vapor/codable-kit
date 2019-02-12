/// Used to unwrap the `Decoder` from a private implementation like `JSONDecoder`.
///
///     let unwrapper = try JSONDecoder().decode(DecoderUnwrapper.self, from: ...)
///     print(unwrapper.decoder) // Decoder
///
public struct DecoderUnwrapper: Decodable {
    /// The unwrapped `Decoder`.
    public let decoder: Decoder
    
    /// `Decodable` conformance.
    public init(from decoder: Decoder) {
        self.decoder = decoder
    }
}
