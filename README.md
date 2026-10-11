![aim42](images/logo/AIM42_black.svg)

# aim42 Public Website

This repo contains the code for the aim42.org public website.

It's built with the Jekyll static site generator.

## Local development

Requirements: [Docker](https://www.docker.com/). No local Ruby needed.

    make build      # once, and after Gemfile.lock changes
    make dev        # serve on http://localhost:4242
    make check      # validate pattern front matter, unit tests, build, site tests

## Adding or editing a pattern

This section is also published at <https://aim42.org/reference/how-to-add-a-pattern/>.

Patterns live in `_patterns/<phase>/<slug>.md`, one file each, in the folder of
their `phase`; the filename is the URL:
`_patterns/analyze/stakeholder-interview.md` → `/patterns/stakeholder-interview/`.

    ---
    title: Introduce Layering
    phase: improve            # analyze | evaluate | improve | crosscutting
    intent: "One sentence: what this practice achieves."
    related: [refactoring]            # optional, slugs of other patterns
    categories: [architecture-and-code]   # optional, improve patterns only
    status: complete          # complete | stub
    ---

    Short summary paragraph.

    ## Description
    ...
    ## Experience
    ...
    ## References
    ...

Rules (checked by `make validate`, in every Jekyll build and in CI; `make check`
runs the full local check, and CI runs the same):
`title`, `phase`, `intent` and `status` are required; `title` and `intent` are
strings; `intent` is one paragraph of inline Markdown (it is shown in lists and
the page description) and must not be `TODO`; `categories` apply to improve
patterns only and must be keys of `_data/categories.yml`; `related` must list existing slugs; the filename is a
kebab-case slug, unique across `_patterns/`, and must not be `index` or a phase
name (`analyze`, `evaluate`, `improve`, `crosscutting`), which are reserved for
the index and phase pages. A `status: stub` pattern needs only the front
matter; the site shows a "help us write it" box.

Quote front-matter values that contain `: ` (colon followed by a space), as in
the `intent` above; otherwise YAML reads them as a nested mapping.

**Editing on GitHub.** Open the pattern page's "Edit this pattern on GitHub" link
(or create a new file in the phase folder, e.g. <https://github.com/aim42/aim42.org-site/new/main/_patterns/analyze/>),
commit to a branch and open a pull request. CI validates the front matter.

Glossary terms link to `/glossary/#term`, e.g. `[system](/glossary/#system)`.

## Site Structure

The header bar has four sections plus search; each section page lists its pages.
`_data/navigation.yml` is the source of truth (a test checks that every URL in it
appears below). URLs are flat: `/principles`, not `/getstarted/principles`.

```text
/                                Home                    _pages/home.md
├── /getstarted                  Get started             _pages/getstarted.md
│   ├── /principles              Principles              _pages/principles.md
│   ├── /using                   Using aim42             _pages/using.md
│   ├── /examples                Examples                _pages/examples.md
│   └── /assets/downloads/AIM42-Whitepaper-v2.0.pdf      Whitepaper (PDF)
├── /patterns/                   Patterns                _pages/patterns/index.md
│   ├── /patterns/analyze/       Analyze                 _pages/patterns/analyze.md
│   ├── /patterns/evaluate/      Evaluate                _pages/patterns/evaluate.md
│   ├── /patterns/improve/       Improve                 _pages/patterns/improve.md
│   ├── /patterns/crosscutting/  Cross-cutting           _pages/patterns/crosscutting.md
│   ├── /patterns/<slug>/        one page per pattern    _patterns/<phase>/<slug>.md
│   └── /reference/domain-model/ Domain model            _pages/reference/domain-model.md
├── /learn                       Learn                   _pages/learn.md
│   ├── /reference/introduction/ Introduction            _pages/reference/introduction.md
│   ├── /publications            Publications            _pages/publications.md
│   ├── /training                Training                _pages/training.md
│   ├── /faq                     FAQ                     _pages/faq.md
│   ├── /glossary/               Glossary                _pages/reference/glossary.md
│   └── /reference/bibliography/ Bibliography            _pages/reference/bibliography.md
├── /about                       About                   _pages/about.md
│   ├── /contact                 Contact                 _pages/contact.md
│   ├── /contribute              Contribute              _pages/contribute.md
│   ├── /license                 License                 _pages/license.md
│   └── /imprint/                Imprint & Privacy       _pages/imprint.md
└── /search/                     Search (header button)  _pages/search.md

Footer:            Contact · GitHub (github.com/aim42) · Imprint + Privacy
Not in navigation: /reference/how-to-add-a-pattern/ (linked from home and Contribute),
                   /404.html (404.html)
```

Shared page parts live in `_includes/aim42/` (header, footer, cycle, search dialog),
layouts in `_layouts/`, data in `_data/`, images in `images/` (pattern diagrams in
`images/patterns/`, their OmniGraffle sources in `original-graphics/`, which is not
published).

## Credits

#### Icons + Images:

* The favicon and logo mark (`images/logo/aim42-mark.svg`) show the aim42 cycle
  from the home page: analyze, evaluate, improve around the cross-cutting hub.


---

## Licenses


### aim42
aim42 is licensed under a [CreativeCommons Sharealike International 4.0 License](https://creativecommons.org/licenses/by-sa/4.0/).

You are free to:

* **Share** — copy and redistribute the template in any medium or format
* **Adapt** — remix, transform, and build upon the material for any purpose, even commercially.
