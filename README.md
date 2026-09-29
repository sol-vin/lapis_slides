# Lapis Presentation Deck & YAML Slide Engine

A modular, high-performance slide presentation engine written in **Crystal**, inspired by [sol.vin](https://www.sol.vin). It converts human-readable YAML slide definitions into an interactive **Reveal.js** presentation (`index.html`) and markdown speaking reference (`SLIDES.md`).

---

## Features

- **Crystal-Native Engine**: Zero external dependencies. Uses Crystal's standard library (`yaml`, `json`, `html`, `http/server`, `option_parser`).
- **Human-Readable YAML Data**: Every slide lives in `data/slides/*.yml`. Adding or rearranging slides is as simple as creating a file and updating `data/deck.yml`.
- **Pre-Determined Layouts**:
  - `code-comparison-layout`: Side-by-side GDScript Anti-Pattern vs. Crystal Clean Solution.
  - `hero-layout`: Cover slide with spinning 3D isometric cube and 4 pillar cards.
  - `two-column-layout`: Flexible two-column layout (code, cards, terminal windows) with customizable ratios (`1:1`, `3:2`, `2:3`).
  - `three-column-layout` & `four-column-layout`: Multi-column card sets and 4-way language comparisons.
  - `matrix-layout`: Comparative tables and feature matrices.
  - `timeline-layout`: Sequential historical or architectural milestones.
  - `media-layout`: Video or image displays with sidebar contextual cards.
  - `architecture-layout`: 5-layer bridge architecture diagram.
- **46 Retro Sol.vin Palettes**: Theme palettes loaded from `solvin_palettes.json` (`monokai`, `warm_paper`, `spaces_98`, `aperture`, `m64`, etc.).
- **Live Preview Server**: Built-in HTTP server with auto-launching browser and speaker notes view.

---

## Quickstart & CLI Commands

### 1. Build the Presentation
Compiles YAML slides into `index.html` and `SLIDES.md`:
```bash
# Using Makefile
make build

# Or directly with Crystal
crystal run src/builder.cr -- build
```

### 2. Validate Slide Schemas
Validates that all slides have titles, valid layouts, and existing Sol.vin theme palettes:
```bash
make validate
# or
crystal run src/builder.cr -- validate
```

### 3. Launch Local Preview Server
Starts the built-in HTTP server on port 8000 and opens your default browser:
```bash
make serve
# or
crystal run src/builder.cr -- serve
```

**Presentation Keyboard Shortcuts:**
- `Space` / `Arrow Keys`: Next / Previous slide
- `S`: Open dual-screen **Speaker Notes** presenter console
- `ESC` or `O`: Toggle multi-slide **Overview Grid**
- `F`: Fullscreen mode

---

## Authoring New Slides

### Step 1: Create a YAML file in `data/slides/`
Example: `data/slides/44_my_new_feature.yml`

```yaml
id: 44_my_new_feature
title: "My New Feature"
subtitle: "High-level overview of the new capability"
badge: "GAMEPLAY • FEATURE"
badge_color: "emerald"
palette: "spaces_98"
layout: "code-comparison-layout"

gdscript:
  title: "❌ GDScript Anti-Pattern: Manual Loop Mutation"
  lang: "gdscript"
  tag: "GDScript"
  code: |
    var out = []
    for x in items:
        if x.is_valid():
            out.append(x.name)
  points:
    - "Manual heap array allocation"
    - "Verbose loops for simple filtering"

crystal:
  title: "✨ Crystal Clean Solution: Chained Enumerable"
  lang: "crystal"
  tag: "Crystal (Lapis)"
  code: |
    out = items.select(&.valid?).map(&.name)
  points:
    - "Clean functional pipeline"
    - "Inlined LLVM machine loop with zero GC overhead"

takeaway:
  badge: "KEY TAKEAWAY"
  text: "Crystal transforms imperative loop boilerplate into expressive, zero-alloc pipelines."

notes: |
  Speaking notes for the presenter when viewing with 'S'...
```

### Step 2: Register in `data/deck.yml`
Add the slide filename (without `.yml`) to the `slides` list in `data/deck.yml`:
```yaml
slides:
  - 01_hero
  - ...
  - 44_my_new_feature
```

### Step 3: Rebuild
```bash
make build
```

---

## Directory Structure

```
slides/
├── data/
│   ├── deck.yml                # Presentation manifest and slide ordering
│   └── slides/                 # 43 modular YAML slide definitions
│       ├── 01_hero.yml
│       ├── 11_antipattern_iterators.yml
│       ├── 12_antipattern_nil_safety.yml
│       └── ...
├── src/
│   ├── models/                 # Slide, Deck, and Palette models
│   ├── layouts/                # Pre-determined layout renderers
│   ├── generator.cr            # Compiles HTML and SLIDES.md
│   ├── server.cr               # Built-in HTTP static server
│   └── builder.cr              # CLI entry point
├── vendor/                     # Reveal.js and Highlight.js assets
├── index.html                  # Generated Reveal.js presentation
├── SLIDES.md                   # Generated Markdown presentation reference
├── theme.css                   # Sol.vin presentation styling
├── solvin_palettes.json        # 46 retro theme palettes
└── Makefile                    # Convenience build targets
```
