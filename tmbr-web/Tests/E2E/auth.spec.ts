import { test, expect } from '@playwright/test';

test.describe('Authentication guards', () => {

    test('unauthenticated GET /albums/new redirects to /signin', async ({ page }) => {
        const response = await page.goto('/albums/new');
        expect(page.url()).toContain('/signin');
    });

    test('unauthenticated GET /posts/new redirects to /signin', async ({ page }) => {
        await page.goto('/posts/new');
        expect(page.url()).toContain('/signin');
    });

    test('unauthenticated GET /notes redirects to /signin', async ({ page }) => {
        await page.goto('/notes');
        expect(page.url()).toContain('/signin');
    });

});
