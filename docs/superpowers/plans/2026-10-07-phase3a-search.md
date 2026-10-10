# Phase 3a Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Readers find any pattern, glossary term or page by typing: a popup with results as you type, keyboard navigation (arrows, Tab, Enter, Cmd/Ctrl-Enter, Esc), and a results page at `/search/`.

**Architecture:** Jekyll generates `/assets/search.json` from the patterns, the navigation pages and the glossary. One plain script, `assets/js/search.js`, loads a vendored Lunr 2.3.9 and that JSON on first use, builds the index in the browser and drives both the `<dialog>` popup (on every page) and the results page. Browser behaviour is tested with Playwright in Docker (`make e2e`, also in CI).

**Tech Stack:** Jekyll 4.3.1, Liquid, Lunr 2.3.9, plain JavaScript (no build step), SCSS, Minitest + Nokogiri, Playwright 1.58.2 (`mcr.microsoft.com/playwright:v1.58.2-jammy`).

**Spec:** `docs/superpowers/specs/2026-10-07-phase3a-search-design.md` (builds on `docs/superpowers/specs/2026-10-07-phase3a-navigation-pages-design.md`; run this plan after `docs/superpowers/plans/2026-10-07-phase3a-navigation-pages.md`)

## Global Constraints

- Builds and tests run in Docker via `make`; never Ruby or Node on the host. Node runs only in the Playwright image.
- Commit on branch `merge-method-reference` only; push only that branch, never master, never force. No PR, no merge.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (subagent commits may name their own model).
- Copy rule: no dashes as sentence punctuation in visible text; commas or semicolons instead.
- Lunr exactly 2.3.9, vendored at `assets/js/vendor/lunr-2.3.9.min.js`; no CDN at runtime.
- Popup: results from the second character, debounce 100 ms, at most 8 results.
- Boosts: title 10, context 4, body 1; each word also as a trailing-wildcard prefix.
- Keys: ↓ and Tab next (wrap), ↑ and Shift-Tab previous (wrap), Enter opens the selected result (none selected: the first), Cmd-Enter or Ctrl-Enter opens `/search/?q=…`, Esc closes and returns focus; `/`, Cmd-K and Ctrl-K open the popup unless focus is in a text field.
- Playwright image and package exactly `1.58.2`.

## Rulings made while planning

- **S1:** The results page shows results as a plain list of links (Tab moves through them natively); the combobox and arrow keys belong to the popup, as the spec's §2.1 describes them. Cost if wrong: arrow keys on the results page later.
- **S2:** The search input in the popup and on the results page strips everything but letters and digits from each word before querying, so Lunr's query syntax (`:`, `*`, `~`, `+`, `^`) cannot throw. Cost if wrong: none for a pattern catalogue.
- **S3:** Words are matched with OR semantics and ranked (as quality.arc42.org does); results that match more words rank higher. Cost if wrong: multi-word queries list more results.
- **S4:** The results page title is "Search", its lede "Find patterns, glossary terms and pages."; it uses `aim42-page` without a section eyebrow and is not in the navigation (spec §2.2).
- **S5:** The old `.site-search` rules in `_sass/_header.scss` (a search field from quality.arc42.org that the header never rendered) are removed with the new button styles.

## Review Focus

1. Lunr query syntax typed by a reader (`c++`, `atam:`, `*`, `"x"`): no error, sensible results (Task 3, `special characters do not break the search`).
2. The index fails to load (offline, blocked): the popup says "Search is unavailable right now." instead of hanging (Task 3, `a failed index load says so`).
3. A query without matches: "No matches for “…”" and a link to the Patterns index (Task 3, `no matches offers the patterns index`).
4. Enter pressed before the results have rendered: the results page for the query opens instead of nothing (Task 3, `Enter before results opens the results page`).
5. Phone width (375px): the popup fits the screen and the input stays visible above the on-screen keyboard area; the header search button is visible (Task 4, visual check).

---

### Task 1: Search documents and Lunr

**Files:**
- Create: `assets/search.json` (Liquid)
- Create: `assets/js/vendor/lunr-2.3.9.min.js` (downloaded, unchanged)
- Test: `tests/site_test.rb`

**Interfaces:**
- Consumes: `NAV` and `PAGES` from the navigation plan's tests; `_data/glossary.yml` (`id`, `term`, `definition`); `_data/phases.yml` (`title`).
- Produces: `/assets/search.json`, an Array of `{url, kind, title, label, context, body}` (all Strings; `kind` is `pattern`, `page` or `term`); `/assets/js/vendor/lunr-2.3.9.min.js` defining `window.lunr`.

- [ ] **Step 1: Write the failing tests**

In `tests/site_test.rb`, add `require "json"` below `require "yaml"`, and add after `test_no_built_page_has_old_theme_markup`:

```ruby
  def test_search_documents_cover_patterns_pages_and_terms_once
    docs = JSON.parse(File.read(File.join(SITE_DIR, "assets", "search.json")))
    urls = docs.map { |d| d["url"] }
    assert_equal urls.uniq, urls, "duplicate search documents"
    PATTERNS.each { |p| assert_includes urls, "/patterns/#{p["slug"]}/" }
    NAV["sections"].values.flat_map { |s| [s["url"]] + s["pages"].map { |p| p["url"] } }
                   .reject { |u| u.end_with?(".pdf") }
                   .each { |u| assert_includes urls, u }
    YAML.safe_load(File.read(File.join(ROOT, "_data", "glossary.yml"))).each { |t| assert_includes urls, "/glossary/##{t["id"]}" }
    docs.each do |d|
      assert_equal %w[body context kind label title url], d.keys.sort, "#{d["url"]}: keys"
      assert_includes %w[pattern page term], d["kind"], "#{d["url"]}: kind"
      refute d["title"].strip.empty?, "#{d["url"]}: title"
      refute d["label"].strip.empty?, "#{d["url"]}: label"
      assert site_file(d["url"]), "#{d["url"]}: not built"
    end
  end

  def test_search_document_of_a_pattern_has_phase_and_plain_intent
    doc = JSON.parse(File.read(File.join(SITE_DIR, "assets", "search.json"))).find { |d| d["url"] == "/patterns/atam/" }
    atam = PATTERNS.find { |p| p["slug"] == "atam" }
    assert_equal ["pattern", "ATAM", "Analyze", plain(atam["intent"])], doc.values_at("kind", "title", "label", "context")
    refute_match(/<[a-z]/, doc["body"], "body must be plain text")
  end

  def test_lunr_is_vendored_at_the_pinned_version
    head = File.read(File.join(SITE_DIR, "assets", "js", "vendor", "lunr-2.3.9.min.js"), 300)
    assert_includes head, "2.3.9"
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `make site-test`
Expected: FAIL with `Errno::ENOENT` for `_site/assets/search.json` and for the Lunr file.

- [ ] **Step 3: Implement**

Download Lunr and verify it against the npm registry's integrity hash:

```bash
cd /private/tmp && curl -sfLO https://registry.npmjs.org/lunr/-/lunr-2.3.9.tgz
expected=$(curl -sf https://registry.npmjs.org/lunr/2.3.9 | python3 -c 'import json,sys; print(json.load(sys.stdin)["dist"]["integrity"])')
actual="sha512-$(openssl dgst -sha512 -binary lunr-2.3.9.tgz | base64)"
test "$expected" = "$actual" && echo "integrity OK"
tar -xzf lunr-2.3.9.tgz package/lunr.min.js
mkdir -p "$OLDPWD/assets/js/vendor" && cp package/lunr.min.js "$OLDPWD/assets/js/vendor/lunr-2.3.9.min.js"
cd "$OLDPWD" && head -c 200 assets/js/vendor/lunr-2.3.9.min.js
```

Expected: `integrity OK`, and the file header names `lunr` and `2.3.9`.

Create `assets/search.json`:

```liquid
---
layout: null
---
{%- comment -%}
  Search documents (docs/superpowers/specs/2026-10-07-phase3a-search-design.md §3):
  every pattern, every page listed in _data/navigation.yml, every glossary
  term. assets/js/search.js builds the Lunr index from this file.
{%- endcomment -%}
{%- assign sep = "" -%}
[
{%- for doc in site.patterns -%}
{{ sep }}{"url":{{ doc.url | relative_url | jsonify }},"kind":"pattern","title":{{ doc.title | jsonify }},"label":{{ site.data.phases[doc.phase].title | jsonify }},"context":{{ doc.intent | markdownify | strip_html | normalize_whitespace | strip | jsonify }},"body":{{ doc.content | markdownify | strip_html | normalize_whitespace | strip | jsonify }}}
{%- assign sep = "," -%}
{%- endfor -%}
{%- for key in site.data.navigation.bar -%}
  {%- assign section = site.data.navigation.sections[key] -%}
  {%- assign urls = section.pages | map: "url" | unshift: section.url -%}
  {%- for url in urls -%}
    {%- assign p = site.pages | where: "url", url | first -%}
    {%- if p -%}
      {%- assign context = p.lede -%}
      {%- if url == section.url and section.lede -%}{%- assign context = section.lede -%}{%- endif -%}
      {%- assign body = p.content | markdownify | strip_html | normalize_whitespace | strip -%}
      {%- unless context -%}{%- assign context = body | truncatewords: 25 -%}{%- endunless -%}
{{ sep }}{"url":{{ p.url | relative_url | jsonify }},"kind":"page","title":{{ p.title | jsonify }},"label":{{ section.title | jsonify }},"context":{{ context | markdownify | strip_html | normalize_whitespace | strip | jsonify }},"body":{{ body | jsonify }}}
      {%- assign sep = "," -%}
    {%- endif -%}
  {%- endfor -%}
{%- endfor -%}
{%- for entry in site.data.glossary -%}
  {%- capture term_url -%}/glossary/#{{ entry.id }}{%- endcapture -%}
{{ sep }}{"url":{{ term_url | relative_url | jsonify }},"kind":"term","title":{{ entry.term | jsonify }},"label":"Glossary","context":{{ entry.definition | markdownify | strip_html | normalize_whitespace | strip | jsonify }},"body":""}
{%- endfor -%}
]
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green, including the three new tests.

- [ ] **Step 5: Commit**

```bash
git add assets/search.json assets/js/vendor/lunr-2.3.9.min.js tests/site_test.rb
git commit -m "Search documents and Lunr 2.3.9

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Browser test harness (Playwright in Docker)

**Files:**
- Create: `tests/e2e/package.json`, `tests/e2e/package-lock.json` (generated), `tests/e2e/playwright.config.mjs`, `tests/e2e/serve.mjs`, `tests/e2e/smoke.spec.mjs`
- Modify: `Makefile`, `.gitignore`, `.github/workflows/<the workflow file containing "name: Check site">`

**Interfaces:**
- Produces: `make e2e` (builds the site, runs every `tests/e2e/*.spec.mjs` against `_site/` served on `http://127.0.0.1:4243`); `make check` runs it last.

- [ ] **Step 1: Write the failing test**

Create `tests/e2e/package.json`:

```json
{
  "name": "aim42-site-e2e",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.58.2"
  }
}
```

Create `tests/e2e/serve.mjs`:

```js
// Serves _site/ for the browser tests the way Jekyll and the host resolve
// URLs: "/about" -> about.html, "/search/" -> search/index.html.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../_site");
const types = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".json": "application/json",
  ".css": "text/css", ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg",
  ".woff2": "font/woff2", ".pdf": "application/pdf", ".ico": "image/x-icon",
};

http.createServer((req, res) => {
  const url = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
  const candidates = url.endsWith("/") ? [url + "index.html"] : [url, url + ".html", url + "/index.html"];
  for (const candidate of candidates) {
    const file = path.join(root, candidate);
    if (file.startsWith(root) && fs.existsSync(file) && fs.statSync(file).isFile()) {
      res.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream" });
      fs.createReadStream(file).pipe(res);
      return;
    }
  }
  res.writeHead(404, { "Content-Type": "text/plain" });
  res.end("not found");
}).listen(4243, "127.0.0.1");
```

Create `tests/e2e/playwright.config.mjs`:

```js
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: ".",
  testMatch: "*.spec.mjs",
  reporter: "list",
  use: { baseURL: "http://127.0.0.1:4243" },
  webServer: { command: "node serve.mjs", url: "http://127.0.0.1:4243/", reuseExistingServer: false },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
```

Create `tests/e2e/smoke.spec.mjs`:

```js
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
```

Generate the lock file inside the Playwright image:

```bash
docker run --rm -v "$PWD:/site" -w /site/tests/e2e mcr.microsoft.com/playwright:v1.58.2-jammy npm install --no-audit --no-fund
```

Expected: `tests/e2e/package-lock.json` exists and pins `@playwright/test` `1.58.2`.

- [ ] **Step 2: Run to verify it fails**

Run: `make e2e`
Expected: FAIL with `make: *** No rule to make target 'e2e'`.

- [ ] **Step 3: Implement**

In `Makefile`:

1. Below `RUN = …` add:
   ```make
   PLAYWRIGHT_IMAGE ?= mcr.microsoft.com/playwright:v1.58.2-jammy
   E2E = docker run --rm --ipc=host -v "$(CURDIR):/site" -w /site/tests/e2e $(PLAYWRIGHT_IMAGE)
   ```
2. Add `e2e` to the `.PHONY` line.
3. In `help`, add the line
   ```make
   	@printf "make e2e        build the site and run the browser tests (Playwright)\n"
   ```
4. Add the target (recipe lines start with a tab):
   ```make
   e2e:
   	$(RUN) bundle exec jekyll build --quiet
   	$(E2E) sh -c "npm ci --no-audit --no-fund && npx playwright test"
   ```
5. Change `check: validate unit site-test` to `check: validate unit site-test e2e`.

In `.gitignore`, add:

```
tests/e2e/node_modules
tests/e2e/test-results
tests/e2e/playwright-report
```

In the CI workflow (`.github/workflows/`, the file with `name: Check site`), add after the `Site tests` step:

```yaml
      - name: Browser tests
        run: docker run --rm --ipc=host -v "$PWD:/site" -w /site/tests/e2e mcr.microsoft.com/playwright:v1.58.2-jammy sh -c "npm ci --no-audit --no-fund && npx playwright test"
```

- [ ] **Step 4: Run to verify it passes**

Run: `make e2e`
Expected: `3 passed`.

Run: `make check`
Expected: all green, ending with the three browser tests.

- [ ] **Step 5: Commit**

```bash
git add tests/e2e/package.json tests/e2e/package-lock.json tests/e2e/playwright.config.mjs tests/e2e/serve.mjs tests/e2e/smoke.spec.mjs Makefile .gitignore .github/workflows
git commit -m "Browser tests with Playwright in Docker (make e2e, CI)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Search popup, header button and results page

**Files:**
- Create: `assets/js/search.js`, `_includes/aim42/search-dialog.html`, `_pages/search.md`, `_sass/components/_search.scss`, `tests/e2e/search.spec.mjs`
- Modify: `_layouts/aim42-base.html`, `_includes/aim42/site-header.html` (search button), `_sass/_header.scss` (remove `.site-search` rules), `assets/css/aim42.scss` (import), `tests/site_test.rb`

**Interfaces:**
- Consumes: `/assets/search.json`, `window.lunr` (Task 1); `make e2e` (Task 2); `PAGES`, `NAV` (navigation plan).
- Produces: element ids `search-dialog`, `search-dialog-input`, `search-dialog-results`, `search-page-input`, `search-page-results`, `search-page-status`; class `site-search-button` with `data-search-open`.

- [ ] **Step 1: Write the failing tests**

Create `tests/e2e/search.spec.mjs`:

```js
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
```

In `tests/site_test.rb`, add after `test_lunr_is_vendored_at_the_pinned_version`:

```ruby
  def test_search_dialog_and_button_are_on_every_page
    PAGES.each do |url|
      doc = page(url)
      assert doc.at_css("dialog#search-dialog input#search-dialog-input[role='combobox'][aria-controls='search-dialog-results']"), "#{url}: search combobox missing"
      assert doc.at_css("dialog#search-dialog #search-dialog-results[role='listbox']"), "#{url}: result listbox missing"
      assert doc.at_css("label[for='search-dialog-input']"), "#{url}: search label missing"
      assert doc.at_css("header.site-header a.site-search-button[href='/search/'][data-search-open]"), "#{url}: header search button missing"
    end
  end

  def test_search_page_works_as_a_plain_form
    doc = page("/search/")
    assert doc.at_css("main form[action='/search/'][method='get'] input#search-page-input[name='q']"), "GET form with q missing"
    assert_match(/Search needs JavaScript/, doc.at_css("main noscript")&.text.to_s)
    assert doc.at_css("main noscript a[href='/patterns/']"), "no-JavaScript notice must link to the patterns index"
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `make check`
Expected: FAIL. Site tests: "/: search combobox missing" and "expected /search/ to be generated". (`make check` stops at the first failing target; run `make e2e` separately to see the browser tests fail too: they fail waiting for `#search-dialog` to be visible.)

- [ ] **Step 3: Implement**

Create `_includes/aim42/search-dialog.html`:

```html
{% comment %}
  search-dialog — the search popup (spec: 2026-10-07-phase3a-search-design.md §2.1).
  assets/js/search.js opens it and fills the result list. The form posts to
  the results page, so Enter without JavaScript still searches.
{% endcomment %}
<dialog id="search-dialog" class="search-dialog" aria-label="Search aim42"
        data-lunr="{{ '/assets/js/vendor/lunr-2.3.9.min.js' | relative_url }}"
        data-index="{{ '/assets/search.json' | relative_url }}"
        data-results="{{ '/search/' | relative_url }}">
  <form class="search-dialog__form" action="{{ '/search/' | relative_url }}" method="get" role="search">
    <label class="visually-hidden" for="search-dialog-input">Search patterns and pages</label>
    <input id="search-dialog-input" class="search-dialog__input" type="search" name="q"
           placeholder="Search patterns and pages" autocomplete="off" spellcheck="false"
           role="combobox" aria-expanded="false" aria-controls="search-dialog-results" aria-autocomplete="list" />
    <kbd class="search-dialog__hint" aria-hidden="true">esc</kbd>
  </form>
  <ul id="search-dialog-results" class="search-results" role="listbox" aria-label="Search results"></ul>
  <p class="search-dialog__status" aria-live="polite"></p>
  <p class="search-dialog__none" hidden>Browse the <a href="{{ '/patterns/' | relative_url }}">patterns index</a>.</p>
  <p class="search-dialog__all" hidden><a href="{{ '/search/' | relative_url }}">Show all results</a></p>
</dialog>
```

Create `_pages/search.md`:

```markdown
---
title: Search
layout: aim42-page
permalink: /search/
lede: Find patterns, glossary terms and pages.
---

<form class="search-page__form" action="{{ '/search/' | relative_url }}" method="get" role="search">
  <label class="visually-hidden" for="search-page-input">Search patterns and pages</label>
  <input id="search-page-input" class="search-page__input" type="search" name="q" autocomplete="off" spellcheck="false" />
  <button class="search-page__button" type="submit">Search</button>
</form>

<p id="search-page-status" class="search-page__status" aria-live="polite"></p>

<noscript><p>Search needs JavaScript. Browse the <a href="{{ '/patterns/' | relative_url }}">patterns index</a> instead.</p></noscript>

<ul id="search-page-results" class="search-results search-results--page"></ul>
```

Create `assets/js/search.js`:

```js
// Site search. Spec: docs/superpowers/specs/2026-10-07-phase3a-search-design.md
// Lunr and /assets/search.json load on first use. The popup (every page) and
// the results page (/search/) share loading, querying and rendering.
(function () {
  "use strict";

  var dialog = document.getElementById("search-dialog");
  if (!dialog) return;

  var LUNR_SRC = dialog.getAttribute("data-lunr");
  var INDEX_SRC = dialog.getAttribute("data-index");
  var RESULTS_URL = dialog.getAttribute("data-results");
  var MIN_CHARS = 2;
  var POPUP_LIMIT = 8;
  var DEBOUNCE_MS = 100;
  var engine = null;

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      var script = document.createElement("script");
      script.src = src;
      script.onload = resolve;
      script.onerror = function () { reject(new Error(src + " did not load")); };
      document.head.appendChild(script);
    });
  }

  // Resolves to {index, docs}; docs maps a URL to its search document.
  function loadEngine() {
    if (!engine) {
      engine = Promise.all([
        window.lunr ? Promise.resolve() : loadScript(LUNR_SRC),
        fetch(INDEX_SRC).then(function (response) {
          if (!response.ok) throw new Error(INDEX_SRC + ": HTTP " + response.status);
          return response.json();
        })
      ]).then(function (loaded) {
        var docs = {};
        var index = window.lunr(function () {
          this.ref("url");
          this.field("title", { boost: 10 });
          this.field("context", { boost: 4 });
          this.field("body");
          loaded[1].forEach(function (doc) {
            docs[doc.url] = doc;
            this.add(doc);
          }, this);
        });
        return { index: index, docs: docs };
      }).catch(function (error) {
        engine = null; // the next keystroke tries again
        throw error;
      });
    }
    return engine;
  }

  // Lower-case words of letters and digits only, so Lunr's query syntax
  // (":", "*", "~", "^", "+") never reaches the index.
  function words(query) {
    return query.toLowerCase().split(/\s+/).map(function (word) {
      return word.replace(/[^\p{L}\p{N}]/gu, "");
    }).filter(Boolean);
  }

  function longEnough(query) {
    return words(query).join("").length >= MIN_CHARS;
  }

  // Each word matches as typed (stemmed) and as a prefix while it is still
  // being typed; documents matching more words rank higher.
  function find(loaded, query) {
    var terms = words(query);
    if (!terms.length) return [];
    return loaded.index.query(function (q) {
      terms.forEach(function (term) {
        q.term(term);
        q.term(term, { usePipeline: false, wildcard: window.lunr.Query.wildcard.TRAILING, boost: 0.5 });
      });
    }).map(function (hit) { return loaded.docs[hit.ref]; });
  }

  function escapeRegExp(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  // Appends text to parent, wrapping each occurrence of a query word in <mark>.
  function appendHighlighted(parent, text, terms) {
    if (!terms.length) {
      parent.appendChild(document.createTextNode(text));
      return;
    }
    var pattern = new RegExp("(" + terms.map(escapeRegExp).join("|") + ")", "gi");
    var last = 0;
    var match;
    while ((match = pattern.exec(text))) {
      parent.appendChild(document.createTextNode(text.slice(last, match.index)));
      var mark = document.createElement("mark");
      mark.textContent = match[0];
      parent.appendChild(mark);
      last = pattern.lastIndex;
    }
    parent.appendChild(document.createTextNode(text.slice(last)));
  }

  // One result: a link with title, label and context line. With an id it is
  // a listbox option (popup); without, a plain list item (results page).
  function resultItem(doc, terms, id) {
    var item = document.createElement("li");
    item.className = "search-result";
    var link = document.createElement("a");
    link.className = "search-result__link";
    link.href = doc.url;
    if (id) {
      item.id = id;
      item.setAttribute("role", "option");
      item.setAttribute("aria-selected", "false");
      link.tabIndex = -1;
    }
    var title = document.createElement("span");
    title.className = "search-result__title";
    appendHighlighted(title, doc.title, terms);
    var label = document.createElement("span");
    label.className = "search-result__label";
    label.textContent = doc.label;
    var context = document.createElement("span");
    context.className = "search-result__context";
    appendHighlighted(context, doc.context, terms);
    link.append(title, label, context);
    item.appendChild(link);
    return item;
  }

  function quoted(query) {
    return "“" + query.trim() + "”";
  }

  function countText(count) {
    return count === 1 ? "1 result" : count + " results";
  }

  function resultsHref(query) {
    return RESULTS_URL + "?q=" + encodeURIComponent(query.trim());
  }

  function unavailable(status) {
    return function (error) {
      console.error("Search is unavailable:", error);
      status.textContent = "Search is unavailable right now.";
    };
  }

  function isTyping(target) {
    return Boolean(target && target.closest && target.closest("input, textarea, select, [contenteditable=''], [contenteditable='true']"));
  }

  // ---- Popup -------------------------------------------------------------

  var input = document.getElementById("search-dialog-input");
  var list = document.getElementById("search-dialog-results");
  var status = dialog.querySelector(".search-dialog__status");
  var none = dialog.querySelector(".search-dialog__none");
  var all = dialog.querySelector(".search-dialog__all");
  var opener = null;
  var selected = -1;
  var timer = null;

  function popupOptions() {
    return list.querySelectorAll("[role=option]");
  }

  function select(position) {
    var options = popupOptions();
    if (!options.length) return;
    selected = (position + options.length) % options.length;
    options.forEach(function (option, n) {
      option.setAttribute("aria-selected", n === selected ? "true" : "false");
    });
    input.setAttribute("aria-activedescendant", options[selected].id);
    options[selected].scrollIntoView({ block: "nearest" });
  }

  function renderPopup() {
    var query = input.value;
    selected = -1;
    input.removeAttribute("aria-activedescendant");
    input.setAttribute("aria-expanded", "false");
    list.replaceChildren();
    none.hidden = true;
    all.hidden = true;
    if (!longEnough(query)) {
      status.textContent = "";
      return;
    }
    loadEngine().then(function (loaded) {
      if (query !== input.value) return; // a newer keystroke renders instead
      var terms = words(query);
      var hits = find(loaded, query);
      hits.slice(0, POPUP_LIMIT).forEach(function (doc, n) {
        list.appendChild(resultItem(doc, terms, "search-option-" + n));
      });
      input.setAttribute("aria-expanded", hits.length ? "true" : "false");
      if (!hits.length) {
        status.textContent = "No matches for " + quoted(query) + ".";
        none.hidden = false;
        return;
      }
      status.textContent = countText(hits.length);
      var link = all.querySelector("a");
      link.href = resultsHref(query);
      link.textContent = "Show all " + countText(hits.length);
      all.hidden = false;
    }, unavailable(status));
  }

  function openPopup() {
    if (dialog.open) return;
    opener = document.activeElement;
    dialog.showModal();
    input.select();
    loadEngine().catch(function () {}); // warm up; errors show when typing
    if (input.value) renderPopup();
  }

  dialog.addEventListener("close", function () {
    if (opener && opener.focus) opener.focus();
  });

  // A click on the backdrop closes the popup.
  dialog.addEventListener("click", function (event) {
    if (event.target === dialog) dialog.close();
  });

  input.addEventListener("input", function () {
    clearTimeout(timer);
    timer = setTimeout(renderPopup, DEBOUNCE_MS);
  });

  input.addEventListener("keydown", function (event) {
    var options = popupOptions();
    if (event.key === "Enter") {
      event.preventDefault();
      if (!input.value.trim()) return;
      if (event.metaKey || event.ctrlKey || !options.length) {
        window.location.href = resultsHref(input.value);
        return;
      }
      window.location.href = options[selected >= 0 ? selected : 0].querySelector("a").href;
      return;
    }
    if (!options.length) return;
    var forward = event.key === "ArrowDown" || (event.key === "Tab" && !event.shiftKey);
    var backward = event.key === "ArrowUp" || (event.key === "Tab" && event.shiftKey);
    if (!forward && !backward) return;
    event.preventDefault();
    if (selected < 0) select(forward ? 0 : options.length - 1);
    else select(selected + (forward ? 1 : -1));
  });

  document.addEventListener("keydown", function (event) {
    if (dialog.open || isTyping(event.target)) return;
    var slash = event.key === "/" && !event.metaKey && !event.ctrlKey && !event.altKey;
    var commandK = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k";
    if (!slash && !commandK) return;
    event.preventDefault();
    openPopup();
  });

  document.querySelectorAll("[data-search-open]").forEach(function (trigger) {
    trigger.addEventListener("click", function (event) {
      event.preventDefault();
      openPopup();
    });
  });

  // ---- Results page ------------------------------------------------------

  var pageInput = document.getElementById("search-page-input");
  if (!pageInput) return;
  var pageList = document.getElementById("search-page-results");
  var pageStatus = document.getElementById("search-page-status");
  var pageTimer = null;

  function renderPage() {
    var query = pageInput.value;
    pageList.replaceChildren();
    if (!longEnough(query)) {
      pageStatus.textContent = "Type at least " + MIN_CHARS + " characters.";
      return;
    }
    loadEngine().then(function (loaded) {
      if (query !== pageInput.value) return;
      var terms = words(query);
      var hits = find(loaded, query);
      hits.forEach(function (doc) { pageList.appendChild(resultItem(doc, terms, null)); });
      pageStatus.textContent = hits.length
        ? countText(hits.length) + " for " + quoted(query) + "."
        : "No matches for " + quoted(query) + ".";
    }, unavailable(pageStatus));
  }

  pageInput.value = new URLSearchParams(window.location.search).get("q") || "";
  renderPage();
  pageInput.addEventListener("input", function () {
    clearTimeout(pageTimer);
    pageTimer = setTimeout(function () {
      var query = pageInput.value.trim();
      history.replaceState(null, "", RESULTS_URL + (query ? "?q=" + encodeURIComponent(query) : ""));
      renderPage();
    }, DEBOUNCE_MS);
  });
})();
```

In `_layouts/aim42-base.html`, replace

```html
{% include aim42/footer.html %}
<script defer src="{{ '/assets/js/aim42.js' | relative_url }}"></script>
```

with

```html
{% include aim42/footer.html %}
{% include aim42/search-dialog.html %}
<script defer src="{{ '/assets/js/aim42.js' | relative_url }}"></script>
<script defer src="{{ '/assets/js/search.js' | relative_url }}"></script>
```

In `_includes/aim42/site-header.html`, inside `<div class="site-actions">`, insert before the `<button class="site-menu-toggle …">`:

```html
        <a class="site-search-button" href="{{ '/search/' | relative_url }}" data-search-open aria-label="Search" title="Search (/ or Cmd-K)">
          <svg aria-hidden="true" viewBox="0 0 20 20" width="18" height="18"><circle cx="8.5" cy="8.5" r="5.5" fill="none" stroke="currentColor" stroke-width="2"></circle><path d="M13 13l4.5 4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round"></path></svg>
        </a>
```

In `_sass/_header.scss`, delete the rules `.site-search { … }`, `.site-search::before { … }`, `.site-search::after { … }` and `.site-search input[type="search"] { … }` (and any `.site-search input…` state rules that follow them), ruling S5.

Create `_sass/components/_search.scss`:

```scss
// Search: header button, popup (<dialog>) and results page.
// Spec: docs/superpowers/specs/2026-10-07-phase3a-search-design.md

.visually-hidden {
  clip: rect(0 0 0 0);
  clip-path: inset(50%);
  height: 1px;
  overflow: hidden;
  position: absolute;
  white-space: nowrap;
  width: 1px;
}

.site-search-button {
  align-items: center;
  background: var(--brand-cream-06);
  border: 1px solid var(--brand-cream-24);
  border-radius: $radius-sm;
  color: var(--header-on-violet-muted);
  display: inline-flex;
  flex: 0 0 2.35rem;
  height: 2.35rem;
  justify-content: center;
  width: 2.35rem;

  &:hover {
    background: var(--brand-cream-09);
    color: var(--header-on-violet);
  }

  &:focus-visible {
    box-shadow: var(--focus-ring-on-violet);
    color: var(--header-on-violet);
    outline: none;
  }
}

.search-dialog {
  background: $background-color;
  border: 1px solid var(--brand-primary-soft);
  border-radius: $radius-lg;
  box-shadow: 0 1.5rem 3rem rgba(29, 40, 51, 0.25);
  color: var(--brand-ink);
  margin: 10vh auto auto;
  max-height: 80vh;
  max-width: 40rem;
  padding: 0;
  width: calc(100% - 2rem);

  &::backdrop {
    background: rgba(29, 40, 51, 0.45);
  }
}

.search-dialog__form {
  align-items: center;
  border-bottom: 1px solid var(--brand-primary-soft);
  display: flex;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
}

.search-dialog__input {
  background: transparent;
  border: 0;
  color: var(--brand-ink);
  flex: 1 1 auto;
  font: inherit;
  font-size: $text-lg;
  min-height: 44px;
  min-width: 0;
  outline: none;
}

.search-dialog__hint {
  border: 1px solid var(--brand-primary-soft);
  border-radius: $radius-xs;
  color: var(--brand-muted-strong);
  font-size: $text-xs;
  padding: 0.1rem 0.35rem;
}

.search-dialog__status,
.search-dialog__none,
.search-dialog__all {
  color: var(--brand-muted-strong);
  font-size: $text-sm;
  margin: 0;
  padding: 0.4rem 1rem;

  &:empty {
    display: none;
  }
}

.search-results {
  list-style: none;
  margin: 0;
  padding: 0;
}

.search-dialog .search-results {
  max-height: 55vh;
  overflow-y: auto;
}

// Anchored to beat the prose rules for `.site-content li a` and lists.
.site-content .search-results {
  max-width: none;
  padding-left: 0;
}

.search-result__link,
.site-content .search-result__link {
  color: var(--brand-ink);
  display: grid;
  gap: 0.1rem 0.6rem;
  grid-template-columns: minmax(0, 1fr) auto;
  min-height: 44px;
  padding: 0.55rem 1rem;
  text-decoration: none;
}

.search-result__title {
  font-weight: 700;
}

.search-result__label {
  align-self: center;
  color: var(--brand-muted-strong);
  font-size: $text-xs;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.search-result__context {
  color: var(--brand-muted-strong);
  font-size: $text-sm;
  grid-column: 1 / -1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.search-results--page .search-result__context {
  white-space: normal;
}

.search-result__link:hover,
.search-result[aria-selected="true"] .search-result__link {
  background: var(--brand-primary-faint);
}

.search-result[aria-selected="true"] .search-result__link {
  box-shadow: inset 3px 0 0 var(--brand-primary);
}

.search-result mark {
  background: rgba(255, 214, 102, 0.55);
  color: inherit;
  padding: 0;
}

.search-page__form {
  display: flex;
  gap: 0.5rem;
  margin: 0 0 1rem;
}

.search-page__input {
  border: 1px solid var(--brand-muted);
  border-radius: $radius-sm;
  flex: 1 1 auto;
  font: inherit;
  min-height: 44px;
  min-width: 0;
  padding: 0 0.75rem;
}

.search-page__button {
  background: var(--brand-primary);
  border: 0;
  border-radius: $radius-sm;
  color: var(--brand-cream);
  cursor: pointer;
  font: inherit;
  font-weight: 600;
  min-height: 44px;
  padding: 0 1rem;
}
```

In `assets/css/aim42.scss`, add after `@import "components/_section-cards";`:

```scss
@import "components/_search";
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green: site tests including the two new ones, then the browser tests (`3` smoke plus `17` search tests passed).

- [ ] **Step 5: Commit**

```bash
git add assets/js/search.js _includes/aim42/search-dialog.html _pages/search.md _sass/components/_search.scss _layouts/aim42-base.html _includes/aim42/site-header.html _sass/_header.scss assets/css/aim42.scss tests/site_test.rb tests/e2e/search.spec.mjs
git commit -m "Search popup, header button and results page

Lunr index built in the browser on first use; results as you type,
arrows and Tab to move, Enter to open, Cmd/Ctrl-Enter for all results,
Esc to close; /search/ lists all matches and keeps the URL in sync.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Visual check and push (controller)

Done by the controller (needs the browser image and GitHub).

**Files:** none (defects go back through a fix round of Task 3).

- [ ] **Step 1: Full check**

Run: `make check`
Expected: all green.

- [ ] **Step 2: Visual check**

With `make dev` running, take Playwright screenshots (image `mcr.microsoft.com/playwright:v1.58.2-jammy`, against `http://host.docker.internal:4242/`) at 375px and 1280px of: the header with the search button; the popup with results for "stakeholder" and one selected result; the popup with no matches; `/search/?q=analysis`. Check: the popup fits the viewport at 375px, the input stays visible at the top, highlights are readable, the selected result is clearly marked, no horizontal scroll.

Any defect: fix round on Task 3, then `make check`.

- [ ] **Step 3: Push**

```bash
git push origin merge-method-reference
```

Expected: push succeeds; the GitHub Actions run, now including the browser tests, is green.
