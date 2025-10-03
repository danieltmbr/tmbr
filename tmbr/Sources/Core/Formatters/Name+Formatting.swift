import Foundation

public struct NameFormatter: Sendable {
    
    typealias Formatter = @Sendable (_ givenName: String?, _ familyName: String?) -> String
    
    private let formatter: Formatter
    
    init(formatter: @escaping Formatter) {
        self.formatter = formatter
    }
    
    public func format(givenName: String?, familyName: String?) -> String {
        formatter(givenName, familyName)
    }
    
    public static let author = Self { givenName, familyName in
#if os(Linux)
        if let familyName = familyName, let givenName = givenName {
            return "\(givenName) \(familyName)"
        } else if let familyName = familyName {
            return familyName
        } else if let givenName = givenName {
            return givenName
        } else {
           return ""
        }
#else
        return PersonNameComponents(
            givenName: givenName,
            familyName: familyName
        ).formatted(.name(style: .long))
#endif
    }
}
