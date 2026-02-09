import Foundation

extension PlatformChecker {

    static let rottenTomatoes = PlatformChecker { url in
        url.host?.lowercased().contains("rottentomatoes.") ?? false
    }
}
