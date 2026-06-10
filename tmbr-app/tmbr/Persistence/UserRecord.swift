import Foundation
import SwiftData

/// Cached profile of the currently signed-in user.
///
/// Written once during the first successful sync. Never has pending state —
/// the user profile is always server-owned. Used by the UI to display account
/// information without an extra network request.
@Model
final class UserRecord {

    @Attribute(.unique)
    var serverID: Int

    var appleID: String
    var email: String?
    var firstName: String?
    var lastName: String?

    init(serverID: Int, appleID: String, email: String? = nil, firstName: String? = nil, lastName: String? = nil) {
        self.serverID = serverID
        self.appleID = appleID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
}
