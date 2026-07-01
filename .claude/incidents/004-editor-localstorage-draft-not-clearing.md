# Incident: Editor localStorage draft not clearing after publish on production

**Date**: 2026-07-01
**Severity**: Low
**Status**: Resolved

## What happened

After publishing a post or catalogue item on the production website, the editor's localStorage draft was not being cleared. The next time the user visited the same editor, the stale draft reappeared. The bug was absent on localhost.

## Root cause

The draft-clearing mechanism works in two phases:

1. On form submit: `markPendingClear(storageKey)` writes the key to an `editor:pendingClear` list in localStorage.
2. On the next editor page load: `clearIfPending(storageKey)` reads that list, removes the draft, and returns early.

After a successful publish the server redirects to the item's detail page, which never runs the editor script — so phase 2 is deferred until the user next opens that editor.

The problem is **bfcache** (Back/Forward Cache). On production (HTTPS), browsers aggressively cache pages in bfcache. When the user presses Back from the detail page, the browser restores the editor from bfcache without re-running `DOMContentLoaded`. Phase 2 (`clearIfPending`) never executes and the draft persists indefinitely.

On localhost (HTTP), bfcache is not used, so Back triggers a real page load and the draft clears as expected. This is why the bug only appeared in production.

## How it was fixed

Added `Page.noStore()` to `web-core` — a modifier that wraps the response and adds `Cache-Control: no-store`. Applied it to all 15 editor page `static var` definitions across 10 files.

`Cache-Control: no-store` opts a page out of bfcache entirely. Pressing Back now triggers a real page load, `clearIfPending` runs, and the draft clears as intended. The deferred mechanism itself was correct and is preserved — it still protects drafts when a submission fails in-flight.

PR: https://github.com/danieltmbr/tmbr/pull/211

## Prevention

- [ ] Process/doc change: document the bfcache pattern and `Page.noStore()` requirement in `quality-assurance.md` — done
- [ ] Long-term: consider an E2E test that publishes an item, navigates back, and asserts the editor is blank

## Tests added

None. The bug is browser-environment-specific (bfcache only on HTTPS) and not easily covered by unit or integration tests. Manual verification: publish an item in production, press Back, confirm the editor is blank and localStorage contains no draft for that key.
