import Testing
import Foundation
@testable import CoreApi

@Suite("QueryItemEncoder")
struct QueryItemEncoderTests {
    private struct Flat: Encodable {
        let name: String
        let count: Int
        let flag: Bool
    }

    private struct WithArray: Encodable {
        let tags: [String]
    }

    @Test func encodesFlatStruct() throws {
        let items = try QueryItemEncoder().encode(Flat(name: "hello", count: 3, flag: true))
        #expect(items.contains(URLQueryItem(name: "name", value: "hello")))
        #expect(items.contains(URLQueryItem(name: "count", value: "3")))
        #expect(items.contains(URLQueryItem(name: "flag", value: "true")))
    }

    @Test func encodesArrayWithRepeatedKey() throws {
        let items = try QueryItemEncoder().encode(WithArray(tags: ["a", "b", "c"]))
        let tagItems = items.filter { $0.name == "tags" }
        #expect(tagItems.count == 3)
        #expect(tagItems.map(\.value) == ["a", "b", "c"])
    }

    @Test func encodesBoolFalse() throws {
        let items = try QueryItemEncoder().encode(Flat(name: "x", count: 0, flag: false))
        #expect(items.contains(URLQueryItem(name: "flag", value: "false")))
    }
}
