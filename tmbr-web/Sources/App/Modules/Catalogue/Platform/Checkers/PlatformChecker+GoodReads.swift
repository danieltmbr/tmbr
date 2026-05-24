import Foundation

extension PlatformChecker {

    static let goodreads = PlatformChecker { url in
        url.host?.lowercased().contains("goodreads.") ?? false
    }
}
