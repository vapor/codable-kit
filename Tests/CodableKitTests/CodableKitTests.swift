import XCTest
import Foundation
import CodableKit

final class CodableKitTests: XCTestCase {
    func testDecoderUnwrapper() throws {
        let data = "{}".data(using: .utf8)!
        let unwrapper = try JSONDecoder().decode(DecoderUnwrapper.self, from: data)
        print(unwrapper.decoder) // Decoder
    }
    
    func testEncodableWrapper() throws {
        let encodable: Encodable = ["hello": "world"]
        let data = try JSONEncoder().encode(EncodableWrapper(encodable))
        print(data)
    }

    static var allTests = [
        ("testDecoderUnwrapper", testDecoderUnwrapper),
        ("testEncodableWrapper", testEncodableWrapper),
    ]
}
