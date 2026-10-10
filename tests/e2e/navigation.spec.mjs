import { test, expect } from "@playwright/test";

// The open menu sits in the sticky header; on a phone it is taller than the
// screen, so it must scroll on its own to reach its last links.
test("on a phone every menu link can be brought into view", async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto("/patterns/atam/");
  await page.mouse.wheel(0, 600);
  await page.locator(".site-menu-toggle").click();
  const last = page.locator("#site-secondary-nav a").last();
  await last.focus();
  const box = await last.boundingBox();
  expect(box.y).toBeGreaterThanOrEqual(0);
  expect(box.y + box.height).toBeLessThanOrEqual(667);
});

test("a box in the domain model diagram leads to its definition", async ({ page }) => {
  await page.goto("/reference/domain-model/");
  await page.locator("#figure-domain-model a[href='#issue']").click();
  await expect(page).toHaveURL(/#issue$/);
  await expect(page.locator("dt#issue")).toBeInViewport();
});
