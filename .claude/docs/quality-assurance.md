# Quality Assurance

## CI Pipeline

Tests run automatically via GitHub Actions on every PR and push to `main` (`.github/workflows/ci.yml`).

| Job | Runner | What it runs |
|-----|--------|-------------|
| `backend-tests` | ubuntu-latest + Postgres 17 | `swift test` in `tmbr-web/` — all AppTests and CoreTests |
| `api-kit-tests` | macos-15 + Xcode 16.2 | `swift test --package-path api-kit` |
| `e2e-tests` | ubuntu-latest + Postgres 17 | Playwright against a live server booted with `--env testing` |

**E2E session in CI:** The server boots in `.testing` mode, which registers `POST /__test/login`. The workflow POSTs `{}` to create a fresh test user, extracts the `vapor_session` cookie from the response, and passes it to Playwright via `E2E_SESSION_COOKIE`. No Apple Sign In credentials are needed.

**No secrets required** — the server gracefully skips Apple JWT setup when `SIWA_APP_ID` is absent.

When a job fails: check the Actions tab on the PR. For E2E failures, download the `playwright-report` artifact (uploaded on failure) for screenshots and traces.

---

## Scope

| Package | Priority | Current state |
|---------|----------|--------------|
| `tmbr-web/` | Primary | Most complexity, most bugs, no tests |
| `api-kit/` | Maintain | Already tested — expand as needed |
| `tmbr-core/` | Low | Shared types only — add tests when logic grows |
| `tmbr-app/` | Future | Empty stubs — tackle after web is stable |

---

## Post-Mortem Process

When something breaks:

1. Fix it
2. Write (or update) a test that would have caught it
3. Write a post-mortem in `.claude/incidents/` using `.claude/incidents/TEMPLATE.md`
4. If the same component breaks twice — an E2E test is **required** before the fix is considered done

---

## E2E Test Policy

Use E2E tests for user-visible flows that cross multiple layers (JS ↔ server ↔ DB). Backend tests cannot catch these.

**Required**: any component that has broken twice gets an E2E test before the fix is considered done.

**Recommended**: flows that depend on client-side state (draft persistence, gallery picker, inline error display).

---

## Error Recovery Model

Three tiers — distinct from logging, which is for developers.

**Tier 1 — Auto-recovered**: The code handles it transparently. Example: 401 → redirect to login + retry after re-auth. Only add auto-recovery when the fix is deterministic and invisible to the user.

**Tier 2 — User-recoverable**: The user can fix it with different input. Show the reason inline near the relevant control. Never show a generic message when a specific one is available.

**Tier 3 — System errors**: The user cannot fix it. Show "Something went wrong — [Report this issue](mailto:bug@tmbr.me)" — never expose internals. Log full detail server-side. A report link is essential since logs aren't actively monitored.

---

## Web (tmbr-web/)

### Logging Requirements

Every completed request must be logged with: method, path, status code, duration, trace ID, user ID (or "anonymous"). Error logs must additionally include error type and message.

Log level scales with response status: `.info` for 2xx/3xx, `.warning` for 4xx, `.error` for 5xx.

Not adding yet: external error tracking (Sentry), DB query logging, request body logging.

### JS Error Handling

Distinguish user-fixable errors from system errors so each gets the right UI treatment.

```javascript
class UserError extends Error {}  // show reason inline — user can act on it
class SystemError extends Error {} // show generic message + report link

async function parseErrorResponse(response) {
    const body = await response.json().catch(() => null);
    if (response.status === 400 || response.status === 422) {
        throw new UserError(body?.reason ?? 'Please check your input and try again.');
    }
    if (response.status === 403) {
        throw new UserError('You don\'t have permission to do this.');
    }
    if (response.status === 404) {
        throw new SystemError(); // item disappeared — data bug, not user error
    }
    throw new SystemError();
}
```

### Testing Invariants

Apply these to every new web feature. When adding a route, ask which categories it falls into and write a test for each.

**Every protected route:**
- Unauthenticated request → redirect to login

**Every POST/PATCH/DELETE:**
- Owner with valid input → succeeds; verify DB state after
- Owner with invalid/missing input → 400 with `reason` in body
- Non-owner → 403

**Every model with visibility states (public/private/draft):**
- Owner sees all their own items regardless of visibility
- Non-owner cannot see private or draft items → 403
- Non-owner can see public items

**Every list endpoint:**
- Only returns items the requester is authorized to see — no leaking private or draft items

---

## Native (tmbr-app/)

`tmbr-app/` is early-stage. Apply these when native development begins.

### Error Handling for Users

Mirror the web tier model:
- **User-recoverable (4xx)**: actionable inline message
- **System errors (5xx)**: "Something went wrong — [Report this issue](mailto:bug@tmbr.me)"
- **Offline**: "No internet connection" with a retry button
- Loading states: spinner/skeleton — never a blank or stuck screen

### Testing Invariants

**Every API call:**
- Successful response → model decoded correctly
- 4xx → appropriate typed error surfaced to the UI
- 5xx / offline / timeout → error surfaced, not a crash

**Every authenticated screen:**
- No valid session → redirects to sign-in, not a blank or broken screen

**Every action that mutates server state:**
- Success → UI reflects the change without requiring a manual refresh
- Failure → error shown, UI not left in a broken intermediate state

### Sign In with Apple

- Successful → user persisted, session established, navigates to home
- Cancelled by user → returns to sign-in screen cleanly, no error shown
- Invalid/expired token → error handled, not a crash
