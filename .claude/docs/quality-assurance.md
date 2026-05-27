# Quality Assurance Strategy

## Scope

| Package | Priority | Current state |
|---------|----------|--------------|
| `tmbr-web/` | Primary | Most complexity, most bugs, no tests |
| `api-kit/` | Maintain | Already tested — expand as needed |
| `tmbr-core/` | Low | Shared types only — add tests when logic grows |
| `tmbr-app/` | Future | Empty stubs — tackle after web is stable |

---

## Part 1: Structured Logging

### Request Logging Middleware

`Sources/Core/Logging/RequestLoggingMiddleware.swift` — logs every completed request.

Placed after `TracingMiddleware` so the trace ID is already in logger metadata. Log level scales with response status: `.info` for 2xx/3xx, `.warning` for 4xx, `.error` for 5xx.

Register in `Configuration+Logging.swift`.

### RecoverMiddleware Logging

`Sources/Core/Web/Recover/RecoverMiddleware.swift` — enrich the existing error log to include:
- HTTP status code
- Request method + path
- Error type (`String(reflecting: type(of: error))`)
- User ID from session (or "anonymous")
- Trace ID is already in logger metadata via `TracingMiddleware`

Not adding yet: external services (Sentry), DB query logging, request body logging.

---

## Part 2: Error Recovery for Users

Three tiers — distinct from logging, which is for us.

**Tier 1 — Auto-recovered by code**: Already working (auth 401 → redirect to login + retry). No change needed.

**Tier 2 — User-recoverable**: Validation errors, duplicates, wrong format. Vapor's `Abort(.badRequest, reason: "...")` already includes the reason in the JSON response body — the JS just ignores it. Fix: read `body.reason` and show it inline near the form with actionable text.

**Tier 3 — System errors**: 500s and unhandled exceptions. Show "Something went wrong. Please try again." — never expose internals. Log full detail server-side.

### JS Error Handling Pattern

Shared helper (add to `catalogue-editor.js` or a new `Shared/errors.js`):

```javascript
class UserError extends Error {}  // user can fix this
class SystemError extends Error {} // we need to fix this

async function parseErrorResponse(response) {
    const body = await response.json().catch(() => null);
    if (response.status === 400 || response.status === 422) {
        throw new UserError(body?.reason ?? 'Please check your input and try again.');
    }
    if (response.status === 404) {
        throw new UserError('This item no longer exists.');
    }
    throw new SystemError(); // 500+ — generic message, details are in server logs
}
```

Apply to: `MetadataController`, `LookupController`, `ResourceInputsController` fetch calls in `catalogue-editor.js`, and image upload calls in `media.js`.

---

## Part 3: Backend Tests (Swift Testing)

Framework already configured: `VaporTesting` + Swift Testing in `Package.swift`, `withApp()` helper in `AppTests.swift`.

### Shared Helpers — `Tests/AppTests/Helpers/TestHelpers.swift`

Extract `withApp()` from `AppTests.swift` and add an authenticated variant:

```swift
// Creates a user, logs in via the real login endpoint, returns a session cookie
func withAuthenticatedApp(_ test: (Application, String) async throws -> ()) async throws
```

This exercises the actual auth stack, not a mock.

### Test Suites — Priority Order

**`Tests/AppTests/Auth/SessionTests.swift`**
- Unauthenticated request to protected route → redirect to login
- Login with valid credentials → session cookie set
- Login with wrong password → error
- Logout → session cleared

**`Tests/AppTests/Catalogue/AlbumTests.swift`** (Albums as representative; other types follow the same pattern)
- `GET /albums/create` unauthenticated → redirect
- `GET /albums/create` authenticated → 200, HTML contains `id="editor-title"`
- `POST /albums` valid input → item in DB, redirect
- `POST /albums` missing required field → 400/422 with reason
- `PATCH /albums/:id` by owner → updated in DB
- `PATCH /albums/:id` by different user → 403
- `DELETE /albums/:id` by owner → removed from DB
- `DELETE /albums/:id` by non-owner → 403

**`Tests/AppTests/Notes/NotesTests.swift`**
- Add note to own catalogue item → persisted
- Private note not visible to other users

**`Tests/AppTests/Posts/PostTests.swift`**
- Create post → persisted
- Edit own post → updated
- Edit other's post → 403

---

## Part 4: Playwright E2E Tests

### Setup

Add to `tmbr-web/`:

```
package.json              — { "devDependencies": { "@playwright/test": "^1.x" } }
playwright.config.ts      — baseURL: http://localhost:8080, testDir: ./Tests/E2E
Tests/E2E/
  helpers/auth.ts         — shared login() helper
  auth.spec.ts
  catalogue-editor.spec.ts
```

Run against a local server:
```bash
# Terminal 1
cd tmbr-web && swift run Backend serve

# Terminal 2
cd tmbr-web && npx playwright test
```

### `catalogue-editor.spec.ts` — the critical suite

Covers the scenarios that broke repeatedly:
- Create album with all fields → lands on detail page, data persisted
- Artwork: set URL → preview shown; clear → `empty` class restored
- Artwork: select from gallery sidebar → state synced to hidden input
- Notes: add note → visible; mark for deletion → delete flag set
- Draft: fills from localStorage on refresh; clears after successful submit
- Duplicate detection: same title+artist → alert shown, submission blocked
- Resource inputs: add row; remove row; autofill triggers on URL change
- Error messages: metadata fetch returns 400 → user sees specific reason, not generic

---

## Part 5: Post-Mortem Process

When something breaks:

1. Fix it
2. Write (or update) a test that would have caught it
3. Write a post-mortem in `.claude/incidents/` using the template
4. If the same component breaks twice — an E2E test is **required** before the fix is considered done

Post-mortems live in `.claude/incidents/`. Template: `.claude/incidents/TEMPLATE.md`.

Format:
```markdown
# Incident: [Short description]

**Date**: YYYY-MM-DD
**Severity**: Low / Medium / High
**Status**: Resolved / Ongoing

## What happened
[Symptom from the user's perspective]

## Root cause
[The specific technical cause — be concrete]

## How it was fixed
[The change made to resolve it]

## Prevention
- [ ] New test: [describe what it verifies]
- [ ] Process/doc change: [what to add or update]
- [ ] Long-term fix if current solution is a workaround: [describe]

## Tests added
[File paths or descriptions]
```

---

## Part 6: Leaf Replacement (Long-Term)

The Note textarea + access checkbox incident (`incidents/001`) is a symptom of Leaf's structural limitations: no component scoping, weak template inheritance. The current fix is a CLAUDE.md reminder, not a real solution.

Worth evaluating when the web frontend next needs significant work: `swift-html` or a Leaf macro/component abstraction that enforces proper scoping. See `leaf-limitations.md` for the known issues.

---

## Implementation Order

1. Logging (`RequestLoggingMiddleware` + enrich `RecoverMiddleware`)
2. JS error recovery tiers 2/3
3. Test helpers + auth backend tests
4. Catalogue backend tests
5. Notes + Posts backend tests
6. Playwright setup + auth E2E
7. Catalogue E2E (most complex — do last)
8. Post-mortem template + first incident write-up + CLAUDE.md update
