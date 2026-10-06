---
name: revealjs-presentation
description: Architect, style, author, and debug interactive Reveal.js presentations. Use when building HTML/JS slide decks, configuring Reveal.js plugins (highlight.js, notes, search), designing responsive slide layouts, implementing speaker notes, keyboard navigation, and custom CSS themes.
---

# Reveal.js Presentation Engineering Guide

This skill provides comprehensive instructions for building, styling, and debugging high-impact **Reveal.js** presentations.

---

## 1. Core Architecture & Configuration

Reveal.js presentations consist of a root `.reveal` container, a `.slides` wrapper, and individual `<section>` elements representing slides or vertical slide stacks.

### Idiomatic Initialization Config:
```javascript
Reveal.initialize({
  width: 1920,
  height: 1080,
  margin: 0.04,
  minScale: 0.2,
  maxScale: 2.0,
  hash: true,
  history: true,
  slideNumber: 'c/t',       // Current / Total slide count
  showSlideNumber: 'all',
  overview: true,           // Toggle via 'O' or 'ESC'
  keyboard: true,
  center: false,            // Prefer false for custom top-aligned card/grid layouts
  transition: 'none',       // 'none' or 'fade' is best for dense technical/code slides
  plugins: [ RevealHighlight, RevealNotes ]
});
```

---

## 2. Layout & Typography Rules

### Fixed Aspect Ratio:
- Author all styles assuming a fixed canvas (`1920×1080` or `1280×720`). Reveal.js handles hardware-accelerated CSS scaling to fit any display.
- Avoid viewport units (`100vw`, `100vh`) inside `.slides section`; use explicit percentages (`%`), `rem`, or fixed pixel values designed for the canvas dimensions.

### Code Highlighting (`RevealHighlight`):
- Ensure syntax highlighting themes do not conflict with slide background colors.
- Use `data-line-numbers` to highlight specific lines during talk points:
  ```html
  <pre><code class="language-crystal" data-line-numbers="1|3-5|7">
  # Crystal snippet
  </code></pre>
  ```
- Use `data-trim` and `data-noescape` to format code blocks cleanly.

---

## 3. Speaker Notes & Dual-Display Presenter Console

Every slide should include presenter notes for live delivery:
```html
<section>
  <h2>Slide Title</h2>
  <!-- Visual content -->
  <aside class="notes">
    Key talking points:
    1. Highlight the compile-time zero-overhead abstraction.
    2. Point to the benchmark diff on the right.
  </aside>
</section>
```
Pressing `S` launches the presenter console with timer, upcoming slide preview, and speaker notes.

---

## 4. Fragments & Progressive Disclosure

- Use `.fragment` to reveal points progressively so the audience doesn't read ahead:
  ```html
  <ul>
    <li class="fragment">Point 1</li>
    <li class="fragment">Point 2</li>
  </ul>
  ```
- Styles of fragments: `.fade-in`, `.fade-out`, `.grow`, `.highlight-red`, `.highlight-green`.

---

## 5. Layout Patterns for Developer Talks

1. **Side-by-Side Comparison (`code-comparison-layout`)**:
   - Left: Bad / Anti-Pattern (red tint badge, muted code).
   - Right: Clean / Modern Solution (green/emerald tint badge, highlighted code).
   - Bottom: Key takeaway pill/banner.
2. **Hero / Title Slide (`hero-layout`)**:
   - Massive title, clear subtitle, presenter badge, animated visual element (3D canvas or isometric graphic), and 3-4 feature pillars.
3. **Multi-Column Matrix (`two-column-layout`, `three-column-layout`)**:
   - Cards with distinct headers, monospace labels, and bulleted takeaways.
4. **Architecture Diagram (`architecture-layout`)**:
   - Visual stack showing layers (e.g. Engine, C ABI, Glue Layer, High-Level DSL, User Scripts).
