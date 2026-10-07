# Phase 3a: the new home page

Design spec, 2026-10-07. Status: approved in conversation, awaiting written review.
Parent spec: `2026-10-07-method-reference-merge-design.md` (phase 3).

## 1. Goal and scope

Phase 3 is split in two sub-projects, each with its own spec, plan and implementation:

- **3a, look and feel:** the home page (this spec), then navigation and the other old
  pages on the aim42 layouts (later specs or a later section of this one).
- **3b, cut-over:** GitHub Actions deploy, redirect shim on `aim42.github.io`,
  `aim42/aim42` archived. Starts after 3a is accepted.

The home page explains **the method first**: a first-time visitor understands what
aim42 is and why to use it; the patterns follow further down. It is written for
**architects and developers** who face an existing system that has become hard to
change. Decision makers are served by the evaluate phase (cost and value), not by a
separate path.

Out of scope here: the logo, the "42" dropdown (arc42, req42, systems42) next to the
hamburger, re-skinning the other pages, navigation changes, deploy, redirects,
archiving.

## 2. Page structure

Top to bottom:

1. **Hero** (layout A): headline and lede on the left, the cycle graphic on the right.
   Buttons "How it works" (`#how-it-works`) and "Browse N patterns" (`/patterns/`,
   N counted at build time).
2. **How it works** (`id="how-it-works"`): four phase cards in the phase colours
   (variant X). Each card: phase name linking to the phase page, the phase
   description, three example patterns as links, and "All N <phase> patterns".
3. **Get started:** three numbered steps, each with links to patterns, and a link to
   `/getstarted`.
4. **Free and open:** two boxes. Free, open source, no vendor or tool lock-in,
   built from the experience of many contributors; and the contribution call
   ("Every pattern is one Markdown file on GitHub", link to
   `/reference/how-to-add-a-pattern/`).

Copy rule: no dashes as sentence punctuation; commas or semicolons instead.

## 3. Data

All editable text sits in the front matter and body of `_pages/home.md`:

```yaml
layout: home
permalink: /
title: Architecture Improvement Method
headline: Improve software systems, systematically.
lede: "aim42 is a free, open method for architects and developers: analyze what hurts, evaluate what it costs, improve what's worth it, step by step."
cycle:
  analyze: find the issues
  evaluate: value and effort
  improve: fix step by step
  crosscutting: plan and keep on track
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
```

The body holds the two Free and open paragraphs.

Derived at build time, never stored on the home page:

- phase title, URL and description: from `_data/phases.yml` (`title`, `url`,
  `blurb`), which the `/patterns/` index already uses; the blurbs are the same texts
  as the phase pages' `lede`;
- pattern counts: `site.patterns` filtered by `phase`;
- example titles: from the pattern's `title`.

`lede` (not a new key) feeds the meta description through the existing base layout.

## 4. Components

| File | Purpose |
|---|---|
| `_layouts/home.html` | On `aim42-base`. Hero, How it works, Get started, then `content` as Free and open |
| `_includes/aim42/cycle.html` | Inline SVG cycle, links to the phase pages |
| `_includes/aim42/phase-cards.html` | The four cards (description, count, examples) |
| `_sass/pages/_home.scss` | Styles; existing tokens and `$home-stack-width` / `$home-edge-width` |

The Minimal Mistakes `splash` layout and the banner image are no longer used by the
home page; the image files stay until the other pages move (3a later part).

## 5. Cycle graphic

- Inline SVG, so links work and colours come from the CSS custom properties
  (`--phase-*`); a palette change updates it.
- Three arcs with arrowheads, clockwise: Analyze (top left) to Evaluate (right) to
  Improve (bottom); Cross-cutting as the centre circle. Same shape as
  `images/aim42-process-2017.png`.
- Each arc and the centre is a link to its phase page. Tab order: Analyze, Evaluate,
  Improve, Cross-cutting. Hover and focus thicken the arc; focus outline visible.
- Labels are SVG text in the phase `-text` colours, with the `cycle:` line below.
- Accessibility: wrapped in `<nav aria-label="aim42 phases">`; each link has an
  accessible name like "Analyze: find the issues"; arcs and arrowheads are
  `aria-hidden`.
- Size: about 380 px wide beside the pitch; below 860 px it moves under the buttons,
  at most 320 px; below 560 px the `cycle:` lines are hidden so the phase names stay
  at least 15 px.
- No JavaScript, no animation.

## 6. Responsive behaviour and accessibility

- Headings: the headline is the only H1; "How it works", "Get started", "Free and
  open" are H2; phase names on the cards are H3. Browser title: "Architecture
  Improvement Method | aim42".
- 860 px and wider: hero in two columns, cards 2×2, steps in three columns, Free and
  open in two. Below 860 px: one column, cycle below the buttons. Below 560 px:
  cards in one column.
- Phase names and links use the `-text` shades. Colour is never the only signal.
- Links and buttons at least 44 px tall; visible focus; the skip link keeps working.

## 7. Validation and tests

- `tools/validate.rb` (runs in the build): every slug under `examples:` and
  `get_started:` exists; each phase has exactly three examples and each belongs to
  that phase; `headline` and `lede` are present. Any finding fails the build.
- `tests/site_test.rb` on the built site: one H1 equal to the headline; meta
  description equals the lede; the cycle has four links to the four phase pages;
  each "All N" count equals the phase's pattern count, and "Browse N patterns" the
  total; all example and Get started links resolve to existing pattern pages; no
  Minimal Mistakes markup on `/`.
- `tests/contrast_test.rb`: each phase `-text` colour on white and on the page
  background.
- `make check` green; preview checked at 375 px and desktop width, including a
  keyboard-only walk through the links.
- GitHub issue "Review homepage copy" (label "help wanted") listing headline, lede,
  cycle lines, Get started steps and Free and open text.
