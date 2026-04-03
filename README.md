# Specifiable — Blog Source

Source code for [jskri.github.io](https://jskri.github.io), a blog on
modeling, formal methods, and correct-by-construction software.

---

## Philosophy

The site is built entirely with [pandoc](https://pandoc.org/) and
[make](https://www.gnu.org/software/make/), with no static site generator,
no JavaScript framework, and no build system beyond these two tools. The goal
is to keep the Markdown source readable and semantically meaningful, and to
delegate all formatting and transformation work to pandoc filters and
templates.

Concretely:
- Math is written in a readable `equation` fenced block in Markdown. A Lua
  filter (`equation_to_tex.lua`) handles the mechanical work: adding spacing,
  line breaks, and distinguishing syntactic elements (typeset in `\texttt{}`)
  from semantic ones (typeset in math mode). The Markdown source stays clean.
- Images are written as standard Markdown image syntax. A Lua filter
  (`figure_to_img.lua`) strips pandoc's automatic `<figure>` wrapper and
  emits a bare `<img>`, since the post layout does not use captions.
- The index page is generated purely from metadata — there is no `index.md`.
  The pandoc template iterates over a list of posts defined in
  `metadata/site.yaml` and produces the full HTML.
- CSS is inlined into each HTML page via pandoc's template partial mechanism.
  This is unusual but deliberate: it allows pandoc variables (colors, fonts,
  dimensions) to be used directly in CSS, and it produces self-contained HTML
  files with no external stylesheet dependency beyond fonts and KaTeX.

---

## Tools

- **[pandoc](https://pandoc.org/)** — Markdown to HTML conversion, template
  engine, and Lua filter runner. The core of the build pipeline.
- **[KaTeX](https://katex.org/)** — Math rendering. Self-hosted (JS, CSS, and
  fonts are in `assets/katex/`). Rendered client-side via the `--katex` pandoc
  flag. Server-side rendering via
  [pandoc-katex](https://github.com/xu-cheng/pandoc-katex) would eliminate the
  client-side dependency but was not adopted due to setup complexity.
- **[make](https://www.gnu.org/software/make/)** — Build system. Tracks
  dependencies between source files and generated HTML.
- **[Docker](https://www.docker.com/)** — The build environment is packaged as
  a Docker image (`Dockerfile`) containing pandoc, make, git, and
  ca-certificates. This ensures reproducible builds locally and in CI.
- **[GitHub Actions](https://github.com/features/actions)** — CI pipeline.
  Builds the site using the Docker image and deploys to GitHub Pages via the
  `gh-pages` branch.

---

## Deployment

Pushes to `main` trigger the CI workflow (`.github/workflows/build.yml`),
which:
1. Pulls the builder Docker image (pinned by SHA256 digest)
2. Runs `make all` to produce the site in `dist/`
3. Pushes `dist/` to the `gh-pages` branch via
   [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages)

GitHub Pages serves the `gh-pages` branch at `https://jskri.github.io`.

The builder image is defined by `Dockerfile` and published to
`ghcr.io/jskri/blog-builder`. It is rebuilt manually.

---

## Directory Structure

```
.
├── assets/
│   ├── fonts/          # Self-hosted Roboto woff2 files
│   ├── img/            # Images and favicon
│   ├── katex/          # Self-hosted KaTeX JS, CSS, and fonts
│   └── scripts/        # Pandoc Lua filters
│       ├── equation_to_tex.lua
│       └── figure_to_img.lua
├── dist/               # Generated site (gitignored, deployed to gh-pages)
├── metadata/
│   └── site.yaml       # Global site metadata (title, description, post list, etc.)
├── src/
│   ├── about.md        # About page source
│   └── posts/
│       └── entity-protocol.md
├── templates/
│   ├── base.css        # Base CSS included by all pages
│   ├── index.css       # Home page-specific CSS
│   ├── about.css       # About page-specific CSS
│   ├── post.css        # Post page-specific CSS
│   ├── meta.html       # Shared <head> partial (meta tags, OG, fonts, preloads)
│   ├── topheader.html  # Shared navigation header partial
│   ├── index.html      # Home page template (no corresponding .md)
│   ├── about.html      # About page template
│   ├── post.html       # Post template
│   └── sitemap.xml     # Sitemap template
├── Dockerfile          # Builder image definition
├── Makefile            # Build rules
├── README.md
└── robots.txt          # Served as-is to dist/
```

---

## File Reference

### `metadata/site.yaml`

Global site variables consumed by all pandoc templates: site title,
description, URL, font configuration, color variables, and the list of posts
(title, URL, date, description). The post list drives the home page index and
the sitemap — adding a new post means adding an entry here and a corresponding
`.md` file in `src/posts/`.

### `templates/base.css`

Included by every page template. Contains: font-face declarations, CSS custom
properties (colors, dimensions), reset rules, base typography, and the
responsive body layout. Pandoc variables from `site.yaml` (font family, sizes,
colors) are interpolated directly into the CSS, which is why CSS is inlined
rather than served as a separate file.

### `templates/index.css`, `about.css`, `post.css`

Page-specific CSS. Each is combined with `base.css` into a single `<style>`
block in the corresponding template:
````html
<style>
  ${base.css()}
  ${post.css()}
</style>
````

`post.css` contains the two-column TOC/article grid layout, sticky TOC,
heading sizes, code block styling, and the math warning banner.

### `templates/meta.html`

Shared `<head>` partial included by all templates. Contains: `<meta charset>`,
viewport, font preloads, robots meta, Open Graph tags, Twitter card, canonical
URL, and favicon. Page-specific values (title, description, URL, OG type) are
filled in via pandoc variables.

### `templates/topheader.html`

Shared partial for the fixed navigation header (site title linking to `/`,
About link). Included by all page templates.

### `templates/index.html`

Home page template. Has no corresponding Markdown source — the page is
generated entirely from metadata (omitting some details):
````bash
pandoc /dev/null --template templates/index.html \
    --metadata-file metadata/site.yaml -o dist/index.html
````

Iterates over the `posts` list from `site.yaml` to render the post index.

### `templates/about.html`, `post.html`

Templates for the about page and individual posts respectively. `post.html`
includes the TOC (generated by pandoc's `--toc` flag), the article body, the
math warning, and the KaTeX loader.

### `templates/sitemap.xml`

Pandoc template that iterates over the post list from `site.yaml` to generate
`dist/sitemap.xml`. Built with `-t plain` to prevent pandoc from injecting HTML
scaffolding.

### `assets/scripts/equation_to_tex.lua`

Lua filter that transforms math (inline, display and `equation` fenced code
blocks) into KaTeX-compatible LaTeX. The Markdown source uses readable
plain-text notation:
````markdown
```equation
alter : State × E × Subset(E × E) → State
alter(state, entity, relations) =
  (state ∖ { (entity, p, o) ∈ state | p ∈ predicates(relations) })
    ∪ { (entity, p, o) | (p, o) ∈ relations }
```
````

The filter adds spacing (`~`), line breaks (`\\`), alignment (`&`), and
distinguishes syntactic protocol elements (typeset with `\texttt{}`) from
semantic mathematical parameters (typeset in math mode). The result is wrapped
in `\begin{equation*}\begin{aligned}...\end{aligned}\end{equation*}`.

This separation of concerns is the key design principle of the blog: the
Markdown source remains readable and writable without knowledge of LaTeX
spacing rules, while the filter handles the mechanical transformation.

### `assets/scripts/figure_to_img.lua`

Lua filter that strips pandoc's automatic `<figure>`/`<figcaption>` wrapper
and emits a bare `<img>` element. Pandoc wraps any image with a non-empty
caption in a `<figure>` by default; this filter reverts that for a cleaner
layout.

### `Dockerfile`

Defines the builder image based on `debian:bookworm-slim`. Contains pandoc,
make, git, and ca-certificates. Published to `ghcr.io/jskri/blog-builder`.

### `Makefile`

Two phony targets:
- `make all` — builds all pages into `dist/`, copies assets, `sitemap.xml` and
  `robots.txt`
- `make clean` — removes `dist/`

### `robots.txt`

Copied as-is to `dist/`. Allows all crawlers and references `sitemap.xml`.

---

## Math Rendering

Math is rendered client-side by KaTeX. The `--katex` pandoc flag causes pandoc
to emit `<span class="math inline">` and `<span class="math display">` elements
containing raw LaTeX, which KaTeX renders in the browser. All KaTeX assets (JS,
CSS, fonts) are self-hosted under `assets/katex/` — no CDN dependency.

A warning banner is shown by default and hidden by a small inline script once
KaTeX has loaded. Known limitation: if KaTeX is blocked by a browser extension
that allows inline scripts (e.g. NoScript blocking the KaTeX JS but allowing
same-origin scripts), the warning will be incorrectly hidden.

Server-side rendering via `pandoc-katex` would eliminate this limitation and
the client-side dependency entirely, at the cost of adding Rust and a
`cargo install` step to the build pipeline.

---

## CSS Architecture

CSS is inlined into each HTML page rather than served as a separate file. This
has two consequences:

- **Pandoc variables work in CSS.** Colors, font names, and dimensions defined
  in `site.yaml` can be interpolated directly into `base.css` via the template
  engine.
- **No cross-page CSS caching.** Each page carries its own copy of the CSS.
  For a small blog this is an acceptable trade-off.

The dark theme is implemented via `@media (prefers-color-scheme: dark)` in
`base.css`, overriding the CSS custom properties. No JavaScript required.
