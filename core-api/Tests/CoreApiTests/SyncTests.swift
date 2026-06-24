import Testing
import Foundation
import CoreTmbr
@testable import CoreApi

@Suite("syncAll pagination driver")
struct SyncAllTests {

    // Drive `syncAll` against a stubbed loader closure — no URLSession, so the driver logic
    // (delta `since` on page 1 only, then follow `nextCursor`) is tested in isolation.

    @Test func walksEveryPageFollowingCursor() async throws {
        let loader = RequestLoader<PageQuery, PageResult<Int>> { (query: PageQuery) in
            if query.cursor == nil {
                #expect(query.since != nil)         // delta cursor on the first page only
                return PageResult(items: [1, 2], nextCursor: "c1")
            } else {
                #expect(query.since == nil)         // dropped on subsequent pages
                #expect(query.cursor == "c1")
                return PageResult(items: [3], nextCursor: nil)
            }
        }
        let all: [Int] = try await loader.syncAll(since: .now)
        #expect(all == [1, 2, 3])
    }

    @Test func orphanQueryAlwaysRequestsNotes() async throws {
        let loader = RequestLoader<OrphanPageQuery, PageResult<Int>> { (query: OrphanPageQuery) in
            #expect(query.notes)                    // orphans always ask for embedded notes
            return query.cursor == nil
                ? PageResult(items: [1], nextCursor: "c1")
                : PageResult(items: [2], nextCursor: nil)
        }
        let all: [Int] = try await loader.syncAll(since: nil)
        #expect(all == [1, 2])
    }

    @Test func stopsAfterOnePageWhenNoCursor() async throws {
        let loader = RequestLoader<PageQuery, PageResult<Int>> { _ in
            PageResult(items: [1], nextCursor: nil)
        }
        let all: [Int] = try await loader.syncAll(since: nil)
        #expect(all == [1])
    }
}

@Suite("SyncGroup concurrent runner")
struct SyncGroupTests {

    // Thread-safe collector — Sendable so child tasks can safely append concurrently.
    private actor Collector {
        var items: [String] = []
        func append(_ item: String) { items.append(item) }
    }

    @Test func allSucceedRunsSilently() async throws {
        let collector = Collector()
        let group = SyncGroup([
            Syncer("a") { await collector.append("a") },
            Syncer("b") { await collector.append("b") },
        ])
        try await group.run()
        let ran = await collector.items
        #expect(ran.sorted() == ["a", "b"])
    }

    @Test func oneFailureLetOthersFinishThenRethrows() async throws {
        struct Boom: Error {}
        let collector = Collector()
        let group = SyncGroup([
            Syncer("ok1") { await collector.append("ok1") },
            Syncer("bad") { throw Boom() },
            Syncer("ok2") { await collector.append("ok2") },
        ])
        await #expect(throws: Boom.self) { try await group.run() }
        let succeeded = await collector.items
        #expect(succeeded.sorted() == ["ok1", "ok2"])  // both non-failing syncers ran
    }

    @Test func allFailRethrowsFirst() async throws {
        struct Boom: Error { }
        let group = SyncGroup([
            Syncer("a") { throw Boom() },
            Syncer("b") { throw Boom() },
        ])
        var didThrow = false
        do {
            try await group.run()
        } catch {
            didThrow = true
            #expect(error is Boom)
        }
        #expect(didThrow)
    }
}

@Suite("Query Date encoding")
struct QueryDateEncodingTests {

    /// A `Date` query param must serialize as ISO 8601 with fractional seconds so the backend's
    /// URL-encoded-form date decoder accepts it — not as a bare `Double`.
    @Test func sinceRoundTripsThroughBackendParser() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000.5)
        let items = try QueryItemEncoder().encode(PageQuery(since: date, cursor: nil, limit: 50))
        let sinceValue = try #require(items.first { $0.name == "since" }?.value)

        #expect(sinceValue.contains("T"))      // ISO datetime, not a number
        #expect(sinceValue.hasSuffix("Z"))

        // Re-parse with the backend's exact formatter (Configuration+Content.swift).
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let parsed = try #require(formatter.date(from: sinceValue))
        #expect(abs(parsed.timeIntervalSince(date)) < 0.001)
    }
}
