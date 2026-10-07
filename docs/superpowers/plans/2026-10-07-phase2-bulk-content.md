# Phase 2: Bulk Content Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every pattern and every remaining chapter of the aim42 method reference
(AsciiDoc in `aim42/aim42`) into aim42.org-site as Markdown, with all ~540 cross-references
rewritten, the old anchors recorded for the phase-3 redirector, and validation in the build.

**Architecture:** `aim42/aim42` is imported with its history into `_import/` (git subtree).
A one-off converter in `tools/migrate/` turns AsciiDoc into Markdown in three stages:
Asciidoctor parses, Nokogiri normalizes the HTML, kramdown writes Markdown. A hand-curated
manifest (`tools/migrate/manifest.yml`) names every pattern, its slug, title, phase,
categories and source; the anchor table built from it resolves `<<xrefs>>` and is dumped
to `_data/anchors.yml`. Generated files are committed once and then reviewed and edited
by hand, phase by phase. The converter never overwrites an existing file.

**Tech Stack:** Jekyll 4.3.1, Ruby 3.3 in Docker, Asciidoctor 2.x (new, `:migration`
gem group), Nokogiri, kramdown 2.4, Minitest.

**Spec:** `docs/superpowers/specs/2026-10-07-method-reference-merge-design.md` (§2 phase 2,
§4 content model, §5 conversion pipeline, §6 non-pattern content, §9 validation).
Phase 1 plan: `docs/superpowers/plans/2026-10-07-pilot-method-reference.md`.

**Prototype status:** The converter, manifest and all migration tests in this plan were
run against the real sources before the plan was written. The full conversion produced
99 pattern files and 6 reference pages, and its report held 25 notes. With the output in
place, the validator passed, `jekyll build` passed, and 16 of 17 site tests passed. The
one failure was the improve page's section anchors, which Task 6 adds. The 36 migration
tests pass with the site's bundled gem versions (kramdown 2.4.0, minitest 5.15).

## Global Constraints

- Content is Markdown, built by Jekyll only. No Node step. (spec §3)
- Builds and tests run in Docker via `make`, never with Ruby on the host (host Ruby is 4.0).
- The live site stays untouched: never push or merge to `master`. Push only the branch `merge-method-reference`, never force. No PR, no merge.
- Source repos stay read-only:
  - `/Users/gernotstarke/projects/aim42/method-reference` (local clone of aim42/aim42, HEAD `40030cb`)
  - `/Users/gernotstarke/projects/arc42/quality.arc42.org-site`

  The import fetches from `https://github.com/aim42/aim42.git` instead.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- URLs are flat: `/patterns/<slug>/`. Slug = kebab-case (lower-case) of the old anchor. (spec §4)
- Pattern front matter (spec §4, validator):
  - `title`, `phase`, `intent` and `status` are required.
  - `phase` ∈ `_data/phases.yml`.
  - `status` ∈ {complete, stub}.
  - `related` lists existing slugs.
  - `categories` ∈ `_data/categories.yml` (new in Task 2).
  - `intent` is one paragraph of inline Markdown (ruling R10 of phase 1) and is never `TODO`.
- Body headings keep their source names (Description, Experience, References …). Intent lives in front matter. "Related patterns" is rendered from `related`. Related items that add explanation stay in the body under `## Notes on related patterns`. (spec §4)
- Images live in `/images/patterns/` and downloads in `/assets/downloads/`. Glossary terms link to `/glossary/#<term>`. Bibliography entries are `/reference/bibliography/#<key-lowercase>`. (spec §4, §6)
- The six pilot patterns stay hand-converted (stakeholder-interview, stakeholder-analysis, atam, strangler-approach, assertions, improvement-backlog). The converter skips them. They are the oracle for its structure; their deliberate prose edits are not. (spec §5)
- Once committed, a converted file is the source of truth. `tools/migrate/run.rb` never overwrites `_patterns/*.md` or `_pages/reference/*.md`.
- Review tasks fix conversion artifacts and obvious misspellings only. They do not reword, shorten or "improve" the prose. (spec §5: "human review against a diff of the original")
- Out of scope:
  - the D3 graph, hosting, the marketing navigation and the palette;
  - the re-skin of existing pages and the switch from `minimal-mistakes-jekyll` to the `github-pages` gem set;
  - the redirector on aim42.github.io.

  All of these are phase 3. This plan produces `_data/anchors.yml` for the redirector.

## Review Focus

1. **Old links in the wild:** an `aim42.github.io/#Anchor` link to a figure or section anchor, not just a pattern, must resolve to a page *and* a fragment that exist. Pinned by `test_every_old_anchor_resolves` (Task 6).
2. **Meta descriptions:** an intent longer than 160 characters that contains `&`, quotes or a line break must not cut an HTML entity in half or glue words together. Pinned by `tests/meta_text_test.rb` (Task 2).
3. **Re-running the converter:** after files have been hand-edited, a run must not silently destroy the edits. Pinned by `test_existing_files_are_not_overwritten` (Task 5).
4. **Improve categories:** a pattern with two categories (e.g. `keep-data-toss-code`) must appear under both on `/patterns/improve/`. A pattern without a category must appear under "Other". Pinned by `test_improve_page_groups_patterns_by_category` (Task 9).
5. **Stubs:** a stub whose one-liner contains an xref (e.g. `mikado-method`) must render a working link in its intent and no empty body section. Pinned by the site link test over all pattern pages plus `test_stub_without_body_renders_no_empty_section` (Task 2).

## Rulings made while writing this plan

- **R13 — conversion engine.** Spec §5 names `kramdoc`, but kramdoc converts Markdown *to* AsciiDoc. The plan uses Asciidoctor → Nokogiri → kramdown instead. The rest of §5 stands: post-processing, anchor table, report, pilot as oracle. If wrong: the engine is swapped inside `adoc_to_md.rb`; manifest, anchors and tests stay.
- **R14 — manifest.** The pattern set is a hand-curated manifest (105 entries, `docs/superpowers/plans/2026-10-07-phase2-manifest.yml`), not inferred at run time. It was derived from `pattern-index.adoc`, the pattern files and the inline `[pattern]` sections, with titles normalized to Title Case. If wrong: edit one YAML line.
  - Three approach patterns have no intent anywhere. They take the one-liner from `improve-approaches.adoc`, written into the manifest as `intent:`.
- **R15 — orphan.** `patterns/improve/isolate-core-domain.adoc` is not included anywhere in the book and is an older copy of `strangler-approach.adoc`. It is not converted. If wrong: add one manifest entry.
- **R16 — phase pages.** The pilot already hand-wrote `/patterns/{analyze,evaluate,improve,crosscutting}/`. The converter writes chapter drafts to `tools/migrate/out/` (git-ignored), and Task 6 merges the missing sections by hand. If wrong: more manual merging.
- **R17 — line style.** Converted Markdown has one paragraph per line, with no hard wrapping at 80 columns as the pilot did. Wrapping split link and alt texts across lines. If wrong: cosmetic.
- **R18 — history.** `git subtree add` imports the full aim42/aim42 history (882 commits, ~49 MB pack), as spec §3 decides. If wrong: use `--squash` instead.

---

### Task 1: Import the AsciiDoc source and the migration toolchain

**Files:**
- Create: `_import/` (git subtree of aim42/aim42), `assets/downloads/*`, `images/patterns/*` (copied)
- Modify: `Gemfile`, `Gemfile.lock`, `Makefile`, `_config.yml`, `.gitignore`

**Interfaces:**
- Produces:
  - `_import/src/main/asciidoc/` (the book sources) and `_import/src/main/resources/`;
  - gem `asciidoctor` in the bundle;
  - `make migrate` (runs `tools/migrate/run.rb`, created in Task 5).

  Later tasks append their new test files to the `unit:` list in `Makefile` and to the CI "Unit tests" step.

- [ ] **Step 1: Check the upstream head**

Run: `git ls-remote https://github.com/aim42/aim42.git master`
Expected: `40030cb8680d89e08ea41e5839ec2b997b98a970	refs/heads/master`. If it differs, continue with the newer commit and mention its hash in the report.

- [ ] **Step 2: Import with history**

```bash
git subtree add --prefix=_import https://github.com/aim42/aim42.git master \
  -m "$(printf 'Import aim42/aim42 (method reference sources) into _import/\n\nSource for the one-off AsciiDoc to Markdown conversion (spec §3). Removed again after phase 2.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>')"
```

Expected: a merge commit. `ls _import/src/main/asciidoc/index.adoc` exists.
If `git subtree` is unavailable, run these instead:
- `git fetch https://github.com/aim42/aim42.git master`
- `git merge -s ours --no-commit --allow-unrelated-histories FETCH_HEAD`
- `git read-tree --prefix=_import/ -u FETCH_HEAD`
- `git commit` with the same message.

Do not use `--squash` (R18).

- [ ] **Step 3: Keep Jekyll away from the import and the drafts**

In `_config.yml`, append `- _import` to the `exclude:` list (`tools` is already there). Jekyll ignores `_`-prefixed directories anyway, but excluding it keeps `jekyll serve` from watching ~1000 files.

Append to `.gitignore`:

```
tools/migrate/out/
```

- [ ] **Step 4: Copy images and downloads (spec §6)**

```bash
cp -Rn _import/src/main/resources/images/. images/patterns/
mkdir -p assets/downloads
cp _import/src/main/resources/docs/DE-Vorab-Fragebogen.pdf _import/src/main/resources/docs/DE-Vorab-Fragebogen.docx assets/downloads/
cp _import/src/main/resources/whitepaper/AIM42-Whitepaper-v2.0.pdf _import/src/main/resources/whitepaper/AIM42-Whitepaper-v2.0.docx assets/downloads/
cp _import/src/main/resources/CostEffort_in_SW_Development.xlsx assets/downloads/
```

- `-n` keeps the four pilot images, which are byte-identical anyway.
- Check: `md5 -q images/patterns/strangulation.jpg _import/src/main/resources/images/strangulation.jpg` prints two equal hashes.
- The old whitepaper version (`AIM42-Whitepaper.pdf/.docx`) and the whitepaper PNGs are not copied, because nothing links to them.

- [ ] **Step 5: Add Asciidoctor in a migration group**

Append to `Gemfile`:

```ruby
# One-off AsciiDoc conversion (tools/migrate/); removed after phase 2.
group :migration do
  gem "asciidoctor", "~> 2.0"
end
```

Run: `make lock && make build`
Expected:
- `Gemfile.lock` gains `asciidoctor (2.x)` and keeps `BUNDLED WITH 2.5.23`.
- The image rebuilds.

- [ ] **Step 6: Add the `migrate` target**

In `Makefile`:
- Add `migrate` to `.PHONY`.
- Add a help line: `@printf "make migrate    convert the imported AsciiDoc (tools/migrate/run.rb)\n"`.
- Add the target:

```make
migrate:
	$(RUN) bundle exec ruby tools/migrate/run.rb
```

- [ ] **Step 7: Verify nothing broke**

Run: `make unit && make site-test`
Expected: unit 28 runs, site 17 runs, all green, as before.

- [ ] **Step 8: Commit**

```bash
git add Gemfile Gemfile.lock Makefile _config.yml .gitignore images/patterns assets/downloads
git commit -m "Add migration toolchain, pattern images and downloads" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Site groundwork for bulk content

Deferred findings from phase 1 that bulk content would trigger, plus the data files of spec §3.

**Files:**
- Create: `_plugins/aim42_filters.rb`, `tests/meta_text_test.rb`, `_data/categories.yml`, `_data/glossary.yml`, `_includes/aim42/glossary.html`
- Modify: `_layouts/aim42-base.html:9`, `_layouts/pattern.html`, `tools/validate.rb`, `tests/validate_test.rb`, `tests/site_test.rb`, `_pages/reference/glossary.md`, `_sass/pages/_patterns.scss`, `Makefile`, `.github/workflows/check.yml`

**Interfaces:**
- Produces:
  - Liquid filter `meta_description` and pure function `Aim42::MetaText.call(html, length = 160) -> String` (escaped);
  - `_data/categories.yml` with keys `approaches, processes, architecture-and-code, technical-infrastructure, analyzability`, each with `title` and `blurb`;
  - `_data/glossary.yml`, a list of `{id, term, definition}`;
  - `SiteTest::PAGES` now includes every `_pages/reference/*.md` permalink;
  - two new validator errors: `"<file>: unknown category '<c>' (allowed: …)"` and `"<file>: 'intent' is still TODO"`.

- [ ] **Step 1: Write the failing meta-text test**

Create `tests/meta_text_test.rb`:

```ruby
require "minitest/autorun"
require_relative "../_plugins/aim42_filters"

class MetaTextTest < Minitest::Test
  def meta(html, length = 160) = Aim42::MetaText.call(html, length)

  def test_strips_tags_and_collapses_whitespace
    assert_equal "Learn from people.", meta("<p>Learn from\n<em>people</em>.</p>\n")
  end

  def test_escapes_exactly_once
    assert_equal "R&amp;D &quot;x&quot;", meta("<p>R&amp;D \"x\"</p>")
  end

  def test_truncation_never_splits_an_entity
    assert_equal "#{"a" * 155} &amp;...", meta("<p>#{"a" * 155} &amp; more</p>")
  end

  def test_text_of_exactly_the_limit_is_kept
    assert_equal "a" * 160, meta("a" * 160)
  end
end
```

Append ` tests/meta_text_test.rb` to the `unit:` file list in `Makefile` and to the CI "Unit tests" step.

- [ ] **Step 2: Run it to see it fail**

Run: `make unit`
Expected: LoadError for `_plugins/aim42_filters`.

- [ ] **Step 3: Implement the filter**

Create `_plugins/aim42_filters.rb`:

```ruby
# Liquid filters of the aim42 layouts.
require "cgi"

module Aim42
  # Plain text for <meta name="description">: tags stripped, entities decoded,
  # whitespace collapsed, cut to `length` characters ("..." included), then
  # escaped once, so a cut can never split an entity like &amp;.
  module MetaText
    module_function

    def call(html, length = 160)
      text = CGI.unescapeHTML(html.to_s.gsub(/<[^>]*>/, "")).gsub(/\s+/, " ").strip
      text = "#{text[0, length - 3]}..." if text.length > length
      CGI.escapeHTML(text)
    end
  end

  module Filters
    # {{ page.intent | meta_description }}: Markdown in, escaped plain text out.
    def meta_description(input)
      converter = @context.registers[:site].find_converter_instance(Jekyll::Converters::Markdown)
      MetaText.call(converter.convert(input.to_s))
    end
  end
end

Liquid::Template.register_filter(Aim42::Filters) if defined?(Liquid::Template)
```

In `_layouts/aim42-base.html` line 9, replace the filter chain:

```liquid
  <meta name="description" content="{{ description | meta_description }}">
```

- [ ] **Step 4: Run unit and site tests**

Run: `make unit && make site-test`
Expected: green. The existing `test_meta_description_is_the_plain_text_intent` still passes, because the truncation format (157 characters + `...`) is unchanged.

- [ ] **Step 5: Write failing validator tests for categories and TODO intents**

Append to `tests/validate_test.rb`, inside the class:

```ruby
  CATEGORIES = "approaches:\n  title: Improvement approaches\narchitecture-and-code:\n  title: Architecture and code structure\n"

  def test_known_categories_pass
    File.write(File.join(@root, "_data", "categories.yml"), CATEGORIES)
    pattern("a", "title: A\nphase: improve\ncategories: [approaches, architecture-and-code]\nintent: I.\nstatus: complete\n")
    assert_empty errors
  end

  def test_unknown_category
    File.write(File.join(@root, "_data", "categories.yml"), CATEGORIES)
    pattern("a", "title: A\nphase: improve\ncategories: [approaches, nonsense]\nintent: I.\nstatus: complete\n")
    assert_includes errors, "a.md: unknown category 'nonsense' (allowed: approaches, architecture-and-code)"
  end

  def test_categories_without_categories_file
    pattern("a", "title: A\nphase: improve\ncategories: [approaches]\nintent: I.\nstatus: complete\n")
    assert_includes errors, "a.md: unknown category 'approaches' (allowed: )"
  end

  def test_todo_intent_is_rejected
    pattern("a", "title: A\nphase: improve\nintent: TODO\nstatus: complete\n")
    assert_includes errors, "a.md: 'intent' is still TODO"
  end
```

Run: `make unit`. Expected: `test_unknown_category`, `test_categories_without_categories_file` and `test_todo_intent_is_rejected` fail. `test_known_categories_pass` already passes.

- [ ] **Step 6: Implement both checks**

In `tools/validate.rb`, in `run`:
- After `phases = …`, add:

```ruby
      categories_file = File.join(@root, "_data", "categories.yml")
      categories = File.file?(categories_file) ? YAML.safe_load(File.read(categories_file)).keys : []
```

- Replace the line `errors << "#{name}: 'categories' must be a list" if …` with:

```ruby
        if fm.key?("categories")
          if fm["categories"].is_a?(Array)
            (fm["categories"] - categories).each do |c|
              errors << "#{name}: unknown category '#{c}' (allowed: #{categories.join(", ")})"
            end
          else
            errors << "#{name}: 'categories' must be a list"
          end
        end
        errors << "#{name}: 'intent' is still TODO" if fm["intent"].to_s.strip == "TODO"
```

- [ ] **Step 7: Create `_data/categories.yml`**

```yaml
# The improve phase groups its patterns by these categories (spec §6).
# Keys are the allowed values of a pattern's `categories`; order is display order.
# Titles and blurbs follow improve.adoc ("Improvement Approaches/Practices (Overview)").
approaches:
  title: Improvement approaches
  blurb: Strategies for improving a system in the large — keep the data and toss the code, rewrite, restructure, improve the modularization or the domain focus.
processes:
  title: Processes and organization
  blurb: Sometimes your issues originate in process or organizational root causes, meaning your development, rollout or operations processes are less efficient than they should be.
architecture-and-code:
  title: Architecture and code structure
  blurb: All aspects of source code may be subject to improvement — style, structure, dependencies, conventions, naming — as well as structure in the large (modules, components, interfaces) and crosscutting technical concepts.
technical-infrastructure:
  title: Technical infrastructure
  blurb: Technical infrastructure encompasses both underlying hardware and software.
analyzability:
  title: Analyzability and evaluability
  blurb: Make the system easier to analyze and understand, e.g. by improving logging or tracing, and enable evaluation by collecting metrics during development, deployment or runtime.
```

Run: `make unit && make validate`
Expected:
- Unit tests are green.
- The validator prints `patterns OK`. The pilot's `assertions` uses `architecture-and-code` and `strangler-approach` uses `approaches`, so both are known.

- [ ] **Step 8: Failing site tests for reference pages, stub bodies and the glossary list**

In `tests/site_test.rb`:
- Replace the `PAGES = …` line with:

```ruby
  # Every page under _pages/reference/ (glossary, introduction, bibliography, …).
  REFERENCE = Dir[File.join(ROOT, "_pages", "reference", "*.md")].sort.filter_map { |f| VALIDATOR.front_matter(f)&.fetch("permalink", nil) }.freeze
  PAGES = (["/patterns/"] + REFERENCE + PHASES.map { |p| "/patterns/#{p}/" } + PATTERNS.map { |p| "/patterns/#{p["slug"]}/" }).uniq.freeze
```

- In `test_glossary_uses_the_aim42_layout`, replace `assert doc.at_css("h3#system"), …` with:

```ruby
    assert doc.at_css("dl.glossary dt#system"), "glossary term #system missing"
    assert_equal YAML.safe_load(File.read(File.join(ROOT, "_data", "glossary.yml"))).size, doc.css("dl.glossary dt").size
```

- Add:

```ruby
  def test_stub_without_body_renders_no_empty_section
    refute page("/patterns/assertions/").at_css("section.post-content"), "empty body section on a stub"
  end
```

Run: `make site-test`
Expected: the glossary and stub tests fail.

- [ ] **Step 9: Implement them**

`_layouts/pattern.html`: wrap the body section:

```liquid
    {% assign body = content | strip %}
    {% if body != "" %}
    <section class="post-content">
      {{ content }}
    </section>
    {% endif %}
```

`_data/glossary.yml`:
- Move every `### Term {#id}` entry of `_pages/reference/glossary.md` here, in the same order.
- Copy every definition verbatim as Markdown in a literal block scalar.
- The first two entries look like this. Continue the same way for `failure`, `issue`, `remedy`, `sei`, `system` and `value`:

```yaml
# Glossary terms; rendered by _includes/aim42/glossary.html on /glossary/.
# `id` is the link target: /glossary/#<id>.
- id: aim42
  term: aim42
  definition: |
    Architecture Improvement Method.
- id: atam
  term: ATAM
  definition: |
    Architecture Tradeoff Analysis Method, described in detail by Clements et al.
    (*Evaluating Software Architectures*, 2001) and online by the SEI; briefly
    described as the aim42 pattern [ATAM](/patterns/atam/).
```

`_includes/aim42/glossary.html`:

```liquid
<dl class="glossary">
  {% for entry in site.data.glossary %}
    <dt id="{{ entry.id }}">{{ entry.term | escape }}</dt>
    <dd>{{ entry.definition | markdownify }}</dd>
  {% endfor %}
</dl>
```

`_pages/reference/glossary.md`: keep the front matter and replace the whole body with `{% include aim42/glossary.html %}`.

In `_sass/pages/_patterns.scss`, append:

```scss
.glossary dt { font-weight: 700; margin-top: 1.5rem; }
.glossary dd { margin-left: 0; }
```

- [ ] **Step 10: Run everything**

Run: `make check`
Expected: validate, unit and site tests all green.

- [ ] **Step 11: Commit**

```bash
git add _plugins/aim42_filters.rb tests/meta_text_test.rb _layouts tools/validate.rb tests/validate_test.rb tests/site_test.rb _data/categories.yml _data/glossary.yml _includes/aim42/glossary.html _pages/reference/glossary.md _sass/pages/_patterns.scss Makefile .github/workflows/check.yml
git commit -m "Prepare the site for bulk content: safe meta text, categories, glossary data" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The AsciiDoc → Markdown converter

**Files:**
- Create: `tools/migrate/adoc_to_md.rb`, `tools/migrate/anchors.rb`, `tests/migrate_converter_test.rb`

**Interfaces:**
- Consumes: Asciidoctor (Task 1).
- Produces:
  - `Aim42::Migrate::AdocToMd.new(anchors).convert(adoc, self_url:) -> Result(title, intent, related, body, images, notes)`;
  - `Aim42::Migrate::MarkdownWriter`;
  - `Aim42::Migrate::Anchors`: `#add(anchor, url, link_text: nil)` and `#lookup(ref) -> Entry(url, link_text) | nil`. Its `.build` and `Snippets` use `Source`, which Task 4 adds.
  - Result fields: `title` String|nil; `intent` String|nil, one line; `related` Array of slugs; `body` String, ends with `"\n"` or is `""`; `images` Array of paths below `/images/patterns/`; `notes` Array of String.

- [ ] **Step 1: Write the failing tests**

Create `tests/migrate_converter_test.rb`:

````ruby
require "minitest/autorun"
require_relative "../tools/migrate/adoc_to_md"
require_relative "../tools/migrate/anchors"

class MigrateConverterTest < Minitest::Test
  PATTERN = <<~ADOC
    [[Some-Pattern]]
    ==== [pattern]#Some Pattern#
    Lede about the <<System>>.

    ===== Intent
    Do _this_ with <<Stakeholder-Analysis>>.

    ===== Description
    See <<Stakeholder-Analysis,the analysis>> and <<Unknown-Thing>>.

    ====== Detail
    He said "hi".

    ===== Applicability

    ===== Related Patterns
    * <<Stakeholder-Analysis>>
  ADOC

  def anchors
    table = Aim42::Migrate::Anchors.new
    table.add("Stakeholder-Analysis", "/patterns/stakeholder-analysis/", link_text: "Stakeholder Analysis")
    table.add("System", "/glossary/#system", link_text: "system")
    table.add("Nygard07", "/reference/bibliography/#nygard07")
    table
  end

  def convert(adoc, self_url: "/patterns/some-pattern/")
    Aim42::Migrate::AdocToMd.new(anchors).convert(adoc, self_url: self_url)
  end

  def test_title_comes_from_the_top_heading
    assert_equal "Some Pattern", convert(PATTERN).title
  end

  def test_intent_is_one_line_of_inline_markdown
    assert_equal "Do *this* with [Stakeholder Analysis](/patterns/stakeholder-analysis/).", convert(PATTERN).intent
  end

  def test_sections_become_h2_and_title_and_intent_leave_the_body
    body = convert(PATTERN).body
    assert_includes body, "## Description\n"
    assert_includes body, "### Detail\n"
    refute_includes body, "Some Pattern"
    refute_match(/^#+ Intent/, body)
  end

  def test_the_lede_stays_at_the_top_of_the_body
    assert convert(PATTERN).body.start_with?("Lede about the [system](/glossary/#system).\n")
  end

  def test_empty_sections_are_dropped
    refute_includes convert(PATTERN).body, "Applicability"
  end

  def test_a_bare_related_list_becomes_front_matter_only
    result = convert(PATTERN)
    assert_equal ["stakeholder-analysis"], result.related
    refute_includes result.body, "Related"
  end

  def test_related_items_with_explanations_stay_in_the_body
    result = convert("== [pattern]#P#\n\n=== Related Patterns\n\n* <<Stakeholder-Analysis>>, to find people.\n* <<Stakeholder-Analysis>>\n")
    assert_equal ["stakeholder-analysis"], result.related
    assert_equal "## Notes on related patterns\n\n* [Stakeholder Analysis](/patterns/stakeholder-analysis/), to find people.\n", result.body
  end

  def test_xrefs_use_the_target_title_or_their_own_text
    body = convert(PATTERN).body
    assert_includes body, "See [the analysis](/patterns/stakeholder-analysis/)"
  end

  def test_unresolved_xrefs_become_plain_text_and_are_reported
    result = convert(PATTERN)
    assert_includes result.body, "and Unknown-Thing."
    assert_includes result.notes, "unresolved xref: Unknown-Thing"
  end

  def test_links_to_the_page_itself_become_plain_text
    result = convert("== [pattern]#P#\n\n=== Description\n\nSee <<Stakeholder-Analysis>>.\n", self_url: "/patterns/stakeholder-analysis/")
    assert_equal "## Description\n\nSee Stakeholder Analysis.\n", result.body
  end

  def test_links_to_sections_of_the_same_page_use_kramdown_ids
    body = convert("== [pattern]#P#\n\n=== Description\n\nSee <<Data Size>>.\n\n=== Data Size\n\nBig.\n").body
    assert_includes body, "See [Data Size](#data-size)."
  end

  def test_quotes_are_not_escaped
    assert_includes convert(PATTERN).body, %(He said "hi".)
  end

  def test_block_image_uses_its_title_as_alt_text
    result = convert("== [pattern]#P#\n\n=== Description\n\n.The big picture\nimage::approaches/big.png[\"ignored\"]\n")
    assert_includes result.body, "![The big picture](/images/patterns/approaches/big.png)"
    assert_equal ["approaches/big.png"], result.images
  end

  def test_admonitions_become_labelled_quotes
    assert_includes convert("== [pattern]#P#\n\n=== Description\n\nTIP: Start small.\n").body, "> **Tip:** Start small."
  end

  def test_tables_become_pipe_tables
    adoc = "== [pattern]#P#\n\n=== Description\n\n[options=\"header\"]\n|===\n| Name | Value\n| a | 1\n|===\n"
    assert_includes convert(adoc).body, "| Name | Value |\n|---|---|\n| a | 1 |\n"
  end

  def test_footnotes_become_kramdown_footnotes
    body = convert("== [pattern]#P#\n\n=== Description\n\nTrue footnote:[Mostly.].\n").body
    assert_includes body, "True[^1]."
    assert body.end_with?("[^1]: Mostly.\n")
  end

  def test_listings_become_fenced_code_with_language
    adoc = "== [pattern]#P#\n\n=== Description\n\n[source,java]\n----\nint x = 1;\n----\n"
    assert_includes convert(adoc).body, "```java\nint x = 1;\n```\n"
  end

  def test_download_links_point_to_assets
    body = convert("== [pattern]#P#\n\n=== Description\n\nlink:./docs/Form.pdf[pdf version^]\n").body
    assert_includes body, "[pdf version](/assets/downloads/Form.pdf)"
  end

  def test_explicit_anchors_survive_as_ids
    adoc = "== Improve\n\n[[improve-approaches-overview]]\n=== Approaches\n\nText.\n\n[bibliography]\n* [[[Nygard07]]] Michael Nygard: Release It!\n"
    body = convert(adoc, self_url: "/patterns/improve/").body
    assert_includes body, "## Approaches   {#improve-approaches-overview}"
    assert_includes body, "* {: #nygard07} \\[Nygard07\\] Michael Nygard: Release It!"
  end
end
````

Append ` tests/migrate_converter_test.rb` to the `unit:` list in `Makefile` and to the CI "Unit tests" step.

- [ ] **Step 2: Run them to see them fail**

Run: `make unit`
Expected: LoadError for `tools/migrate/adoc_to_md`.

- [ ] **Step 3: Implement the anchor table**

Create `tools/migrate/anchors.rb`:

```ruby
# The table of old AsciiDoc anchors and the URLs they now live at.
# The converter resolves <<xrefs>> with it; _data/anchors.yml is its dump
# and feeds the phase-3 redirector on aim42.github.io.
module Aim42
  module Migrate
    class Anchors
      Entry = Struct.new(:url, :link_text, keyword_init: true)

      attr_reader :duplicates

      def initialize
        @map = {}
        @duplicates = []
      end

      # The first registration of an anchor wins; later ones are recorded.
      def add(anchor, url, link_text: nil)
        if @map.key?(anchor)
          @duplicates << anchor unless @map[anchor].url == url
          return
        end
        @map[anchor] = Entry.new(url: url, link_text: link_text)
      end

      # Exact match first, then case-insensitive, then with blanks as hyphens.
      def lookup(ref)
        ref = ref.strip
        @map[ref] || find { |k| k.casecmp?(ref) } || find { |k| k.casecmp?(ref.gsub(/\s+/, "-")) }
      end

      def to_h
        @map.sort_by { |k, _| k.downcase }.to_h { |k, v| [k, v.url] }
      end

      # manifest: the parsed tools/migrate/manifest.yml; source: a Source.
      # Patterns, pages and glossary terms come first, so their own anchors win
      # over anchors that merely sit somewhere inside another file.
      def self.build(manifest, source)
        table = new
        manifest["patterns"].each do |p|
          url = "/patterns/#{p["slug"]}/"
          ([p["anchor"]] + Array(p["aliases"])).each { |a| table.add(a, url, link_text: p["title"]) }
        end
        manifest["pages"].each do |page|
          Array(page["anchors"]).each { |a| table.add(a, page["url"]) }
        end
        manifest["glossary"].each do |term, slug|
          table.add(term, "/glossary/##{slug}", link_text: term.downcase)
        end
        Array(manifest["extra_anchors"]).each { |anchor, url| table.add(anchor, url) }
        manifest["patterns"].each do |p|
          url = "/patterns/#{p["slug"]}/"
          (source.anchors_in(Snippets.pattern(source, p)) - [p["anchor"]]).each do |a|
            table.add(a, "#{url}##{a.downcase}")
          end
        end
        manifest["pages"].each do |page|
          (source.anchors_in(Snippets.page(source, page, manifest)) - Array(page["anchors"])).each do |a|
            table.add(a, "#{page["url"]}##{a.downcase}")
          end
        end
        table
      end

      private

      def find
        key = @map.keys.find { |k| yield k }
        key && @map[key]
      end
    end

    # Where the AsciiDoc text of a manifest entry comes from.
    module Snippets
      module_function

      # source: "file.adoc" (whole file) or "file.adoc#Anchor" (one section).
      def pattern(source, entry)
        file, anchor = entry["source"].split("#", 2)
        if file == "pattern-index.adoc"
          source.index_entry(anchor).to_s
        elsif anchor
          source.section(source.expand(file), anchor)
        else
          source.expand(file)
        end
      end

      def page(source, page, manifest)
        text = Array(page["source"]).map { |f| source.expand(f) }.join("\n")
        inline = manifest["patterns"].map { |p| p["source"].split("#", 2) }
                                     .select { |f, a| a && Array(page["source"]).include?(f) }.map(&:last)
        source.cut(text, inline)
      end
    end
  end
end
```

`Anchors.build` and `Snippets` refer to `Source` (Task 4). Ruby resolves constants only when they are called, and nothing in this task calls them.

- [ ] **Step 4: Implement the converter**

Create `tools/migrate/adoc_to_md.rb`:

````ruby
# Converts one AsciiDoc snippet of the aim42 method reference to Markdown.
# Asciidoctor parses, Nokogiri normalizes the HTML, kramdown writes Markdown.
#
#   result = Aim42::Migrate::AdocToMd.new(anchors).convert(adoc, self_url: "/patterns/x/")
#   result.title, result.intent, result.related, result.body, result.images, result.notes
require "asciidoctor"
require "nokogiri"
require "kramdown"

module Aim42
  module Migrate
    # kramdown's own writer, with three changes for hand-editable output:
    # inline links instead of reference links, no escaping of quotes,
    # fenced code blocks and one delimiter cell per table column.
    class MarkdownWriter < Kramdown::Converter::Kramdown
      ESCAPES = /(\$\$|[\\*_`\[\]{|])|^ {0,3}(:)/

      def convert_text(el, opts)
        return el.value if opts[:raw_text]
        result = el.value.gsub(/\A\n/) { opts[:prev] && opts[:prev].type == :br ? "" : "\n" }
        result.gsub!(/\s+/, " ") unless el.options[:cdata]
        result.gsub(ESCAPES) { $1 || !opts[:prev] || opts[:prev].type == :br ? "\\#{$1 || $2}" : $& }
      end

      def convert_a(el, opts)
        href = el.attr["href"].to_s
        return super if href.empty?
        "[#{inner(el, opts)}](#{href})"
      end

      def convert_codeblock(el, _opts)
        lang = el.attr.delete("class").to_s[/language-(\S+)/, 1]
        "```#{lang}\n#{el.value.chomp}\n```\n"
      end

      def convert_thead(el, opts)
        columns = el.children.first ? el.children.first.children.size : 1
        "#{inner(el, opts)}|#{(["---"] * columns).join("|")}|\n"
      end
    end

    class AdocToMd
      Result = Struct.new(:title, :intent, :related, :body, :images, :notes, keyword_init: true)

      HEADINGS = %w[h1 h2 h3 h4 h5 h6].freeze
      RELATED = /\Arelated(\s+(patterns|practices))?\z/i
      ADMONITIONS = %w[note tip important warning caution].freeze
      KEEP = { "a" => %w[href], "img" => %w[src alt], "code" => %w[class],
               "p" => %w[id], "li" => %w[id], "dt" => %w[id], "dd" => %w[id] }.freeze
      # Blocks that take over the id of an inline [[anchor]] inside them.
      ID_HOSTS = %w[p li dt dd].freeze

      # anchors: an Anchors instance (lookup(ref) -> Anchors::Entry or nil).
      def initialize(anchors)
        @anchors = anchors
      end

      # adoc: the AsciiDoc source of one pattern or page, includes already expanded.
      # self_url: the URL the result is published at; links to it are dropped.
      def convert(adoc, self_url: nil)
        @notes = []
        @images = []
        @self_url = self_url
        frag = Nokogiri::HTML::DocumentFragment.parse(render(adoc))
        footnotes = extract_footnotes(frag)
        normalize_blocks(frag)
        rewrite_links(frag)
        flatten(frag)
        nodes = frag.children.reject { |n| n.text? && n.text.strip.empty? }
        title = take_title(nodes)
        intent_nodes, related, body_nodes = split_sections(nodes)
        body = markdown(body_nodes.map(&:to_html).join("\n"))
        body = add_footnotes(body, footnotes)
        intent = intent_nodes && one_line(markdown(intent_nodes.to_html))
        Result.new(title: title, intent: intent, related: related, body: body,
                   images: @images.uniq, notes: @notes)
      end

      private

      def render(adoc)
        logger = Asciidoctor::MemoryLogger.new
        Asciidoctor::LoggerManager.logger = logger
        html = Asciidoctor.convert(adoc, safe: :safe, attributes: { "imagesdir" => "/images/patterns" })
        logger.messages.each do |m|
          text = m[:message].is_a?(String) ? m[:message] : m[:message].text
          @notes << "asciidoctor: #{text}" unless text.include?("section title out of sequence")
        end
        html
      ensure
        Asciidoctor::LoggerManager.logger = nil
      end

      # Footnote markers become placeholder tokens; their texts are returned in order.
      def extract_footnotes(frag)
        texts = frag.css("div#footnotes div.footnote").map do |div|
          div.at_css("a")&.remove
          one_line(markdown(div.inner_html.sub(/\A\s*\.\s*/, "")))
        end
        frag.css("div#footnotes").each(&:remove)
        frag.css("hr").each(&:remove) if texts.any?
        frag.css("sup.footnote").each do |sup|
          number = sup.text[/\d+/]
          sup.replace(Nokogiri::XML::Text.new("AIMFN#{number}X", frag.document))
        end
        texts
      end

      def normalize_blocks(frag)
        frag.css("map").each(&:remove)
        frag.css("div.admonitionblock").each { |div| admonition(div) }
        frag.css("div.imageblock").each { |div| image_block(div) }
        frag.css("div.quoteblock").each { |div| quote_block(div) }
        frag.css("div.hdlist").each { |div| hdlist(div) }
        frag.css("table.tableblock").each { |table| table_block(table) }
        frag.css("div.listingblock, div.literalblock").each do |div|
          div.css("div.title").each { |t| t.name = "p"; t.inner_html = "<em>#{t.inner_html}</em>" }
        end
        frag.css("div.ulist > div.title, div.olist > div.title, div.paragraph > div.title").each do |t|
          t.name = "p"
          t.inner_html = "<strong>#{t.inner_html}</strong>"
        end
        frag.css("img").each { |img| image_src(img) }
        frag.css("li, dd").each do |item|
          paragraphs = item.element_children.select { |c| c.name == "p" }
          first = item.element_children.first
          first.replace(first.children) if first&.name == "p" && paragraphs.size == 1
        end
      end

      def admonition(div)
        kind = (div["class"].split & ADMONITIONS).first || "note"
        content = div.at_css("td.content")
        quote = Nokogiri::XML::Node.new("blockquote", div.document)
        inner = content.element_children.any? { |c| c.name == "div" || c.name == "p" } ? content.inner_html : "<p>#{content.inner_html}</p>"
        quote.inner_html = inner
        flatten(quote)
        first = quote.at_css("p") || quote.add_child("<p></p>").first
        first.prepend_child("<strong>#{kind.capitalize}:</strong> ")
        div.replace(quote)
      end

      # A block image with a title becomes ![title](src): the pilot's convention.
      def image_block(div)
        img = div.at_css("img")
        caption = div.at_css("div.title")&.text&.sub(/\A(Figure|Abbildung)\s+\d+\.\s*/, "")
        img["alt"] = caption.strip if caption && !caption.strip.empty?
        para = Nokogiri::XML::Node.new("p", div.document)
        para << (img.parent.name == "a" ? img.parent : img)
        para["id"] = div["id"] if explicit_id?(div["id"])
        div.replace(para)
      end

      def quote_block(div)
        quote = div.at_css("blockquote")
        attribution = div.at_css("div.attribution")
        quote.add_child("<p>— #{attribution.inner_html.strip}</p>") if attribution
        div.replace(quote)
      end

      def hdlist(div)
        dl = Nokogiri::XML::Node.new("dl", div.document)
        div.css("tr").each do |tr|
          dl.add_child("<dt>#{tr.at_css("td.hdlist1").inner_html}</dt>")
          dl.add_child("<dd>#{tr.at_css("td.hdlist2").inner_html}</dd>")
        end
        div.replace(dl)
      end

      def table_block(table)
        table.css("colgroup").each(&:remove)
        caption = table.at_css("caption")
        if caption
          text = caption.text.sub(/\A(Table|Tabelle)\s+\d+\.\s*/, "").strip
          table.add_previous_sibling("<p><em>#{text}</em></p>") unless text.empty?
          caption.remove
        end
        table.css("th, td").each do |cell|
          cell.css("div.content").each { |c| c.replace(c.children) }
          paragraphs = cell.css("p")
          next if paragraphs.empty?
          cell.inner_html = paragraphs.map(&:inner_html).join("<br>")
        end
      end

      def image_src(img)
        src = img["src"].to_s
        return if src.match?(%r{\A(https?:)?//})
        path = src.sub(%r{\A/images/patterns/}, "").sub(%r{\A(\./)?images/}, "")
        img["src"] = "/images/patterns/#{path}"
        @images << path
      end

      def rewrite_links(frag)
        frag.css("a[href]").each do |a|
          href = a["href"]
          if href.start_with?("#_") && (target = frag.at_css("[id='#{href[1..]}']")) && heading?(target)
            a["href"] = "##{heading_id(target.text)}"
          elsif href.start_with?("#")
            internal_link(a, href.delete_prefix("#"))
          elsif href.match?(%r{\A(\./)?(docs|whitepaper)/})
            a["href"] = "/assets/downloads/#{File.basename(href)}"
          end
        end
      end

      # <<Anchor>> arrives as <a href="#Anchor">[Anchor]</a>, <<Anchor,text>> with its text.
      def internal_link(a, ref)
        entry = @anchors.lookup(ref)
        text = a.text.strip
        default = text == "[#{ref}]" || text == ref
        if entry.nil?
          @notes << "unresolved xref: #{ref}"
          a.replace(Nokogiri::XML::Text.new(default ? ref : text, a.document))
          return
        end
        label = entry.link_text if default
        if entry.url == @self_url
          a.replace(label ? Nokogiri::XML::Text.new(label, a.document) : a.children)
        else
          a["href"] = entry.url
          a.content = label if label
        end
      end

      # Removes asciidoctor's wrapper divs and spans and every attribute
      # that the Markdown writer would turn into {: …} noise.
      def flatten(node)
        node.css("div, span").each { |n| n.replace(n.children) }
        node.css("a[id]:not([href])").each do |a|
          host = a.ancestors.find { |n| ID_HOSTS.include?(n.name) }
          host["id"] ||= a["id"] if host && explicit_id?(a["id"])
          a.remove
        end
        node.traverse do |n|
          next unless n.element?
          keep = HEADINGS.include?(n.name) ? %w[id] : KEEP.fetch(n.name, [])
          n.attribute_nodes.each { |attr| attr.remove unless keep.include?(attr.name) }
          n.remove_attribute("id") if n["id"] && !explicit_id?(n["id"])
          n["id"] = n["id"].downcase if n["id"]
          n.remove_attribute("class") if n["class"] && !n["class"].start_with?("language-")
        end
      end

      # Asciidoctor's generated ids start with "_"; [[Anchor]] ids do not.
      def explicit_id?(id)
        !id.to_s.empty? && !id.start_with?("_")
      end

      # The id kramdown generates for a heading (auto_ids), for links within a page.
      def heading_id(text)
        text.downcase.gsub(/[^a-z0-9 -]/, "").strip.gsub(/\s+/, "-").sub(/\A[^a-z]+/, "")
      end

      def heading?(node)
        node.element? && HEADINGS.include?(node.name)
      end

      def level(node)
        node.name[1].to_i
      end

      # The first heading at the top level is the title; the levels below it
      # are shifted so that the title's children become h2.
      def take_title(nodes)
        headings = nodes.select { |n| heading?(n) }
        return nil if headings.empty?
        top = headings.map { |h| level(h) }.min
        title = nil
        if heading?(nodes.first) && level(nodes.first) == top
          title = nodes.shift.text.strip
          shift = top - 1
        else
          shift = top - 2
        end
        headings.drop(title ? 1 : 0).each { |h| h.name = "h#{[[level(h) - shift, 2].max, 6].min}" }
        title
      end

      # Returns [intent nodes or nil, related slugs, body nodes].
      def split_sections(nodes)
        intent = nil
        related = []
        notes = []
        body = []
        section = nil
        nodes.each do |node|
          if heading?(node) && level(node) == 2
            section = node.text.strip
            next if section.match?(/\Aintent\z/i) || section.match?(RELATED)
          end
          if section&.match?(/\Aintent\z/i) && !heading?(node)
            if intent.nil? && node.name == "p"
              intent = node
            else
              body << node
              @notes << "intent section has more than one paragraph; the rest stays in the body"
            end
          elsif section&.match?(RELATED) && !heading?(node)
            related.concat(related_slugs(node))
            notes.concat(explained_items(node))
          else
            body << node
          end
        end
        unless notes.empty?
          doc = nodes.first.document
          body << Nokogiri::XML::Node.new("h2", doc).tap { |h| h.content = "Notes on related patterns" }
          list = Nokogiri::XML::Node.new("ul", doc)
          notes.each { |item| list << item }
          body << list
        end
        [intent, related.uniq, drop_empty_sections(body)]
      end

      def related_slugs(node)
        node.css("a[href]").map { |a| a["href"][%r{\A/patterns/([a-z0-9-]+)/\z}, 1] }.compact
      end

      # List items that say more than the link itself; they stay in the body.
      def explained_items(node)
        items = node.name.match?(/\A[uo]l\z/) ? node.css("> li") : [node]
        items.select do |item|
          copy = item.dup
          copy.css("a").each(&:remove)
          copy.text.gsub(/[[:punct:]\s]|\b(and|or|see|also|especially|e\.g)\b/i, "").length > 0
        end.map { |item| item.name == "li" ? item : Nokogiri::XML::Node.new("li", item.document).tap { |li| li << item } }
      end

      def drop_empty_sections(nodes)
        loop do
          empty = nodes.each_index.find do |i|
            next false unless heading?(nodes[i])
            following = nodes[i + 1]
            following.nil? || (heading?(following) && level(following) <= level(nodes[i]))
          end
          break nodes if empty.nil?
          nodes.delete_at(empty)
        end
      end

      # One line per paragraph: wrapping would split link and alt texts.
      def markdown(html)
        doc = Kramdown::Document.new(html, input: "html", html_to_native: true, line_width: 100_000)
        output, = MarkdownWriter.convert(doc.root, doc.options)
        output.delete("​").gsub(/  \n +/, "  \n").gsub(/\n{3,}/, "\n\n").strip + "\n"
      end

      def one_line(text)
        text.gsub(/\s*\n\s*/, " ").strip
      end

      def add_footnotes(body, footnotes)
        return body if footnotes.empty?
        body = body.gsub(/\s*AIMFN(\d+)X/) { "[^#{$1}]" }
        defs = footnotes.each_with_index.map { |text, i| "[^#{i + 1}]: #{text}" }
        "#{body}\n#{defs.join("\n")}\n"
      end
    end
  end
end
````

- [ ] **Step 5: Run the tests**

Run: `make unit`
Expected: `MigrateConverterTest` 19 runs, all green. All other unit tests stay green.

- [ ] **Step 6: Commit**

```bash
git add tools/migrate/adoc_to_md.rb tools/migrate/anchors.rb tests/migrate_converter_test.rb Makefile .github/workflows/check.yml
git commit -m "Add the AsciiDoc to Markdown converter for the method reference" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Source snippets, manifest and the anchor table

**Files:**
- Create: `tools/migrate/source.rb`, `tools/migrate/manifest.yml`, `tests/migrate_source_test.rb`

**Interfaces:**
- Consumes: `_import/src/main/asciidoc/` (Task 1), `tools/migrate/anchors.rb` (Task 3).
- Produces:
  - `Aim42::Migrate::Source.new(root, skip: [paths])`, with methods:
    - `#expand(path) -> String`
    - `#section(text, anchor) -> String` (raises ArgumentError for an unknown anchor)
    - `#cut(text, anchors) -> String`
    - `#index_entry(anchor) -> String | nil`
    - `#anchors_in(text) -> [String]`
  - `Aim42::Migrate::Anchors.build(manifest_hash, source)` now works;
  - `tools/migrate/manifest.yml` with top-level keys `glossary`, `extra_anchors`, `pages`, `patterns`.

- [ ] **Step 1: Copy the manifest**

```bash
cp docs/superpowers/plans/2026-10-07-phase2-manifest.yml tools/migrate/manifest.yml
```

It lists 105 patterns (6 of them `pilot: true`): 32 analyze, 4 evaluate, 49 improve, 20 crosscutting. It also lists 10 pages, one glossary anchor and two extra anchors. Do not edit it in this task.

- [ ] **Step 2: Write the failing tests**

Create `tests/migrate_source_test.rb`:

```ruby
require "minitest/autorun"
require "yaml"
require_relative "../tools/migrate/source"
require_relative "../tools/migrate/anchors"

class MigrateSourceTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  ASCIIDOC = File.join(ROOT, "_import", "src", "main", "asciidoc")
  MANIFEST = YAML.safe_load(File.read(File.join(ROOT, "tools", "migrate", "manifest.yml")))

  def source(skip: [])
    Aim42::Migrate::Source.new(ASCIIDOC, skip: skip)
  end

  def test_expand_inlines_includes_but_drops_skipped_files
    text = source(skip: ["patterns/analyze/atam.adoc"]).expand("analyze.adoc")
    refute_includes text, "[[ATAM]]"
    assert_includes text, "[[Stakeholder-Interview]]"
    refute_match(/^include::/, text)
  end

  def test_section_runs_from_the_anchor_to_the_next_sibling_heading
    text = source.section(source.expand("crosscutting.adoc"), "Fail-Fast")
    assert text.start_with?("[[Fail-Fast]]\n=== [pattern]#Fail Fast#")
    assert_includes text, "==== Takeaways"
    refute_includes text, "Fast-Feedback"
  end

  def test_section_raises_for_an_unknown_anchor
    assert_raises(ArgumentError) { source.section("text\n", "Nope") }
  end

  def test_cut_removes_sections
    text = source.cut(source.expand("crosscutting.adoc"), %w[Fail-Fast Fast-Feedback])
    refute_includes text, "[[Fail-Fast]]"
    refute_includes text, "[[Fast-Feedback]]"
    assert_includes text, "[[Impact-Analysis]]"
  end

  def test_index_entry_reads_both_entry_forms
    assert source.index_entry("Bulkhead").start_with?("Can be placed between two systems")
    assert source.index_entry("Deprecate-Obsolete-Parts").start_with?("Actively mark parts")
    assert source.index_entry("Quality-Driven-Software-Architecture").start_with?("Derive (technical")
    assert source.index_entry("ATAM").start_with?("Systematic approach")
    refute_includes source.index_entry("ATAM"), "Category"
    assert_nil source.index_entry("No-Such-Pattern")
  end

  def test_anchors_in_finds_block_inline_and_bibliography_anchors
    assert_equal %w[a b c], source.anchors_in("[[a]] text [[[b]]] and [[c,label]]")
  end

  def test_lookup_is_exact_then_case_insensitive_then_with_hyphens
    table = Aim42::Migrate::Anchors.new
    table.add("Domain-Model", "/reference/domain-model/")
    assert_equal "/reference/domain-model/", table.lookup("Domain-Model").url
    assert_equal "/reference/domain-model/", table.lookup("domain-model").url
    assert_equal "/reference/domain-model/", table.lookup("Domain Model").url
    assert_nil table.lookup("Domain")
  end

  def test_first_registration_wins_and_conflicts_are_recorded
    table = Aim42::Migrate::Anchors.new
    table.add("X", "/a/")
    table.add("X", "/a/")
    table.add("X", "/b/")
    assert_equal "/a/", table.lookup("X").url
    assert_equal ["X"], table.duplicates
  end

  def test_the_manifest_table_resolves_every_kind_of_anchor
    files = MANIFEST["patterns"].map { |p| p["source"] }.reject { |s| s.include?("#") }
    table = Aim42::Migrate::Anchors.build(MANIFEST, source(skip: files))
    assert_equal "/patterns/atam/", table.lookup("ATAM").url
    assert_equal "ATAM", table.lookup("ATAM").link_text
    assert_equal "/patterns/fail-fast/", table.lookup("Fail-Fast").url
    assert_equal "/patterns/bulkhead/", table.lookup("Bulkhead").url
    assert_equal "/patterns/atam/#figure-atam-approach", table.lookup("figure-atam-approach").url
    assert_equal "/patterns/improve/", table.lookup("Improve").url
    assert_equal "/patterns/improve/#improve-processes", table.lookup("improve-processes").url
    assert_equal "/reference/bibliography/#nygard07", table.lookup("Nygard07").url
    assert_equal "/glossary/#system", table.lookup("System").url
    assert_equal "/reference/domain-model/", table.lookup("Domain Model").url
    assert_empty table.duplicates
  end
end
```

Append ` tests/migrate_source_test.rb` to the `unit:` list in `Makefile` and to the CI "Unit tests" step.

Run: `make unit`. Expected: LoadError for `tools/migrate/source`.

- [ ] **Step 3: Implement**

Create `tools/migrate/source.rb`:

```ruby
# Reads the imported AsciiDoc sources (_import/src/main/asciidoc) and cuts
# them into the snippets the converter works on.
module Aim42
  module Migrate
    class Source
      ANCHOR = /\[\[\[?([A-Za-z0-9_.-]+)(?:,[^\]]*)?\]\]\]?/
      INCLUDE = /\Ainclude::([^\[]+)\[[^\]]*\]\s*\z/
      HEADING = /\A(=+)\s+\S/

      # root: the asciidoc directory. skip: paths (relative to root) whose
      # includes are dropped, because they are converted on their own.
      def initialize(root, skip: [])
        @root = root
        @skip = skip.map { |p| File.expand_path(p, root) }
      end

      # The file's text with includes inlined, except includes of skipped files.
      def expand(path)
        full = File.expand_path(path, @root)
        File.read(full, encoding: "UTF-8").gsub("\r\n", "\n").lines.map do |line|
          match = line.match(INCLUDE)
          next line unless match
          target = File.expand_path(match[1], File.dirname(full))
          next "" if @skip.include?(target)
          expand(target.delete_prefix("#{@root}/")) + "\n"
        end.join
      end

      # The block that starts at the line [[anchor]] and ends before the next
      # heading at the same or a higher level (or before the anchor line of it).
      def section(text, anchor)
        lines = text.lines
        start = lines.index { |l| l.strip.match?(/\A\[\[#{Regexp.escape(anchor)}(,[^\]]*)?\]\]\z/) }
        raise ArgumentError, "anchor #{anchor} not found" unless start
        heading = (start + 1...lines.size).find { |i| lines[i].match?(HEADING) }
        depth = lines[heading][HEADING, 1].size
        stop = (heading + 1...lines.size).find do |i|
          lines[i].match?(HEADING) && lines[i][HEADING, 1].size <= depth
        end || lines.size
        stop -= 1 while stop > heading + 1 && (lines[stop - 1].strip.empty? || lines[stop - 1].strip.match?(/\A\[\[.*\]\]\z/))
        lines[start...stop].join
      end

      # text without the sections that start at the given anchors.
      def cut(text, anchors)
        anchors.reduce(text) do |result, anchor|
          result.include?("[[#{anchor}]]") ? result.sub(section(result, anchor), "") : result
        end
      end

      # The one-line description of an entry in pattern-index.adoc, as AsciiDoc.
      def index_entry(anchor)
        entries = expand("pattern-index.adoc").split(/^(?=\. )/)
        entry = entries.find { |e| e.match?(/\A\. (\[\[#{Regexp.escape(anchor)}\]\]|\*<<#{Regexp.escape(anchor)}(,[^>]*)?>>\*)/) }
        return nil unless entry
        text = entry.sub(/\A\. \*<<[^>]+>>\*\s*/, "")
                    .sub(/\A\. \[\[[^\]]+\]\]\s*(\+\s*)?\[pattern\]#[^#]+#[^:\n]*::\s*/, "")
        text = text.sub(/^\s*Category:.*\z/m, "").gsub(/^\+\s*$/, "").strip
        text.empty? ? nil : text
      end

      def anchors_in(text)
        text.scan(ANCHOR).flatten.uniq
      end
    end
  end
end
```

- [ ] **Step 4: Run the tests**

Run: `make unit`
Expected: `MigrateSourceTest` 9 runs, all green; everything else stays green.

- [ ] **Step 5: Commit**

```bash
git add tools/migrate/source.rb tools/migrate/manifest.yml tests/migrate_source_test.rb Makefile .github/workflows/check.yml
git commit -m "Add the migration manifest, source snippets and anchor table" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: The conversion run, with the pilot as oracle

**Files:**
- Create: `tools/migrate/run.rb`, `tests/migrate_run_test.rb`

**Interfaces:**
- Consumes: Tasks 3–4, `tools/validate.rb`.
- Produces: `Aim42::Migrate::Run.new(out: ROOT, only: nil, pilot: false).call -> [[path, note], …]`. When `only` is nil, a run writes:
  - `_patterns/<slug>.md` for every non-pilot manifest pattern;
  - `_pages/reference/*.md` and `tools/migrate/out/{evaluate,improve,crosscutting}.md`, for the pages that have a `target`;
  - `_data/anchors.yml`;
  - `tools/migrate/report.md`.

  Existing pattern and page files are skipped and reported as `"exists: not overwritten"`.

- [ ] **Step 1: Write the failing tests**

Create `tests/migrate_run_test.rb`:

```ruby
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../tools/migrate/run"
require_relative "../tools/validate"

class MigrateRunTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  MANIFEST = YAML.safe_load(File.read(File.join(ROOT, "tools", "migrate", "manifest.yml")))
  PILOT = MANIFEST["patterns"].select { |p| p["pilot"] }.map { |p| p["slug"] }

  # One full conversion into a scratch root, shared by the tests below.
  def self.converted
    @converted ||= begin
      out = Dir.mktmpdir("aim42-migrate")
      FileUtils.mkdir_p(File.join(out, "_data"))
      Dir[File.join(ROOT, "_data", "*.yml")].each { |f| FileUtils.cp(f, File.join(out, "_data")) }
      FileUtils.mkdir_p(File.join(out, "_patterns"))
      PILOT.each { |slug| FileUtils.cp(File.join(ROOT, "_patterns", "#{slug}.md"), File.join(out, "_patterns")) }
      report = Aim42::Migrate::Run.new(out: out).call
      [out, report]
    end
  end

  def out
    self.class.converted.first
  end

  def report
    self.class.converted.last
  end

  def headings(text)
    text.scan(/^#+ (.+?)(?:\s+\{#[^}]*\})?$/).flatten.map(&:downcase)
  end

  def test_every_manifest_pattern_gets_a_file
    MANIFEST["patterns"].each do |p|
      assert File.file?(File.join(out, "_patterns", "#{p["slug"]}.md")), "#{p["slug"]} not written"
    end
  end

  def test_converted_front_matter_passes_the_validator
    assert_equal [], Aim42::Validator.new(out).run
  end

  def test_no_intent_is_left_empty
    todo = Dir[File.join(out, "_patterns", "*.md")].select { |f| File.read(f).include?("\nintent: TODO\n") }
    assert_equal [], todo.map { |f| File.basename(f) }
  end

  def test_stubs_from_the_index_have_no_body
    text = File.read(File.join(out, "_patterns", "bulkhead.md"))
    assert_includes text, "\nstatus: stub\n"
    assert text.end_with?("---\n"), "stub body must be empty"
  end

  def test_anchor_table_and_report_are_written
    anchors = YAML.safe_load(File.read(File.join(out, "_data", "anchors.yml")))
    assert_equal "/patterns/stakeholder-interview/", anchors["Stakeholder-Interview"]
    assert_operator anchors.size, :>=, 190
    assert File.file?(File.join(out, "tools", "migrate", "report.md"))
    refute report.any? { |_, note| note.start_with?("duplicate anchor") }, "anchor conflicts"
  end

  def test_pilot_files_are_left_alone
    PILOT.each do |slug|
      assert_equal File.read(File.join(ROOT, "_patterns", "#{slug}.md")), File.read(File.join(out, "_patterns", "#{slug}.md"))
    end
  end

  def test_existing_files_are_not_overwritten
    Dir.mktmpdir("aim42-rerun") do |dir|
      Aim42::Migrate::Run.new(out: dir, only: ["fail-fast"]).call
      path = File.join(dir, "_patterns", "fail-fast.md")
      File.write(path, "hand edited")
      report = Aim42::Migrate::Run.new(out: dir, only: ["fail-fast"]).call
      assert_equal "hand edited", File.read(path)
      assert_includes report, ["_patterns/fail-fast.md", "exists: not overwritten"]
    end
  end

  # The hand-converted pilot is the oracle (spec §5): the converter must agree on
  # front matter, images and section structure. Prose edits made by hand in the
  # pilot (spelling, wording) are deliberate and not compared.
  def test_converter_agrees_with_the_hand_converted_pilot
    Dir.mktmpdir("aim42-oracle") do |oracle|
      Aim42::Migrate::Run.new(out: oracle, only: PILOT, pilot: true).call
      PILOT.each do |slug|
        mine = File.read(File.join(oracle, "_patterns", "#{slug}.md"))
        pilot = File.read(File.join(ROOT, "_patterns", "#{slug}.md"))
        mine_fm = YAML.safe_load(mine[/\A---\n.*?\n---\n/m])
        pilot_fm = YAML.safe_load(pilot[/\A---\n.*?\n---\n/m])
        keys = %w[title phase categories status]
        assert_equal pilot_fm.slice(*keys), mine_fm.slice(*keys), "#{slug}: front matter"
        assert_equal pilot.scan(/!\[[^\]]*\]\(([^)]+)\)/), mine.scan(/!\[[^\]]*\]\(([^)]+)\)/), "#{slug}: images"
        extra = headings(mine) - headings(pilot) - ["notes on related patterns"]
        assert_empty extra, "#{slug}: headings the pilot does not have"
      end
    end
  end
end
```

Append ` tests/migrate_run_test.rb` to the `unit:` list in `Makefile` and to the CI "Unit tests" step.

Run: `make unit`. Expected: LoadError for `tools/migrate/run`.

- [ ] **Step 2: Implement**

Create `tools/migrate/run.rb`:

```ruby
# One-off conversion of the aim42 method reference (AsciiDoc, in _import/)
# into _patterns/*.md, reference pages and _data/anchors.yml.
#
#   ruby tools/migrate/run.rb                    # convert everything not yet converted
#   ruby tools/migrate/run.rb --out /tmp/x --pilot --only atam,assertions
#
# Existing pattern and page files are never overwritten: once committed, a
# converted file is the source of truth and is edited by hand. The anchor
# table, the report and the phase-page drafts in tools/migrate/out/ are
# rewritten on every run. --out writes below another root (tests), --only
# limits the run to some slugs, --pilot includes the hand-converted pilot.
require "yaml"
require "json"
require "fileutils"
require_relative "adoc_to_md"
require_relative "source"
require_relative "anchors"

module Aim42
  module Migrate
    class Run
      ROOT = File.expand_path("../..", __dir__)
      ASCIIDOC = File.join(ROOT, "_import", "src", "main", "asciidoc")
      MANIFEST = File.join(__dir__, "manifest.yml")

      def initialize(out: ROOT, only: nil, pilot: false)
        @out = out
        @only = only
        @pilot = pilot
        @manifest = YAML.safe_load(File.read(MANIFEST))
        files = @manifest["patterns"].map { |p| p["source"] }.reject { |s| s.include?("#") }
        @source = Source.new(ASCIIDOC, skip: files)
        @anchors = Anchors.build(@manifest, @source)
        @converter = AdocToMd.new(@anchors)
        @slugs = @manifest["patterns"].map { |p| p["slug"] }
        @report = []
      end

      # Returns the report: [path, note] pairs.
      def call
        @manifest["patterns"].each { |entry| pattern(entry) if wanted?(entry) }
        if @only.nil?
          @manifest["pages"].each { |page| page(page) if page["target"] }
          write_anchors
          write_report
        end
        @report
      end

      private

      def wanted?(entry)
        (@only.nil? || @only.include?(entry["slug"])) && (@pilot || !entry["pilot"])
      end

      def pattern(entry)
        slug = entry["slug"]
        path = "_patterns/#{slug}.md"
        result = @converter.convert(Snippets.pattern(@source, entry), self_url: "/patterns/#{slug}/")
        notes = result.notes.dup
        body = result.body
        if entry["source"].start_with?("pattern-index.adoc#")
          intent = one_line(body)
          body = ""
        else
          intent = entry["intent"] || result.intent || index_intent(entry, notes) || lede_intent(body, notes)
        end
        if intent.to_s.empty?
          notes << "no intent found: write one"
          intent = "TODO"
        end
        front = { "title" => entry["title"], "phase" => entry["phase"] }
        front["categories"] = entry["categories"] if entry["categories"]
        front["intent"] = intent
        related = result.related.select { |s| @slugs.include?(s) } - [slug]
        front["related"] = related unless related.empty?
        front["status"] = body.strip.empty? ? "stub" : "complete"
        write(path, front_matter(front) + (body.strip.empty? ? "" : "\n#{body}"))
        check_images(result.images, notes)
        notes.each { |n| @report << [path, n] }
      end

      # pattern-index.adoc has a one-line description of most patterns.
      def index_intent(entry, notes)
        text = @source.index_entry(entry["anchor"])
        return nil unless text
        notes << "intent taken from pattern-index.adoc"
        one_line(@converter.convert(text, self_url: "/patterns/#{entry["slug"]}/").body)
      end

      # Last resort: the first paragraph before the first heading.
      def lede_intent(body, notes)
        first = body.split(/\n{2,}/).first.to_s.strip
        return nil if first.empty? || first.start_with?("#", "*", "!", "|", ">", "`", "1.")
        notes << "intent taken from the first paragraph"
        first
      end

      def page(page)
        result = @converter.convert(Snippets.page(@source, page, @manifest), self_url: page["url"])
        front = { "title" => page["title"], "layout" => "aim42-page", "permalink" => page["url"] }
        draft = page["target"].start_with?("tools/migrate/out/")
        write(page["target"], front_matter(front) + "\n" + result.body, overwrite: draft)
        check_images(result.images, result.notes)
        result.notes.each { |n| @report << [page["target"], n] }
      end

      def write_anchors
        header = "# Old AsciiDoc anchor (aim42.github.io/#Anchor) → URL on this site.\n" \
                 "# Generated by tools/migrate/run.rb; read by the phase-3 redirector.\n"
        write("_data/anchors.yml", header + @anchors.to_h.to_yaml.delete_prefix("---\n"), overwrite: true)
        @anchors.duplicates.uniq.each { |a| @report << ["_data/anchors.yml", "duplicate anchor #{a}: first one wins"] }
      end

      def write_report
        sections = @report.group_by(&:first).sort.map do |path, items|
          "## #{path}\n\n" + items.map { |_, note| "- #{note}\n" }.join
        end
        write("tools/migrate/report.md", "# Conversion report\n\n" + sections.join("\n"), overwrite: true)
      end

      def check_images(images, notes)
        images.each do |image|
          notes << "missing image images/patterns/#{image}" unless File.file?(File.join(ROOT, "images", "patterns", image))
        end
      end

      def one_line(text)
        text.gsub(/\s*\n\s*/, " ").strip
      end

      def front_matter(hash)
        lines = hash.map { |key, value| "#{key}: #{value.is_a?(Array) ? "[#{value.join(", ")}]" : scalar(value)}" }
        "---\n#{lines.join("\n")}\n---\n"
      end

      # Plain YAML where it reads back unchanged, a double-quoted string otherwise.
      def scalar(value)
        plain = !value.match?(/\A[\s\-?:,\[\]{}#&*!|>'"%@`]/) && YAML.safe_load("k: #{value}")["k"] == value
        plain ? value : JSON.generate(value)
      rescue Psych::Exception
        JSON.generate(value)
      end

      def write(path, content, overwrite: false)
        target = File.join(@out, path)
        if File.exist?(target) && !overwrite
          @report << [path, "exists: not overwritten"]
          return
        end
        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, content)
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}
  args = ARGV.dup
  while (arg = args.shift)
    case arg
    when "--only" then options[:only] = args.shift.split(",")
    when "--out" then options[:out] = File.expand_path(args.shift)
    when "--pilot" then options[:pilot] = true
    else abort "unknown option #{arg}"
    end
  end
  report = Aim42::Migrate::Run.new(**options).call
  puts "#{report.size} report entries; see tools/migrate/report.md"
end
```

- [ ] **Step 3: Run the tests**

Run: `make unit`
Expected: `MigrateRunTest` 8 runs, all green (the run takes about one second); everything else stays green.
If `test_converter_agrees_with_the_hand_converted_pilot` fails, the converter is wrong, not the pilot. Fix `adoc_to_md.rb` and add a converter test for the case.

- [ ] **Step 4: Commit**

```bash
git add tools/migrate/run.rb tests/migrate_run_test.rb Makefile .github/workflows/check.yml
git commit -m "Add the conversion run, checked against the hand-converted pilot" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Convert everything, merge the phase pages, resolve every old anchor

**Files:**
- Create: `_patterns/*.md` (99 new), `_pages/reference/{introduction,domain-model,bibliography,organizational-scenarios,team,contributing}.md`, `_data/anchors.yml`, `tools/migrate/report.md`
- Modify: `_pages/patterns/{evaluate,improve,crosscutting,analyze}.md`, pilot patterns (anchor ids only), `tests/site_test.rb`

**Interfaces:**
- Consumes: `make migrate` (Task 5).
- Produces:
  - the committed raw conversion that Tasks 7–10 review;
  - `test_every_old_anchor_resolves`;
  - `tools/migrate/report.md`, the work list for Tasks 7–10.

- [ ] **Step 1: Write the failing anchor test**

Add to `tests/site_test.rb`:

```ruby
  # Every anchor of the old AsciiDoc reference has a working new home (spec §9),
  # so the phase-3 redirector can send aim42.github.io/#Anchor there.
  def test_every_old_anchor_resolves
    anchors = YAML.safe_load(File.read(File.join(ROOT, "_data", "anchors.yml")))
    docs = {}
    anchors.each do |old, url|
      target, fragment = url.split("#", 2)
      assert site_file(target), "anchor #{old}: #{target} is not generated"
      next unless fragment
      doc = (docs[target] ||= page(target))
      assert doc.css("[id]").any? { |e| e["id"] == fragment }, "anchor #{old}: ##{fragment} missing on #{target}"
    end
  end
```

Run: `make site-test`. Expected: error, because `_data/anchors.yml` does not exist yet.

- [ ] **Step 2: Convert**

Run: `make migrate`
Expected:
- The output is `25 report entries; see tools/migrate/report.md`.
- `ls _patterns | wc -l` gives 105.
- Six reference pages and three drafts in `tools/migrate/out/` exist.
- The report holds three kinds of notes:
  - 11 × "intent taken from pattern-index.adoc";
  - 11 × "intent section has more than one paragraph";
  - 3 × "intent taken from the first paragraph".
- It holds no unresolved xref, no missing image, no duplicate anchor and no "no intent found".

Any other note means the sources or the toolchain differ from the prototype run. Stop and report it.

- [ ] **Step 3: Merge the phase-page drafts (R16)**

For each of `evaluate`, `improve` and `crosscutting`, open `tools/migrate/out/<phase>.md` next to `_pages/patterns/<phase>.md`. The pilot's sections were edited by hand: keep them as they are.

1. From the draft, add every section that the page lacks. Put them in draft order, before the final `## … patterns and practices …` heading that holds the `pattern-list` include. For example, the improve page gains:
   - Fundamentals
   - Improvement Approaches (Overview)
   - Improvement Practices (Overview)
   - Approaches, Practices and Regular Development
   - Improvement Approaches (Details)
   - Improvement Practices (Details), and the four category sections

   The evaluate page gains Estimation. The cross-cutting page gains Goals and Overview.
2. Keep every `{#id}` from the draft on its heading, and every `{: #id}` on its paragraph. These ids are old anchors.
3. Delete bullet lists that only repeat links to this phase's patterns ("(given in alphabetical order)", "… Practices in Detail"). The generated pattern list replaces them. Keep the concept-map images that the image maps turned into.

- [ ] **Step 4: Give hand-converted pages their old anchor ids**

Run: `make site-test`. `test_every_old_anchor_resolves` reports fragments missing on pilot pages (e.g. `#figure-atam-approach` on `/patterns/atam/`, `#figure-analyze-pattern-overview` on `/patterns/analyze/`), and on phase pages if Step 3 missed one. Add the id where the anchor sat in the source:
- on the line after an image: `{: #figure-atam-approach}`
- on a heading: ` {#improve-processes}`

Repeat until the test passes. Do not change `_data/anchors.yml` by hand.

- [ ] **Step 5: Run everything**

Run: `make check`
Expected: validate, unit and site tests are green, including `test_every_old_anchor_resolves`, the link test over all new pages, and the meta-description test over all 105 patterns.

- [ ] **Step 6: Commit**

```bash
git add _patterns _pages _data/anchors.yml tools/migrate/report.md tests/site_test.rb
git commit -m "Convert all patterns and reference chapters from AsciiDoc" -m "Generated by tools/migrate/run.rb; phase pages merged by hand. Reviewed per phase in the following commits." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Tasks 7–10: Content review (shared procedure)

Each review task covers one batch. For **every file in the batch**:

1. **Compare it with its source.** Find the source path in `tools/migrate/manifest.yml`; the files are under `_import/src/main/asciidoc/`.
   - Every paragraph, list item, table row, image, footnote and link of the source must appear in the Markdown, in the same order. Exceptions: the Intent and Related sections, which moved into front matter.
   - Restore anything that was lost.
2. **Work off the file's notes in `tools/migrate/report.md`:**
   - *Intent taken from pattern-index.adoc / the first paragraph*: keep it if it states the pattern's purpose in one sentence. Otherwise use the source's own best sentence for it. Never invent one.
   - *Intent section has more than one paragraph*: the extra blocks sit at the top of the body. Leave them unless they repeat the intent word for word.
3. **Fix conversion artifacts only:**
   - stray backslash escapes outside link texts;
   - broken list nesting;
   - leftover `{: …}` attribute lines that are not ids;
   - a hard line break (two spaces at a line end) that the source did not intend.

   Fix obvious misspellings ("protocoll", "neccessary"). Do not reword, shorten, merge sections or change heading names. Bibliography links keep their `[\[Key\]](…)` form.
4. **Check `related`:**
   - Every pattern the source's Related section linked to must be in `related` or in `## Notes on related patterns`.
   - Every slug in `related` must be a real relation, not a link that happened to sit in the section.
5. **Check `status`:** `stub` exactly when the body is empty.

After the batch:
- `make check` must be green.
- Record in the task report, per file: `ok` or the list of changes.

Commit with the message given in the task.

### Task 7: Review the analyze batch

**Files:** the 32 `_patterns/*.md` with `phase: analyze` (the pilots `atam`, `stakeholder-analysis` and `stakeholder-interview` included), `tools/migrate/report.md` (read only)

- [ ] **Step 1:** Run the shared procedure on every non-pilot analyze file.
- [ ] **Step 2: Restore the analyze pilots' relations and links.**
  - In the three analyze pilots, replace each `# phase 2 restores: a, b` comment by adding those slugs to `related`, then delete the comment lines:
    - `atam`: `qualitative-analysis, capture-quality-requirements`
    - `stakeholder-analysis`: `stakeholder-specific-communication`
    - `stakeholder-interview`: `questionnaire, pre-interview-questionnaire, stakeholder-specific-communication`
  - Restore xrefs that the pilot had to leave as plain text because the target did not exist yet. Compare each pilot file with the `<<…>>` xrefs of its source. For example, "*pre-interview questionnaire*" in `stakeholder-interview.md` becomes `[pre-interview questionnaire](/patterns/pre-interview-questionnaire/)`.
- [ ] **Step 3:** `make check` → green.
- [ ] **Step 4:** Commit: `git add _patterns && git commit -m "Review converted analyze patterns" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 8: Review the evaluate and cross-cutting batches

**Files:** the 4 `evaluate` and 20 `crosscutting` `_patterns/*.md` (pilot `improvement-backlog` included), `_pages/patterns/{evaluate,crosscutting}.md`

- [ ] **Step 1:** Run the shared procedure on every non-pilot file. Their sources are mostly sections of `evaluate.adoc` / `crosscutting.adoc` (`file#Anchor` in the manifest).
- [ ] **Step 2:** `improvement-backlog.md`: add `issue-list` to `related`, delete the `# phase 2 restores` comment, and restore links the pilot left as plain text.
- [ ] **Step 3:** Re-read the merged `evaluate` and `crosscutting` phase pages against `tools/migrate/out/`. The same rules apply: nothing lost, no rewording.
- [ ] **Step 4:** `make check` → green.
- [ ] **Step 5:** Commit: `git add _patterns _pages/patterns && git commit -m "Review converted evaluate and cross-cutting patterns" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 9: Review the improve batch and group the improve page by category

**Files:** the 49 `_patterns/*.md` with `phase: improve` (pilots `strangler-approach` and `assertions` included), `_pages/patterns/improve.md`, `_includes/aim42/pattern-list.html`, `_layouts/pattern.html`, `tests/site_test.rb`

- [ ] **Step 1:** Run the shared procedure on every non-pilot improve file.
- [ ] **Step 2:** `strangler-approach.md`: add `big-bang-approach` to `related`, delete the comment, and restore plain-text links.
- [ ] **Step 3: Failing tests.** Add to `tests/site_test.rb`:

```ruby
  CATEGORIES = YAML.safe_load(File.read(File.join(ROOT, "_data", "categories.yml"))).freeze

  def test_improve_page_groups_patterns_by_category
    doc = page("/patterns/improve/")
    improve = PATTERNS.select { |p| p["phase"] == "improve" }
    CATEGORIES.each_key do |key|
      group = doc.at_css(".pattern-group[data-category='#{key}']")
      assert group, "/patterns/improve/: group #{key} missing"
      mine = improve.select { |p| Array(p["categories"]).include?(key) }
      if mine.empty?
        assert_includes group.text, "No patterns in this category yet."
      else
        assert_pattern_list(group, mine, "/patterns/improve/ #{key}")
      end
    end
    other = doc.at_css(".pattern-group[data-category='other']")
    assert other, "/patterns/improve/: group other missing"
    assert_pattern_list(other, improve.select { |p| Array(p["categories"]).empty? }, "/patterns/improve/ other")
  end

  def test_category_chips_show_category_titles
    chips = page("/patterns/assertions/").css(".section-hero__chips .tag").map { |t| t.text.strip }
    assert_includes chips, CATEGORIES["architecture-and-code"]["title"]
  end
```

In `test_phase_pages_list_only_their_patterns`, add `next if phase == "improve" # grouped by category, see below` directly after the `assert_equal phase, …data-section…` line.

Run: `make site-test`. Expected: the two new tests fail.

- [ ] **Step 4: Implement.**

In `_includes/aim42/pattern-list.html`:
- After the `{% if include.phase %}…{% endif %}` block, add:

```liquid
{% if include.category == "none" %}
  {% assign items = items | where_exp: "p", "p.categories == nil" %}
{% elsif include.category %}
  {% assign items = items | where_exp: "p", "p.categories contains include.category" %}
{% endif %}
```

- Replace `<p>No patterns in this phase yet.</p>` with `<p>{{ include.empty | default: "No patterns in this phase yet." }}</p>`.

In `_pages/patterns/improve.md`, replace the single `{% include aim42/pattern-list.html phase="improve" %}` with:

```liquid
{% for entry in site.data.categories %}
<section class="pattern-group" data-category="{{ entry[0] }}">
<h3 id="category-{{ entry[0] }}">{{ entry[1].title }}</h3>
<p>{{ entry[1].blurb }}</p>
{% include aim42/pattern-list.html phase="improve" category=entry[0] empty="No patterns in this category yet." %}
</section>
{% endfor %}

<section class="pattern-group" data-category="other">
<h3 id="category-other">Other improvement patterns</h3>
{% include aim42/pattern-list.html phase="improve" category="none" %}
</section>
```

In `_layouts/pattern.html`, in the `chips` capture, replace `<span class="tag">{{ category }}</span>` with `<span class="tag">{{ site.data.categories[category].title | default: category }}</span>`.

- [ ] **Step 5:** `make check` → green.
- [ ] **Step 6:** Commit: `git add _patterns _pages/patterns/improve.md _includes/aim42/pattern-list.html _layouts/pattern.html tests/site_test.rb && git commit -m "Review converted improve patterns and group them by category" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`

### Task 10: Review the reference pages, add the authoring guide, link it all

**Files:** `_pages/reference/{introduction,domain-model,bibliography,organizational-scenarios,team,contributing}.md`, `_pages/reference/how-to-add-a-pattern.md` (new), `_pages/patterns/index.md`, `_data/navigation.yml`, `README.md`

- [ ] **Step 1:** Run the shared procedure on the six converted reference pages. Their sources are the `pages:` entries of the manifest. In `contributing.md`, replace the AsciiDoc-era instructions (fork, AsciiDoc, Gradle) with one sentence linking to `/reference/how-to-add-a-pattern/`. That is the only rewrite allowed (spec §6: "rewritten for the Markdown workflow").
- [ ] **Step 2:** Create `_pages/reference/how-to-add-a-pattern.md`:
  - Front matter: `title: How to add a pattern`, `layout: aim42-page`, `section: reference`, `permalink: /reference/how-to-add-a-pattern/`, `lede: Every pattern is one Markdown file — edit it on GitHub or locally.`
  - Body: the content of the section `## Adding or editing a pattern` of `README.md`, copied verbatim. Leave out that `##` heading itself, because the page title replaces it, and lift its `###` subheadings to `##`. Its rules list and front-matter example are the authoring contract the validator enforces.
  - Add one paragraph at the end: `Not sure where to start? Every pattern marked *stub* on the [pattern index](/patterns/) is waiting for a description.`

  In `README.md`, directly under that section's heading, add the line `This section is also published at <https://aim42.org/reference/how-to-add-a-pattern/>.`
- [ ] **Step 3:** In `_data/navigation.yml`, under `secondary:`, insert after the `Glossary` entry:

```yaml
  - label: Introduction
    url: /reference/introduction/
  - label: Bibliography
    url: /reference/bibliography/
  - label: Add a pattern
    url: /reference/how-to-add-a-pattern/
```

- [ ] **Step 4:** In `_pages/patterns/index.md`, replace the sentence `This is the pilot of the migrated method reference; the complete reference follows.` with `New here? Read the [introduction](/reference/introduction/) first.`
- [ ] **Step 5:** `make check` → green. Then `grep -rnE 'AIMFN|^\{: \.|^intent: TODO' _patterns _pages` must print nothing.
- [ ] **Step 6:** Commit: `git add _pages README.md _data/navigation.yml && git commit -m "Review reference chapters and add the pattern authoring guide" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`
- [ ] **Step 7:** Push the branch and wait for CI: `git push origin merge-method-reference`, then `gh run watch` on the new run. Expected: the "check" workflow succeeds.

---

### Task 11: Partner review (handoff)

Planned stop for the human partner, as Task 8 was in phase 1.

- [ ] **Step 1:** `make dev`, then give the partner:
  - URLs to spot-check: `/patterns/`, the four phase pages, five converted patterns (one per phase plus one stub), `/reference/introduction/`, `/reference/bibliography/` and `/glossary/`;
  - the Task 7–10 reports, which list per file what changed beyond the raw conversion.
- [ ] **Step 2:** Apply the partner's corrections. `make check` must stay green. Commit "Apply partner review of the converted reference" and push.

### Task 12: Retire the migration tooling (after the partner's sign-off)

Spec §3: "tools/: one-off migration scripts; deleted after phase 2"; `_import` goes too. The import's history stays in git.

**Files:** delete `_import/`, `tools/migrate/`, `tests/migrate_converter_test.rb`, `tests/migrate_source_test.rb`, `tests/migrate_run_test.rb`; modify `Gemfile`, `Gemfile.lock`, `Makefile`, `.github/workflows/check.yml`, `_config.yml`, `.gitignore`

- [ ] **Step 1:** `git rm -r -q _import tools/migrate tests/migrate_converter_test.rb tests/migrate_source_test.rb tests/migrate_run_test.rb`
- [ ] **Step 2:** Clean up the references:
  - Remove the `group :migration` block from `Gemfile`.
  - Remove the `migrate` target, its help line and its `.PHONY` entry from `Makefile`.
  - Remove the three `tests/migrate_*` files from the unit lists in `Makefile` and CI.
  - Remove `- _import` from `_config.yml`'s `exclude:`.
  - Remove `tools/migrate/out/` from `.gitignore`.
  - Then run `make lock && make build`.

  Keep `_data/anchors.yml` and `test_every_old_anchor_resolves`: phase 3 needs both.
- [ ] **Step 3:** `make check` → green.
- [ ] **Step 4:** Commit "Retire the one-off migration tooling", then push.
