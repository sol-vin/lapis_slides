# Lapis for Crystal — Flagship Presentation Deck

<!-- carbon:badges -->
[![CI](https://github.com/sol-vin/lapis_slides/actions/workflows/deploy.yml/badge.svg)](https://github.com/sol-vin/lapis_slides/actions/workflows/deploy.yml)
[![Crystal](https://img.shields.io/badge/crystal-%3E%3D%201.10.0-black.svg)](https://crystal-lang.org)
[![Version](https://img.shields.io/badge/version-0.2.41-blue.svg)](https://github.com/sol-vin/lapis_slides/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
<!-- /carbon:badges -->

The flagship technical presentation and deep-dive slide deck for **Lapis** (*Native Machine Speed • Zen Ergonomics • Godot Engine 4.8+*), authored by [sol.vin](https://www.sol.vin) and powered by the [Sunstone](https://github.com/sol-vin/sunstone) YAML presentation engine.

It compiles modular, human-readable YAML slide definitions (`deck.yml` + `data/slides/*.yml`) into an interactive 16:9 **Reveal.js** web presentation ([`index.html`](index.html)) and a comprehensive speaker reference document ([`SLIDES.md`](SLIDES.md)).

---

## Presentation Architecture (5 Acts • 113 Slides)

- **Act I — Ethos & The Vision**: Presenter background (`sol.vin`), content & length advisory.
- **Act II — The Ruby Heritage & The Scale Wall**: Developer happiness, postage-stamp ~40-keyword grammar, backend/frontend class ergonomics, and the enterprise dynamic typing scale wall (Sorbet/RBS).
- **Act III — Crystal: The Compiled Synthesis**: Whole-program flow-sensitive type inference, compile-time nil safety, expressive syntax delights, modules, closures, compile-time AST macro metaprogramming, zero-overhead C bindings, `doo-cr`, and *The Ship of Shwageseus*.
- **Act IV — The Lapis Godot Engine Masterclass**:
  - **4.1**: The Gameplay DSL, `node` / `gmodule` composition, resource preloading, fluent spawning, tweens, physics queries, and `@[Autoload]` singletons.
  - **4.2**: Typed signals, declarative `on` connections, and reactive async workflows.
  - **4.3**: Optional Lapis syntactic sugar and hierarchy/scene pipeline operators (`~`, `*`, `>`, `>>`).
  - **4.4**: The GDScript Face-Off — 10 side-by-side antipattern comparisons vs. Crystal Zen, `Lapis.frame_arena`, type firewalls, and 64-bit ObjectDB dead-pointer armor.
  - **4.5**: Fearless concurrency, timers, `await` / `await?` / `await!`, channels, thread safety policies, and lockstep multiplayer `@[RPC]`.
  - **4.6**: The C# (.NET) Shootout — boilerplate, nullability, GC/runtime tax, reflection vs. AST macros, hot-reload state preservation, and `crystal spec`.
  - **4.7**: Zero-friction bidirectional GDScript ↔ Crystal interoperability.
  - **4.8**: Inside the Godot Editor — native inspector integration, in-editor validator/LSP, and shadow-DLL hot reloading.
  - **4.9**: The Lapis CLI Command Center (`lapis`).
  - **4.11**: Mission-critical zero-leak testing, headless editor driver, multiplayer testing, and TUI test runner.
  - **4.12**: Hard empirical benchmarks & multi-language shootouts (Lapis vs. C++, Rust, C#, and GDScript).
  - **4.13**: The LibGodot / GDExtension bridge architecture, dual execution modes, and `lapis package` distribution.
- **Act V — Live Demonstration & The Road Ahead**: 5-step live demo roadmap, future milestones, and community links.

---

## Quickstart & CLI Commands

### 1. Build the Presentation
Compiles `deck.yml` and `data/slides/*.yml` into `index.html`, `theme.css`, and `SLIDES.md`:
```bash
sunstone build -o .
# or via Makefile:
make build
```

### 2. Validate Slide Schemas
Audits `deck.yml`, layout schemas, and `sol.vin` theme palette names:
```bash
sunstone validate
# or via Makefile:
make validate
```

### 3. Run Deck Verification Specs
Verifies 16:9 stage resolution, 1:1 parity between `deck.yml` and `data/slides/*.yml`, zero-inline-styles invariant, and compiled HTML/Markdown outputs:
```bash
crystal spec
# or via Makefile:
make spec
```

### 4. Launch Local Preview Server
Starts the live preview server on port `8000`:
```bash
sunstone serve
# or via Makefile:
make serve
```

**Presentation Keyboard Shortcuts:**
- `Space` / `Arrow Keys`: Next / Previous slide
- `S`: Open dual-screen **Speaker Notes** presenter console
- `ESC` or `O`: Toggle multi-slide **Overview Grid**
- `F`: Fullscreen mode

---

## Authoring or Updating Slides

1. **Create or edit a slide YAML in `data/slides/`** (e.g., `data/slides/20_node_dsl.yml`).
2. **Register the slide ID in [`deck.yml`](deck.yml)** under `slides:`.
3. **Validate, build, and test**:
   ```bash
   sunstone validate && sunstone build -o . && crystal spec
   ```

---

## Repository Structure

```text
lapis_slides/
├── deck.yml                    # Canonical Sunstone presentation manifest & slide order
├── data/
│   └── slides/                 # 113 modular YAML slide definitions
├── casts/                      # 6 embedded Asciinema terminal/TUI recordings (*.cast)
├── vendor/                     # Bundled Reveal.js, Highlight.js, FontAwesome & Asciinema assets
├── spec/
│   ├── spec_helper.cr
│   └── flagship_deck_spec.cr   # Automated deck, schema & artifact verification suite
├── custom.css                  # Deck-specific layout & typography refinements
├── theme.css                   # Compiled Sol.vin theme & retro palettes stylesheet
├── cube.js                     # Interactive 3D isometric wireframe cube engine
├── hold_click.js               # Hold-click interaction helper
├── palette_engine.js           # Live Sol.vin palette switcher engine
├── doom.mp4                    # Embedded DOOM in Crystal (doo-cr) showcase video
├── index.html                  # Compiled Reveal.js presentation
├── SLIDES.md                   # Compiled speaker notes & slide reference script
├── Makefile                    # Convenience build, validate, serve & spec targets
└── shard.yml                   # Crystal shard manifest (Sunstone dependency)
```
