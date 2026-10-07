# Phase 3a Navigation and Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the navigation around four sections (Get started, Patterns, Learn, About), move every remaining page onto the aim42 layouts, and remove Minimal Mistakes from the repository.

**Architecture:** `_data/navigation.yml` becomes the single source for the header bar, the hamburger menu, the section cards and each page's section eyebrow; an include derives the current page's section from it by URL. Section pages get a new `aim42-section` layout; all other pages use `aim42-page`. The theme gem, its config, files and mentions go last, guarded by repository and built-site scans.

**Tech Stack:** Jekyll 4.3.1, Liquid, SCSS (libsass via jekyll-sass-converter 2.2), Minitest + Nokogiri, Docker via `make`.

**Spec:** `docs/superpowers/specs/2026-10-07-phase3a-navigation-pages-design.md` (parent: `docs/superpowers/specs/2026-10-07-method-reference-merge-design.md`)

## Global Constraints

- Builds and tests run in Docker via `make` (`make validate`, `make unit`, `make site-test`, `make check`, `make lock`, `make build`); never Ruby on the host. Shell edits use `perl -pi -e` or `python3` (host tools), never Ruby.
- Commit on branch `merge-method-reference` only; push only that branch, never master, never force. No PR, no merge.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (subagent commits may name their own model).
- Copy rule: no dashes as sentence punctuation in visible text; commas or semicolons instead.
- Page text moves as is; only the factual fixes of spec §4.4 and §5 change wording.
- URLs stay: `/about`, `/contact`, `/contribute`, `/examples`, `/faq`, `/getstarted`, `/imprint/`, `/learn`, `/license`, `/principles`, `/publications`, `/training`, `/using`, `/404.html`.
- LinkedIn URL exactly: `https://www.linkedin.com/in/gernotstarke/`
- Logo exactly: `images/logo/AIM42_white.svg`, alt `aim42`.
- Planning documents under `docs/superpowers/` are not edited for the theme cleanup.

## Rulings made while planning

- **N1:** A page's section comes from `_data/navigation.yml` by URL (spec §2); `section:` front matter keeps meaning "hero colour" only.
- **N2:** The old navigation keys (`main`, `getstarted`, `learn`, `about`, `examples`) stay until Task 5, because Minimal Mistakes pages still render them until they are migrated; Task 1 removes only `primary` and `secondary`.
- **N3:** Content headings `# X` on migrated pages become `## X`, so each page has exactly one H1 (the hero title). `{% include toc %}` (a theme include) becomes kramdown's `* Table of contents` / `{:toc}`.
- **N4:** The section page hero shows the section's `title` and `lede` from the navigation data; the page front matter `title` is set to the same text for the browser title.
- **N5:** `images/aim42-process-2017.png` is an old home page image with no references and is removed with the others in Task 5.
- **N6:** On About, the badge block for the archived `aim42/aim42` repository is removed (it would show a frozen repository); the website badges stay.
- **N7:** `_config.yml` `description` loses its dash: "Architecture Improvement Method: systematic modernization and evolution of IT systems." (it is the meta description of pages without a lede).

## Review Focus

1. A page added under `_pages/` but not to the navigation: the tests must fail and name the file (Task 4, `test_every_page_is_in_the_navigation`).
2. A typo in a navigation URL: the tests must fail and name the URL (Task 1, `test_navigation_urls_resolve`).
3. Phone width (375px): the header fits in one row (logo, hamburger), the open menu shows all four groups readably (Task 6, visual check).
4. Old inbound links (`/about`, `/faq`, `/imprint/`, `/getstarted`, `/learn`, `/contact`) keep resolving (existing `test_existing_pages_still_build`; Task 5 makes the link check cover every built page).
5. Keyboard: the menu opens with Enter on the toggle, Esc closes it and returns focus to the toggle, every menu link is reachable by Tab (Task 6, Playwright check).

---

### Task 1: Navigation data, header bar, menu and logo

**Files:**
- Modify: `_data/navigation.yml` (add `bar` and `sections`; remove `primary`, `secondary`)
- Create: `_includes/aim42/current-section.html`
- Modify: `_includes/aim42/site-header.html` (whole file)
- Modify: `_sass/_header.scss`
- Add: `images/logo/AIM42_white.svg`, `images/logo/AIM42_black.svg`, `images/logo/AIM42_white.png`, `images/logo/AIM42_black.png` (already in the working tree, untracked)
- Test: `tests/site_test.rb`

**Interfaces:**
- Produces: `site.data.navigation.bar` (Array of section keys) and `site.data.navigation.sections` (Hash key to `{title, url, lede?, pages: [{title, url, blurb?}]}`); `{% include aim42/current-section.html %}` assigns `current_section` (String key or `""`) and `current_is_section_page` (Boolean). Test constants `NAV` and `BAR`.

- [ ] **Step 1: Write the failing tests**

In `tests/site_test.rb`, below the `HOME = …` line add:

```ruby
  NAV = YAML.safe_load(File.read(File.join(ROOT, "_data", "navigation.yml"))).freeze
  BAR = ["Get started", "Patterns", "Learn", "About"].freeze
```

Add these tests after `test_menu_toggle_label_is_state_neutral`:

```ruby
  def test_navigation_urls_resolve
    NAV["sections"].each do |key, section|
      ([section["url"]] + section["pages"].map { |p| p["url"] }).each do |url|
        assert site_file(url), "navigation #{key}: #{url} is not built"
      end
    end
  end

  def test_navigation_lists_each_url_once
    urls = NAV["sections"].values.flat_map { |s| [s["url"]] + s["pages"].map { |p| p["url"] } }
    assert_equal urls.uniq, urls
  end

  def test_header_bar_lists_the_sections_and_marks_the_current_one
    {
      "/patterns/atam/" => ["Patterns", "true"],
      "/patterns/" => ["Patterns", "page"],
      "/glossary/" => ["Patterns", "true"],
      "/reference/team/" => ["About", "true"]
    }.each do |url, expected|
      links = page(url).css("nav.site-primary-nav a")
      assert_equal BAR, links.map { |a| a.text.strip }, "#{url}: bar"
      assert_equal [expected], links.select { |a| a["aria-current"] }.map { |a| [a.text.strip, a["aria-current"]] }, "#{url}: current section"
    end
  end

  def test_menu_groups_every_section_with_its_pages
    groups = page("/glossary/").css("#site-secondary-nav .site-secondary-nav__group")
    assert_equal NAV["bar"], groups.map { |g| g["data-section"] }
    groups.each do |group|
      section = NAV["sections"][group["data-section"]]
      label = group.at_css("a.site-secondary-nav__label")
      assert_equal [section["title"], section["url"]], [label.text.strip, label["href"]]
      assert_equal section["pages"].map { |p| [p["title"], p["url"]] },
                   group.css("a:not(.site-secondary-nav__label)").map { |a| [a.text.strip, a["href"]] }
    end
  end

  def test_header_shows_the_svg_logo
    logo = page("/glossary/").at_css(".site-brand img")
    assert_equal ["/images/logo/AIM42_white.svg", "aim42"], [logo["src"], logo["alt"]]
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `make site-test`
Expected: FAIL. `test_navigation_urls_resolve` and `test_navigation_lists_each_url_once` error with "undefined method `each' for nil" (no `sections` yet); the header, menu and logo tests fail on labels and src.

- [ ] **Step 3: Implement**

In `_data/navigation.yml`, delete the block from the comment `# Header of the aim42 (Q42-style) layouts …` to the end of the file (the `primary:` and `secondary:` lists), and append:

```yaml
# Header bar, hamburger menu, section pages and page eyebrows.
# Spec: docs/superpowers/specs/2026-10-07-phase3a-navigation-pages-design.md
# A page belongs to the section that lists its URL (_includes/aim42/current-section.html).
bar:
  - getstarted
  - patterns
  - learn
  - about

sections:
  getstarted:
    title: Get started
    url: /getstarted
    lede: How to apply aim42 to your own system, from the first principles to worked examples.
    pages:
      - title: Principles
        url: /principles
        blurb: The terms aim42 uses and the few rules it is built on.
      - title: Using aim42
        url: /using
        blurb: A first improvement in a few steps, from brainstorming to root cause analysis.
      - title: Examples
        url: /examples
        blurb: Systems from different industries where contributors applied aim42.
      - title: Whitepaper (PDF)
        url: /assets/downloads/AIM42-Whitepaper-v2.0.pdf
        blurb: A short summary of aim42 to read offline or pass on.
  patterns:
    title: Patterns
    url: /patterns/
    pages:
      - title: Analyze
        url: /patterns/analyze/
      - title: Evaluate
        url: /patterns/evaluate/
      - title: Improve
        url: /patterns/improve/
      - title: Cross-cutting
        url: /patterns/crosscutting/
      - title: Glossary
        url: /glossary/
      - title: Introduction
        url: /reference/introduction/
      - title: Domain model
        url: /reference/domain-model/
      - title: Bibliography
        url: /reference/bibliography/
      - title: Organizational scenarios
        url: /reference/organizational-scenarios/
  learn:
    title: Learn
    url: /learn
    lede: Articles, talks, training and answers to common questions about aim42.
    pages:
      - title: Publications
        url: /publications
        blurb: Articles, papers and talks about aim42, in English and German.
      - title: Training
        url: /training
        blurb: The IMPROVE training towards the iSAQB CPSA-Advanced certificate, held in German.
      - title: FAQ
        url: /faq
        blurb: Short answers about aim42, refactoring and the people behind it.
  about:
    title: About
    url: /about
    lede: Who is behind aim42, how to reach us and how to take part.
    pages:
      - title: Contact
        url: /contact
        blurb: Email, GitHub and LinkedIn.
      - title: Contribute
        url: /contribute
        blurb: Ways to help, from reporting an issue to sending a pull request.
      - title: Contributing to the reference
        url: /reference/contributing/
        blurb: How to take part in the pattern reference.
      - title: How to add a pattern
        url: /reference/how-to-add-a-pattern/
        blurb: Every pattern is one Markdown file; this is how to write one.
      - title: Team
        url: /reference/team/
        blurb: The people who built aim42 and what they worked on.
      - title: License
        url: /license
        blurb: aim42 is free to use under CC BY-SA 4.0.
      - title: Imprint
        url: /imprint/
        blurb: Imprint and privacy statement.
```

Create `_includes/aim42/current-section.html`:

```html
{% comment %}
  current-section — sets `current_section` (a key of
  site.data.navigation.sections, or "") and `current_is_section_page` for
  the page being rendered. A page belongs to the section whose url or
  pages[].url equals page.url; pattern pages belong to `patterns`.
{% endcomment %}
{% assign current_section = "" %}
{% assign current_is_section_page = false %}
{% if page.collection == "patterns" %}
  {% assign current_section = "patterns" %}
{% else %}
  {% for entry in site.data.navigation.sections %}
    {% if entry[1].url == page.url %}
      {% assign current_section = entry[0] %}
      {% assign current_is_section_page = true %}
    {% endif %}
    {% for item in entry[1].pages %}
      {% if item.url == page.url %}{% assign current_section = entry[0] %}{% endif %}
    {% endfor %}
  {% endfor %}
{% endif %}
```

Replace `_includes/aim42/site-header.html` completely with:

```html
{% include aim42/current-section.html %}
{% assign nav = site.data.navigation %}
<header class="site-header">
  <div class="site-header__inner">
    <a class="site-brand" href="{{ '/' | relative_url }}" aria-label="aim42 home">
      <img class="site-brand__logo" src="{{ '/images/logo/AIM42_white.svg' | relative_url }}" alt="aim42" width="418" height="126" />
      <span class="site-brand__name">architecture improvement method</span>
    </a>

    <div class="site-header__right">
      <nav class="site-primary-nav" aria-label="Primary navigation">
        {% for key in nav.bar %}
          {% assign section = nav.sections[key] %}
          {% if key == current_section %}
          <a class="site-primary-nav__link is-active" href="{{ section.url | relative_url }}" aria-current="{% if current_is_section_page %}page{% else %}true{% endif %}">{{ section.title }}</a>
          {% else %}
          <a class="site-primary-nav__link" href="{{ section.url | relative_url }}">{{ section.title }}</a>
          {% endif %}
        {% endfor %}
      </nav>

      <div class="site-actions">
        <button class="site-menu-toggle nav-toggle" type="button" data-target="#site-secondary-nav" aria-controls="site-secondary-nav" aria-expanded="false" aria-label="Navigation menu">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </button>
      </div>
    </div>
  </div>

  <nav id="site-secondary-nav" class="site-secondary-nav" aria-label="Site menu">
    <div class="site-secondary-nav__inner">
      {% for key in nav.bar %}
        {% assign section = nav.sections[key] %}
      <div class="site-secondary-nav__group" data-section="{{ key }}">
        <a class="site-secondary-nav__label" href="{{ section.url | relative_url }}">{{ section.title }}</a>
        {% for item in section.pages %}
        <a href="{{ item.url | relative_url }}">{{ item.title }}</a>
        {% endfor %}
      </div>
      {% endfor %}
    </div>
  </nav>
</header>
```

In `_sass/_header.scss`:

1. In `.site-brand__logo`, replace `width: 5.9rem;` with `width: auto;`.
2. Replace the whole `.site-actions { … }` rule with:
   ```scss
   .site-actions {
     align-items: center;
     display: flex;
     flex: 0 0 auto;
     gap: 0.45rem;
   }
   ```
3. Replace the rules `.site-secondary-nav__inner { … }`, `.site-secondary-nav__group { … }`, `.site-secondary-nav__primary { … }` and `.site-secondary-nav__label { … }` with:
   ```scss
   .site-secondary-nav__inner {
     display: grid;
     gap: 1.3rem;
     grid-template-columns: repeat(4, minmax(0, 1fr));
     margin: 0 auto;
     max-width: $site-max-width;
     padding: 0.75rem 2rem 0.85rem;
   }

   .site-secondary-nav__group {
     align-items: flex-start;
     display: flex;
     flex-direction: column;
     gap: 0.1rem;
   }

   // The group heading is a link to the section page.
   .site-secondary-nav a.site-secondary-nav__label {
     color: var(--brand-cream-74); // cream-48 measured 3.85:1 at 0.75rem; fails AA
     font-size: $text-xs;
     font-weight: 700;
     letter-spacing: 0.06em;
   }
   ```
4. Replace the whole `@media screen and (max-width: $nav-collapse-width) { … }` block with:
   ```scss
   @media screen and (max-width: $nav-compact-width) {
     .site-primary-nav {
       display: none;
     }

     .site-secondary-nav__inner {
       grid-template-columns: repeat(2, minmax(0, 1fr));
     }
   }
   ```
5. In the `@media screen and (max-width: $nav-narrow-width)` block, replace the `.site-secondary-nav__inner { align-items: …; flex-direction: column; gap: 0.75rem; }` rule with:
   ```scss
   .site-secondary-nav__inner {
     grid-template-columns: minmax(0, 1fr);
   }
   ```
   and in the same block replace the `.site-brand { … }` rule with:
   ```scss
   .site-brand {
     margin-right: 0;
     min-width: 0;
   }
   ```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green, including the five new tests.

- [ ] **Step 5: Commit**

```bash
git add _data/navigation.yml _includes/aim42/current-section.html _includes/aim42/site-header.html _sass/_header.scss images/logo tests/site_test.rb
git commit -m "Navigation from one data file: four sections, menu groups, SVG logo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Section layout, eyebrows from the navigation, section pages

**Files:**
- Create: `_layouts/aim42-section.html`
- Create: `_sass/components/_section-cards.scss`
- Modify: `assets/css/aim42.scss` (import)
- Modify: `_layouts/aim42-page.html` (whole file)
- Modify: `_pages/getstarted.md`, `_pages/learn.md`, `_pages/about.md`
- Test: `tests/site_test.rb`

**Interfaces:**
- Consumes: `NAV`, `BAR`, `current-section.html` from Task 1.
- Produces: layout `aim42-section`; `aim42-page` shows the section eyebrow for every page listed in a section unless the page sets `eyebrow_label`. Section card markup: `ul.phase-list.section-cards > li.phase-card > h3 > a` plus `p` blurb.

- [ ] **Step 1: Write the failing tests**

Add to `tests/site_test.rb` after `test_header_shows_the_svg_logo`:

```ruby
  def test_section_pages_show_a_card_per_page
    %w[getstarted learn about].each do |key|
      section = NAV["sections"][key]
      doc = page(section["url"])
      assert_equal section["title"], doc.at_css("h1.section-hero__title").text.strip, "#{key}: title"
      assert_equal section["lede"], doc.at_css(".section-hero__lede").text.strip, "#{key}: lede"
      cards = doc.css(".section-cards .phase-card")
      assert_equal section["pages"].map { |p| [p["title"], p["url"], p["blurb"]] },
                   cards.map { |c| [c.at_css("h3 a").text.strip, c.at_css("h3 a")["href"], c.at_css("p").text.strip] }, "#{key}: cards"
      assert_equal 1, doc.css("h1").size, "#{key}: exactly one h1"
    end
  end

  def test_pages_show_their_section_as_eyebrow
    {
      "/reference/team/" => ["About", "/about"],
      "/glossary/" => ["Patterns", "/patterns/"],
      "/patterns/analyze/" => ["Phase", "/patterns/"]
    }.each do |url, expected|
      link = page(url).at_css(".section-hero__eyebrow a")
      assert_equal expected, [link&.text&.strip, link&.[]("href")], "#{url}: eyebrow"
    end
  end
```

In `test_header_bar_lists_the_sections_and_marks_the_current_one`, add two entries to the Hash:

```ruby
      "/about" => ["About", "page"],
      "/getstarted" => ["Get started", "page"],
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `make site-test`
Expected: FAIL. The section page test fails on `h1.section-hero__title` (nil), the eyebrow test on `/reference/team/` and `/glossary/` (no eyebrow), the header test on `/about` and `/getstarted` (old theme header, no `nav.site-primary-nav`).

- [ ] **Step 3: Implement**

Replace `_layouts/aim42-page.html` completely with:

```html
---
layout: aim42-base
---
{% comment %}
  The eyebrow names the page's section (from _data/navigation.yml) and links
  to the section page. A page may override it with eyebrow_label/eyebrow_href
  (the phase pages do).
{% endcomment %}
{% include aim42/current-section.html %}
{% assign eyebrow_label = page.eyebrow_label %}
{% assign eyebrow_href = page.eyebrow_href %}
{% unless page.eyebrow_label %}
  {% if current_section != "" and current_is_section_page == false %}
    {% assign eyebrow_label = site.data.navigation.sections[current_section].title %}
    {% assign eyebrow_href = site.data.navigation.sections[current_section].url %}
  {% endif %}
{% endunless %}
<div class="article-wrapper">
  <article>
    {% include aim42/section-hero.html
      section=page.section
      title=page.title
      eyebrow_label=eyebrow_label
      eyebrow_href=eyebrow_href
      lede=page.lede
      meta=page.meta %}
    <section class="post-content">
      {{ content }}
    </section>
  </article>
</div>
```

Create `_layouts/aim42-section.html`:

```html
---
layout: aim42-base
---
{% comment %}
  Section page (Get started, Learn, About): hero from the section's title
  and lede in _data/navigation.yml, the page's own text, then one card per
  page of the section.
{% endcomment %}
{% include aim42/current-section.html %}
{% assign section = site.data.navigation.sections[current_section] %}
<div class="article-wrapper">
  <article>
    {% include aim42/section-hero.html
      section="reference"
      title=section.title
      lede=section.lede %}
    <section class="post-content">
      {{ content }}
    </section>
    <section class="section-cards-section" aria-labelledby="in-this-section">
      <h2 id="in-this-section" class="section-heading">In this section</h2>
      <ul class="phase-list section-cards">
        {% for item in section.pages %}
        <li class="phase-card">
          <h3><a href="{{ item.url | relative_url }}">{{ item.title }}</a></h3>
          <p>{{ item.blurb }}</p>
        </li>
        {% endfor %}
      </ul>
    </section>
  </article>
</div>
```

Create `_sass/components/_section-cards.scss`:

```scss
// Cards on the section pages (_layouts/aim42-section.html). They reuse
// .phase-list / .phase-card from pages/_patterns.scss; the generic
// `.site-content ul` prose rules (75ch, indent) do not apply to them.
.site-content .section-cards {
  max-width: none;
  padding-left: 0;
}

.section-cards h3 {
  font-size: $text-xl;
  margin: 0 0 0.3rem;
}

.section-cards-section {
  margin-top: 2.5rem;
}
```

In `assets/css/aim42.scss`, add after `@import "components/_section-hero";`:

```scss
@import "components/_section-cards";
```

`_pages/getstarted.md`: replace the front matter with

```yaml
---
title: Get started
layout: aim42-section
permalink: /getstarted
---
```

and in the body replace `# Elevator Pitch` with `## Elevator Pitch` and `collects over 90 established practices` with `collects {{ site.patterns | size }} established practices`.

`_pages/learn.md`: replace the front matter with

```yaml
---
title: Learn
layout: aim42-section
permalink: /learn
---
```

`_pages/about.md`: replace the front matter with

```yaml
---
title: About
layout: aim42-section
permalink: /about
---
```

and in the body:
- replace `# aim42` (the first heading) with `## aim42`;
- delete the heading `### aim42 Method Reference` and the four badge lines below it (the ones pointing to `aim42/aim42`), ruling N6;
- in "Found a bug?", replace `https://github.com/aim42/aim42/pulls` with `https://github.com/aim42/aim42.org-site/pulls` and `https://github.com/aim42/aim42/issues` with `https://github.com/aim42/aim42.org-site/issues`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add _layouts/aim42-section.html _layouts/aim42-page.html _sass/components/_section-cards.scss assets/css/aim42.scss _pages/getstarted.md _pages/learn.md _pages/about.md tests/site_test.rb
git commit -m "Section pages for Get started, Learn and About; section eyebrows

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Move the Get started and Learn pages

**Files:**
- Modify: `_pages/principles.md`, `_pages/using.md`, `_pages/examples.md`, `_pages/publications.md`, `_pages/training.md`, `_pages/faq.md`
- Test: `tests/site_test.rb`

**Interfaces:**
- Consumes: `aim42-page` eyebrow behaviour (Task 2).
- Produces: test constant `MIGRATED` (Array of URLs), extended in Task 4.

- [ ] **Step 1: Write the failing test**

Add to `tests/site_test.rb` (constant next to `BAR`, test after `test_pages_show_their_section_as_eyebrow`):

```ruby
  MIGRATED = %w[/principles /using /examples /publications /training /faq].freeze
```

```ruby
  OLD_THEME_MARKUP = ".page__hero, .page__hero--overlay, .masthead, .sidebar, .page__content, .feature__wrapper, .greedy-nav, i.fa, i.fab".freeze

  def test_migrated_pages_use_the_aim42_layout
    MIGRATED.each do |url|
      doc = page(url)
      assert doc.at_css("header.site-header"), "#{url}: aim42 header missing"
      assert_equal 1, doc.css("h1").size, "#{url}: exactly one h1"
      assert doc.at_css(".section-hero__eyebrow a"), "#{url}: section eyebrow missing"
      assert_nil doc.at_css(OLD_THEME_MARKUP), "#{url}: old theme markup"
    end
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `make site-test`
Expected: FAIL with "/principles: aim42 header missing".

- [ ] **Step 3: Implement**

Front matter for each page (replace the whole block between the `---` lines):

| File | New front matter |
|---|---|
| `_pages/principles.md` | `title: aim42 Principles` / `layout: aim42-page` / `permalink: /principles` |
| `_pages/using.md` | `title: Using aim42` / `layout: aim42-page` / `permalink: /using` |
| `_pages/examples.md` | `title: "Examples"` / `layout: aim42-page` / `permalink: /examples` |
| `_pages/publications.md` | `title: "Publications"` / `layout: aim42-page` / `permalink: /publications` |
| `_pages/training.md` | `title: "Training"` / `layout: aim42-page` / `permalink: /training` |
| `_pages/faq.md` | `title: "FAQ"` / `layout: aim42-page` / `permalink: /faq` |

(one key per line; the old `header:`, `sidebar:` and `tweets:` keys are dropped.)

Body changes:

- `using.md`, `publications.md`, `faq.md`: replace the line `{% include toc %}` with the two lines
  ```markdown
  * Table of contents
  {:toc}
  ```
- `training.md`, `faq.md`: demote content H1s (ruling N3):
  `perl -pi -e 's/^# /## /' _pages/training.md _pages/faq.md`
- `publications.md`: delete the final section, from the line `## Tweets` to the end of the file (the heading and `{% include feature_row id="tweets" %}`).
- `faq.md`: in "Where's the code?", replace `[Github repository](https://github.com/aim42/aim42)` with `[GitHub repository](https://github.com/aim42/aim42.org-site)`. (The rest of that answer is issue #53.)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add _pages/principles.md _pages/using.md _pages/examples.md _pages/publications.md _pages/training.md _pages/faq.md tests/site_test.rb
git commit -m "Move the Get started and Learn pages onto the aim42 layout

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Move the About pages and the 404 page; contact and Twitter fixes

**Files:**
- Modify: `_pages/contact.md`, `_pages/contribute.md`, `_pages/license.md`, `_pages/imprint.md`, `404.html`, `_pages/reference/contributing.md`, `_pages/reference/how-to-add-a-pattern.md` (lede only)
- Test: `tests/site_test.rb`

**Interfaces:**
- Consumes: `MIGRATED`, `OLD_THEME_MARKUP` (Task 3), `NAV` (Task 1).

- [ ] **Step 1: Write the failing tests**

Change the `MIGRATED` constant to:

```ruby
  MIGRATED = %w[/principles /using /examples /publications /training /faq /contact /contribute /license /imprint/].freeze
```

Add after `test_migrated_pages_use_the_aim42_layout`:

```ruby
  def test_not_found_page_uses_the_aim42_layout
    doc = page("/404.html")
    assert doc.at_css("header.site-header"), "404: aim42 header missing"
    assert_equal 1, doc.css("h1").size
    assert_nil doc.at_css(OLD_THEME_MARKUP)
  end

  def test_contact_lists_email_github_and_linkedin
    hrefs = page("/contact").css(".post-content a").map { |a| a["href"] }
    assert_includes hrefs, "https://www.linkedin.com/in/gernotstarke/"
    assert_includes hrefs, "https://github.com/aim42"
    assert hrefs.any? { |h| h.start_with?("xmxaxixlxtxo:") }, "obfuscated email link missing"
  end

  def test_no_page_links_to_twitter_or_xing
    Dir[File.join(SITE_DIR, "**", "*.html")].each do |file|
      hrefs = Nokogiri::HTML(File.read(file)).css("a[href]").map { |a| a["href"] }
      bad = hrefs.grep(%r{\Ahttps?://(www\.)?(twitter\.com|x\.com|xing\.com)/})
      assert_empty bad, "#{file.delete_prefix(SITE_DIR)} links to #{bad.join(", ")}"
    end
  end

  def test_every_page_is_in_the_navigation
    listed = NAV["sections"].values.flat_map { |s| [s["url"]] + s["pages"].map { |p| p["url"] } }
    Dir[File.join(ROOT, "_pages", "**", "*.md")].sort.each do |file|
      next if file.include?("/_pages/patterns/") || %w[home.md search.md].include?(File.basename(file))
      url = VALIDATOR.front_matter(file)["permalink"]
      assert_includes listed, url, "#{file.delete_prefix(ROOT)} (#{url}) is not in _data/navigation.yml"
    end
  end
```

In `test_header_bar_lists_the_sections_and_marks_the_current_one`, add `"/contact" => ["About", "true"],` to the Hash.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `make site-test`
Expected: FAIL: `/contact: aim42 header missing`, the 404 test, the LinkedIn test, and the Twitter test (contact, publications timelines are gone already but contact and reference/contributing still link to twitter.com). `test_every_page_is_in_the_navigation` passes already (every page is listed since Task 1); it guards future pages.

- [ ] **Step 3: Implement**

`_pages/contact.md`: replace the whole file with

```markdown
---
title: "Contact"
layout: aim42-page
permalink: /contact
---

## Questions? Suggestions? We're listening ...

... on various channels:

* <a href="xmxaxixlxtxo:gxsx@gxexrxnxoxtxsxtxaxrxkxex.xdxe" onmouseover="this.href=this.href.replace(/x/g,'');">Email</a>

* [GitHub](https://github.com/aim42)

* [LinkedIn](https://www.linkedin.com/in/gernotstarke/)
```

`_pages/contribute.md`: replace the front matter with `title: "Contribute"` / `layout: aim42-page` / `permalink: /contribute`, and in the body:
- every `https://github.com/aim42/aim42/issues` becomes `https://github.com/aim42/aim42.org-site/issues`; every remaining `https://github.com/aim42/aim42` (link target and the visible URL text) becomes `https://github.com/aim42/aim42.org-site`:
  `perl -pi -e 's{github\.com/aim42/aim42(?![.\w-])}{github.com/aim42/aim42.org-site}g' _pages/contribute.md`
- `or patterns - and send a pull request.` becomes `or patterns, and send a pull request.`
- `the liberal [](https://creativecommons.org/licenses/by-sa/4.0/) license` becomes `the liberal [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) license`

`_pages/license.md`: replace the front matter with `title: "License"` / `layout: aim42-page` / `permalink: /license`; demote H1s: `perl -pi -e 's/^# /## /' _pages/license.md`.

`_pages/imprint.md`: replace the front matter with `layout: aim42-page` / `title: Imprint & Privacy` / `permalink: /imprint/`; in the body delete `<i class="fa fa-fw fa-envelope"></i>`.

`404.html`: replace the whole file with

```html
---
layout: aim42-page
title: Page not found
permalink: /404.html
---

<p>... you found a broken link!</p>

<p><img src="/images/ugly-404.png" alt="A broken page" /></p>

<p>Please tell me what you were looking for, so I can fix it
(<a href="xmxaxixlxtxo:xgxsx@xgxexrxnxoxtxsxtxaxrxkxex.xdxex" onmouseover="this.href=this.href.replace(/x/g,'');">Email</a>).</p>
```

`_pages/reference/contributing.md`: delete the two lines `Twitter` and `: [@arc\_improve42](https://twitter.com/arc_improve42)` and the blank line after them; replace `https://github.com/aim42/aim42/issues` with `https://github.com/aim42/aim42.org-site/issues`.

`_pages/reference/how-to-add-a-pattern.md`: in the front matter, `lede: Every pattern is one Markdown file — edit it on GitHub or locally.` becomes `lede: Every pattern is one Markdown file; edit it on GitHub or locally.`

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green.

- [ ] **Step 5: Commit**

```bash
git add _pages/contact.md _pages/contribute.md _pages/license.md _pages/imprint.md 404.html _pages/reference/contributing.md _pages/reference/how-to-add-a-pattern.md tests/site_test.rb
git commit -m "Move the About pages and 404 onto the aim42 layout

Contact drops Twitter and Xing and adds LinkedIn; Twitter links go from
the reference contributing page; aim42/aim42 links point to this site's
repository.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Remove Minimal Mistakes

**Files:**
- Modify: `Gemfile`, `Gemfile.lock` (regenerated), `_config.yml` (whole file), `_data/navigation.yml` (old keys), `README.md`, `tests/site_test.rb`
- Delete: `_includes/masthead.html`, `_includes/footer.html`, `_data/ui-text.yml`, `assets/css/main.scss`, `assets/css/footer.css`, `assets/js/_main.js`, `assets/js/main.min.js`, `assets/js/mod_outer_links.js`, `assets/js/plugins/`, `assets/js/vendor/`, `assets/js/lunr/`, `images/splash/`, `images/aim42-splash.png`, `images/aim42-splash-slim.png`, `images/aim42-site-logo.png`, `images/aim42-process-2017.png`, `images/analyze-phase.png`, `images/evaluate-phase.png`, `images/improve-phase.png`, `images/crosscutting-phase.png`, `images/analyze-splash-4-website.png`, `images/evaluate-splash-4-website.png`, `images/improve-splash-4-website.png`, `images/crosscutting-splash-4-website.png`

**Interfaces:**
- Consumes: `OLD_THEME_MARKUP` (Task 3).
- Produces: `PAGES` covers every built HTML page (the search plan relies on this).

- [ ] **Step 1: Write the failing tests**

In `tests/site_test.rb`:

1. Replace the `PAGES = …` line with:
   ```ruby
     # Every built page; the link and image checks run over all of them.
     PAGES = Dir[File.join(SITE_DIR, "**", "*.html")].map { |f| "/" + f.delete_prefix("#{SITE_DIR}/").sub(%r{(\A|/)index\.html\z}, "\\1") }.sort.freeze
   ```
2. In `test_home_page_uses_the_aim42_layout`, change the message `"Minimal Mistakes markup on /"` to `"old theme markup on /"`.
3. Add after `test_every_page_is_in_the_navigation`:

```ruby
  # Spec §5: nothing outside docs/superpowers/ mentions the old theme.
  OLD_THEME = /minimal[-_ ]?mistakes|mmistakes|mademistakes/i

  def test_old_theme_is_not_mentioned_in_the_repository
    skip_dirs = %w[.git .jekyll-cache .sass-cache .superpowers .bundle .idea _site vendor node_modules docs/superpowers]
    files = Dir.glob("**/*", File::FNM_DOTMATCH, base: ROOT).reject do |f|
      skip_dirs.any? { |d| f == d || f.start_with?("#{d}/") } ||
        f.split("/").include?("node_modules") || # tests/e2e/node_modules (search plan)
        File.directory?(File.join(ROOT, f))
    end
    hits = (files - ["tests/site_test.rb"]).select { |f| File.binread(File.join(ROOT, f)).match?(OLD_THEME) }
    assert_empty hits, "files mentioning the old theme"
  end

  def test_no_built_page_has_old_theme_markup
    PAGES.each do |url|
      doc = page(url)
      assert_nil doc.at_css(OLD_THEME_MARKUP), "#{url}: old theme markup"
      assert doc.at_css("header.site-header"), "#{url}: aim42 header missing"
    end
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `make site-test`
Expected: FAIL: `test_old_theme_is_not_mentioned_in_the_repository` lists `Gemfile`, `Gemfile.lock`, `README.md`, `_config.yml`, `assets/css/main.scss`, `assets/js/main.min.js`, `_includes/masthead.html` (at least). `test_no_built_page_has_old_theme_markup` passes if Tasks 2 to 4 moved every page; if it names a page, that page was missed and is moved now like the others.

- [ ] **Step 3: Implement**

Replace `Gemfile` completely with:

```ruby
source "https://rubygems.org"

gem "jekyll", "4.3.1"
# The contrast and CSS tests rely on libsass passing color-mix() through.
gem "jekyll-sass-converter", "~> 2.2"

# Jekyll 4.3.1 breaks with logger >= 1.6 (bundled with Ruby 3.3)
gem "logger", "< 1.6"
# liquid 4.0.3 calls String#tainted?, removed in Ruby 3.2
gem "liquid", ">= 4.0.4"

group :jekyll_plugins do
  gem "jekyll-sitemap"
  gem "webrick"
end

group :test do
  gem "minitest"
  gem "nokogiri"
end
```

Run: `make lock && make build`
Expected: `Gemfile.lock` no longer lists `minimal-mistakes-jekyll`, `jekyll-gist`, `jekyll-feed`, `jemoji`, `jekyll-include-cache`, `jekyll-paginate`; `jekyll (4.3.1)` and `jekyll-sass-converter (2.2.0)` stay. Check with `grep -n "minimal\|jemoji\|jekyll-feed\|jekyll (\|jekyll-sass-converter (" Gemfile.lock`.

Replace `_config.yml` completely with:

```yaml
# aim42.org site settings. The site uses its own layouts in _layouts/ (no theme gem).

title: aim42
description: "Architecture Improvement Method: systematic modernization and evolution of IT systems."
url: "https://aim42.org"
baseurl: ""
repository: "aim42/aim42.org-site" # used by the "Edit this pattern on GitHub" links

include:
  - .htaccess
  - _pages
exclude:
  - vendor
  - .asset-cache
  - .bundle
  - .sass-cache
  - Gemfile
  - Gemfile.lock
  - LICENSE
  - node_modules
  - package.json
  - package-lock.json
  - README.md
  - tmp
  - /zz-resources
  - Makefile
  - docker-compose.yml
  - _docker
  - tools
  - tests
  - docs
keep_files:
  - .git

encoding: "utf-8"
markdown_ext: "markdown,mkdown,mkdn,mkd,md"
markdown: kramdown
highlighter: rouge
kramdown:
  input: GFM
  hard_wrap: false
  auto_ids: true
  footnote_nr: 1
  entity_output: as_char
  toc_levels: 1..6
  smart_quotes: lsquo,rsquo,ldquo,rdquo
  enable_coderay: false
sass:
  sass_dir: _sass
  style: compressed
permalink: /:categories/:title/

plugins:
  - jekyll-sitemap

collections:
  patterns:
    output: true
    permalink: /patterns/:name/
    sort_by: title

defaults:
  - scope:
      path: ""
      type: patterns
    values:
      layout: pattern
```

In `_data/navigation.yml`, delete the old lists `main`, `getstarted`, `learn`, `about` and `examples` (everything above the comment `# Header bar, hamburger menu, section pages and page eyebrows.`), ruling N2.

Delete the files and directories listed under **Files** with `git rm -r`. Before deleting each image, confirm it has no references: `git grep -n "<image file name>" -- ':!docs'` must print nothing (apart from the file list in this plan).

In `README.md`, delete the block from `##### Michael Rose, creator of the Minimal-Mistakes Jekyll Theme` up to (not including) `#### Icons + Images:`, and delete everything from the heading `### [Minimal Mistakes Jekyll Theme](https://mmistakes.github.io/minimal-mistakes/)` to the end of the file.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green: `patterns OK`, unit tests pass, site tests pass including the two new scans and the link and image checks over every built page.

- [ ] **Step 5: Commit**

```bash
git add -A Gemfile Gemfile.lock _config.yml _data/navigation.yml README.md tests/site_test.rb _includes assets images
git status --short   # only the intended deletions and edits
git commit -m "Remove Minimal Mistakes

The theme gem, its settings, includes, stylesheets, scripts and images
go; Jekyll and the Sass converter are pinned explicitly. Tests guard that
nothing mentions or renders the old theme.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Visual and keyboard check, copy review issue, push (controller)

Done by the controller (needs the browser image and GitHub).

**Files:** none (defects go back through a fix round of Tasks 1 to 5).

- [ ] **Step 1: Full check**

Run: `make check`
Expected: all green.

- [ ] **Step 2: Visual and keyboard check**

With `make dev` running, run Playwright in Docker (`mcr.microsoft.com/playwright:v1.58.2-jammy`, as in the home page plan) against `http://host.docker.internal:4242/` at 375px and 1280px:
- screenshots of `/about`, `/contact`, `/faq`, `/glossary/` and the open menu;
- the header fits in one row at 375px (logo and hamburger only) and at 1280px (logo, four sections, hamburger);
- no horizontal scroll on any of these pages;
- keyboard: Tab to the menu toggle, Enter opens the menu, Tab reaches every menu link, Esc closes it and focus returns to the toggle.

Any defect: fix round on the owning task, then `make check`.

- [ ] **Step 3: Open the copy review issue**

```bash
gh issue create --repo aim42/aim42.org-site --label "help wanted" \
  --title "Review migrated pages" \
  --body-file <file listing: the section ledes and card blurbs from _data/navigation.yml; the overlap of /contribute and /reference/contributing/; the Get started overview text that describes the old diagram; any other text found outdated during Tasks 2 to 4>
```

Expected: an issue URL.

- [ ] **Step 4: Push**

```bash
git push origin merge-method-reference
```

Expected: push succeeds; the GitHub Actions run on the branch is green.
