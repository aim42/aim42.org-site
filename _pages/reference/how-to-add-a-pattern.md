---
title: How to add a pattern
layout: aim42-page
section: reference
permalink: /reference/how-to-add-a-pattern/
lede: Every pattern is one Markdown file — edit it on GitHub or locally.
---

Patterns live in `_patterns/<slug>.md`, one file each; the filename is the URL:
`_patterns/stakeholder-interview.md` → `/patterns/stakeholder-interview/`.

    ---
    title: Stakeholder Interview
    phase: analyze            # analyze | evaluate | improve | crosscutting
    intent: "One sentence: what this practice achieves."
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

Rules (checked by `ruby tools/validate.rb`, in every Jekyll build and in CI):
`title`, `phase`, `intent` and `status` are required; `title` and `intent` are
strings; `intent` is one paragraph of inline Markdown (it is shown in lists and
the page description); `related` must list existing slugs; the filename is a
kebab-case slug, unique across `_patterns/`, and must not be `index` or a phase
name (`analyze`, `evaluate`, `improve`, `crosscutting`), which are reserved for
the index and phase pages. A `status: stub` pattern needs only the front
matter; the site shows a "help us write it" box.

Quote front-matter values that contain `: ` (colon followed by a space), as in
the `intent` above; otherwise YAML reads them as a nested mapping.

Glossary terms link to `/glossary/#term`, e.g. `[system](/glossary/#system)`.

Not sure where to start? Every pattern marked *stub* on the [pattern index](/patterns/) is waiting for a description.
