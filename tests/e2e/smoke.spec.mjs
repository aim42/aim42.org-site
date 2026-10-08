import { test, expect } from "@playwright/test";

// Pages render without script errors.
for (const url of ["/", "/patterns/atam/", "/about"]) {
  test(`no console errors on ${url}`, async ({ page }) => {
    const errors = [];
    page.on("console", (msg) => { if (msg.type() === "error") errors.push(msg.text()); });
    page.on("pageerror", (error) => errors.push(error.message));
    await page.goto(url);
    await expect(page.locator("header.site-header")).toBeVisible();
    expect(errors).toEqual([]);
  });
}
