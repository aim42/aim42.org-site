# Merge the aim42 method reference into aim42.org-site

Design spec, 2026-10-07. Status: approved in conversation, awaiting written review.

## 1. Goal

aim42.org becomes *the* reference for patterns and practices of architecture and
software-system improvement. Contributing a pattern must be as easy as editing one
Markdown file on GitHub. One repository, one build.

### Current state

- `aim42/aim42.org-site`: Jekyll site, Minimal Mistakes theme, ~14 Markdown pages,
  hosted on Netlify. Links out to the reference in six places.
- `aim42/aim42` (local clone: `method-reference`): the reference as one AsciiDoc
  book, ~5000 lines, ~65 pattern files, 117 anchors, ~540 `<<xref>>`s. Built with
  Gradle/Asciidoctor and published by Travis to `aim42.github.io`.
- `aim42.github.io`: generated HTML only (all commits are build artifacts). Last
  publish 2020-12-03; six real source changes since then were never published.

### Decisions already taken

| Topic | Decision |
|---|---|
| Content format | Markdown |
| Host repository | `aim42/aim42.org-site`; `aim42/aim42` gets archived afterwards |
| Content source | `aim42/aim42` only (the HTML guide is a stale derivative) |
| Theme | quality.arc42.org (Q42) layouts and structure, **not** its palette |
| Palette | aim42's red/blue/green, modernized and subtler; tuned during the pilot |
| Structure | Analyze / Evaluate / Improve / Crosscutting stay the primary structure |
| URLs | flat: `/patterns/<slug>/` |
| Stubs | published, marked as stubs with a contribution call-to-action |
| Sequencing | pilot of ~5 patterns drives layout and palette, then bulk migration, then re-skin and cut-over |

### Out of scope (separate discussions)

- The interactive graph (Q42-style D3 view). The content model is designed so it
  can be added later from front matter alone.
- Hosting target: GitHub Pages vs. Netlify. Either way the build runs in GitHub Actions.
- Navigation and content structure of the marketing pages (except the home page,
  whose redesign is part of phase 3).
- The final palette values.

## 2. Phases

1. **Pilot.** Import Q42's theme scaffolding. Hand-convert five patterns spanning the
   structure: Stakeholder Interview (analyze), ATAM (analyze, long), Strangler
   Approach (improve, approaches), Improvement Backlog (crosscutting), Assertions
   (stub). Build the `pattern` layout, one phase page,
   the index, the stub box. Tune the palette. Preview deploy; the live site is untouched.
2. **Bulk content.** Scripted conversion of the remaining patterns, cross-reference
   rewrite, non-pattern chapters as pages, validation in the build.
3. **Re-skin and cut-over.** Existing pages onto the Q42 layouts, a redesigned home page
   (added 2026-10-07 by the project owner), navigation, redirect shim on
   `aim42.github.io`, `aim42/aim42` archived. Split into 3a (look and feel: home page,
   navigation, other pages, search; specs `2026-10-07-phase3a-homepage-design.md`,
   `2026-10-07-phase3a-navigation-pages-design.md`, `2026-10-07-phase3a-search-design.md`)
   and 3b (cut-over: deploy, redirects, archiving).

Each phase gets its own implementation plan.

## 3. Repository layout (target)

```
aim42.org-site/
├── _patterns/                 one .md per pattern, flat; slug = filename
├── _pages/                    existing pages + reference chapters (_pages/reference/*.md)
├── _data/phases.yml           analyze/evaluate/improve/crosscutting: title, order, color token, blurb
├── _data/categories.yml       the four improve categories: title, blurb
├── _data/glossary.yml         terms from glossary.adoc
├── _data/anchors.yml          old AsciiDoc anchor → new URL (used by xref rewrite and redirector)
├── _layouts/ _includes/ _sass/   copied from Q42 and adapted (no shared gem)
├── images/patterns/           from method-reference src/main/resources/images
├── assets/downloads/          whitepaper, questionnaire, cost/effort sheet
├── tools/                     one-off migration scripts; deleted after phase 2
└── docs/superpowers/          specs and plans
```

- Build: Jekyll only in phases 1–3. No Node step until the graph arrives.
- The site is built by GitHub Actions (decided 2026-10-07). The Gemfile keeps an explicit
  gem list instead of the `github-pages` gem set, whose safe mode would disable the site's
  plugins (`_plugins/`: build-time pattern validation, meta-description filter).
- Docker dev setup (`make dev`) copied from Q42.
- History: `git subtree add --prefix=_import <aim42/aim42>` keeps blame; files then
  move to their final places in ordinary commits.

## 4. Content model

One file per pattern, `_patterns/<slug>.md`. Slug = kebab-case of the existing anchor
(`Stakeholder-Interview` → `stakeholder-interview`), so old anchor → new URL is mechanical.

```yaml
---
title: Stakeholder Interview
phase: analyze                 # analyze | evaluate | improve | crosscutting
categories: [communication]    # optional; improve uses its four existing categories
intent: Learn from the people who know or care about the system and everything around it.
related: [stakeholder-analysis, questionnaire, pre-interview-questionnaire]
status: complete               # complete | stub
---
```

Rules:

- `title`, `phase`, `intent`, `status` are required. A missing or unknown `phase`
  fails the build.
- No per-file `permalink`. `_config.yml` sets `/patterns/:name/` for the collection.
- `related` holds slugs. Unknown slugs fail the build.
- `intent` is the teaser on phase pages and the index; `pattern-index.adoc` disappears.
- `status: stub`: body is whatever one-liner exists. The layout renders a
  "This practice is a stub — help us write it" box linking to the GitHub editor for
  the file.
- Body headings keep the existing names: **Description**, **Experience**,
  **References**. Intent lives in front matter. "Related Patterns" is rendered from
  `related`; a prose list that only repeated the links is dropped in conversion, prose
  that adds explanation stays in the body.
- A pattern belongs to exactly one phase; `crosscutting` is a phase, not a tag.
- Glossary terms (`<<System>>` etc.) become plain links to `/glossary/#<term>`.

## 5. Conversion pipeline (phase 2)

- `tools/convert.rb`: per pattern file, run `kramdoc` (kramdown-asciidoc), then
  post-process: `[[Anchor]]` → slug/filename; `[pattern]#Title#` heading → `title`;
  first paragraph under `Intent` → `intent`; bullet list under `Related Patterns` →
  `related`; shift headings up three levels (patterns were `====` inside the book).
- `tools/xrefs.rb`: rewrite `<<Anchor>>` and `<<Anchor,text>>` in all converted files
  using `_data/anchors.yml` (117 anchors; each maps to one pattern slug or one
  glossary term). Unresolved references go to a report file; nothing is dropped silently.
- Passthrough HTML blocks (`++++`, including the image maps in `analyze.adoc` and
  `crosscutting.adoc`) become plain images. Image maps do not survive; the generated
  phase pages take over their job.
- Every converted file gets a human review against a diff of the original. The five
  pilot patterns, converted by hand in phase 1, serve as the oracle for the converter.

## 6. Non-pattern content

| Source (`src/main/asciidoc/`) | Target |
|---|---|
| `aim42_introduction.adoc`, `aim42-overview.adoc` | `_pages/reference/introduction.md` (one page) |
| prose of `analyze/evaluate/improve/crosscutting.adoc` (Goals, How it works) | blurb in `_data/phases.yml` plus the Markdown body of the generated phase page `/patterns/analyze/` etc. |
| `improve-approaches.adoc`, `improve-practices.adoc`, `patterns/category-improve-*.adoc` | the four improve categories as `categories:` values; intro text in `_data/categories.yml` |
| `pattern-index.adoc` | generated index at `/patterns/`; its stub one-liners seed the stub files |
| `appendices/glossary.adoc` | `_data/glossary.yml` + `/glossary/` page |
| `appendices/domain-model`, `bibliography`, `organizational-scenarios`, `team`, `contributing`, `howto-add-new-pattern` | `_pages/reference/*.md`; "how to add a pattern" is rewritten for the Markdown workflow |
| `about.adoc`, `appendices/license.adoc`, `asciidoc-help.adoc`, `organizational-stuff.adoc` | dropped (site already has about/license; the rest is obsolete) |
| `src/main/resources/{whitepaper,docs,*.xlsx}` | `assets/downloads/` |
| `src/main/resources/images` | `images/patterns/` |

## 7. Pilot and theme (phase 1)

- Copy from Q42: `_layouts/default`, the `approach` layout as basis for `pattern`,
  header/footer includes, `_sass` structure, Docker dev setup, the Playwright/WCAG
  test scaffold (tests adapted later).
- Palette: new SCSS tokens for the four phases (red/blue/green for
  analyze/evaluate/improve, a neutral for crosscutting) plus text and background.
  Contrast checked with Q42's existing script.
- Deliverable: preview deploy with one phase page, the index, five pattern pages, the
  stub box. Palette and layout are fine-tuned on that preview.

## 8. Redirects and wind-down (phase 3)

- `aim42.github.io`: replaced by one `index.html` with a JS fragment redirector
  (`#Stakeholder-Interview` → `https://aim42.org/patterns/stakeholder-interview/`),
  generated from `_data/anchors.yml`. Unknown fragments land on `/patterns/`.
- `aim42/aim42`: README replaced by a pointer, repository archived. Open issues moved
  to `aim42.org-site` or closed with a comment.
- The six in-site links to `aim42.github.io` are rewritten.

## 9. Validation

- `tools/validate.rb`, run in the build: unknown phase or related slug, missing
  required front matter, duplicate titles. Any finding fails the build.
- Link check on the built site (Q42's `validate-links` or htmlSanityCheck).
- Before cut-over: each of the 117 old anchors resolves through the redirector to a
  page that returns 200.

## 10. Risks

- **Conversion fidelity.** Mitigated by the pilot-as-oracle and per-file diff review.
- **Links in the wild** to `aim42.github.io/#Anchor`. Mitigated by the redirector; the
  anchor table is the single source for both xref rewrite and redirects.
- **Overclaiming "~90 practices"** while only ~65 have content. Mitigated by the visible
  stub status; the index can show counts honestly.
- **Theme drift from Q42.** Accepted: the copy is a fork, not a shared gem. The
  palette diverges by design.
