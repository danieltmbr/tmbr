import Testing
import Foundation
import WebCore

@Suite("QuoteReconciler")
struct QuoteReconcilerTests {

    typealias IdentifiedBody = QuoteReconciler.IdentifiedBody

    // Helpers

    private func makeID(_ n: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", n))")!
    }

    private func existing(_ pairs: [(Int, String)]) -> [IdentifiedBody] {
        pairs.map { IdentifiedBody(id: makeID($0), body: $1) }
    }

    // MARK: Unchanged / exact match

    @Test("Unchanged text: both ids preserved, no writes needed")
    func unchangedText() {
        let ex = existing([(1, "hello"), (2, "world")])
        let actions = QuoteReconciler.plan(existing: ex, freshBodies: ["hello", "world"])
        #expect(Set(actions.unchanged) == Set([makeID(1), makeID(2)]))
        #expect(actions.toUpdate.isEmpty)
        #expect(actions.toInsert.isEmpty)
        #expect(actions.toDelete.isEmpty)
    }

    @Test("Reorder: exact matching preserves both ids regardless of position")
    func reorder() {
        let ex = existing([(1, "alpha"), (2, "beta")])
        let actions = QuoteReconciler.plan(existing: ex, freshBodies: ["beta", "alpha"])
        #expect(Set(actions.unchanged) == Set([makeID(1), makeID(2)]))
        #expect(actions.toUpdate.isEmpty)
        #expect(actions.toInsert.isEmpty)
        #expect(actions.toDelete.isEmpty)
    }

    // MARK: Residual pairing — in-place edits

    @Test("Typo fix: id preserved via residual pairing, body updated")
    func typoFix() {
        // "second" exact-matches; "helo world" → "hello world" is a residual pair
        let ex = existing([(1, "helo world"), (2, "second")])
        let actions = QuoteReconciler.plan(existing: ex, freshBodies: ["hello world", "second"])
        #expect(Set(actions.unchanged) == [makeID(2)])
        #expect(actions.toUpdate.count == 1)
        #expect(actions.toUpdate[0].id == makeID(1))
        #expect(actions.toUpdate[0].body == "hello world")
        #expect(actions.toInsert.isEmpty)
        #expect(actions.toDelete.isEmpty)
    }

    @Test("All quotes edited simultaneously: residual pairing pairs by document order")
    func multipleSimultaneousEdits() {
        let ex = existing([(1, "aaa"), (2, "bbb")])
        let actions = QuoteReconciler.plan(existing: ex, freshBodies: ["AAA", "BBB"])
        #expect(actions.unchanged.isEmpty)
        #expect(actions.toUpdate.count == 2)
        #expect(actions.toUpdate[0].id == makeID(1))
        #expect(actions.toUpdate[0].body == "AAA")
        #expect(actions.toUpdate[1].id == makeID(2))
        #expect(actions.toUpdate[1].body == "BBB")
        #expect(actions.toInsert.isEmpty)
        #expect(actions.toDelete.isEmpty)
    }

    // MARK: Insertions

    @Test("New blockquote appended: existing id unchanged, new body inserted")
    func newQuoteAppended() {
        let ex = existing([(1, "existing")])
        let actions = QuoteReconciler.plan(existing: ex, freshBodies: ["existing", "brand new"])
        #expect(actions.unchanged == [makeID(1)])
        #expect(actions.toUpdate.isEmpty)
        #expect(actions.toInsert == ["brand new"])
        #expect(actions.toDelete.isEmpty)
    }

    @Test("First extraction from empty source: all bodies inserted")
    func firstExtraction() {
        let actions = QuoteReconciler.plan(existing: [], freshBodies: ["one", "two"])
        #expect(actions.unchanged.isEmpty)
        #expect(actions.toUpdate.isEmpty)
        #expect(actions.toInsert == ["one", "two"])
        #expect(actions.toDelete.isEmpty)
    }

    // MARK: Deletions

    @Test("Removed blockquote: surviving id unchanged, removed id scheduled for deletion")
    func removedQuote() {
        let ex = existing([(1, "keep"), (2, "remove me")])
        let actions = QuoteReconciler.plan(existing: ex, freshBodies: ["keep"])
        #expect(actions.unchanged == [makeID(1)])
        #expect(actions.toUpdate.isEmpty)
        #expect(actions.toInsert.isEmpty)
        #expect(actions.toDelete == [makeID(2)])
    }

    @Test("All blockquotes removed: all ids scheduled for deletion")
    func allRemoved() {
        let ex = existing([(1, "a"), (2, "b")])
        let actions = QuoteReconciler.plan(existing: ex, freshBodies: [])
        #expect(actions.unchanged.isEmpty)
        #expect(actions.toUpdate.isEmpty)
        #expect(actions.toInsert.isEmpty)
        #expect(Set(actions.toDelete) == Set([makeID(1), makeID(2)]))
    }

    // MARK: Combined scenarios

    @Test("Mix of unchanged, edited, new, and deleted quotes in one save")
    func mixedOperations() {
        // existing: [keep, edit-me, gone]
        // fresh:    [keep, edited, brand-new]
        let ex = existing([(1, "keep"), (2, "edit-me"), (3, "gone")])
        let actions = QuoteReconciler.plan(
            existing: ex,
            freshBodies: ["keep", "edited", "brand-new"]
        )
        #expect(actions.unchanged == [makeID(1)])
        // "edit-me" and "gone" are unmatched; "edited" and "brand-new" are unmatched
        // residual pairing: (2,"edit-me") ↔ "edited" → update; (3,"gone") ↔ "brand-new" → update
        // No surplus inserts or deletes in this exact configuration
        #expect(actions.toUpdate.count == 2)
        #expect(actions.toUpdate[0].id == makeID(2))
        #expect(actions.toUpdate[0].body == "edited")
        #expect(actions.toUpdate[1].id == makeID(3))
        #expect(actions.toUpdate[1].body == "brand-new")
        #expect(actions.toInsert.isEmpty)
        #expect(actions.toDelete.isEmpty)
    }
}
