import Testing
@testable import ApiKit

@Suite("AuthToken")
struct AuthTokenTests {
    @Test func startsNil() async {
        #expect(await AuthToken().value == nil)
    }

    @Test func storesInitialValue() async {
        #expect(await AuthToken(value: "tok").value == "tok")
    }

    @Test func updatesValue() async {
        let token = AuthToken(value: "old")
        await token.set("new")
        #expect(await token.value == "new")
    }

    @Test func clearsValue() async {
        let token = AuthToken(value: "something")
        await token.set(nil)
        #expect(await token.value == nil)
    }
}
