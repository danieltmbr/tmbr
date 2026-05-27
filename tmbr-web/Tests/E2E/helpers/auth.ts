import type { Page } from '@playwright/test';

// Credentials for the test user. Set via environment variables or use defaults
// that match a seeded user in your local dev DB.
const TEST_EMAIL = process.env.E2E_EMAIL ?? '';
const TEST_PASSWORD = process.env.E2E_PASSWORD ?? '';

/**
 * Navigate to /signin and complete Apple Sign In.
 *
 * NOTE: Apple Sign In requires real credentials and cannot be automated in headless
 * mode without a special test account. For local E2E tests, use one of:
 *   1. A pre-seeded test session cookie (set E2E_SESSION_COOKIE env var)
 *   2. Manual login before running tests (reuse storage state)
 *
 * See: https://playwright.dev/docs/auth
 */
export async function loginWithStoredSession(page: Page): Promise<void> {
    // If a pre-baked session cookie is provided, inject it directly.
    const sessionCookie = process.env.E2E_SESSION_COOKIE;
    if (sessionCookie) {
        await page.context().addCookies([{
            name: 'vapor_session',
            value: sessionCookie,
            domain: 'localhost',
            path: '/',
        }]);
        return;
    }

    // Fall back to navigating to the sign-in page.
    // Real Apple Sign In can't be automated — use stored auth state instead.
    await page.goto('/signin');
    throw new Error(
        'E2E_SESSION_COOKIE not set. ' +
        'Log in manually, export the vapor_session cookie, and set E2E_SESSION_COOKIE. ' +
        'See Tests/E2E/README.md for setup instructions.'
    );
}

export { TEST_EMAIL, TEST_PASSWORD };
