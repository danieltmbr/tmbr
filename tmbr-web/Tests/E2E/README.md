# E2E Tests (Playwright)

Browser-level tests that exercise HTML + JS + backend together.

## Setup

```bash
cd tmbr-web
npm install
npx playwright install chromium
```

## Running tests

Start the server first, then run Playwright:

```bash
# Terminal 1 — start the server
swift run Backend serve

# Terminal 2 — run tests
E2E_SESSION_COOKIE=<your-session-cookie> npx playwright test

# Or run a single file
E2E_SESSION_COOKIE=<your-session-cookie> npx playwright test Tests/E2E/auth.spec.ts

# Interactive UI mode
E2E_SESSION_COOKIE=<your-session-cookie> npx playwright test --ui
```

## Getting a session cookie

Apple Sign In can't be automated headlessly. Get a session cookie from a running browser session:

1. Start the server: `swift run Backend serve`
2. Open http://localhost:8080 and sign in with Apple
3. Open DevTools → Application → Cookies → http://localhost:8080
4. Copy the value of the `vapor_session` cookie
5. Set it as `E2E_SESSION_COOKIE` when running tests

The cookie is valid until you sign out. For recurring use, add it to a `.env.e2e` file (not committed):

```
E2E_SESSION_COOKIE=your_session_value_here
```

Then run: `source .env.e2e && npx playwright test`

## What's tested

| File | Coverage |
|------|----------|
| `auth.spec.ts` | Unauthenticated redirects to /signin |
| `catalogue-editor.spec.ts` | Album create form, artwork state, notes, draft persistence, duplicate detection, resource inputs, note textarea layout |

## Adding new tests

When a component breaks and is fixed, add a test here before marking the fix done.
Use `test.describe` to group by feature area and `test.beforeEach` to inject the session cookie.
