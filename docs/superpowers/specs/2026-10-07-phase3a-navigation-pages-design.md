# Phase 3a, part 2: navigation and the remaining pages

Design spec, 2026-10-07. Status: approved in conversation, awaiting written review.
Parent spec: `2026-10-07-method-reference-merge-design.md` (phase 3). Sibling specs:
`2026-10-07-phase3a-homepage-design.md` (done), `2026-10-07-phase3a-search-design.md`
(search; built after this one).

## 1. Goal and scope

Every page of aim42.org uses the aim42 layouts, the navigation is rebuilt around four
sections, and the Minimal Mistakes theme is gone from the repository.

In scope:

- header bar, hamburger menu and the new SVG logo;
- section pages for Get started, Learn and About;
- moving the remaining old pages and `404.html` onto aim42 layouts, with factual fixes;
- removing Minimal Mistakes completely (gems, config, files, README, tests).

Out of scope: search (sibling spec; this spec only places the search button), the "42"
dropdown, rewriting page copy, deploy and redirects (3b).

Copy rule: no dashes as sentence punctuation in visible text; commas or semicolons.

## 2. Navigation data

`_data/navigation.yml` is the single source for the header bar, the hamburger menu and
the section cards. Its current lists (`main`, `getstarted`, `learn`, `about`,
`primary`, `secondary`) are replaced by:

```yaml
bar:            # header bar, left to right; the search button and hamburger follow
  - getstarted
  - patterns
  - learn
  - about
sections:
  getstarted:
    title: Get started
    url: /getstarted
    lede: <one line>
    pages:
      - { title: Principles, url: /principles, blurb: <one line> }
      - { title: Using aim42, url: /using, blurb: <one line> }
      - { title: Examples, url: /examples, blurb: <one line> }
      - { title: Whitepaper (PDF), url: /assets/downloads/AIM42-Whitepaper-v2.0.pdf, blurb: <one line> }
  patterns:
    title: Patterns
    url: /patterns/
    pages: Analyze, Evaluate, Improve, Cross-cutting, Glossary, Introduction,
           Domain model, Bibliography, Organizational scenarios
  learn:
    title: Learn
    url: /learn
    pages: Publications, Training, FAQ
  about:
    title: About
    url: /about
    pages: Contact, Contribute, Contributing to the reference, How to add a pattern,
           Team, License, Imprint
```

(`<one line>` blurbs are written during implementation from each page's first
paragraph, following the copy rule, and listed in the copy review issue of §5.)

A page's section is derived from this file by URL (§3), so a page needs no new front
matter to join a section; moving a page means editing this file only. (This replaces
the `section: <key>` front matter discussed in conversation: one source instead of
two that can disagree.) The existing `section:` front-matter key of `aim42-page` keeps
its current meaning, the hero colour (`analyze`, `patterns`, `reference`, …).

## 3. Header and menu

- **Logo:** `images/logo/AIM42_white.svg` (new, committed with this change), alt text
  "aim42", linking to `/`; "architecture improvement method" stays as text beside it.
  `images/logo/AIM42_black.svg` and both PNGs are committed too, unused for now.
  `images/aim42-site-logo.png` is removed.
- **Bar:** logo, then the four sections from `bar:`, then a search button, then the
  hamburger. The search button is a placeholder in this spec (a link to `/search/`,
  which the search spec builds); until then it is hidden.
- **Current section:** the bar entry of the page's section gets `aria-current="page"`
  on the section page itself and `aria-current="true"` plus the active style on its
  pages. A page's section is the section whose `url` or `pages[].url` equals the page
  URL; pattern pages belong to `patterns`.
- **Hamburger menu:** four groups in bar order; each group heading links to the
  section page, followed by its pages. The open/close script (`assets/js/aim42.js`)
  and the label "Navigation menu" stay.
- **Phones:** below `$nav-compact-width` the four bar entries are hidden; logo, search
  and hamburger remain; everything is reachable in the menu.

## 4. Pages

### 4.1 Section pages

New layout `_layouts/aim42-section.html` on `aim42-base`: section hero (title, lede),
the page's own content, then one card per page of the section (title linking to the
page, blurb), styled like the home page phase cards. Used by `/getstarted`, `/learn`,
`/about`; their current text stays above the cards.

### 4.2 Other pages

Use `aim42-page`. The hero eyebrow shows the section title linking to the section page,
taken from the navigation data (no per-page `eyebrow_label`/`eyebrow_href` needed).

| Page | Section |
|---|---|
| principles, using, examples | getstarted |
| publications, training, faq | learn |
| contact, contribute, license, imprint | about |
| reference/contributing, reference/how-to-add-a-pattern, reference/team | about |
| 404.html | none (no eyebrow) |

### 4.3 What is removed from every page

Banner image and caption (`header:`), `sidebar:`, Font Awesome icons (`<i class="fa…">`),
Minimal Mistakes includes and classes: `feature_row` (Contribute, Publications) becomes
plain Markdown (headings, paragraphs, lists, images); `{: .notice…}` becomes the
existing callouts (`_sass/components/_callouts.scss`).

### 4.4 Factual fixes (text otherwise unchanged)

- Contact: remove both Twitter entries and Xing; add LinkedIn
  `https://www.linkedin.com/in/gernotstarke/`; keep the obfuscated email link, without
  icon.
- Publications: remove the two embedded Twitter timelines; keep the publication list.
- reference/contributing: remove the Twitter line.
- Get started: "over 90" becomes the pattern count computed at build time.
- Links to `github.com/aim42/aim42` meaning issues or source point to
  `github.com/aim42/aim42.org-site`.
- Dashes as sentence punctuation in touched sentences become commas or semicolons.

URLs stay as they are (`/about`, `/faq`, `/imprint/`, …).

## 5. Removing Minimal Mistakes

- **Gemfile:** remove `minimal-mistakes-jekyll`; add `gem "jekyll", "4.3.1"`,
  `gem "jekyll-sass-converter", "~> 2.2"` (the contrast and CSS tests rely on libsass
  passing `color-mix()` through) and `jekyll-sitemap` in `:jekyll_plugins`. Drop
  `jekyll-gist`, `jekyll-feed`, `jemoji`, `jekyll-include-cache`, `jekyll-paginate`.
  Regenerate `Gemfile.lock` (`make lock`, `make build`).
- **`_config.yml`:** remove `theme`, `minimal_mistakes_skin`, theme-only settings
  (author, social, comments, atom feed, search, analytics, archives, theme `defaults`)
  and the GitHub Pages `whitelist`; `plugins:` lists only `jekyll-sitemap`. Comments
  naming the theme or its author go.
- **Files removed:** `_includes/masthead.html`, `_includes/footer.html`,
  `assets/css/main.scss`, `assets/css/footer.css`, everything in `assets/js/` except
  `aim42.js` (jQuery, theme scripts, Lunr 2.1.5), `images/splash/`, the old home page
  images (`aim42-splash*.png`, `*-phase.png`, `*-splash-4-website.png`) and
  `aim42-site-logo.png`. An image is only removed when no page, pattern or layout
  references it.
- **README.md:** the credits for Michael Rose and the theme go.
- **Mentions:** no file outside `docs/superpowers/` mentions Minimal Mistakes. The
  planning documents under `docs/superpowers/` are historical records and stay as
  written.
- **Copy review:** one issue "Review migrated pages" (label "help wanted"): section
  ledes and blurbs, the overlap of Contribute and Contributing to the reference, and
  any text that reads outdated but was kept.

## 6. Tests

- Navigation data: every `url` resolves to a built page or file; every page under
  `_pages/` (except `home.md`, the search page of the sibling spec and pages under
  `_pages/patterns/`, which belong to `patterns`) is listed in exactly one section;
  every listed page URL appears at most once.
- Header, on a pattern page, `/contact` and `/about`: bar labels are Get started,
  Patterns, Learn, About in that order; the current section is marked; the menu has
  four groups with their pages; the logo is `AIM42_white.svg` with alt "aim42".
- Section pages: `/getstarted`, `/learn`, `/about` show one card per page of their
  section, with title, link and blurb from the navigation data.
- Migrated pages: all pages use an aim42 layout and show their section eyebrow;
  `/contact` links to LinkedIn and to neither Twitter nor Xing; no built page links to
  twitter.com, x.com or xing.com.
- Old theme gone: no file in the repository outside `docs/superpowers/` (and the test
  file itself) mentions Minimal Mistakes; no built page contains theme markup
  (`.page__hero`, `.masthead`, `.feature__wrapper`, `.sidebar`, `.page__content`).
- The existing link and image checks run over every built page (the `PAGES` list grows
  to all pages).
- Visual check at 375 and 1280 px with the Playwright image: header, open menu, one
  section page, two migrated pages.
