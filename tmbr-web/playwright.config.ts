import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    testDir: './Tests/E2E',
    timeout: 30_000,
    fullyParallel: false, // serial — tests share a running server and DB
    forbidOnly: !!process.env.CI,
    retries: 0,
    reporter: 'list',
    use: {
        baseURL: process.env.BASE_URL ?? 'http://localhost:8080',
        trace: 'on-first-retry',
    },
    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
    ],
    // Run 'swift run Backend serve' before tests if you want the server managed here.
    // For now, start the server manually in a separate terminal.
});
