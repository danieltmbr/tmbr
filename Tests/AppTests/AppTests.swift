@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testRoot() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        try app.test(.GET, "", afterResponse: { res in
            print(res)
            XCTAssertEqual(res.status, .ok)
        })
    }
}
