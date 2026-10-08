---
title: How to add a pattern
layout: aim42-page
section: reference
permalink: /reference/how-to-add-a-pattern/
lede: Every pattern is one Markdown file; edit it on GitHub or locally.
---

Patterns live in `_patterns/<slug>.md`, one file each; the filename is the URL:
`_patterns/stakeholder-interview.md` → `/patterns/stakeholder-interview/`.

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
(or create a new file at <https://github.com/aim42/aim42.org-site/new/master/_patterns/>),
commit to a branch and open a pull request. CI validates the front matter.

Glossary terms link to `/glossary/#term`, e.g. `[system](/glossary/#system)`.

Not sure where to start? Every pattern marked *stub* on the [pattern index](/patterns/) is waiting for a description.
