import { test, expect } from "@playwright/test";

const options = (page) => page.locator("#search-dialog-results [role=option]");

async function openPopup(page, query) {
  await page.goto("/patterns/atam/");
  await page.keyboard.press("/");
  await expect(page.locator("#search-dialog")).toBeVisible();
  if (query) {
    await page.keyboard.type(query);
    await expect(options(page).first()).toBeVisible();
  }
}

test("a prefix finds the pattern while typing", async ({ page }) => {
  await openPopup(page, "strang");
  await expect(options(page).first()).toContainText("Strangler Approach");
});

test("a word finds the patterns that contain it", async ({ page }) => {
  await openPopup(page, "stakeholder");
  await expect(page.locator("#search-dialog-results")).toContainText("Stakeholder Interview");
  await expect(page.locator("#search-dialog-results")).toContainText("Stakeholder Analysis");
});

test("at most eight results and a link to all of them", async ({ page }) => {
  await openPopup(page, "analysis");
  expect(await options(page).count()).toBeLessThanOrEqual(8);
  await expect(page.locator(".search-dialog__all a")).toHaveAttribute("href", "/search/?q=analysis");
  await expect(page.locator(".search-dialog__all a")).toHaveText(/^Show all \d+ results$/);
});

test("arrows and Tab move the selection and wrap", async ({ page }) => {
  await openPopup(page, "stakeholder");
  const input = page.locator("#search-dialog-input");
  const ids = await options(page).evaluateAll((els) => els.map((e) => e.id));
  const active = () => input.getAttribute("aria-activedescendant");
  await page.keyboard.press("ArrowDown");
  expect(await active()).toBe(ids[0]);
  await page.keyboard.press("Tab");
  expect(await active()).toBe(ids[1]);
  await page.keyboard.press("Shift+Tab");
  expect(await active()).toBe(ids[0]);
  await page.keyboard.press("ArrowUp");
  expect(await active()).toBe(ids[ids.length - 1]);
  await page.keyboard.press("ArrowDown");
  expect(await active()).toBe(ids[0]);
  await expect(input).toBeFocused();
  await expect(page.locator(`#${ids[0]}`)).toHaveAttribute("aria-selected", "true");
});

test("Enter opens the selected result", async ({ page }) => {
  await openPopup(page, "strang");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/\/patterns\/strangler-approach\/$/);
});

for (const combo of ["Control+Enter", "Meta+Enter"]) {
  test(`${combo} opens the results page`, async ({ page }) => {
    await openPopup(page, "strang");
    await page.keyboard.press(combo);
    await expect(page).toHaveURL(/\/search\/\?q=strang$/);
  });
}

test("Enter before results opens the results page", async ({ page }) => {
  await page.goto("/patterns/atam/");
  await page.keyboard.press("/");
  await page.locator("#search-dialog-input").fill("atam");
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/\/(search\/\?q=atam|patterns\/atam\/)$/);
});

test("Esc closes the popup and returns focus to the search button", async ({ page }) => {
  await page.goto("/patterns/atam/");
  await page.locator(".site-search-button").click();
  await expect(page.locator("#search-dialog")).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(page.locator("#search-dialog")).toBeHidden();
  await expect(page.locator(".site-search-button")).toBeFocused();
});

for (const combo of ["Control+k", "Meta+k"]) {
  test(`${combo} opens the popup`, async ({ page }) => {
    await page.goto("/");
    await page.keyboard.press(combo);
    await expect(page.locator("#search-dialog")).toBeVisible();
    await expect(page.locator("#search-dialog-input")).toBeFocused();
  });
}

test("a slash typed into a text field stays in the field", async ({ page }) => {
  await page.goto("/search/");
  await page.locator("#search-page-input").press("/");
  await expect(page.locator("#search-dialog")).toBeHidden();
  await expect(page.locator("#search-page-input")).toHaveValue("/");
});

test("no matches offers the patterns index", async ({ page }) => {
  await page.goto("/patterns/atam/");
  await page.keyboard.press("/");
  await page.keyboard.type("xyzzyq");
  await expect(page.locator(".search-dialog__status")).toHaveText("No matches for “xyzzyq”.");
  await expect(page.locator(".search-dialog__none a")).toHaveAttribute("href", "/patterns/");
});

test("special characters do not break the search", async ({ page }) => {
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await openPopup(page);
  for (const query of ["c++", "atam:", "*", "\"atam\"", "~x^2"]) {
    await page.locator("#search-dialog-input").fill(query);
    await page.waitForTimeout(250);
  }
  await page.locator("#search-dialog-input").fill("atam:");
  await expect(options(page).first()).toContainText("ATAM");
  expect(errors).toEqual([]);
});

test("a failed index load says so", async ({ page }) => {
  await page.route("**/assets/search.json", (route) => route.abort());
  await page.goto("/patterns/atam/");
  await page.keyboard.press("/");
  await page.keyboard.type("atam");
  await expect(page.locator(".search-dialog__status")).toHaveText("Search is unavailable right now.");
});

test("the results page lists all matches and keeps the URL in sync", async ({ page }) => {
  await page.goto("/search/?q=stakeholder");
  const results = page.locator("#search-page-results li");
  await expect(page.locator("#search-page-input")).toHaveValue("stakeholder");
  await expect(page.locator("#search-page-results")).toContainText("Stakeholder Interview");
  await expect(page.locator("#search-page-results")).toContainText("Stakeholder Analysis");
  await page.locator("#search-page-input").fill("atam");
  await expect(page).toHaveURL(/\/search\/\?q=atam$/);
  await expect(results.first()).toContainText("ATAM");
  await expect(page.locator("#search-page-status")).toHaveText(/^\d+ results? for “atam”\.$/);
});

test("no console errors when searching", async ({ page }) => {
  const errors = [];
  page.on("console", (msg) => { if (msg.type() === "error") errors.push(msg.text()); });
  page.on("pageerror", (error) => errors.push(error.message));
  await openPopup(page, "atam");
  await page.goto("/search/?q=atam");
  await expect(page.locator("#search-page-results li").first()).toBeVisible();
  expect(errors).toEqual([]);
});

// Final review fixes.

test("Enter right after retyping does not open the previous query's result", async ({ page }) => {
  await openPopup(page, "atam");
  await page.locator("#search-dialog-input").fill("strangler");
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/\/(search\/\?q=strangler|patterns\/strangler-approach\/)$/);
});

test("hyphenated words find their pattern", async ({ page }) => {
  await openPopup(page, "change-by-split");
  await expect(options(page).first()).toContainText("Change-by-Split Approach");
});

test("Esc closes the popup even with text in the field", async ({ page }) => {
  await openPopup(page, "atam");
  await page.keyboard.press("Escape");
  await expect(page.locator("#search-dialog")).toBeHidden();
});

test("results do not repeat while the index is still loading", async ({ page }) => {
  await page.route("**/assets/search.json", async (route) => {
    await new Promise((resolve) => setTimeout(resolve, 1500));
    await route.continue();
  });
  await page.goto("/patterns/atam/");
  await page.keyboard.press("/");
  await page.keyboard.type("st");
  await page.waitForTimeout(200);
  await page.keyboard.type("r");
  await page.waitForTimeout(200);
  await page.keyboard.press("Backspace");
  await expect(options(page).first()).toBeVisible({ timeout: 5000 });
  await page.waitForTimeout(300);
  const ids = await options(page).evaluateAll((els) => els.map((e) => e.id));
  expect(new Set(ids).size).toBe(ids.length);
  expect(ids.length).toBeLessThanOrEqual(8);
});
