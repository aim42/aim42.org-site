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

## Site Structure

![](zz-resources/site-navigation.png)


## Credits

#### Icons + Images:

* Free images can be found at [Unsplash](https://unsplash.com/)
* I generated the various favicon files with [RealFavIconGenerator](http://realfavicongenerator.net/).


---

## Licenses


### aim42
aim42 is licensed under a [CreativeCommons Sharealike International 4.0 License](https://creativecommons.org/licenses/by-sa/4.0/).

You are free to:

* **Share** — copy and redistribute the template in any medium or format
* **Adapt** — remix, transform, and build upon the material for any purpose, even commercially.
