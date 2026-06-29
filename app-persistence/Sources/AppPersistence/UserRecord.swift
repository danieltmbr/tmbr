import Foundation
import SwiftData
import TmbrCore

/// Cached profile of the currently signed-in user (Author app) or the iCloud user (Personal).
///
/// Written once during sync; never has pending state — the profile is server/account-owned.
/// 
@Model
public final class UserRecord {

    public var serverID: Int = 0

    public var appleID: String = ""
    
    public var email: String?
    
    public var firstName: String?
    
    public var lastName: String?

    public init(
        serverID: Int = 0,
        appleID: String = "",
        email: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil
    ) {
        self.serverID = serverID
        self.appleID = appleID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
}
