# Phase 3a Home Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Minimal Mistakes splash home page with a method-first aim42 home page: hero with headline, lede and a linked SVG cycle, four phase cards with three examples each, Get started, Free and open.

**Architecture:** A new `home` layout on `aim42-base` renders everything from the front matter of `_pages/home.md` plus data that already exists (`_data/phases.yml`, `site.patterns`). Two includes keep the layout small: `aim42/phase-cards.html` and `aim42/cycle.html` (inline SVG). `tools/validate.rb` checks the home page's slug references in every build.

**Tech Stack:** Jekyll 4.3.1, Liquid, SCSS (libsass via jekyll-sass-converter), Minitest + Nokogiri, Docker via `make`.

**Spec:** `docs/superpowers/specs/2026-10-07-phase3a-homepage-design.md` (parent: `docs/superpowers/specs/2026-10-07-method-reference-merge-design.md`)

## Global Constraints

- Builds and tests run in Docker via `make` (`make validate`, `make unit`, `make site-test`, `make check`); never Ruby on the host.
- Commit on branch `merge-method-reference` only; push only that branch, never master, never force. No PR, no merge.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (subagent commits may name their own model).
- Copy rule: no dashes as sentence punctuation in any visible text; commas or semicolons instead.
- Headline text exactly: `Improve software systems, systematically.`
- Lede text exactly: `aim42 is a free, open method for architects and developers: analyze what hurts, evaluate what it costs, improve what's worth it, step by step.`
- Breakpoints: `$home-stack-width` (860px) and `$home-edge-width` (560px), both already in `_sass/base/_variables.scss`.
- Links and buttons on the home page at least 44px tall; no home-specific JavaScript and no animation (the base layout's header script stays).
- Out of scope: logo, "42" dropdown, other pages, navigation changes, deploy, redirects.

## Rulings made while planning

- **P1:** Phase card descriptions come from `_data/phases.yml` (`title`, `url`, `blurb`), not from the phase pages' `lede`. The `/patterns/` index already renders these blurbs, and today each blurb is identical to its phase page's `lede`. Spec §3 is amended in the same commit as this plan. Cost if wrong: none visible; the texts are identical.
- **P2:** Patterns are looked up by URL (`site.patterns | where: "url", "/patterns/<slug>/"`), because Jekyll 4 does not set `slug` on collection documents without a date in the file name.
- **P3:** SVG elements are written with explicit closing tags (`<path ...></path>`), not self-closing, so Nokogiri's HTML parser in the site tests reads the same tree as browsers.

## Review Focus

1. A pattern used as a home example is renamed, deleted or moved to another phase later: the build must fail with a message naming `_pages/home.md` and the slug (Task 1, `test_home_example_*`).
2. A phase is added to `_data/phases.yml` without a home example list or cycle line: the build must fail, not render an empty card (Task 1, `test_home_needs_examples_and_cycle_line_for_every_phase`).
3. Phone width (375px): cycle labels must not be clipped and phase names in the cycle stay at least 15px (Task 4, manual check; Task 3 sizes the viewBox to include every label).
4. Keyboard only: Tab reaches the two hero buttons, then Analyze, Evaluate, Improve, Cross-cutting in the cycle, each with a visible focus outline (Task 3 test pins DOM order; Task 4 manual check).
5. Every link on `/` resolves, including `#how-it-works` (Task 2 adds `/` to the site test's link and image checks).

---

### Task 1: Validate the home page's pattern references

**Files:**
- Modify: `tools/validate.rb`
- Test: `tests/validate_test.rb`

**Interfaces:**
- Consumes: existing `Aim42::Validator#run`, `#front_matter`, `#slug`.
- Produces: `Aim42::Validator#home_errors(phases, phase_of) -> Array<String>`, called from `#run`; every message starts with `_pages/home.md: `. Only runs when `_pages/home.md` exists and has `layout: home`.

- [ ] **Step 1: Write the failing tests**

Append to `tests/validate_test.rb`, inside `class ValidatorTest` (before its final `end`):

```ruby
  HOME_OK = <<~YAML
    layout: home
    headline: Improve software systems, systematically.
    lede: A method.
    cycle:
      analyze: find the issues
      improve: fix step by step
    examples:
      analyze: [a1, a2, a3]
      improve: [i1, i2, i3]
    get_started:
      - text: Collect issues.
        patterns: [a1]
  YAML

  def home(front_matter)
    FileUtils.mkdir_p(File.join(@root, "_pages"))
    File.write(File.join(@root, "_pages", "home.md"), "---\n#{front_matter}---\n\nBody.\n")
  end

  def home_patterns
    %w[a1 a2 a3].each { |s| pattern(s, "title: #{s.upcase}\nphase: analyze\nintent: x\nstatus: complete\n") }
    %w[i1 i2 i3].each { |s| pattern(s, "title: #{s.upcase}\nphase: improve\nintent: x\nstatus: complete\n") }
  end

  def test_valid_home_page_has_no_errors
    home_patterns
    home(HOME_OK)
    assert_empty errors
  end

  def test_home_page_with_another_layout_is_not_checked
    home_patterns
    home("layout: splash\n")
    assert_empty errors
  end

  def test_home_needs_headline_and_lede
    home_patterns
    home(HOME_OK.sub(/^headline:.*\n/, "").sub(/^lede:.*\n/, "lede: \"\"\n"))
    assert_includes errors, "_pages/home.md: missing required key 'headline'"
    assert_includes errors, "_pages/home.md: missing required key 'lede'"
  end

  def test_home_needs_examples_and_cycle_line_for_every_phase
    home_patterns
    home(HOME_OK.sub("  improve: fix step by step\n", "").sub("  improve: [i1, i2, i3]\n", ""))
    assert_includes errors, "_pages/home.md: cycle line for 'improve' is missing"
    assert_includes errors, "_pages/home.md: examples for 'improve' must be a list of three slugs"
  end

  def test_home_example_must_be_three
    home_patterns
    home(HOME_OK.sub("[a1, a2, a3]", "[a1, a2]"))
    assert_includes errors, "_pages/home.md: examples for 'analyze' must be a list of three slugs"
  end

  def test_home_example_must_exist
    home_patterns
    home(HOME_OK.sub("[a1, a2, a3]", "[a1, a2, nope]"))
    assert_includes errors, "_pages/home.md: example 'nope' does not exist in _patterns/"
  end

  def test_home_example_must_belong_to_its_phase
    home_patterns
    home(HOME_OK.sub("[a1, a2, a3]", "[a1, a2, i1]"))
    assert_includes errors, "_pages/home.md: example 'i1' belongs to 'improve', not 'analyze'"
  end

  def test_home_examples_for_unknown_phase
    home_patterns
    home(HOME_OK.sub("examples:\n", "examples:\n  evaluate: [a1, a2, a3]\n"))
    assert_includes errors, "_pages/home.md: examples for unknown phase 'evaluate'"
  end

  def test_home_get_started_is_required
    home_patterns
    home(HOME_OK.sub(/^get_started:.*\z/m, ""))
    assert_includes errors, "_pages/home.md: 'get_started' must be a list of steps"
  end

  def test_home_get_started_step_needs_text_and_existing_patterns
    home_patterns
    home(HOME_OK.sub("  - text: Collect issues.\n    patterns: [a1]\n", "  - text: Collect issues.\n    patterns: [nope]\n  - patterns: [a1]\n  - text: Estimate.\n"))
    assert_includes errors, "_pages/home.md: get_started step 1: 'nope' does not exist in _patterns/"
    assert_includes errors, "_pages/home.md: get_started step 2 needs a 'text'"
    assert_includes errors, "_pages/home.md: get_started step 3 needs a list of patterns"
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `docker compose run --rm --no-deps jekyll bundle exec ruby tests/validate_test.rb -n /home/`
Expected: FAIL. `test_valid_home_page_has_no_errors` and `test_home_page_with_another_layout_is_not_checked` pass already; the other eight fail with "Expected [] to include …".

- [ ] **Step 3: Implement**

In `tools/validate.rb`:

1. Replace the first line of the header comment
   `# Validates the front matter of every file in _patterns/.`
   with
   ```ruby
   # Validates the front matter of every file in _patterns/, and the pattern
   # references on the home page (_pages/home.md with layout: home).
   ```
2. Add the constant below `EXTENSIONS`:
   ```ruby
       HOME = File.join("_pages", "home.md").freeze
   ```
3. In `#run`, next to `titles = …`, add `phase_of = {}`. Directly after the `unless fm.is_a?(Hash) … end` block inside the loop, add:
   ```ruby
           phase_of[slug] = fm["phase"]
   ```
4. In `#run`, just before the final `errors` line (after the duplicate-title check), add:
   ```ruby
         errors.concat(home_errors(phases, phase_of))
   ```
5. Add this method between `#run` and `#front_matter`:

```ruby
    # The home page names patterns by slug (examples per phase, Get started
    # steps). A rename or delete must fail the build like a broken `related`.
    def home_errors(phases, phase_of)
      file = File.join(@root, HOME)
      return [] unless File.file?(file)
      begin
        fm = front_matter(file)
      rescue Psych::Exception => e
        return ["#{HOME}: invalid YAML front matter (#{e.message})"]
      end
      return [] unless fm.is_a?(Hash) && fm["layout"] == "home"

      errors = []
      text = ->(value) { value.is_a?(String) && !value.strip.empty? }
      %w[headline lede].each do |key|
        errors << "#{HOME}: missing required key '#{key}'" unless text.(fm[key])
      end

      cycle = fm["cycle"].is_a?(Hash) ? fm["cycle"] : {}
      phases.each do |phase|
        errors << "#{HOME}: cycle line for '#{phase}' is missing" unless text.(cycle[phase])
      end

      examples = fm["examples"].is_a?(Hash) ? fm["examples"] : {}
      phases.each do |phase|
        list = examples[phase]
        unless list.is_a?(Array) && list.size == 3
          errors << "#{HOME}: examples for '#{phase}' must be a list of three slugs"
          next
        end
        list.each do |slug|
          if !phase_of.key?(slug)
            errors << "#{HOME}: example '#{slug}' does not exist in _patterns/"
          elsif phase_of[slug] != phase
            errors << "#{HOME}: example '#{slug}' belongs to '#{phase_of[slug]}', not '#{phase}'"
          end
        end
      end
      (examples.keys - phases).each { |key| errors << "#{HOME}: examples for unknown phase '#{key}'" }

      steps = fm["get_started"]
      unless steps.is_a?(Array) && !steps.empty?
        return errors << "#{HOME}: 'get_started' must be a list of steps"
      end
      steps.each.with_index(1) do |step, n|
        unless step.is_a?(Hash)
          errors << "#{HOME}: get_started step #{n} must be a mapping"
          next
        end
        errors << "#{HOME}: get_started step #{n} needs a 'text'" unless text.(step["text"])
        if step["patterns"].is_a?(Array) && !step["patterns"].empty?
          (step["patterns"] - phase_of.keys).each do |slug|
            errors << "#{HOME}: get_started step #{n}: '#{slug}' does not exist in _patterns/"
          end
        else
          errors << "#{HOME}: get_started step #{n} needs a list of patterns"
        end
      end
      errors
    end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `docker compose run --rm --no-deps jekyll bundle exec ruby tests/validate_test.rb`
Expected: PASS, 0 failures, 0 errors.

Run: `make validate && make unit`
Expected: `patterns OK` (the current `_pages/home.md` still has `layout: splash`, so it is not checked yet); unit tests all pass.

- [ ] **Step 5: Commit**

```bash
git add tools/validate.rb tests/validate_test.rb
git commit -m "Validate the home page's pattern references

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Home layout, phase cards, Get started, Free and open

**Files:**
- Create: `_layouts/home.html`
- Create: `_includes/aim42/phase-cards.html`
- Create: `_sass/pages/_home.scss`
- Modify: `assets/css/aim42.scss` (import the new partial)
- Replace: `_pages/home.md` (whole file)
- Modify: `tests/site_test.rb` (constants, `PAGES`, replace `test_home_page_still_builds_with_minimal_mistakes`, add home tests)
- Modify: `tests/contrast_test.rb`

**Interfaces:**
- Consumes: `Aim42::Validator#home_errors` (Task 1) runs in the build through `_plugins/validate_patterns.rb`; `_data/phases.yml` keys `title`, `url`, `blurb`; existing `.phase-list` / `.phase-card` styles in `_sass/pages/_patterns.scss`.
- Produces for Task 3: in `_layouts/home.html`, the hero is `<section class="home-hero">` with first child `<div class="home-hero__text">`; Task 3 inserts `{% include aim42/cycle.html %}` directly after that div. `_sass/pages/_home.scss` exists; Task 3 appends to it. `tests/site_test.rb` has constants `HOME` (home front matter Hash) and `PHASE_DATA` (phases.yml Hash).

- [ ] **Step 1: Write the failing tests**

In `tests/site_test.rb`:

1. Below the `PHASES = …` line add:
   ```ruby
     PHASE_DATA = YAML.safe_load(File.read(File.join(ROOT, "_data", "phases.yml"))).freeze
     HOME = VALIDATOR.front_matter(File.join(ROOT, "_pages", "home.md")).freeze
   ```
2. Change the `PAGES = (["/patterns/"] + …` line so the list starts with the home page:
   ```ruby
     PAGES = (["/", "/patterns/"] + REFERENCE + PHASES.map { |p| "/patterns/#{p}/" } + PATTERNS.map { |p| "/patterns/#{p["slug"]}/" }).uniq.freeze
   ```
3. Add a helper next to `by_title`:
   ```ruby
     def pattern_title(slug)
       PATTERNS.find { |p| p["slug"] == slug }&.fetch("title") || flunk("unknown pattern slug #{slug.inspect}")
     end
   ```
4. Replace the whole method `test_home_page_still_builds_with_minimal_mistakes` with:

```ruby
  def test_home_page_uses_the_aim42_layout
    doc = page("/")
    assert_nil doc.at_css(".page__hero, .page__hero--overlay, .feature__wrapper, .masthead"), "Minimal Mistakes markup on /"
    assert doc.at_css("header.site-header"), "aim42 header missing on /"
    assert_equal [HOME["headline"]], doc.css("h1").map { |h| h.text.strip }
    assert_equal ["How it works", "Get started", "Free and open"], doc.css("main h2").map { |h| h.text.strip }
    assert_equal "Architecture Improvement Method | aim42", doc.at_css("title").text.strip
    assert_equal HOME["lede"], doc.at_css("meta[name='description']")["content"]
    assert_equal HOME["lede"], doc.at_css(".home-hero__lede").text.strip
  end

  def test_home_buttons_lead_to_phases_and_patterns
    doc = page("/")
    buttons = doc.css(".home-hero__actions a")
    assert_equal ["#how-it-works", "/patterns/"], buttons.map { |a| a["href"] }
    assert_equal ["How it works", "Browse #{PATTERNS.size} patterns"], buttons.map { |a| a.text.strip }
    assert doc.at_css("h2#how-it-works"), "How it works heading missing"
  end

  def test_home_phase_cards_show_blurb_count_and_examples
    cards = page("/").css(".home-phase-list .phase-card")
    assert_equal PHASES, cards.map { |c| c["data-phase"] }
    cards.each do |card|
      key = card["data-phase"]
      phase = PHASE_DATA[key]
      count = PATTERNS.count { |p| p["phase"] == key }
      assert_equal phase["title"], card.at_css("h3 a").text.strip
      assert_equal phase["url"], card.at_css("h3 a")["href"]
      assert_equal phase["blurb"], card.at_css(".home-phase__blurb").text.strip
      examples = card.css(".home-examples a")
      assert_equal HOME["examples"][key].map { |s| "/patterns/#{s}/" }, examples.map { |a| a["href"] }
      assert_equal HOME["examples"][key].map { |s| pattern_title(s) }, examples.map { |a| a.text.strip }
      assert_equal "All #{count} #{phase["title"].downcase} patterns", card.at_css(".home-phase__all a").text.strip
    end
  end

  def test_home_get_started_and_contribution_links
    doc = page("/")
    steps = doc.css(".home-steps__item")
    assert_equal HOME["get_started"].map { |s| s["text"] }, steps.map { |li| li.at_css(".home-steps__text").text.strip }
    HOME["get_started"].zip(steps).each do |step, li|
      assert_equal step["patterns"].map { |s| "/patterns/#{s}/" }, li.css(".home-steps__links a").map { |a| a["href"] }
    end
    assert doc.at_css(".home-start a[href='/getstarted']"), "link to the getting-started guide missing"
    assert doc.at_css(".home-open a[href='/reference/how-to-add-a-pattern/']"), "Add a pattern link missing"
  end
```

In `tests/contrast_test.rb`, add after `test_phase_text_colors_are_readable_on_paper`:

```ruby
  # The home page shows phase names and links on the white page background too.
  def test_phase_text_colors_are_readable_on_white
    %w[analyze evaluate improve crosscutting].each do |phase|
      ratio = contrast(token("phase-#{phase}-text"), "#ffffff")
      assert ratio >= 4.5, "phase-#{phase}-text on white: #{ratio.round(2)}:1 is below 4.5:1"
    end
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `make site-test`
Expected: FAIL. `HOME` is the old splash front matter, so the four home tests fail (for example "Minimal Mistakes markup on /" and the h1 assertion). Other tests may fail on `/` links too; that is expected until Step 3.

Run: `make unit`
Expected: PASS (the white-background contrast test passes with today's palette; it guards future palette changes).

- [ ] **Step 3: Implement**

Replace `_pages/home.md` completely with:

```markdown
---
title: Architecture Improvement Method
layout: home
permalink: /
# Plain text, one line each. tools/validate.rb checks every slug below.
headline: Improve software systems, systematically.
lede: "aim42 is a free, open method for architects and developers: analyze what hurts, evaluate what it costs, improve what's worth it, step by step."
# The short line under each phase name in the cycle graphic.
cycle:
  analyze: find the issues
  evaluate: value and effort
  improve: fix step by step
  crosscutting: plan and keep on track
# Exactly three pattern slugs (file names in _patterns/) per phase.
examples:
  analyze: [stakeholder-interview, static-code-analysis, root-cause-analysis]
  evaluate: [estimate-issue-cost, estimate-improvement-cost, estimate-in-interval]
  improve: [strangler-approach, anticorruption-layer, introduce-boy-scout-rule]
  crosscutting: [issue-list, improvement-backlog, impact-analysis]
get_started:
  - text: Collect issues.
    patterns: [issue-list, stakeholder-interview]
  - text: Estimate what they cost, and what fixing them would cost.
    patterns: [estimate-issue-cost]
  - text: Improve the most valuable ones first, in small steps.
    patterns: [improvement-backlog]
---

aim42 is free to use and open source, with no vendor or tool lock-in. It is
built from the experience of many contributors from different industries.

Know a practice that's missing? Every pattern is one Markdown file on GitHub.
[Add a pattern](/reference/how-to-add-a-pattern/).
```

Create `_layouts/home.html`:

```html
---
layout: aim42-base
---
{% comment %}
  Home page. Spec: docs/superpowers/specs/2026-10-07-phase3a-homepage-design.md
  All text comes from the front matter of _pages/home.md; the page body is
  the "Free and open" section.
{% endcomment %}
{% assign total = site.patterns | size %}
<div class="home">
  <section class="home-hero">
    <div class="home-hero__text">
      <h1 class="home-hero__title">{{ page.headline | escape }}</h1>
      <p class="home-hero__lede">{{ page.lede }}</p>
      <p class="home-hero__actions">
        <a class="home-button" href="#how-it-works">How it works</a>
        <a class="home-button home-button--ghost" href="{{ '/patterns/' | relative_url }}">Browse {{ total }} patterns</a>
      </p>
    </div>
  </section>

  <section class="home-section home-phases">
    <h2 id="how-it-works">How it works</h2>
    {% include aim42/phase-cards.html %}
  </section>

  <section class="home-section home-start">
    <h2 id="get-started">Get started</h2>
    <ol class="home-steps">
      {% for step in page.get_started %}
      <li class="home-steps__item">
        <p class="home-steps__text">{{ step.text | escape }}</p>
        <p class="home-steps__links">
          {%- for slug in step.patterns -%}
            {%- capture url %}/patterns/{{ slug }}/{% endcapture -%}
            {%- assign pattern = site.patterns | where: "url", url | first -%}
            <a href="{{ pattern.url | relative_url }}">{{ pattern.title | escape }}</a>{% unless forloop.last %}, {% endunless %}
          {%- endfor -%}
        </p>
      </li>
      {% endfor %}
    </ol>
    <p><a href="{{ '/getstarted' | relative_url }}">Read the full getting-started guide</a></p>
  </section>

  <section class="home-section home-open">
    <h2 id="free-and-open">Free and open</h2>
    <div class="home-open__grid">
      {{ content }}
    </div>
  </section>
</div>
```

Create `_includes/aim42/phase-cards.html`:

```html
{% comment %}
  phase-cards — the four phase cards on the home page (spec 3a §2).
  Title, URL and description from _data/phases.yml; three examples per
  phase from the home page's `examples:`; the count from site.patterns.
{% endcomment %}
<ul class="phase-list home-phase-list">
  {% for entry in site.data.phases %}
    {% assign key = entry[0] %}
    {% assign phase = entry[1] %}
    {% assign count = site.patterns | where: "phase", key | size %}
  <li class="phase-card" data-phase="{{ key }}">
    <h3><a href="{{ phase.url | relative_url }}">{{ phase.title }}</a></h3>
    <p class="home-phase__blurb">{{ phase.blurb }}</p>
    <ul class="home-examples">
      {% for slug in page.examples[key] %}
        {% capture url %}/patterns/{{ slug }}/{% endcapture %}
        {% assign pattern = site.patterns | where: "url", url | first %}
      <li><a href="{{ pattern.url | relative_url }}">{{ pattern.title | escape }}</a></li>
      {% endfor %}
    </ul>
    <p class="home-phase__all"><a href="{{ phase.url | relative_url }}">All {{ count }} {{ phase.title | downcase }} patterns</a></p>
  </li>
  {% endfor %}
</ul>
```

Create `_sass/pages/_home.scss`:

```scss
// Home page (_layouts/home.html).
// Spec: docs/superpowers/specs/2026-10-07-phase3a-homepage-design.md

.home {
  padding: 2rem 0 3rem;
}

.home-hero {
  align-items: center;
  display: flex;
  gap: 2.5rem;
  margin-bottom: 3rem;

  @media (max-width: $home-stack-width) {
    align-items: stretch;
    flex-direction: column;
  }
}

.home-hero__text {
  flex: 1 1 0;
}

// Anchored to .site-content to beat the global `.site-content h1` rule in
// _content.scss (see the note in components/_section-hero.scss).
.site-content .home-hero__title {
  color: var(--brand-ink);
  font-size: clamp(2rem, 4.2vw, #{$text-4xl});
  margin: 0 0 1rem;
}

.home-hero__lede {
  color: var(--brand-muted-strong);
  font-size: $text-lg;
  margin: 0 0 1.5rem;
  max-width: 34em;
}

.home-hero__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin: 0;
}

.site-content .home-button {
  align-items: center;
  background: var(--brand-primary);
  border: 2px solid var(--brand-primary);
  border-radius: $radius-xs;
  color: var(--brand-cream);
  display: inline-flex;
  font-weight: 600;
  min-height: 44px;
  padding: 0 1.1rem;
  text-decoration: none;

  &:hover {
    background: var(--brand-primary-deep);
    border-color: var(--brand-primary-deep);
  }

  &:focus-visible {
    outline: 3px solid var(--brand-primary);
    outline-offset: 3px;
  }
}

.site-content .home-button--ghost {
  background: transparent;
  color: var(--brand-primary);

  &:hover {
    background: var(--brand-primary-faint);
    color: var(--brand-primary-deep);
  }
}

.home-section {
  margin-bottom: 3rem;
}

// Cards reuse .phase-list / .phase-card from pages/_patterns.scss.
.home-phase-list {
  grid-template-columns: repeat(2, minmax(0, 1fr));

  @media (max-width: $home-edge-width) {
    grid-template-columns: minmax(0, 1fr);
  }

  .phase-card {
    &[data-phase="analyze"] {
      --cat-text: var(--phase-analyze-text);
    }
    &[data-phase="evaluate"] {
      --cat-text: var(--phase-evaluate-text);
    }
    &[data-phase="improve"] {
      --cat-text: var(--phase-improve-text);
    }
    &[data-phase="crosscutting"] {
      --cat-text: var(--phase-crosscutting-text);
    }
  }

  h3 {
    font-size: $text-xl;
    margin: 0 0 0.3rem;
  }
}

.site-content .home-phase-list a {
  color: var(--cat-text);
}

.home-examples {
  list-style: none;
  margin: 0.4rem 0;
  padding: 0;
}

.home-phase__all {
  font-weight: 600;
}

// 44px touch targets for every text link in the cards and steps.
.home-phase-list h3 a,
.home-examples a,
.home-phase__all a,
.home-steps__links a {
  align-items: center;
  display: inline-flex;
  min-height: 44px;
}

.home-steps {
  counter-reset: step;
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  list-style: none;
  margin: 0 0 1rem;
  padding: 0;

  @media (max-width: $home-stack-width) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.home-steps__item {
  background: var(--brand-paper);
  border-radius: $radius-md;
  counter-increment: step;
  padding: 0.8rem 1rem;

  &::before {
    color: var(--brand-primary);
    content: counter(step);
    display: block;
    font-family: $heading-font-family;
    font-size: $text-2xl;
    line-height: 1;
    margin-bottom: 0.4rem;
  }

  p {
    margin: 0;
  }
}

.home-open__grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(2, minmax(0, 1fr));

  @media (max-width: $home-stack-width) {
    grid-template-columns: minmax(0, 1fr);
  }

  > p {
    background: var(--brand-paper);
    border-radius: $radius-md;
    margin: 0;
    padding: 0.8rem 1rem;
  }
}
```

In `assets/css/aim42.scss`, add after `@import "pages/_patterns";`:

```scss
@import "pages/_home";
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: `patterns OK`; unit tests pass; site tests pass, including the four new home tests and the link and image checks that now include `/`.

- [ ] **Step 5: Commit**

```bash
git add _layouts/home.html _includes/aim42/phase-cards.html _sass/pages/_home.scss assets/css/aim42.scss _pages/home.md tests/site_test.rb tests/contrast_test.rb
git commit -m "New home page on the aim42 layout

Method-first home page: hero with headline and lede, four phase cards
with three examples each, Get started steps, Free and open. Replaces the
Minimal Mistakes splash page.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The cycle graphic

**Files:**
- Create: `_includes/aim42/cycle.html`
- Modify: `_layouts/home.html` (one include line)
- Modify: `_sass/pages/_home.scss` (append)
- Test: `tests/site_test.rb`

**Interfaces:**
- Consumes: `page.cycle` (Hash phase key to String) from `_pages/home.md`; `site.data.phases.<key>.title` and `.url`; the hero markup and the `HOME` / `PHASE_DATA` test constants from Task 2.
- Produces: `<nav class="home-cycle" aria-label="aim42 phases">` inside `.home-hero`, with four `a.home-cycle__link[data-phase]` in phase order.

- [ ] **Step 1: Write the failing test**

Add to `tests/site_test.rb`, after `test_home_buttons_lead_to_phases_and_patterns`:

```ruby
  def test_home_cycle_links_to_the_four_phases
    nav = page("/").at_css(".home-hero nav.home-cycle[aria-label='aim42 phases']")
    assert nav, "cycle navigation missing from the hero"
    links = nav.css("a")
    assert_equal PHASES.map { |k| PHASE_DATA[k]["url"] }, links.map { |a| a["href"] }
    assert_equal PHASES.map { |k| "#{PHASE_DATA[k]["title"]}: #{HOME["cycle"][k]}" }, links.map { |a| a["aria-label"] }
    assert_equal PHASES.map { |k| PHASE_DATA[k]["title"] }, links.map { |a| a.at_css(".home-cycle__name").text.strip }
    links.each do |a|
      assert a.css("path, circle, text").all? { |e| e["aria-hidden"] == "true" }, "#{a["href"]}: shapes and labels must be aria-hidden"
    end
  end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `make site-test`
Expected: FAIL with "cycle navigation missing from the hero".

- [ ] **Step 3: Implement**

Create `_includes/aim42/cycle.html`. Geometry: circle centre (150,150), arc radius 105; each arc spans 108° clockwise with a gap for the arrowhead. The viewBox includes all labels.

```html
{% comment %}
  cycle — the aim42 cycle in the home page hero (spec 3a §5). Inline SVG so
  the arcs link to the phase pages and take the phase colours from CSS.
  Phase titles and URLs from _data/phases.yml; the short lines from the
  home page's `cycle:` front matter. SVG elements use explicit closing tags
  so HTML parsers (and the site tests) read the same tree as browsers.
{% endcomment %}
{% assign phases = site.data.phases %}
<nav class="home-cycle" aria-label="aim42 phases">
  <svg class="home-cycle__svg" viewBox="-80 -20 470 330" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <marker id="cycle-head-analyze" class="home-cycle__head home-cycle__head--analyze" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="2" markerHeight="2" orient="auto"><path d="M0,0 L10,5 L0,10 z"></path></marker>
      <marker id="cycle-head-evaluate" class="home-cycle__head home-cycle__head--evaluate" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="2" markerHeight="2" orient="auto"><path d="M0,0 L10,5 L0,10 z"></path></marker>
      <marker id="cycle-head-improve" class="home-cycle__head home-cycle__head--improve" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="2" markerHeight="2" orient="auto"><path d="M0,0 L10,5 L0,10 z"></path></marker>
    </defs>

    <a class="home-cycle__link" data-phase="analyze" href="{{ phases.analyze.url | relative_url }}" aria-label="{{ phases.analyze.title }}: {{ page.cycle.analyze | escape }}">
      <path class="home-cycle__arc" d="M59.1 97.5 A105 105 0 0 1 228.0 79.8" marker-end="url(#cycle-head-analyze)" aria-hidden="true"></path>
      <text class="home-cycle__name" x="40" y="22" text-anchor="end" aria-hidden="true">{{ phases.analyze.title }}</text>
      <text class="home-cycle__note" x="40" y="40" text-anchor="end" aria-hidden="true">{{ page.cycle.analyze | escape }}</text>
    </a>

    <a class="home-cycle__link" data-phase="evaluate" href="{{ phases.evaluate.url | relative_url }}" aria-label="{{ phases.evaluate.title }}: {{ page.cycle.evaluate | escape }}">
      <path class="home-cycle__arc" d="M240.9 97.5 A105 105 0 0 1 171.8 252.7" marker-end="url(#cycle-head-evaluate)" aria-hidden="true"></path>
      <text class="home-cycle__name" x="282" y="205" aria-hidden="true">{{ phases.evaluate.title }}</text>
      <text class="home-cycle__note" x="282" y="223" aria-hidden="true">{{ page.cycle.evaluate | escape }}</text>
    </a>

    <a class="home-cycle__link" data-phase="improve" href="{{ phases.improve.url | relative_url }}" aria-label="{{ phases.improve.title }}: {{ page.cycle.improve | escape }}">
      <path class="home-cycle__arc" d="M150 255 A105 105 0 0 1 50.1 117.6" marker-end="url(#cycle-head-improve)" aria-hidden="true"></path>
      <text class="home-cycle__name" x="40" y="262" text-anchor="end" aria-hidden="true">{{ phases.improve.title }}</text>
      <text class="home-cycle__note" x="40" y="280" text-anchor="end" aria-hidden="true">{{ page.cycle.improve | escape }}</text>
    </a>

    <a class="home-cycle__link" data-phase="crosscutting" href="{{ phases.crosscutting.url | relative_url }}" aria-label="{{ phases.crosscutting.title }}: {{ page.cycle.crosscutting | escape }}">
      <circle class="home-cycle__hub" cx="150" cy="150" r="76" aria-hidden="true"></circle>
      <text class="home-cycle__name" x="150" y="152" text-anchor="middle" aria-hidden="true">{{ phases.crosscutting.title }}</text>
      <text class="home-cycle__note" x="150" y="172" text-anchor="middle" aria-hidden="true">{{ page.cycle.crosscutting | escape }}</text>
    </a>
  </svg>
</nav>
```

In `_layouts/home.html`, insert directly after the closing `</div>` of `<div class="home-hero__text">` (still inside `<section class="home-hero">`):

```html
    {% include aim42/cycle.html %}
```

Append to `_sass/pages/_home.scss`:

```scss
// Cycle graphic (_includes/aim42/cycle.html). Phase names use 22 user units;
// at the 320px phone width (viewBox 470 wide) that renders at 15px.
.home-cycle {
  flex: 0 1 380px;

  @media (max-width: $home-stack-width) {
    align-self: center;
    flex-basis: auto;
    max-width: 320px;
    width: 100%;
  }
}

.home-cycle__svg {
  display: block;
  height: auto;
  width: 100%;
}

.home-cycle__link {
  &[data-phase="analyze"] {
    --cat: var(--phase-analyze);
    --cat-text: var(--phase-analyze-text);
  }
  &[data-phase="evaluate"] {
    --cat: var(--phase-evaluate);
    --cat-text: var(--phase-evaluate-text);
  }
  &[data-phase="improve"] {
    --cat: var(--phase-improve);
    --cat-text: var(--phase-improve-text);
  }
  &[data-phase="crosscutting"] {
    --cat: var(--phase-crosscutting);
    --cat-text: var(--phase-crosscutting-text);
  }

  &:focus-visible {
    outline: 3px solid var(--brand-primary);
    outline-offset: 2px;
  }

  &:hover .home-cycle__arc,
  &:focus-visible .home-cycle__arc {
    stroke-width: 32;
  }

  &:hover .home-cycle__hub,
  &:focus-visible .home-cycle__hub {
    fill: var(--brand-primary-faint);
  }
}

.home-cycle__arc {
  fill: none;
  stroke: var(--cat);
  stroke-width: 26;
}

.home-cycle__head--analyze path {
  fill: var(--phase-analyze);
}
.home-cycle__head--evaluate path {
  fill: var(--phase-evaluate);
}
.home-cycle__head--improve path {
  fill: var(--phase-improve);
}

.home-cycle__hub {
  fill: var(--brand-paper);
  stroke: var(--cat);
  stroke-width: 2;
}

.home-cycle__name {
  fill: var(--cat-text);
  font-family: $heading-font-family;
  font-size: 22px;
}

.home-cycle__note {
  fill: var(--brand-muted-strong);
  font-family: $font-family;
  font-size: 12px;

  @media (max-width: $home-edge-width) {
    display: none;
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `make check`
Expected: all green, including `test_home_cycle_links_to_the_four_phases` and the link check on `/` (the cycle links resolve to the phase pages).

- [ ] **Step 5: Commit**

```bash
git add _includes/aim42/cycle.html _layouts/home.html _sass/pages/_home.scss tests/site_test.rb
git commit -m "Cycle graphic in the home page hero

Inline SVG in the phase colours; each arc and the centre link to their
phase page, with accessible names from the cycle lines.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Visual check, copy review issue, push (controller)

This task is done by the controller, not an implementer subagent: it needs the browser and GitHub.

**Files:** none (fixes found here go back through a fix round of Task 2 or Task 3).

- [ ] **Step 1: Full check**

Run: `make check`
Expected: all green.

- [ ] **Step 2: Look at the preview**

With `make dev` running (http://localhost:4242/), check in Chrome at 375px and at 1280px width:
- hero: headline, lede, two buttons; cycle beside (1280) or below (375) the buttons;
- no cycle label clipped; phase names in the cycle legible at 375px; the cycle notes hidden at 375px;
- arrowheads do not overlap the centre circle;
- cards 2×2 at 1280, one column at 375; steps in three columns at 1280, one at 375;
- keyboard only: Tab order is skip link, header, "How it works", "Browse 104 patterns", Analyze, Evaluate, Improve, Cross-cutting, then the cards; every focus is visible; "How it works" jumps to the cards.

Any defect: fix round on the owning task, then `make check` again.

- [ ] **Step 3: Open the copy review issue**

```bash
gh issue create --repo aim42/aim42.org-site --label "help wanted" \
  --title "Review homepage copy" \
  --body-file <file listing headline, lede, the four cycle lines, the three Get started steps and the two Free and open paragraphs, each quoted from _pages/home.md, with a pointer to that file>
```

Expected: an issue URL.

- [ ] **Step 4: Push**

```bash
git push origin merge-method-reference
```

Expected: push succeeds; the GitHub Actions run on the branch is green.
