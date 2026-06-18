import Foundation

public struct QueryItemEncoder {

    public init() {}

    public func encode<T: Encodable>(_ value: T) throws -> [URLQueryItem] {
        let impl = _Encoder(codingPath: [])
        try value.encode(to: impl)
        return impl.storage.items
    }
}

// MARK: - Internal encoder

private final class _Storage {
    var items: [URLQueryItem] = []
    func append(name: String, value: String) {
        items.append(URLQueryItem(name: name, value: value))
    }
}

private struct _Encoder: Encoder {
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any] = [:]
    let storage: _Storage

    init(codingPath: [CodingKey]) {
        self.codingPath = codingPath
        self.storage = _Storage()
    }

    init(codingPath: [CodingKey], storage: _Storage) {
        self.codingPath = codingPath
        self.storage = storage
    }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(_KeyedContainer<Key>(codingPath: codingPath, storage: storage))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        _UnkeyedContainer(codingPath: codingPath, storage: storage)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        _SingleValueContainer(codingPath: codingPath, storage: storage)
    }
}

// MARK: - Keyed container

private struct _KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey]
    let storage: _Storage

    mutating func encodeNil(forKey key: Key) throws {}

    mutating func encode(_ value: Bool,   forKey key: Key) throws { storage.append(name: key.stringValue, value: value ? "true" : "false") }
    mutating func encode(_ value: String, forKey key: Key) throws { storage.append(name: key.stringValue, value: value) }
    mutating func encode(_ value: Double, forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: Float,  forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: Int,    forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: Int8,   forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: Int16,  forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: Int32,  forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: Int64,  forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: UInt,   forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: UInt8,  forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: UInt16, forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: UInt32, forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }
    mutating func encode(_ value: UInt64, forKey key: Key) throws { storage.append(name: key.stringValue, value: "\(value)") }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        let sub = _Encoder(codingPath: codingPath + [key], storage: storage)
        try value.encode(to: sub)
    }

    mutating func nestedContainer<NK: CodingKey>(keyedBy type: NK.Type, forKey key: Key) -> KeyedEncodingContainer<NK> {
        KeyedEncodingContainer(_KeyedContainer<NK>(codingPath: codingPath + [key], storage: storage))
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        _UnkeyedContainer(codingPath: codingPath + [key], storage: storage)
    }

    mutating func superEncoder() -> Encoder { _Encoder(codingPath: codingPath, storage: storage) }
    mutating func superEncoder(forKey key: Key) -> Encoder { _Encoder(codingPath: codingPath + [key], storage: storage) }
}

// MARK: - Unkeyed container (array elements repeat the parent key)

private struct _UnkeyedContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey]
    var count: Int = 0
    let storage: _Storage

    private var name: String { codingPath.last?.stringValue ?? "" }

    mutating func encodeNil() throws {}

    mutating func encode(_ value: Bool)   throws { storage.append(name: name, value: value ? "true" : "false"); count += 1 }
    mutating func encode(_ value: String) throws { storage.append(name: name, value: value); count += 1 }
    mutating func encode(_ value: Double) throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: Float)  throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: Int)    throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: Int8)   throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: Int16)  throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: Int32)  throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: Int64)  throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: UInt)   throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: UInt8)  throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: UInt16) throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: UInt32) throws { storage.append(name: name, value: "\(value)"); count += 1 }
    mutating func encode(_ value: UInt64) throws { storage.append(name: name, value: "\(value)"); count += 1 }

    mutating func encode<T: Encodable>(_ value: T) throws {
        let sub = _Encoder(codingPath: codingPath, storage: storage)
        try value.encode(to: sub)
        count += 1
    }

    mutating func nestedContainer<NK: CodingKey>(keyedBy type: NK.Type) -> KeyedEncodingContainer<NK> {
        defer { count += 1 }
        return KeyedEncodingContainer(_KeyedContainer<NK>(codingPath: codingPath, storage: storage))
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        defer { count += 1 }
        return _UnkeyedContainer(codingPath: codingPath, storage: storage)
    }

    mutating func superEncoder() -> Encoder { _Encoder(codingPath: codingPath, storage: storage) }
}

// MARK: - Single value container

private struct _SingleValueContainer: SingleValueEncodingContainer {
    var codingPath: [CodingKey]
    let storage: _Storage

    private var key: String { codingPath.last?.stringValue ?? "" }

    mutating func encodeNil() throws {}

    mutating func encode(_ value: Bool)   throws { storage.append(name: key, value: value ? "true" : "false") }
    mutating func encode(_ value: String) throws { storage.append(name: key, value: value) }
    mutating func encode(_ value: Double) throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: Float)  throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: Int)    throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: Int8)   throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: Int16)  throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: Int32)  throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: Int64)  throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: UInt)   throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: UInt8)  throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: UInt16) throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: UInt32) throws { storage.append(name: key, value: "\(value)") }
    mutating func encode(_ value: UInt64) throws { storage.append(name: key, value: "\(value)") }

    mutating func encode<T: Encodable>(_ value: T) throws {
        let sub = _Encoder(codingPath: codingPath, storage: storage)
        try value.encode(to: sub)
    }
}
