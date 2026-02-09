import Foundation

extension PlatformChecker {

    static let imdb = PlatformChecker { url in
        url.host?.lowercased().contains("imdb.") ?? false
    }
}
