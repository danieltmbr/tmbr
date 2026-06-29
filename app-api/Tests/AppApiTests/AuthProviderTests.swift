import Testing
@testable import AppApi

@Suite("AuthProvider")
struct AuthProviderTests {

    @Test func startsNil() async {
        let provider = AuthProvider { "tok" }
        #expect(await provider.value == nil)
    }

    @Test func storesInitialValue() async {
        let provider = AuthProvider(token: "tok") { "new" }
        #expect(await provider.value == "tok")
    }

    @Test func setsValue() async {
        let provider = AuthProvider { "tok" }
        await provider.set("new")
        #expect(await provider.value == "new")
    }

    @Test func clearsValue() async {
        let provider = AuthProvider(token: "something") { "new" }
        await provider.set(nil)
        #expect(await provider.value == nil)
    }

    @Test func refreshedTokenCallsRefresherAndStores() async throws {
        let provider = AuthProvider { "fresh" }
        let token = try await provider.refreshedToken()
        #expect(token == "fresh")
        #expect(await provider.value == "fresh")
    }

    @Test func concurrentRefreshesCallRefresherOnce() async throws {
        let counter = CallCounter()
        let provider = AuthProvider {
            try await Task.sleep(for: .milliseconds(50))
            await counter.increment()
            return "fresh"
        }
        async let a: String = provider.refreshedToken()
        async let b: String = provider.refreshedToken()
        async let c: String = provider.refreshedToken()
        let results = try await [a, b, c]
        #expect(results.allSatisfy { $0 == "fresh" })
        #expect(await counter.count == 1)
    }

    @Test func refreshAfterCompletionStartsNewRefresh() async throws {
        let counter = CallCounter()
        let provider = AuthProvider {
            await counter.increment()
            return "fresh"
        }
        _ = try await provider.refreshedToken()
        _ = try await provider.refreshedToken()
        #expect(await counter.count == 2)
    }
}
