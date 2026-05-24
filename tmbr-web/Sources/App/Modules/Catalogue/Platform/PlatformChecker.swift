import Foundation

struct PlatformChecker: Sendable {

    private let check: @Sendable (URL) -> Bool

    init(check: @escaping @Sendable (URL) -> Bool) {
        self.check = check
    }

    func matches(_ url: URL) -> Bool {
        check(url)
    }
}
