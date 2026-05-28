# QA Backlog

Concrete work to bring the codebase up to the standards in `quality-assurance.md`. Check items off as they're completed.

## Implementation Order

- [ ] 1. Logging middleware
- [ ] 2. JS error recovery
- [ ] 3. Test helpers + auth backend tests
- [ ] 4. Catalogue backend tests
- [ ] 5. Notes + Posts backend tests
- [ ] 6. Playwright setup + auth E2E
- [ ] 7. Catalogue E2E
- [ ] 8. Leaf replacement evaluation

---

## 1. Logging

**New: `Sources/Core/Logging/RequestLoggingMiddleware.swift`**

Logs every completed request. Place after `TracingMiddleware` in the stack so trace ID is already in logger metadata. Register in `Configuration+Logging.swift`.

**Update: `Sources/Core/Web/Recover/RecoverMiddleware.swift`**

Enrich the existing error log to include:
- HTTP status code
- Request method + path
- Error type (`String(reflecting: type(of: error))`)
- User ID from session (or "anonymous")

Trace ID is already present via `TracingMiddleware`.

---

## 2. JS Error Recovery

Add `parseErrorResponse()` (see pattern in `quality-assurance.md`) to `catalogue-editor.js` or extract to `Public/js/Shared/errors.js`.

Apply to:
- `MetadataController`, `LookupController`, `ResourceInputsController` fetch calls in `catalogue-editor.js`
- Image upload calls in `media.js`

---

## 3. Test Helpers

**`Tests/AppTests/Helpers/TestHelpers.swift`**

Extract `withApp()` from `AppTests.swift` and add an authenticated variant:

```swift
// Creates a user, logs in via the real login endpoint, returns a session cookie
func withAuthenticatedApp(_ test: (Application, String) async throws -> ()) async throws
```

This exercises the actual auth stack, not a mock.

---

## 4. Auth Tests — `Tests/AppTests/Auth/SessionTests.swift`

- Unauthenticated request to protected route → redirect to login
- Sign In with Apple: valid token → session cookie set, user persisted in DB
- Sign In with Apple: invalid/expired token → 401
- Sign In with Apple: valid token but no matching user → 401
- Logout → session cleared

---

## 5. Catalogue Tests — `Tests/AppTests/Catalogue/AlbumTests.swift`

Albums as representative — other catalogue types follow the same pattern per the Testing Invariants in `quality-assurance.md`.

- `GET /albums/create` unauthenticated → redirect
- `GET /albums/create` authenticated → 200, HTML contains `id="editor-title"`
- `POST /albums` valid input → item in DB, redirect
- `POST /albums` missing required field → 400/422 with reason
- `PATCH /albums/:id` by owner → updated in DB
- `PATCH /albums/:id` by different user → 403
- `DELETE /albums/:id` by owner → removed from DB
- `DELETE /albums/:id` by non-owner → 403

---

## 6. Notes Tests — `Tests/AppTests/Notes/NotesTests.swift`

- Add note to own catalogue item → persisted
- Private note not visible to other users → 403
- Private note visible to owner alongside their public notes

---

## 7. Posts Tests — `Tests/AppTests/Posts/PostTests.swift`

- Create post → persisted
- Edit own post → updated
- Edit other's post → 403
- View other's private post → 403
- View other's draft post → 403
- `GET /posts` (list) → only shows published posts to non-owners
- `GET /posts` by author → includes their own drafts

---

## 8. Playwright Setup

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

---

## 9. Catalogue E2E — `Tests/E2E/catalogue-editor.spec.ts`

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

## 10. Leaf Replacement Evaluation

The Note textarea + access checkbox incident (`incidents/001`) is a symptom of Leaf's structural limitations: no component scoping, weak template inheritance. The current fix is a CLAUDE.md reminder, not a real solution.

Evaluate when the frontend next needs significant work: `swift-html` or a Leaf macro/component abstraction that enforces proper scoping. See `leaf-limitations.md` for the known issues.
