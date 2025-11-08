import Foundation
import Vapor
import Logging

public struct Trace: Hashable, Sendable {

    static let key = "traceparent"
        
    private let version: String
    
    private let traceID: String
    
    private let parentID: String
    
    private let flags: String
    
    fileprivate var string: String {
        "\(version)-\(traceID)-\(parentID)-\(flags)"
    }
    
    init?(traceparent: String) {
        let components = traceparent.split(separator: "-").map(String.init)
        guard components.count == 4 else { return nil }
        self.init(
            version: components[0],
            traceID: components[1],
            parentID: components[2],
            flags: components[3]
        )
    }
    
    public init?(
        version: String,
        traceID: String,
        parentID: String,
        flags: String
    ) {
        guard version.count == 2, version.isHex,
              traceID.count == 32, traceID.isHex, !traceID.isAllZero,
              parentID.count == 16, parentID.isHex, !parentID.isAllZero,
              flags.count == 2, flags.isHex else {
            return nil
        }
        self.version = version
        self.traceID = traceID
        self.parentID = parentID
        self.flags = flags
    }
    
    init() {
        self.version = "00"
        self.traceID = Self.randomHexString(byteCount: 16)
        self.parentID = Self.randomHexString(byteCount: 8)
        self.flags = "01"
    }
    
    public static func randomHexString(byteCount: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        if hex.isAllZero {
            return randomHexString(byteCount: byteCount)
        } else {
            return hex
        }
    }
}

extension Logger {
    var trace: Trace? {
        get {
            guard case .string(let value) = self[metadataKey: Trace.key] else {
                return nil
            }
            return Trace(traceparent: value)
        }
        set {
            if let newValue {
                self[metadataKey: Trace.key] = .string(newValue.string)
            } else {
                self[metadataKey: Trace.key] = nil
            }
        }
    }
}

extension String {
    var isHex: Bool {
        isEmpty || allSatisfy(\.isHexDigit)
    }
    
    var isAllZero: Bool {
        Set(self).count == 1 && first == "0"
    }
}
