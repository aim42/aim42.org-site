# Method Reference Pilot — Implementation Plan (Phase 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Six aim42 patterns live in `aim42.org-site` as a Markdown collection with Q42-derived layouts, an aim42 palette, a patterns index, an Analyze phase page, a glossary, a front-matter validator, and a Docker/CI test harness — without touching the live Minimal Mistakes pages.

**Architecture:** Jekyll only (no Node). A new `_patterns` collection renders through a `pattern` layout that sits on a new `aim42-base` layout (ported from quality.arc42.org). The existing Minimal Mistakes theme keeps serving all current pages; the new layouts/includes/SCSS use names that cannot collide with the theme gem (`aim42-*` layouts, `_includes/aim42/`, `assets/css/aim42.scss`). Validation and tests run in Docker via `make`, and in GitHub Actions.

**Tech Stack:** Jekyll 4.3.1 (existing lock), Ruby 3.3 in Docker, kramdown, Minitest + Nokogiri for tests, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-10-07-method-reference-merge-design.md` (sections 2, 3, 4, 7, 9). Executors read both.

**Working directory for every command:** the repo root `aim42.org-site` on branch `merge-method-reference`. Paths to the other repos used as copy sources:
- Q42 theme source: `/Users/gernotstarke/projects/arc42/quality.arc42.org-site` (referred to as `$Q`)
- aim42 method reference source: `/Users/gernotstarke/projects/aim42/method-reference` (referred to as `$M`)

## Global Constraints

- Content format is Markdown (kramdown, GFM input is already configured).
- Pattern URLs are flat: `/patterns/<slug>/`; the slug is the filename; no per-file `permalink`.
- Required front matter: `title`, `phase`, `intent`, `status`. `phase` ∈ keys of `_data/phases.yml` (analyze, evaluate, improve, crosscutting). `status` ∈ {complete, stub}. `related` is a list of existing slugs. `categories`, if present, is a list.
- A pattern belongs to exactly one phase; `crosscutting` is a phase.
- Glossary terms link to `/glossary/#<term>`.
- Q42 layouts and structure are reused, **not** its palette. Palette: aim42 red/blue/green (analyze/evaluate/improve) plus a neutral for crosscutting, derived from the current aim42 graphics (#F22658, #3FC4F4, #63E174, #ADC6C4) but subtler.
- Stubs are published with `status: stub` and a visible contribution box.
- Existing pages (home, about, …) must keep building unchanged on Minimal Mistakes; the live site is not affected (everything stays on the feature branch).
- No Node step in this phase.
- Commits end with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Pilot pattern set (fixed): Stakeholder Interview, Stakeholder Analysis, ATAM (analyze); Strangler Approach, Assertions as stub (improve); Improvement Backlog (crosscutting).
- References from pilot patterns to patterns that are not yet migrated are rendered as plain text and recorded as YAML comments (`# phase 2 restores: …`) in the front matter; phase 2 re-converts everything from AsciiDoc anyway.

## Review Focus

1. **`categories` front matter on a collection document.** Jekyll treats `categories` specially for posts; a pattern that declares `categories: [approaches]` must still render at `/patterns/<slug>/`, not under a category path. Pinned by `test_pattern_with_categories_renders_at_flat_url` in Task 4.
2. **`related` given as a string instead of a list** (`related: stakeholder-analysis`). The validator must reject it with a message naming the file; otherwise the layout silently renders nothing. Pinned in Task 2 (`test_related_must_be_a_list`).
3. **A pattern slug that collides with a phase page** (`_patterns/analyze.md` would shadow `/patterns/analyze/`). The validator rejects slugs equal to a phase key or `index`. Pinned in Task 2 (`test_slug_must_not_collide_with_phase_pages`).
4. **libsass (Jekyll 4.3 / sassc) vs. Q42's `color-mix()` and `clamp()`.** Q42 compiles with the Ruby `sass` gem; this site compiles with libsass. The generated `aim42.css` must contain `color-mix(` untouched. Pinned in Task 3 (`test_aim42_css_is_generated_with_modern_color_functions`), with a documented fallback.
5. **Regression of the existing Minimal Mistakes pages** after adding `_layouts/`, `_includes/`, `_sass/` files and config changes. Pinned in Task 1 (`test_home_page_still_builds_with_minimal_mistakes`, `test_existing_pages_still_build`) and re-run by every later task.

---

## File Structure

```
aim42.org-site/
├── Makefile                          build/dev/test entry points (Docker)
├── docker-compose.yml                replaced: jekyll service on port 4242
├── _docker/jekyll/Dockerfile         ruby:3.3 + bundled gems
├── Gemfile                           + group :test (minitest, nokogiri)
├── _config.yml                       + patterns collection, defaults, excludes
├── _data/phases.yml                  phase metadata (title, order, url, blurb)
├── _data/navigation.yml              + primary/secondary for the aim42 header
├── _layouts/aim42-base.html          HTML skeleton (ported Q42 default.html)
├── _layouts/aim42-page.html          hero + content, for index/phase/glossary pages
├── _layouts/pattern.html             one pattern
├── _includes/aim42/site-header.html  masthead + nav (no search)
├── _includes/aim42/footer.html
├── _includes/aim42/section-hero.html ported from Q42
├── _includes/aim42/stub-notice.html
├── _includes/aim42/related-patterns.html
├── _includes/aim42/pattern-list.html
├── _sass/base/*.scss, _sass/_*.scss, _sass/components/*.scss   copied from Q42
├── _sass/pages/_patterns.scss        new styles for pattern pages/lists
├── assets/css/aim42.scss             entry point → /assets/css/aim42.css
├── assets/js/aim42.js                nav toggle
├── assets/fonts/{atkinson,libre-caslon}/   copied from Q42
├── images/patterns/                  images used by pilot patterns
├── _patterns/*.md                    six pilot patterns
├── _pages/patterns/index.md          /patterns/
├── _pages/patterns/{analyze,evaluate,improve,crosscutting}.md
├── _pages/reference/glossary.md      /glossary/
├── tools/validate.rb                 front-matter validator (CLI + library)
├── tests/validate_test.rb            unit tests for the validator
├── tests/contrast_test.rb            WCAG contrast of palette tokens
├── tests/site_test.rb                checks on the generated _site
└── .github/workflows/check.yml       validate + build + tests
```

---

### Task 1: Docker toolchain and test harness

**Files:**
- Modify: `Gemfile`
- Create: `_docker/jekyll/Dockerfile`, `docker-compose.yml` (overwrite), `Makefile`, `tests/site_test.rb`
- Modify: `_config.yml` (exclude list), `.gitignore`

**Interfaces:**
- Produces: `make build`, `make lock`, `make dev`, `make down`, `make clean`, `make site-test`. `tests/site_test.rb` defines `SiteTest` with helper `page(url)` returning a Nokogiri doc; later tasks add test methods to this class.

- [ ] **Step 1: Add the test gems to the Gemfile**

Append to `Gemfile`:

```ruby

group :test do
  gem "minitest"
  gem "nokogiri"
end
```

- [ ] **Step 2: Write the Dockerfile**

`_docker/jekyll/Dockerfile`:

```dockerfile
FROM ruby:3.3

RUN gem install bundler:2.5.23

WORKDIR /site
COPY Gemfile Gemfile.lock ./
RUN bundle _2.5.23_ config set path /usr/local/bundle \
    && bundle _2.5.23_ install --jobs 4 --retry 3

# The repo is bind-mounted over /site at runtime; the gems live outside it.
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--port", "4242", "--force_polling"]
```

- [ ] **Step 3: Replace docker-compose.yml**

```yaml
services:
  jekyll:
    build:
      context: .
      dockerfile: _docker/jekyll/Dockerfile
    volumes:
      - .:/site
      - jekyll_cache:/site/.jekyll-cache
    ports:
      - "4242:4242"

volumes:
  jekyll_cache:
```

- [ ] **Step 4: Write the Makefile** (recipe lines start with a TAB)

```make
# Local development and checks run in Docker; no local Ruby needed.
SITE_PORT ?= 4242
RUN = docker compose run --rm --no-deps jekyll

.PHONY: help build lock dev down clean site-test

help:
	@printf "make build      build the Jekyll image (rerun after Gemfile.lock changes)\n"
	@printf "make lock       regenerate Gemfile.lock inside Docker (after editing Gemfile)\n"
	@printf "make dev        serve the site on http://localhost:$(SITE_PORT)\n"
	@printf "make down       stop the dev container\n"
	@printf "make clean      remove containers, cache volumes and _site\n"
	@printf "make site-test  build the site and run tests/site_test.rb\n"

build:
	docker compose build jekyll

lock:
	docker run --rm -v "$(CURDIR):/site" -w /site ruby:3.3 sh -c \
	  "gem install bundler:2.5.23 && bundle _2.5.23_ lock --add-platform aarch64-linux x86_64-linux"

dev:
	@printf "==> open http://localhost:$(SITE_PORT)\n"
	docker compose up jekyll

down:
	docker compose down

clean:
	docker compose down --volumes 2>/dev/null || true
	rm -rf _site

site-test:
	$(RUN) sh -c "bundle exec jekyll build --quiet && bundle exec ruby tests/site_test.rb"
```

- [ ] **Step 5: Exclude tooling from the Jekyll build**

In `_config.yml`, add to the existing `exclude:` list:

```yaml
  - Makefile
  - docker-compose.yml
  - _docker
  - tools
  - tests
  - docs
```

Append to `.gitignore`:

```
.jekyll-cache
```

- [ ] **Step 6: Write the first site tests (regression guards)**

`tests/site_test.rb`:

```ruby
# Checks on the generated site. Run after `bundle exec jekyll build`.
require "minitest/autorun"
require "nokogiri"

SITE_DIR = File.expand_path("../_site", __dir__)

class SiteTest < Minitest::Test
  # Resolves a site URL ("/about", "/patterns/atam/") to its generated file.
  def site_file(url)
    url = url.sub(%r{\?.*\z}, "").sub(/#.*\z/, "")
    candidates = if url.end_with?("/")
                   [File.join(SITE_DIR, url, "index.html")]
                 else
                   [File.join(SITE_DIR, url), File.join(SITE_DIR, "#{url}.html"), File.join(SITE_DIR, url, "index.html")]
                 end
    candidates.find { |f| File.file?(f) }
  end

  def page(url)
    file = site_file(url)
    assert file, "expected #{url} to be generated under _site/"
    Nokogiri::HTML(File.read(file))
  end

  def test_home_page_still_builds_with_minimal_mistakes
    doc = page("/")
    assert doc.at_css(".page__hero--overlay, .page__hero"), "home page lost its Minimal Mistakes hero"
  end

  def test_existing_pages_still_build
    %w[/about /getstarted /learn /faq /imprint /contact].each { |url| page(url) }
  end
end
```

- [ ] **Step 7: Regenerate the lock file and build the image**

Run: `make lock && make build`
Expected: `Gemfile.lock` now lists `minitest` and `nokogiri` under DEPENDENCIES and keeps `aarch64-linux`/`x86_64-linux` platforms; image builds without error.

- [ ] **Step 8: Run the site tests**

Run: `make site-test`
Expected: `2 runs, … 0 failures, 0 errors`. If `page("/contact")` fails because the page has no `permalink`, check `_pages/contact.md` and use its actual URL in the list.

- [ ] **Step 9: Commit**

```bash
git add Gemfile Gemfile.lock _docker docker-compose.yml Makefile tests/site_test.rb _config.yml .gitignore
git commit -m "Add Docker dev toolchain and site regression tests

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: Phase data and front-matter validator

**Files:**
- Create: `_data/phases.yml`, `tools/validate.rb`, `tests/validate_test.rb`
- Modify: `Makefile` (add `validate`, `unit`, `check`)

**Interfaces:**
- Produces: `Aim42::Validator.new(site_root).run → Array<String>` (empty = valid). CLI: `ruby tools/validate.rb [site_root]`, exit 1 on errors. `_data/phases.yml` keys `analyze|evaluate|improve|crosscutting`, each with `title`, `order`, `url`, `blurb`.

- [ ] **Step 1: Write `_data/phases.yml`**

```yaml
# The four aim42 phases. Keys are the allowed values of a pattern's `phase`.
analyze:
  title: Analyze
  order: 1
  url: /patterns/analyze/
  blurb: Find issues, risks and technical debt in the system and its organization, and understand their root causes.
evaluate:
  title: Evaluate
  order: 2
  url: /patterns/evaluate/
  blurb: Make issues and remedies comparable by estimating their value, cost and risk, then prioritize.
improve:
  title: Improve
  order: 3
  url: /patterns/improve/
  blurb: Apply approaches and practices that eliminate issues, reduce technical debt and optimize quality.
crosscutting:
  title: Cross-cutting
  order: 4
  url: /patterns/crosscutting/
  blurb: Practices that span all phases and keep issues and improvements visible, understood and aligned.
```

- [ ] **Step 2: Write the failing validator tests**

`tests/validate_test.rb`:

```ruby
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../tools/validate"

class ValidatorTest < Minitest::Test
  PHASES = "analyze:\n  title: Analyze\nimprove:\n  title: Improve\n"

  def setup
    @root = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@root, "_data"))
    FileUtils.mkdir_p(File.join(@root, "_patterns"))
    File.write(File.join(@root, "_data", "phases.yml"), PHASES)
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def pattern(name, front_matter, body: "Body.\n")
    File.write(File.join(@root, "_patterns", "#{name}.md"), "---\n#{front_matter}---\n\n#{body}")
  end

  def errors
    Aim42::Validator.new(@root).run
  end

  VALID = "title: Stakeholder Interview\nphase: analyze\nintent: Learn.\nstatus: complete\n"

  def test_valid_patterns_have_no_errors
    pattern("stakeholder-interview", VALID + "related: [stakeholder-analysis]\n")
    pattern("stakeholder-analysis", "title: Stakeholder Analysis\nphase: analyze\nintent: Find.\nstatus: complete\n")
    assert_empty errors
  end

  def test_missing_required_key
    pattern("a", "title: A\nphase: analyze\nstatus: complete\n")
    assert_includes errors, "a.md: missing required key 'intent'"
  end

  def test_unknown_phase
    pattern("a", "title: A\nphase: evaluate\nintent: x\nstatus: complete\n")
    assert_includes errors, "a.md: unknown phase 'evaluate' (allowed: analyze, improve)"
  end

  def test_unknown_status
    pattern("a", "title: A\nphase: analyze\nintent: x\nstatus: draft\n")
    assert_includes errors, "a.md: unknown status 'draft' (allowed: complete, stub)"
  end

  def test_related_must_be_a_list
    pattern("a", VALID + "related: stakeholder-analysis\n")
    assert_includes errors, "a.md: 'related' must be a list of slugs"
  end

  def test_related_unknown_slug
    pattern("a", VALID + "related: [nope]\n")
    assert_includes errors, "a.md: related slug 'nope' does not exist in _patterns/"
  end

  def test_categories_must_be_a_list
    pattern("a", VALID + "categories: approaches\n")
    assert_includes errors, "a.md: 'categories' must be a list"
  end

  def test_filename_must_be_kebab_case
    pattern("Stakeholder_Interview", VALID)
    assert_includes errors, "Stakeholder_Interview.md: filename must be a kebab-case slug"
  end

  def test_slug_must_not_collide_with_phase_pages
    pattern("analyze", VALID)
    pattern("index", VALID)
    assert_includes errors, "analyze.md: slug 'analyze' is reserved for a phase page"
    assert_includes errors, "index.md: slug 'index' is reserved"
  end

  def test_duplicate_titles
    pattern("a", VALID)
    pattern("b", VALID)
    assert_includes errors, "duplicate title 'stakeholder interview' in a.md, b.md"
  end

  def test_missing_front_matter
    File.write(File.join(@root, "_patterns", "a.md"), "no front matter\n")
    assert_includes errors, "a.md: missing front matter"
  end

  def test_invalid_yaml
    pattern("a", "title: [unclosed\n")
    assert errors.any? { |e| e.start_with?("a.md: invalid YAML front matter") }, errors.inspect
  end
end
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `docker compose run --rm --no-deps jekyll bundle exec ruby tests/validate_test.rb`
Expected: `LoadError: cannot load such file -- …/tools/validate`

- [ ] **Step 4: Write the validator**

`tools/validate.rb`:

```ruby
# Validates the front matter of every file in _patterns/.
#
#   ruby tools/validate.rb            # checks the current directory
#   ruby tools/validate.rb path/to/site
#
# Exit status 1 and one "ERROR …" line per finding when anything is wrong.
require "yaml"

module Aim42
  class Validator
    REQUIRED = %w[title phase intent status].freeze
    STATUSES = %w[complete stub].freeze
    SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

    def initialize(root)
      @root = root
    end

    def run
      errors = []
      phases = YAML.safe_load(File.read(File.join(@root, "_data", "phases.yml"))).keys
      files = Dir[File.join(@root, "_patterns", "*.md")].sort
      slugs = files.map { |f| File.basename(f, ".md") }
      titles = Hash.new { |h, k| h[k] = [] }

      files.each do |file|
        name = File.basename(file)
        slug = File.basename(file, ".md")
        errors << "#{name}: filename must be a kebab-case slug" unless slug.match?(SLUG)
        errors << "#{name}: slug '#{slug}' is reserved for a phase page" if phases.include?(slug)
        errors << "#{name}: slug 'index' is reserved" if slug == "index"

        begin
          fm = front_matter(file)
        rescue Psych::SyntaxError => e
          errors << "#{name}: invalid YAML front matter (#{e.message})"
          next
        end
        if fm.nil?
          errors << "#{name}: missing front matter"
          next
        end

        REQUIRED.each do |key|
          errors << "#{name}: missing required key '#{key}'" if fm[key].to_s.strip.empty?
        end
        if fm.key?("phase") && !phases.include?(fm["phase"])
          errors << "#{name}: unknown phase '#{fm["phase"]}' (allowed: #{phases.join(", ")})"
        end
        if fm.key?("status") && !STATUSES.include?(fm["status"])
          errors << "#{name}: unknown status '#{fm["status"]}' (allowed: #{STATUSES.join(", ")})"
        end
        if fm.key?("related")
          if fm["related"].is_a?(Array)
            (fm["related"] - slugs).each { |r| errors << "#{name}: related slug '#{r}' does not exist in _patterns/" }
          else
            errors << "#{name}: 'related' must be a list of slugs"
          end
        end
        errors << "#{name}: 'categories' must be a list" if fm.key?("categories") && !fm["categories"].is_a?(Array)
        titles[fm["title"].to_s.strip.downcase] << name unless fm["title"].to_s.strip.empty?
      end

      titles.each { |title, names| errors << "duplicate title '#{title}' in #{names.join(", ")}" if names.size > 1 }
      errors
    end

    private

    # Returns the parsed front matter hash, nil when the file has none.
    def front_matter(file)
      text = File.read(file)
      return nil unless text.start_with?("---\n")
      close = text.index("\n---", 4)
      return nil unless close
      YAML.safe_load(text[4...close]) || {}
    end
  end
end

if $PROGRAM_NAME == __FILE__
  errors = Aim42::Validator.new(ARGV[0] || Dir.pwd).run
  if errors.empty?
    puts "patterns OK"
  else
    errors.each { |e| warn "ERROR #{e}" }
    exit 1
  end
end
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `docker compose run --rm --no-deps jekyll bundle exec ruby tests/validate_test.rb`
Expected: `12 runs, … 0 failures, 0 errors`

- [ ] **Step 6: Add Make targets**

Add to `Makefile` (`.PHONY` line gets `validate unit check`):

```make
validate:
	$(RUN) ruby tools/validate.rb

unit:
	$(RUN) bundle exec ruby tests/validate_test.rb

check: validate unit site-test
```

Run: `make check`
Expected: validator prints `patterns OK` (no patterns yet), unit tests pass, site tests pass.

- [ ] **Step 7: Commit**

```bash
git add _data/phases.yml tools/validate.rb tests/validate_test.rb Makefile
git commit -m "Add phase data and pattern front-matter validator

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Theme scaffold, palette and glossary page

**Files:**
- Create (copied from `$Q`): `_sass/base/{_reset,_syntax,_variables,_fonts,_layout,_utilities}.scss`, `_sass/{_common,_header,_footer,_content}.scss`, `_sass/components/{_section-hero,_tag-chips,_section-headings,_panels,_callouts}.scss`, `assets/fonts/atkinson/`, `assets/fonts/libre-caslon/`, `_includes/aim42/section-hero.html`
- Create: `_sass/pages/_patterns.scss`, `assets/css/aim42.scss`, `assets/js/aim42.js`, `_layouts/aim42-base.html`, `_layouts/aim42-page.html`, `_includes/aim42/site-header.html`, `_includes/aim42/footer.html`, `_pages/reference/glossary.md`, `tests/contrast_test.rb`
- Modify: `_sass/base/_variables.scss` (palette), `_sass/components/_section-hero.scss` (phase variants), `_data/navigation.yml`, `Makefile` (`unit` also runs contrast test), `tests/site_test.rb`

**Interfaces:**
- Produces: layout `aim42-base` (expects nothing), layout `aim42-page` (front matter: `title`, optional `section`, `lede`, `eyebrow_label`, `eyebrow_href`, `meta`), include `aim42/section-hero.html` (params `section`, `title`, `eyebrow_label`, `eyebrow_href`, `lede`, `chips_html`, `meta`), CSS custom properties `--phase-analyze`, `--phase-evaluate`, `--phase-improve`, `--phase-crosscutting` (+ `-text` variants), `--brand-primary`, `--brand-primary-soft`, `--brand-primary-faint`, `--brand-paper`, `--brand-ink`, `--muted-text-1`.

- [ ] **Step 1: Write the failing contrast test (palette TDD)**

`tests/contrast_test.rb`:

```ruby
# WCAG 2.x contrast of the aim42 palette tokens in _sass/base/_variables.scss.
require "minitest/autorun"

class ContrastTest < Minitest::Test
  VARS = File.read(File.expand_path("../_sass/base/_variables.scss", __dir__))

  def token(name)
    VARS[/^\$#{Regexp.escape(name)}:\s*(#[0-9a-fA-F]{6})\s*;/, 1] or flunk "token $#{name} not found as a hex literal"
  end

  def luminance(hex)
    r, g, b = hex[1..].scan(/../).map do |c|
      v = c.hex / 255.0
      v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def contrast(a, b)
    hi, lo = [luminance(a), luminance(b)].sort.reverse
    (hi + 0.05) / (lo + 0.05)
  end

  def assert_contrast(fg, bg, min)
    ratio = contrast(token(fg), token(bg))
    assert ratio >= min, "#{fg} on #{bg}: #{ratio.round(2)}:1 is below #{min}:1"
  end

  def test_phase_text_colors_are_readable_on_paper
    %w[analyze evaluate improve crosscutting].each do |phase|
      assert_contrast("phase-#{phase}-text", "brand-paper", 4.5)
    end
  end

  def test_body_text_is_readable_on_paper
    assert_contrast("brand-ink", "brand-paper", 7.0)
    assert_contrast("brand-muted-strong", "brand-paper", 4.5)
  end

  def test_header_text_is_readable_on_primary
    assert_contrast("brand-cream", "brand-primary", 4.5)
  end

  def test_stub_badge_text_is_readable
    assert_contrast("brand-ink", "phase-crosscutting", 4.5)
  end
end
```

Run: `docker compose run --rm --no-deps jekyll bundle exec ruby tests/contrast_test.rb`
Expected: 4 failures/errors (`_sass/base/_variables.scss` does not exist yet).

- [ ] **Step 2: Copy the Q42 partials, fonts and the hero include**

```bash
Q=/Users/gernotstarke/projects/arc42/quality.arc42.org-site
mkdir -p _sass/base _sass/components _sass/pages assets/fonts _includes/aim42
cp $Q/_sass/base/{_reset,_syntax,_variables,_fonts,_layout,_utilities}.scss _sass/base/
cp $Q/_sass/{_common,_header,_footer,_content}.scss _sass/
cp $Q/_sass/components/{_section-hero,_tag-chips,_section-headings,_panels,_callouts}.scss _sass/components/
cp -R $Q/assets/fonts/atkinson $Q/assets/fonts/libre-caslon assets/fonts/
cp $Q/_includes/section-hero.liquid _includes/aim42/section-hero.html
```

In `_includes/aim42/section-hero.html`, change the opening tag so the section defaults to `reference`:

```html
<header class="section-hero" data-section="{{ include.section | default: 'reference' }}">
```

- [ ] **Step 3: Replace the brand tokens in `_sass/base/_variables.scss`**

Replace the block from the line `$brand-violet: #682d63;` through the line `$marker-color: $brand-color;` (Q42 lines 68–96) with:

```scss
// ── aim42 brand tokens ───────────────────────────────────────────────
// Phase colours derive from the original aim42 graphics
// (analyze #F22658, evaluate #3FC4F4, improve #63E174, crosscutting #ADC6C4),
// toned down for large surfaces. Tune on the pilot pages; tests/contrast_test.rb
// guards the WCAG minimums.
$brand-ink: #1f2429;
$brand-paper: #f8f7f4;
$brand-cream: #fbf9f5;
$brand-muted: #6b7076;
$brand-muted-strong: #4f5459;
$brand-primary: #2b3a4a; // masthead, footer, links
$brand-primary-deep: #1d2833;
$brand-primary-soft: #e3e8ee;
$brand-primary-faint: #f1f4f7;

$phase-analyze: #d4405f;
$phase-analyze-text: #8c1f39;
$phase-evaluate: #2f9fd0;
$phase-evaluate-text: #0f4f6e;
$phase-improve: #3fae63;
$phase-improve-text: #1c5e33;
$phase-crosscutting: #7f9b99;
$phase-crosscutting-text: #3b5553;

// Legacy aliases: partials copied from quality.arc42.org still use the Q42
// names. Keep them until each partial is migrated; never add new uses.
$brand-violet: $brand-primary;
$brand-violet-deep: $brand-primary-deep;
$brand-violet-soft: $brand-primary-soft;
$brand-violet-faint: $brand-primary-faint;
$brand-teal: $phase-crosscutting;
$brand-blue: $phase-evaluate;
$brand-blue-dark: $phase-evaluate-text;
$brand-blue-soft: #eef7fb;
$brand-blue-text: $phase-evaluate-text;
$brand-blue-muted: #536b80;
$brand-blue-accent: #1675b9;
$brand-blue-accent-dark: #1f5f82;

$brand-color: $brand-primary;
$brand-color-light: $brand-primary-soft;
$brand-color-blue: $brand-blue;
$brand-color-lila: $brand-primary;
$brand-color-dark: $brand-primary-deep;
$marker-color: $brand-color;
```

Leave everything after that line (the `$quality-*`, `$requirement-*`, … tokens) unchanged; copied partials still reference them.

Then, inside the `:root {` block, directly after the line `color-scheme: light;`, insert:

```scss
  // aim42 tokens
  --brand-primary: #{$brand-primary};
  --brand-primary-deep: #{$brand-primary-deep};
  --brand-primary-soft: #{$brand-primary-soft};
  --brand-primary-faint: #{$brand-primary-faint};
  --phase-analyze: #{$phase-analyze};
  --phase-analyze-text: #{$phase-analyze-text};
  --phase-evaluate: #{$phase-evaluate};
  --phase-evaluate-text: #{$phase-evaluate-text};
  --phase-improve: #{$phase-improve};
  --phase-improve-text: #{$phase-improve-text};
  --phase-crosscutting: #{$phase-crosscutting};
  --phase-crosscutting-text: #{$phase-crosscutting-text};
```

- [ ] **Step 4: Run the contrast test**

Run: `docker compose run --rm --no-deps jekyll bundle exec ruby tests/contrast_test.rb`
Expected: `4 runs, … 0 failures`. If a pair fails, darken the `-text` token (or the `brand-primary`) until it passes; do not lower the thresholds.

- [ ] **Step 5: Give the section hero its phase variants**

In `_sass/components/_section-hero.scss`, replace the block of `&[data-section="…"]` rules (from `&[data-section="qualities"]` through the closing brace of `&[data-section="how-to"]`) with:

```scss
  // Phase heroes carry the phase colour on the rail and a 14% wash.
  &[data-section="analyze"],
  &[data-section="evaluate"],
  &[data-section="improve"] {
    background: var(--brand-paper);
    background: color-mix(in oklab, var(--brand-paper) 86%, var(--cat) 14%);
  }
  &[data-section="analyze"] {
    --cat: var(--phase-analyze);
  }
  &[data-section="evaluate"] {
    --cat: var(--phase-evaluate);
  }
  &[data-section="improve"] {
    --cat: var(--phase-improve);
  }
  &[data-section="crosscutting"] {
    --cat: var(--phase-crosscutting);
  }
  // Index and reference pages (glossary, introduction) use the site colour.
  &[data-section="patterns"],
  &[data-section="reference"] {
    --cat: var(--brand-primary);
  }
```

- [ ] **Step 6: Write `_sass/pages/_patterns.scss`**

```scss
// Pattern pages, pattern lists and phase cards.

.pattern-meta {
  margin: 0 0 1.2rem;
}

.pattern-meta__title {
  color: var(--brand-muted-strong);
  font-size: $text-sm;
  letter-spacing: 0.08em;
  margin: 0 0 0.2rem;
  text-transform: uppercase;
}

.pattern-meta p {
  font-size: $text-lg;
  line-height: 1.4;
  margin: 0;
}

.stub-notice {
  background: var(--brand-primary-faint);
  border: 1px solid var(--brand-primary-soft);
  border-left: 6px solid var(--phase-crosscutting);
  border-radius: $radius-sm;
  margin: 0 0 1.2rem;
  padding: 0.75rem 1rem;

  p {
    margin: 0;
  }
}

.tag--stub {
  background: var(--phase-crosscutting);
  color: var(--brand-ink);
}

.pattern-list {
  list-style: none;
  margin: 0 0 1.5rem;
  padding: 0;
}

.pattern-list__item {
  border-bottom: 1px solid var(--approach-impact-border-color);
  padding: 0.7rem 0;
}

.pattern-list__title {
  font-weight: 600;
  margin: 0;
}

.pattern-list__intent {
  color: var(--muted-text-1);
  margin: 0.2rem 0 0;
}

.pattern-related {
  list-style: none;
  margin: 0;
  padding: 0;

  li {
    border-bottom: 1px solid var(--approach-impact-border-color);
    padding: 0.5rem 0;
  }
}

.pattern-edit {
  color: var(--brand-muted);
  font-size: $text-sm;
  margin-top: 2rem;
}

.phase-list {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  list-style: none;
  margin: 0 0 1.5rem;
  padding: 0;
}

.phase-card {
  --cat: var(--brand-primary);
  background: var(--brand-paper);
  border-left: 10px solid var(--cat);
  border-radius: $radius-md;
  padding: 0.8rem 1rem;

  &[data-phase="analyze"] {
    --cat: var(--phase-analyze);
  }
  &[data-phase="evaluate"] {
    --cat: var(--phase-evaluate);
  }
  &[data-phase="improve"] {
    --cat: var(--phase-improve);
  }
  &[data-phase="crosscutting"] {
    --cat: var(--phase-crosscutting);
  }

  h2 {
    font-size: $text-xl;
    margin: 0 0 0.3rem;
  }

  p {
    color: var(--muted-text-1);
    margin: 0;
  }
}
```

- [ ] **Step 7: Write the stylesheet entry point `assets/css/aim42.scss`**

```scss
---
---

@import "base/_reset";
@import "base/_syntax";
@import "base/_variables";
@import "base/_fonts";
@import "base/_layout";
@import "base/_utilities";
@import "_common";
@import "_header";
@import "_footer";
@import "_content";
@import "components/_callouts";
@import "components/_tag-chips";
@import "components/_section-headings";
@import "components/_panels";
@import "components/_section-hero";
@import "pages/_patterns";
```

- [ ] **Step 8: Write the base layout `_layouts/aim42-base.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{% if page.title %}{{ page.title }} | {% endif %}{{ site.title }}</title>
  {% assign description = page.intent | default: page.lede | default: site.description %}
  <meta name="description" content="{{ description | strip_html | strip_newlines | truncate: 160 }}">
  <link rel="canonical" href="{{ page.url | replace: 'index.html', '' | absolute_url }}">
  <link rel="icon" type="image/png" sizes="32x32" href="{{ '/favicon-32x32.png' | relative_url }}">
  <link rel="icon" type="image/png" sizes="16x16" href="{{ '/favicon-16x16.png' | relative_url }}">
  <link rel="apple-touch-icon" sizes="180x180" href="{{ '/apple-touch-icon.png' | relative_url }}">
  <meta name="theme-color" content="#2b3a4a">
  <link rel="preload" href="{{ '/assets/fonts/atkinson/AtkinsonHyperlegibleNext-Variable.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
  <link rel="preload" href="{{ '/assets/fonts/libre-caslon/LibreCaslonText-Regular.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
  <link href="{{ '/assets/css/aim42.css' | relative_url }}" rel="stylesheet">
</head>
<body>
<a class="skip-link" href="#main-content">Skip to content</a>
{% include aim42/site-header.html %}
<div class="site-container">
  <main id="main-content" class="site-content" tabindex="-1">
    {{ content }}
  </main>
</div>
{% include aim42/footer.html %}
<script defer src="{{ '/assets/js/aim42.js' | relative_url }}"></script>
</body>
</html>
```

- [ ] **Step 9: Write the header, footer, navigation data and JS**

`_includes/aim42/site-header.html`:

```html
{% assign primary_nav = site.data.navigation.primary %}
{% assign secondary_nav = site.data.navigation.secondary %}
<header class="site-header">
  <div class="site-header__inner">
    <a class="site-brand" href="{{ '/' | relative_url }}" aria-label="aim42 home">
      <img class="site-brand__logo" src="{{ '/images/aim42-site-logo.png' | relative_url }}" alt="aim42" />
      <span class="site-brand__name">architecture improvement method</span>
    </a>

    <div class="site-header__right">
      <nav class="site-primary-nav" aria-label="Primary navigation">
        {% for item in primary_nav %}
          {% assign item_active = false %}
          {% if page.url == item.url %}{% assign item_active = true %}{% endif %}
          <a class="site-primary-nav__link{% if item_active %} is-active{% endif %}" href="{{ item.url | relative_url }}"{% if item_active %} aria-current="page"{% endif %}>{{ item.label }}</a>
        {% endfor %}
      </nav>

      <div class="site-actions">
        <button class="site-menu-toggle nav-toggle" type="button" data-target="#site-secondary-nav" aria-controls="site-secondary-nav" aria-expanded="false" aria-label="Open navigation menu">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </button>
      </div>
    </div>
  </div>

  <nav id="site-secondary-nav" class="site-secondary-nav" aria-label="Secondary navigation">
    <div class="site-secondary-nav__inner">
      <div class="site-secondary-nav__group site-secondary-nav__primary">
        <span class="site-secondary-nav__label">Patterns</span>
        {% for item in primary_nav %}
          <a href="{{ item.url | relative_url }}">{{ item.label }}</a>
        {% endfor %}
      </div>
      <div class="site-secondary-nav__group">
        <span class="site-secondary-nav__label">More</span>
        {% for item in secondary_nav %}
          <a href="{{ item.url | relative_url }}">{{ item.label }}</a>
        {% endfor %}
      </div>
    </div>
  </nav>
</header>
```

`_includes/aim42/footer.html`:

```html
<footer class="site-footer" role="contentinfo" aria-label="Site footer">
  <div class="site-footer__inner">
    <div class="footer-sponsor">
      <a href="https://www.innoq.com" target="_blank" rel="noopener noreferrer nofollow" aria-label="Supported by INNOQ">
        <img alt="Supported by INNOQ" loading="lazy" decoding="async" src="{{ '/images/supported-by-innoq--petrol-apricot.svg' | relative_url }}" />
      </a>
    </div>

    <p class="footer-colophon">
      <a href="{{ '/contact' | relative_url }}">Contact</a><span class="footer-sep" aria-hidden="true">·</span><a href="https://github.com/aim42">GitHub</a><span class="footer-sep" aria-hidden="true">·</span><a href="{{ '/imprint' | relative_url }}">Imprint + Privacy</a>
    </p>

    <p class="footer-credits">
      &copy; {{ site.time | date: '%Y' }} Created by <a href="https://gernotstarke.de">Gernot Starke</a> and aim42 <a href="https://github.com/orgs/aim42/people">contributors</a>, licensed under <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0</a>. Supported by <a href="https://kroener-starke.ch/">Kröner &amp; Starke</a>.
    </p>
  </div>
</footer>
```

Append to `_data/navigation.yml` (the existing `main:` etc. stay for Minimal Mistakes):

```yaml

# Header of the aim42 (Q42-style) layouts — _includes/aim42/site-header.html.
# Navigation of the whole site is redesigned in phase 3; this is the pilot's.
primary:
  - label: Patterns
    url: /patterns/
  - label: Analyze
    url: /patterns/analyze/
  - label: Evaluate
    url: /patterns/evaluate/
  - label: Improve
    url: /patterns/improve/
  - label: Cross-cutting
    url: /patterns/crosscutting/

secondary:
  - label: Glossary
    url: /glossary/
  - label: Get started
    url: /getstarted
  - label: About
    url: /about
```

`assets/js/aim42.js`:

```js
// Navigation toggle for the aim42 header. Ported and trimmed from
// quality.arc42.org (src/scripts/site/navigation.js): the toggle and its
// target get the `active` class, aria-expanded follows; Esc and clicks
// outside the header close it.
(function () {
  var toggles = Array.prototype.slice.call(document.querySelectorAll('.nav-toggle'));

  function setOpen(toggle, open) {
    var target = document.querySelector(toggle.getAttribute('data-target'));
    if (!target) return;
    toggle.classList.toggle('active', open);
    target.classList.toggle('active', open);
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  }

  toggles.forEach(function (toggle) {
    toggle.addEventListener('click', function (event) {
      event.preventDefault();
      setOpen(toggle, !toggle.classList.contains('active'));
    });
  });

  document.addEventListener('keydown', function (event) {
    if (event.key !== 'Escape') return;
    toggles.forEach(function (toggle) {
      if (!toggle.classList.contains('active')) return;
      setOpen(toggle, false);
      toggle.focus();
    });
  });

  document.addEventListener('click', function (event) {
    if (event.target.closest('.site-header')) return;
    toggles.forEach(function (toggle) { setOpen(toggle, false); });
  });
})();
```

- [ ] **Step 10: Write the page layout and the glossary page**

`_layouts/aim42-page.html`:

```html
---
layout: aim42-base
---
<div class="article-wrapper">
  <article>
    {% include aim42/section-hero.html
      section=page.section
      title=page.title
      eyebrow_label=page.eyebrow_label
      eyebrow_href=page.eyebrow_href
      lede=page.lede
      meta=page.meta %}
    <section class="post-content">
      {{ content }}
    </section>
  </article>
</div>
```

`_pages/reference/glossary.md` (terms from `$M/src/main/asciidoc/appendices/glossary.adoc`; *Issue* and *Remedy* had no definition there and get one-liners consistent with the aim42 domain model — phase 2 revisits them with the domain-model page):

```markdown
---
title: Glossary
layout: aim42-page
section: reference
permalink: /glossary/
lede: Terms used throughout the aim42 patterns and practices.
---

### aim42 {#aim42}

Architecture Improvement Method.

### ATAM {#atam}

Architecture Tradeoff Analysis Method, described in detail by Clements et al.
(*Evaluating Software Architectures*, 2001) and online by the SEI; briefly
described as the aim42 pattern [ATAM](/patterns/atam/).

### Failure {#failure}

Loss of functionality under defined (*stated*) conditions.

### Issue {#issue}

A problem, risk, symptom or piece of technical debt found in the system or its
associated processes. Issues are collected during *analyze*, valued during
*evaluate* and addressed by remedies during *improve*.

### Remedy {#remedy}

A measure (practice, approach, change) that solves or mitigates one or more
issues.

### SEI {#sei}

Software Engineering Institute at Carnegie Mellon University. A federally
funded research and development institute, sponsored by the US Department of
Defense.

### System {#system}

The system to be improved — often a single software system, but it might be a
complex combination of hardware, software and organizational aspects.
*Systems* in our sense consist of:

* software, usually with corresponding data structures and data
* required infrastructure software, like operating system, database,
  UI frameworks, middleware etc.
* required hardware infrastructure, like processors, storage, network, routers etc.
* associated development processes, like requirements engineering,
  architecture, implementation, version and configuration management,
  build and deployment
* associated administration and operation processes or procedures
* associated organizational processes, like budgeting, HR, controlling,
  management etc.
* associated external systems, like data or event providers or consumers

and maybe even more.

### Value {#value}

(of an improvement or remedy) Approximately −1 times the cost of the associated
issue(s). If an improvement solves only part of an issue, value estimation
becomes much harder.
```

- [ ] **Step 11: Add site tests for the scaffold**

Add to `class SiteTest` in `tests/site_test.rb`:

```ruby
  def test_aim42_css_is_generated_with_modern_color_functions
    css = File.read(File.join(SITE_DIR, "assets/css/aim42.css"))
    assert_includes css, "--phase-analyze:", "palette tokens missing from aim42.css"
    assert_includes css, "color-mix(", "libsass must pass color-mix() through unchanged"
  end

  def test_glossary_uses_the_aim42_layout
    doc = page("/glossary/")
    assert_equal "Glossary", doc.at_css("h1.section-hero__title")&.text&.strip
    assert doc.at_css("header.site-header nav.site-primary-nav a[href='/patterns/']"), "primary nav missing"
    assert doc.at_css("footer.site-footer"), "aim42 footer missing"
    assert doc.at_css("h3#system"), "glossary anchor #system missing"
    assert doc.at_css("link[href='/assets/css/aim42.css']"), "aim42 stylesheet not linked"
  end
```

Also make `make unit` run the contrast test — change the `unit` recipe to:

```make
unit:
	$(RUN) bundle exec ruby -e 'ARGV.each { |t| require File.expand_path(t) }' tests/validate_test.rb tests/contrast_test.rb
```

- [ ] **Step 12: Build and run all checks**

Run: `make check`
Expected: validator OK, unit tests pass (16 runs), site tests pass (4 runs).

If `jekyll build` fails with an SCSS error:
- `Undefined variable` → the named variable lives in a Q42 partial that was not copied; add the variable to the aim42 block in `_variables.scss` with a sensible value rather than copying more partials.
- A parse error on `color-mix(` → libsass cannot pass it through. Fallback: in `_section-hero.scss` delete every `background: color-mix(...)` line (the preceding `background: var(--brand-paper)` line remains the wash); the test `test_aim42_css_is_generated_with_modern_color_functions` then changes its second assertion to `refute_includes css, "color-mix("` with a comment explaining why.

- [ ] **Step 13: Commit**

```bash
git add _sass assets/css/aim42.scss assets/js/aim42.js assets/fonts _layouts/aim42-base.html _layouts/aim42-page.html _includes/aim42 _pages/reference/glossary.md _data/navigation.yml tests Makefile
git commit -m "Add aim42 theme scaffold ported from quality.arc42.org, palette, glossary

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Pattern collection, layout, and the first three patterns

**Files:**
- Modify: `_config.yml` (collection + default layout), `tests/site_test.rb`
- Create: `_layouts/pattern.html`, `_includes/aim42/stub-notice.html`, `_includes/aim42/related-patterns.html`, `_patterns/stakeholder-interview.md`, `_patterns/stakeholder-analysis.md`, `_patterns/assertions.md`

**Interfaces:**
- Consumes: layout `aim42-base`, include `aim42/section-hero.html`, `site.data.phases`, CSS classes from `_patterns.scss`.
- Produces: collection `site.patterns` (documents with `title`, `phase`, `intent`, `status`, `related`, `categories`, `url`), layout `pattern`, include `aim42/related-patterns.html` (param `page`), include `aim42/stub-notice.html` (param `page`).

- [ ] **Step 1: Write the failing site tests**

Add to `class SiteTest`:

```ruby
  def test_pattern_page_renders_title_intent_and_phase
    doc = page("/patterns/stakeholder-interview/")
    assert_equal "Stakeholder Interview", doc.at_css("h1.section-hero__title")&.text&.strip
    assert_equal "analyze", doc.at_css("header.section-hero")["data-section"]
    assert_equal "/patterns/analyze/", doc.at_css(".section-hero__eyebrow a")["href"]
    assert_includes doc.at_css(".pattern-meta p").text, "Learn from the people"
    assert doc.at_css(".post-content h2"), "body headings missing"
    refute doc.at_css(".stub-notice"), "complete pattern must not show the stub notice"
    edit = doc.at_css("a.pattern-edit__link")
    assert_equal "https://github.com/aim42/aim42.org-site/edit/master/_patterns/stakeholder-interview.md", edit["href"]
  end

  def test_related_patterns_render_in_both_directions
    interview = page("/patterns/stakeholder-interview/")
    assert interview.at_css(".pattern-related a[href='/patterns/stakeholder-analysis/']"), "forward relation missing"
    analysis = page("/patterns/stakeholder-analysis/")
    assert analysis.at_css(".pattern-related a[href='/patterns/stakeholder-interview/']"), "reverse relation missing"
  end

  def test_stub_pattern_shows_contribution_notice
    doc = page("/patterns/assertions/")
    notice = doc.at_css(".stub-notice")
    assert notice, "stub notice missing"
    assert_includes notice.text, "stub"
    assert notice.at_css("a[href*='/edit/master/_patterns/assertions.md']"), "edit link missing from stub notice"
    assert doc.at_css(".section-hero__chips .tag--stub"), "stub chip missing"
  end

  def test_pattern_with_categories_renders_at_flat_url
    doc = page("/patterns/assertions/")
    assert_equal "improve", doc.at_css("header.section-hero")["data-section"]
    refute site_file("/architecture-and-code/assertions/"), "categories must not change the pattern URL"
  end
```

Run: `make site-test`
Expected: the four new tests fail (`expected /patterns/stakeholder-interview/ to be generated`).

- [ ] **Step 2: Register the collection in `_config.yml`**

Replace the line `# Collections:` with:

```yaml
# Collections:
collections:
  patterns:
    output: true
    permalink: /patterns/:name/
    sort_by: title
```

Append to the existing `defaults:` list:

```yaml
  - scope:
      path: ""
      type: patterns
    values:
      layout: pattern
```

- [ ] **Step 3: Write the includes**

`_includes/aim42/stub-notice.html`:

```html
<aside class="stub-notice" role="note">
  <p>
    <strong>This practice is a stub.</strong> It has a name and an intent, but no description yet.
    <a href="https://github.com/{{ site.repository }}/edit/master/{{ include.page.path }}">Help us write it</a>
    or <a href="https://github.com/{{ site.repository }}/issues/new?title={{ include.page.title | uri_escape }}&amp;body=I%20can%20contribute%20to%20this%20pattern.">open an issue</a>.
  </p>
</aside>
```

`_includes/aim42/related-patterns.html` (forward links from `related`, plus reverse links from patterns that list this one):

```html
{% assign me = include.page.url | split: "/" | last %}
{% assign none = "" | split: "" %}
{% assign forward = include.page.related | default: none %}
{% assign reverse = none %}
{% for other in site.patterns %}
  {% assign other_slug = other.url | split: "/" | last %}
  {% if other_slug != me and other.related contains me %}
    {% unless forward contains other_slug %}
      {% assign reverse = reverse | push: other_slug %}
    {% endunless %}
  {% endif %}
{% endfor %}
{% assign all = forward | concat: reverse %}
{% if all.size > 0 %}
<section class="pattern-related-section">
  <h2 class="section-heading">Related patterns</h2>
  <ul class="pattern-related">
    {% for slug in all %}
      {% for other in site.patterns %}
        {% assign other_slug = other.url | split: "/" | last %}
        {% if other_slug == slug %}
          <li>
            <a href="{{ other.url | relative_url }}">{{ other.title }}</a>{% if other.status == "stub" %} <span class="tag tag--stub">stub</span>{% endif %}
            <p class="pattern-list__intent">{{ other.intent }}</p>
          </li>
        {% endif %}
      {% endfor %}
    {% endfor %}
  </ul>
</section>
{% endif %}
```

- [ ] **Step 4: Write the pattern layout `_layouts/pattern.html`**

```html
---
layout: aim42-base
---
{% assign phase = site.data.phases[page.phase] %}
{% capture chips %}{% if page.categories %}{% for category in page.categories %}<span class="tag">{{ category }}</span>{% endfor %}{% endif %}{% if page.status == "stub" %}<span class="tag tag--stub">stub</span>{% endif %}{% endcapture %}
<div class="article-wrapper">
  <article>
    {% include aim42/section-hero.html
      section=page.phase
      title=page.title
      eyebrow_label=phase.title
      eyebrow_href=phase.url
      chips_html=chips %}

    {% if page.status == "stub" %}
      {% include aim42/stub-notice.html page=page %}
    {% endif %}

    <div class="pattern-meta">
      <h2 class="pattern-meta__title">Intent</h2>
      <p>{{ page.intent }}</p>
    </div>

    <section class="post-content">
      {{ content }}
    </section>

    {% include aim42/related-patterns.html page=page %}

    <p class="pattern-edit">
      Found a mistake or want to add your experience?
      <a class="pattern-edit__link" href="https://github.com/{{ site.repository }}/edit/master/{{ page.path }}">Edit this pattern on GitHub</a>.
    </p>
  </article>
</div>
```

- [ ] **Step 5: Write the first three patterns**

`_patterns/stakeholder-interview.md` (from `$M/src/main/asciidoc/patterns/analyze/stakeholder-interview.adoc`):

```markdown
---
title: Stakeholder Interview
phase: analyze
intent: Learn from the people who know or care about the system and everything around it.
related: [stakeholder-analysis]
# phase 2 restores: questionnaire, pre-interview-questionnaire, stakeholder-specific-communication
status: complete
---

Conduct personal interviews with key persons of the [system](/glossary/#system)
or associated processes to identify, clarify or discuss potential issues and
remedies.

## Description

Conduct a [Stakeholder Analysis](/patterns/stakeholder-analysis/) first to find
out whom to interview.

Apply a breadth-first strategy, speak with people from different departments,
roles, management levels. Include at least business people, IT and business
managers, end users, developers, testers, customer service, subject-matter
experts.

Plan the interview dates at least 5–10 days in advance, choose a quiet
location, make sure nobody can overhear your interviews.

If possible, send out a stakeholder- or role-specific *pre-interview
questionnaire* some days in advance.

Ensure a no-stress and no-fear situation. Never have top managers or
supervisors present during interviews of their subordinates. Explain your
positive intent and your role in the improvement project. Have water and
cookies at hand. Make your interview partners feel comfortable and relaxed. Be
honest and humble. *Never* ever promise something you cannot guarantee!

Ask open questions.

Record or take notes of questions and answers.

Some typical questions:

* What is your role in this project?
* What is great about the system, the business and the processes?
* What worries you about the system? What are currently the 3 worst problems?
* What problems or risks do you see in (business/development/operation/usage…)?
  * Can you show/demonstrate this problem?
  * How can I reproduce this problem myself?
  * When/where does it occur?
  * What are the consequences of this problem? Who cares about this problem?
  * How can we/you/somebody overcome this problem?
* How are the processes working? What are the differences between *theory*
  and *practice*?
* If you had time, money and qualified people, what top-3 measures do you
  propose?
* Is there anyone you think we need to speak with who isn't on our list?
* How would you like to be involved in the rest of this project, and what's
  the best way to reach you?

In case people told you about severe problems, try to experience or see those
problems yourself. At the end of the interview, give short feedback and
summarize important results to ensure you understood your interview partner
correctly.

## Experience

Expect the usual difficulties in human communication: people will love or
dislike your work, the interview or the intent of your endeavour.

* Some people will hold back information, either accidentally or deliberately.
* You have to create the *big picture* yourself. Most people tend to focus on
  their specific issues.
* Double-check critical statements, as some people might exaggerate.

## References

* [A stakeholder interview checklist](http://boxesandarrows.com/a-stakeholder-interview-checklist)
  (Boxes and Arrows) — nice checklists for several kinds of stakeholder interviews
```

`_patterns/stakeholder-analysis.md` (from `patterns/analyze/stakeholder-analysis.adoc`):

```markdown
---
title: Stakeholder Analysis
phase: analyze
intent: Ensure that all concerned parties are addressed.
# phase 2 restores: stakeholder-specific-communication
status: complete
---

Find out which people, roles, organizational units or organizations have
interests in the [system](/glossary/#system).

## Description

Get an initial list of stakeholders from project management.

Distinguish between *roles* and *individuals*. Some stakeholders need to be
addressed individually; for *roles* it might be sufficient to identify any of
several possible representatives.

Take the following list as examples of *roles*:

<small>top management, business management, project management, product
management, process management, client, subject-matter expert, business
experts, business development, enterprise architect, IT strategy, lead
architect, developer, tester, QA representative, configuration manager, release
manager, maintenance team, external service provider, hardware designer, rollout
manager, infrastructure planner, infrastructure provider, IT administrator, DB
administrator, system administrator, security or safety representative, end
user, hotline, service technician, scrum master, product owner, business
controller, marketing, related projects, public or government agency,
authorities, standard bodies, external service or interface providers, industry
or business associations, trade groups, competitors</small>

Include those stakeholders in a simple table:

| Role/Name | Description | Intention | Contribution | Contact |
|---|---|---|---|---|
| name of person or role | responsibility for the system | intention for/with/against the system | what they can, will or need to contribute to the improvement, optional or required | how to contact; for roles, name a primary contact person |

## Experience

There are often more stakeholder roles involved than is obvious. Especially
people not directly involved in project or development work are sometimes
forgotten, e.g. standard bodies, external organizations, competitors, press or
media, legal department, employee organization.

## References

* Section *Stakeholders* of the
  [arc42 template, Introduction and Goals](https://github.com/arc42/arc42-template/blob/master/EN/asciidoc/src/01_introduction_and_goals.adoc)
```

`_patterns/assertions.md` (stub; the one-liner is from `pattern-index.adoc`):

```markdown
---
title: Assertions
phase: improve
categories: [architecture-and-code]
intent: Use assertions to verify preconditions and to make a program fail early when something goes fundamentally wrong.
status: stub
---
```

- [ ] **Step 6: Validate, build, test**

Run: `make check`
Expected: `patterns OK`; all site tests pass (8 runs).

- [ ] **Step 7: Commit**

```bash
git add _config.yml _layouts/pattern.html _includes/aim42 _patterns tests/site_test.rb
git commit -m "Add patterns collection with layout, stub notice and first three patterns

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: ATAM, Strangler Approach, Improvement Backlog with images

**Files:**
- Create: `images/patterns/approach-of-atam.png`, `images/patterns/strangulation.jpg`, `images/patterns/improvement-backlog.jpg`, `_patterns/atam.md`, `_patterns/strangler-approach.md`, `_patterns/improvement-backlog.md`
- Modify: `tests/site_test.rb`

**Interfaces:**
- Consumes: layout `pattern`, glossary anchors, phase page URLs from `_data/phases.yml` (the phase pages themselves arrive in Task 6; the link check in this task therefore covers images and glossary/pattern links only).

- [ ] **Step 1: Write the failing tests**

Add to `class SiteTest`:

```ruby
  PILOT_PATTERNS = %w[stakeholder-interview stakeholder-analysis atam strangler-approach assertions improvement-backlog].freeze

  def test_all_pilot_patterns_are_generated
    PILOT_PATTERNS.each { |slug| page("/patterns/#{slug}/") }
  end

  def test_pattern_images_exist
    PILOT_PATTERNS.each do |slug|
      page("/patterns/#{slug}/").css(".post-content img").each do |img|
        src = img["src"]
        assert File.file?(File.join(SITE_DIR, src)), "#{slug}: image #{src} missing from _site/"
      end
    end
  end

  def test_pattern_links_to_glossary_and_patterns_resolve
    PILOT_PATTERNS.each do |slug|
      page("/patterns/#{slug}/").css(".post-content a[href^='/']").each do |a|
        href = a["href"]
        next unless href.start_with?("/glossary", "/patterns/")
        assert site_file(href), "#{slug}: dead internal link #{href}"
        if href.include?("#")
          anchor = href.split("#").last
          assert page(href.split("#").first).at_css("##{anchor}"), "#{slug}: anchor ##{anchor} missing in #{href}"
        end
      end
    end
  end
```

Run: `make site-test`
Expected: `test_all_pilot_patterns_are_generated` fails for `atam`.

- [ ] **Step 2: Copy the images**

```bash
M=/Users/gernotstarke/projects/aim42/method-reference
mkdir -p images/patterns
cp $M/src/main/resources/images/approach-of-atam.png $M/src/main/resources/images/strangulation.jpg $M/src/main/resources/images/improvement-backlog.jpg images/patterns/
```

- [ ] **Step 3: Write `_patterns/atam.md`** (from `patterns/analyze/atam.adoc`)

```markdown
---
title: ATAM
phase: analyze
intent: Apply the ATAM method to evaluate the software architecture regarding its compliance with quality goals.
# phase 2 restores: qualitative-analysis, capture-quality-requirements
status: complete
---

Architecture Tradeoff Analysis Method. Systematic approach to find
architectural risks, tradeoffs and sensitivity points.

## Description

The ATAM method consists of four phases as shown in the diagram "Approach of ATAM".

![Approach of ATAM](/images/patterns/approach-of-atam.png)

The phases are:

1. **Preparation**
   1. *Identify the relevant stakeholders*: The specific goals of the relevant
      stakeholders define the primary goals of the architecture. Who belongs to
      these *relevant* stakeholders has to be determined by a
      [Stakeholder Analysis](/patterns/stakeholder-analysis/).
2. **Kickoff**
   1. *Present the ATAM method*: Convince the relevant stakeholders of the
      significance of comprehensible and specific architecture and quality
      goals. ATAM helps identify risks, non-risks, tradeoffs and sensitivity
      points. Calculation of quantitative attributes is not subject of this
      method.
   2. *Present the business objectives and architecture goals*: Present the
      business context to the relevant stakeholders, especially the *business
      motivation and reasons* for the development of the system. Clarify
      specific requirements that the architecture should meet, for instance
      flexibility, modifiability and performance.
   3. *Present the architecture of the system*: The architect presents the
      *architecture* of the system. This includes:
      * all other systems with interactions to the [system](/glossary/#system),
      * building blocks of the top abstraction level,
      * runtime views of some important use cases,
      * change or modification scenarios.
3. **Evaluation**
   1. *Explain in detail the architecture approaches*: The following questions
      are answered by the architect or developers:
      * How are the relevant quality requirements achieved within the
        architecture or the implementation?
      * What are the structures and concepts solving the relevant problems or
        challenges?
      * What are the important design decisions of the architecture?
   2. *Create a quality tree and scenarios*: In the context of a creative
      brainstorming the stakeholders develop the relevant required quality
      goals. These are arranged in a quality tree. Afterwards the quality
      requirements and architecture goals of the system are refined by
      scenarios which are added to the quality tree. The found scenarios are
      prioritized according to their business value.
   3. *Analyze the architecture approaches with respect to the scenarios*:
      Based on the priorities of the scenarios the evaluation team examines
      together with the architect or developers how the architecture
      approaches support the considered scenario. The findings of the analysis
      are:
      * existing risks concerning the attainment of the architecture goals,
      * non-risks, which means that the quality requirements are achieved,
      * tradeoff points: decisions that affect some quality attributes
        positively and others negatively,
      * sensitivity points: elements of the architecture that have formative
        influence on the quality attributes.
4. **Follow-up**
   1. *Present the results*: Creation of a report with:
      * architectural approaches
      * quality tree with prioritized scenarios
      * risks
      * non-risks
      * tradeoffs
      * sensitivity points

## Experiences

The ATAM method:

* provides operational, specific quality requirements,
* discloses important architectural decisions of the [system](/glossary/#system),
* promotes the communication between relevant stakeholders.

> **Important:** The ATAM method does not develop concrete measures, strategies
> or tactics against the found risks.

ATAM has been successfully applied by many organizations to a variety of
systems. It is widely regarded as the most important systematic approach to
qualitative system/architecture analysis.[^1]

[^1]: The original authors of ATAM call it an *evaluation* method, whereas
    aim42 classifies ATAM as belonging to the category of analysis practices.

## Applicability

Evaluate an architecture:

* as soon as possible,
* already in the construction phase,
* better not after the completion of the system.
```

- [ ] **Step 4: Write `_patterns/strangler-approach.md`** (from `patterns/improve/strangler-approach.adoc`; the empty "Consequences" section is dropped)

```markdown
---
title: Strangler Approach
phase: improve
categories: [approaches]
intent: Divide a legacy system into different functional domains and replace those step by step.
# phase 2 restores: big-bang-approach
status: complete
---

## Description

Rewriting an old system with a *big-bang approach* is a risky endeavor. It is
harder than you might think at the beginning.

An alternative way is to gradually create a new system around the edges of the
old, letting it grow slowly over several years until the old system is
strangled. The most important reason to consider a strangler application over
a cut-over rewrite is reduced risk (it might cost more to do a strangler, but
that's the price of risk reduction) [1].

Paul Hammant depicts the strangler approach as follows [2]:

![Strangler Applications (Paul Hammant)](/images/patterns/strangulation.jpg)

He discusses two ways of achieving the goal of moving from the (red) old system
to the (blue) new system:

1. with adding new features,
2. without adding new features.

Deciding to go for the first strategy means that you can still keep your
business happy because you are still able to deliver new features. However,
this approach will take longer than the second one.

## Experiences

* Paul Hammant reports the following positive
  [case studies](http://paulhammant.com/2013/07/14/legacy-application-strangulation-case-studies/):
  * Airline booking system: the C++ application, which was stable but hard to
    grow (and to find developers for), has been incrementally replaced by a
    Spring stack based application. A load balancer routed the requests to
    either the C++ or the Spring application. They introduced a session store
    used by both systems (the C++ application needed to be adjusted for this).
  * Trading company's PowerBuilder based rich client: you cannot integrate a
    new rich client into an old one, so the team decided to run two client
    applications in parallel for the energy traders, adding more and more
    functionality to the new (Swing-based) client. The users weren't forced to
    use one or the other, but the team made the new application so compelling
    that they wanted to. Google is (as I heard from a Googler) doing similar
    approaches to their internal systems, which are replaced by new systems all
    the time, and you need to decide when to switch.
  * National supermarket's internal planning system based on Swing and a major
    database is moving into a Rails and Java microservices based web
    application. Since the two technologies are also very different, there is
    no smooth way of integrating the old and the new system; they have to
    exist in parallel (it is an internal system).
  * Used consumer goods magazine's web portal: a move from Oracle Endeca to
    Java/JavaScript. First, they changed the Oracle frontend so that it looks
    like the new system. Then they integrated a little piece of new
    functionality from the new stack into the website. The first strangler
    release took 6 months, then they delivered regularly.
* Nat Pryce reports failed projects and challenges using the strangler pattern [3]:
  * "I've seen critical systems that have suffered both of these fates, and
    ended up with about four or five 'strategic architectural directions' and
    'future state architectures'. One large multi-site project ended up with
    eight different new persistence mechanisms in its new architecture."
  * "Another ended up with two different database schemas, one for the old way
    of doing things and another for the new way, neither schema was ever
    removed from the system and there were also multiple class hierarchies
    that mapped to one or even both of these schemas."

## Risks

* You need to overcome the lack of will to actually finish the strangling
  (usually political will from non-technical stakeholders manifested as lack
  of budget). If you don't completely kill off the old system, you'll end up
  in a worse mess because your system now has two ways of doing everything
  with an awkward interface between the two. Later, another wave of developers
  will probably decide to strangle what's there, writing yet another strangler
  application, and again a lack of will might leave the system in an even
  worse state, with three ways of doing things [1].
* You need to have consensus across the development team(s) on the future
  state of the architecture and how to get there. If everyone runs in another
  direction, then you end up with a new system which is also hard to maintain.
* If you're introducing technologies that are new to the team or to
  support/maintenance staff (e.g. adding reliable async messaging to what is
  currently a synchronous three-tier client/server architecture) then you have
  to ensure that there are experienced technical leads on the project who know
  how to build systems with that technology and support those systems. And
  those tech leads have to stick with the project for some time after the old
  app has been fully strangled. Otherwise, the architecture will degrade as
  inexperienced developers modify it in ways they know but not in ways that
  fit with the new architecture [1].
* Strangling creates a layer of goo and there is a risk that this layer
  becomes a mess, too.

## Applicability

* A big-bang replacement is too risky and/or your business wants you to
  constantly deliver new features and does not accept a 1–3 year break for the
  big rewrite.
* The "cost of delay" of not moving to the new platform as early as possible
  is higher than the cost of running two systems in parallel.

## Proposed practices

Paul Hammant recommends the following practices [2]:

* You really should phase the strangulation. Keep your larger application in a
  continually deployable state while working on it. The first go-live after a
  month or so of work, then every two weeks after that at least, or you'll
  fail — probably via project cancellation by a checkbook-holding sponsor.
* Do enhancements or new "business value" work concurrently with
  strangulation, while getting all to agree that both are happening. As you
  work on the strangulation, a decent percentage of work should be
  enhancements too. This allows value to be associated with each release from
  the point of view of the people paying for it. ROI and all that isn't just
  abandonment of costly end-of-life IT choices, it is about tangible changes
  for the better. From top to bottom, everyone needs to agree that both are
  happening.
* The addition of integration and functional test suites as a safety net is
  key. This is particularly true when the old technology did not have unit
  test coverage. The functional tests will be able to step between old and new
  (and back), to prevent surprises.
* Understand that non-functional requirements (NFRs) that don't directly
  cheapen the re-implementation may jeopardize the initiative — jeopardize in
  the "courting cancellation" territory again. Various authority figures may
  have pet technologies to include or things to exclude. The test is whether
  the dev team cranking stuff out agrees or not.
* Agile methodologies optimize everything for maximized developer throughput
  and phased deliveries to production. You will not manage this with
  waterfall, unless you want glacially long intervals between production
  pushes. The [Pols/Stevenson white paper](http://cdn.pols.co.uk/papers/agile-approach-to-legacy-systems.pdf)
  drills much further into the agile aspects.
* Lastly, you should always be aware that there could be functionality and
  context hidden within the old application that people have forgotten about,
  and that a team of business analysts assigned to reverse engineering
  behaviors might also miss. This is a risk for any "rewrite" though.

## Related

* Replaceable Component Architecture

## References

* [1] Martin Fowler [about the Strangler Application](https://www.martinfowler.com/bliki/StranglerApplication.html)
* [2] Paul Hammant's [blog post](http://paulhammant.com/2013/07/14/legacy-application-strangulation-case-studies/) with practices and case studies
* [3] [Discussion on StackOverflow](https://stackoverflow.com/questions/1118804/application-strangler-pattern-experiences-thoughts) with Nat Pryce and Ira Baxter
* Michael Feathers speaks on [Hanselminutes](https://www.hanselman.com/blog/HanselminutesPodcast165WorkingEffectivelyWithLegacyCodeWithMichaelFeathers.aspx) about the Strangler Application
```

- [ ] **Step 5: Write `_patterns/improvement-backlog.md`** (from `patterns/crosscutting/improvement-backlog.adoc`)

```markdown
---
title: Improvement Backlog
phase: crosscutting
intent: Collect all known issues and problems within a system or its associated processes, and make them comparable by evaluating each one.
# phase 2 restores: issue-list
status: complete
---

Keep a public, written backlog of possible improvements, remedies, tactics or
strategies.

* Revise this backlog in regular intervals.
* Define the *owner role* for this backlog, similar to the *product owner* in
  Scrum.
* Enhance the backlog with information from the
  [Evaluate](/patterns/evaluate/) phase, like cost, effort or risk.

![Improvement Backlog](/images/patterns/improvement-backlog.jpg)

## Description

Collect all known issues and problems within a system or its associated
processes. Make the issues comparable by evaluating each one, usually using
economical units like money or time. Align carefully with the *issue list*.

## Content

| ID | Improvement | Description | min cost | max cost | Related issues |
|---|---|---|---|---|---|
| identifier | name | short description of this improvement or remedy | minimal estimated cost or effort | maximal cost or effort | links to related issues |

## Representation and tools

Try to use a documentation approach similar to the *issue list*. It should be
as easy as possible to link issues to improvements and vice versa.
```

- [ ] **Step 6: Validate, build, test**

Run: `make check`
Expected: all pass. (`test_pattern_links_to_glossary_and_patterns_resolve` skips `/patterns/evaluate/` only because the check is restricted to `/glossary` and `/patterns/<slug>/` paths that exist; Task 6 adds the phase pages and widens the check.)

- [ ] **Step 7: Commit**

```bash
git add images/patterns _patterns tests/site_test.rb
git commit -m "Add ATAM, Strangler Approach and Improvement Backlog pilot patterns

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Patterns index and phase pages

**Files:**
- Create: `_includes/aim42/pattern-list.html`, `_pages/patterns/index.md`, `_pages/patterns/analyze.md`, `_pages/patterns/evaluate.md`, `_pages/patterns/improve.md`, `_pages/patterns/crosscutting.md`, `images/patterns/analyze-patterns-overview.png`
- Modify: `tests/site_test.rb`

**Interfaces:**
- Consumes: `site.patterns`, `site.data.phases`, layout `aim42-page`.
- Produces: include `aim42/pattern-list.html` (optional param `phase`); pages `/patterns/`, `/patterns/<phase>/`.

- [ ] **Step 1: Write the failing tests**

Add to `class SiteTest`:

```ruby
  def test_index_lists_every_pattern_with_phase_cards
    doc = page("/patterns/")
    titles = doc.css(".pattern-list__title a").map { |a| a.text.strip }
    assert_equal ["ATAM", "Assertions", "Improvement Backlog", "Stakeholder Analysis", "Stakeholder Interview", "Strangler Approach"], titles
    assert_equal 4, doc.css(".phase-card").size
    assert doc.at_css(".phase-card[data-phase='analyze'] a[href='/patterns/analyze/']")
    stub_item = doc.css(".pattern-list__item").find { |li| li.text.include?("Assertions") }
    assert stub_item.at_css(".tag--stub"), "stub badge missing on the index"
  end

  def test_phase_page_lists_only_its_patterns
    doc = page("/patterns/analyze/")
    assert_equal "analyze", doc.at_css("header.section-hero")["data-section"]
    titles = doc.css(".pattern-list__title a").map { |a| a.text.strip }
    assert_equal ["ATAM", "Stakeholder Analysis", "Stakeholder Interview"], titles
    assert doc.at_css(".post-content h2"), "phase prose (Goals / How it works) missing"
  end

  def test_every_phase_page_exists
    %w[analyze evaluate improve crosscutting].each do |phase|
      doc = page("/patterns/#{phase}/")
      assert_equal phase, doc.at_css("header.section-hero")["data-section"]
    end
  end

  def test_internal_links_on_new_pages_resolve
    urls = ["/patterns/", "/glossary/"] + %w[analyze evaluate improve crosscutting].map { |p| "/patterns/#{p}/" } + PILOT_PATTERNS.map { |s| "/patterns/#{s}/" }
    urls.each do |url|
      page(url).css("a[href^='/']").each do |a|
        href = a["href"]
        next if href.start_with?("/images/") || href.start_with?("/assets/")
        assert site_file(href), "#{url}: dead internal link #{href}"
      end
    end
  end
```

Run: `make site-test`
Expected: the four new tests fail.

- [ ] **Step 2: Write the list include `_includes/aim42/pattern-list.html`**

```html
{% assign items = site.patterns | sort: "title" %}
{% if include.phase %}
  {% assign items = items | where: "phase", include.phase %}
{% endif %}
{% if items.size > 0 %}
<ul class="pattern-list">
  {% for pattern in items %}
    <li class="pattern-list__item">
      <p class="pattern-list__title">
        <a href="{{ pattern.url | relative_url }}">{{ pattern.title }}</a>
        {% if pattern.status == "stub" %}<span class="tag tag--stub">stub</span>{% endif %}
        {% unless include.phase %}<span class="tag">{{ site.data.phases[pattern.phase].title }}</span>{% endunless %}
      </p>
      <p class="pattern-list__intent">{{ pattern.intent }}</p>
    </li>
  {% endfor %}
</ul>
{% else %}
<p>No patterns in this phase yet.</p>
{% endif %}
```

- [ ] **Step 3: Write the index page `_pages/patterns/index.md`**

```markdown
---
title: Patterns and Practices
layout: aim42-page
section: patterns
permalink: /patterns/
lede: aim42 collects proven practices and patterns to analyze, evaluate and improve software systems and the organizations around them.
---

{% assign total = site.patterns | size %}
{% assign stubs = site.patterns | where: "status", "stub" | size %}
{% assign phases = site.data.phases | sort: "order" %}

<ul class="phase-list">
{% for entry in phases %}
  {% assign key = entry[0] %}
  {% assign phase = entry[1] %}
  {% assign count = site.patterns | where: "phase", key | size %}
  <li class="phase-card" data-phase="{{ key }}">
    <h2><a href="{{ phase.url | relative_url }}">{{ phase.title }}</a></h2>
    <p>{{ phase.blurb }}</p>
    <p><b>{{ count }}</b> {% if count == 1 %}pattern{% else %}patterns{% endif %}</p>
  </li>
{% endfor %}
</ul>

<p class="section-hero__meta"><b>{{ total }}</b> patterns and practices, of which <b>{{ stubs }}</b> are stubs waiting for contributors. This is the pilot of the migrated method reference; the complete reference follows.</p>

## All patterns, A–Z

{% include aim42/pattern-list.html %}
```

Note: `site.data.phases | sort: "order"` sorts the hash's `[key, value]` pairs by `value.order` — Jekyll's `sort` filter handles hashes this way; if the build errors on it, replace the three `assign` lines with `{% assign phases = site.data.phases %}` and the `for` loop keeps working in file order (which already is 1–4).

- [ ] **Step 4: Copy the analyze overview image and write the phase pages**

```bash
cp /Users/gernotstarke/projects/aim42/method-reference/src/main/resources/images/analyze-patterns-overview.png images/patterns/
```

`_pages/patterns/analyze.md` (prose from `$M/src/main/asciidoc/analyze.adoc`; the HTML image map becomes a plain image):

```markdown
---
title: Analyze
layout: aim42-page
section: analyze
eyebrow_label: Phase
eyebrow_href: /patterns/
permalink: /patterns/analyze/
lede: Find issues, risks and technical debt in the system and its organization, and understand their root causes.
---

## Goals

1. Obtain an overview of intent, purpose and quality requirements of the
   [system](/glossary/#system).
2. Develop and document an understanding of internal structures, concepts and
   architectural approaches.
3. Find all problems, issues, symptoms, risks or technical debt within the
   system, its operation, maintenance or otherwise related processes.
4. Understand root causes of the problems found, and potential
   interdependencies between issues.

## How it works

Look systematically for such issues at various places and with support of
various people.

> **Tip:** To effectively find issues, you need an appropriate amount of
> *understanding* of the system under design, its technical concepts, code
> structure, inner workings, major external interfaces and its development
> process.

One serious risk in this phase is a premature restriction to certain artifacts
or aspects of the system: if you search with a microscope, you're likely to
miss several aspects.

![Overview of the most important analysis practices](/images/patterns/analyze-patterns-overview.png)

Always begin with a [Stakeholder Analysis](/patterns/stakeholder-analysis/),
then conduct [Stakeholder Interviews](/patterns/stakeholder-interview/) with
important stakeholders.

Improve your *architectural understanding* of the system by

* context analysis,
* documentation analysis — read especially the architecture documentation,
  focus on view-based understanding,
* development-process analysis,
* static code analysis, to learn about code structure *in the large*; this
  also helps to identify risky code.

Then

* capture quality requirements from the *authoritative* stakeholders of the
  system,
* conduct a qualitative analysis of the system, its architecture and the
  associated organization, based upon the specific quality requirements —
  inspect and analyze all involved organizational processes (development,
  project management, operations, requirements analysis),
* perform runtime analysis or quantitative analysis, e.g. performance and load
  monitoring, process and thread analysis — inspect the data created, modified
  and queried by the system for structure, size, volume or specialities.

Finally, conduct a root cause analysis for the discovered major issues in
close collaboration with the appropriate stakeholders.

> **Warning:** Never start solving problems until you have a thorough
> understanding of the current stakeholder requirements. Otherwise you risk
> wasting effort in areas which no influential stakeholder cares about.

## Patterns and practices for analysis

{% include aim42/pattern-list.html phase="analyze" %}
```

`_pages/patterns/evaluate.md`:

```markdown
---
title: Evaluate
layout: aim42-page
section: evaluate
eyebrow_label: Phase
eyebrow_href: /patterns/
permalink: /patterns/evaluate/
lede: Make issues and remedies comparable by estimating their value, cost and risk, then prioritize.
---

## Goals

Make the issues, problems and risks found during [analysis](/patterns/analyze/)
comparable by estimating or measuring their *value* (that's why we call this
activity *evaluate*):

1. estimate the *value* of problems, issues, risks and their remedies,
2. prioritize issues, their remedies and improvement measures.

Usually, evaluation implies *estimation*; only in few cases can you measure or
observe the evaluation subject and produce *hard facts*.

## Patterns and practices for evaluation

{% include aim42/pattern-list.html phase="evaluate" %}
```

`_pages/patterns/improve.md`:

```markdown
---
title: Improve
layout: aim42-page
section: improve
eyebrow_label: Phase
eyebrow_href: /patterns/
permalink: /patterns/improve/
lede: Apply approaches and practices that eliminate issues, reduce technical debt and optimize quality.
---

## Goals

1. Execute and coordinate the improvement activities to eliminate problems and
   issues found during [analysis](/patterns/analyze/). There is a whole bunch
   of practices devoted to this step, and several approaches you can take to
   run the improvements.
2. Apply selected opportunities for improvement:
   * change code, structures, concepts or processes to achieve better software,
   * reduce costs and/or technical debt,
   * eliminate all kinds of issues,
   * optimize quality attributes (like performance, maintainability, security),
   * optimize operation and administration processes, thereby reducing effort
     and cost.

## Structure of the improvement phase

*Fundamentals* are principles you should consider whatever steps you take on
your road to improvement. *Approaches* are overall (strategic, long-term)
decisions on how to tackle improvement. *Practices* are fine-grained practices
or patterns, structured in several categories.

## Approaches and practices for improvement

{% include aim42/pattern-list.html phase="improve" %}
```

`_pages/patterns/crosscutting.md`:

```markdown
---
title: Cross-cutting
layout: aim42-page
section: crosscutting
eyebrow_label: Phase
eyebrow_href: /patterns/
permalink: /patterns/crosscutting/
lede: Practices that span all phases and keep issues and improvements visible, understood and aligned.
---

## How it works

1. Start with collecting issues — mainly in the [Analyze](/patterns/analyze/)
   phase. Based upon your findings, maintain an *issue list*.
2. [Evaluate](/patterns/evaluate/) those, determine *values*, preferably cost.
   This ensures you later solve *important* and *relevant* issues.
3. Collect opportunities for improvement and evaluate those too.
4. Align issues and potential improvements; plan improvements in an
   [Improvement Backlog](/patterns/improvement-backlog/).
5. Continuously strive to increase your *architectural understanding*, as this
   facilitates identification of additional issues and improvements.

## Cross-cutting patterns and practices

{% include aim42/pattern-list.html phase="crosscutting" %}
```

- [ ] **Step 5: Validate, build, test**

Run: `make check`
Expected: all tests pass (site tests: 15 runs).

- [ ] **Step 6: Commit**

```bash
git add _includes/aim42/pattern-list.html _pages/patterns images/patterns/analyze-patterns-overview.png tests/site_test.rb
git commit -m "Add patterns index and phase pages

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: CI workflow and contributor documentation

**Files:**
- Create: `.github/workflows/check.yml`
- Modify: `README.md`

**Interfaces:**
- Consumes: `tools/validate.rb`, `tests/*.rb`, `Gemfile.lock` (x86_64-linux platform present).

- [ ] **Step 1: Write the workflow**

`.github/workflows/check.yml`:

```yaml
name: Check site

on:
  push:
    branches: [master, merge-method-reference]
  pull_request:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3" # keep in sync with _docker/jekyll/Dockerfile
          bundler-cache: true

      - name: Validate pattern front matter
        run: ruby tools/validate.rb

      - name: Unit tests
        run: bundle exec ruby -e 'ARGV.each { |t| require File.expand_path(t) }' tests/validate_test.rb tests/contrast_test.rb

      - name: Build site
        run: bundle exec jekyll build
        env:
          JEKYLL_ENV: production

      - name: Site tests
        run: bundle exec ruby tests/site_test.rb
```

- [ ] **Step 2: Document local development and pattern authoring in `README.md`**

Replace the `## HowTo` section (from `## HowTo` up to, not including, `## Site Structure`) with:

```markdown
## Local development

Requirements: [Docker](https://www.docker.com/). No local Ruby needed.

    make build      # once, and after Gemfile.lock changes
    make dev        # serve on http://localhost:4242
    make check      # validate pattern front matter, unit tests, build, site tests

## Adding or editing a pattern

Patterns live in `_patterns/<slug>.md`, one file each; the filename is the URL:
`_patterns/stakeholder-interview.md` → `/patterns/stakeholder-interview/`.

    ---
    title: Stakeholder Interview
    phase: analyze            # analyze | evaluate | improve | crosscutting
    intent: One sentence: what this practice achieves.
    related: [stakeholder-analysis]   # optional, slugs of other patterns
    categories: [approaches]          # optional
    status: complete          # complete | stub
    ---

    Short summary paragraph.

    ## Description
    ...
    ## Experience
    ...
    ## References
    ...

Rules (checked by `ruby tools/validate.rb` and in CI): `title`, `phase`,
`intent` and `status` are required; `related` must list existing slugs; the
filename is a kebab-case slug. A `status: stub` pattern needs only the front
matter; the site shows a "help us write it" box.

Glossary terms link to `/glossary/#term`, e.g. `[system](/glossary/#system)`.
```

- [ ] **Step 3: Run everything once more and commit**

Run: `make check`
Expected: all pass.

```bash
git add .github/workflows/check.yml README.md
git commit -m "Add CI check workflow and pattern authoring docs

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 4: Push the branch and watch the workflow**

Run: `git push -u origin merge-method-reference && gh run watch --exit-status`
Expected: the `Check site` workflow passes. If `bundle install` fails on CI because of the platform list, run `make lock` again (it adds `x86_64-linux`), commit `Gemfile.lock`, push.

---

### Task 8: Preview and palette tuning (handoff to the human partner)

**Files:**
- Possibly modify: `_sass/base/_variables.scss` (tokens), `_sass/pages/_patterns.scss`, `_includes/aim42/site-header.html` (logo)

- [ ] **Step 1: Start the preview**

Run: `make dev`, then open:
- http://localhost:4242/patterns/
- http://localhost:4242/patterns/analyze/
- http://localhost:4242/patterns/stakeholder-interview/ (complete, with related)
- http://localhost:4242/patterns/strangler-approach/ (long, with image and categories chip)
- http://localhost:4242/patterns/assertions/ (stub)
- http://localhost:4242/glossary/
- http://localhost:4242/ (must still be the untouched Minimal Mistakes home page)

- [ ] **Step 2: Review checklist with the human partner**

Walk through and note decisions (the partner decides; the executor applies):
1. Masthead: does `images/aim42-site-logo.png` work on the navy `--brand-primary` background? If not, use a white/transparent variant or text-only brand (`.site-brand__name` only).
2. Phase colours on the hero rails and phase cards: too loud / too dull? Adjust `$phase-*` tokens; `make unit` must stay green (contrast).
3. Stub notice wording and placement.
4. Body typography (Atkinson Hyperlegible + Libre Caslon from Q42): keep or swap.
5. Mobile: open the secondary nav with the toggle at < 720px width; Esc closes it.

- [ ] **Step 3: Apply the tuning, re-run checks, commit**

Run: `make check`

```bash
git add -A _sass _includes/aim42 images
git commit -m "Tune aim42 palette and header after pilot review

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
git push
```

- [ ] **Step 4: Optional shared preview**

If a shareable URL is wanted before the hosting decision: in the Netlify UI for aim42.org, enable *branch deploys* for `merge-method-reference`; Netlify's existing Jekyll build then serves the branch at `https://merge-method-reference--<site-name>.netlify.app`. This is a human action; the plan does not depend on it.

---

## Self-review notes

- Spec §2 (content model): Tasks 2 (validator rules, phases.yml) and 4 (layout, collection, stub box, related). Covered. `permalink` is set once in `_config.yml`, never per file.
- Spec §3 (layout/build): Task 1 (Docker, make), Task 3 (SCSS/layouts under non-colliding names). The spec's "Gemfile moves to Q42's github-pages set" is deferred to phase 3 on purpose: Minimal Mistakes must keep serving the existing pages until the re-skin. The `git subtree` import of the method reference also belongs to phase 2 (bulk content); the pilot hand-copies six files and four images.
- Spec §7 (pilot & theme): Task 3 copies the listed Q42 files, replaces the palette, Task 8 tunes. "Contrast checked with Q42's existing script" became `tests/contrast_test.rb` (Ruby), because the pilot has no Node.
- Spec §9 (validation): validator in `make check` and CI (Task 7); dead-link check limited to the new pages (Task 6) — the full-site link check follows in phase 2.
- Review Focus items 1–5 each have a named test in Tasks 1–4.
