---
name: frontend-slides
description: Create stunning, animation-rich HTML presentations from scratch or by converting slides. Use when the user wants to build a presentation, convert PPT to web, or create slides for a talk/pitch with fixed 16:9 stage scaling and custom design.
---

# Frontend Slides

Create zero-dependency, animation-rich HTML presentations that run entirely in the browser.

## Core Principles

1. **Zero Dependencies** — Single HTML files with inline CSS/JS. No npm, no build tools.
2. **Show, Don't Tell** — Generate visual previews, not abstract choices. People discover what they want by seeing it.
3. **Distinctive Design** — No generic "AI slop." Every presentation must feel custom-crafted.
4. **Progressive Disclosure** — Read lightweight style indexes first. Use preview cards for style previews.
5. **Fixed 16:9 Stage (NON-NEGOTIABLE)** — Every deck uses a 1920×1080 slide canvas scaled as a whole to the viewport using CSS transform. Slides must stay 16:9 on every screen. Do not reflow slide content to fit the device.

## Design Aesthetics

Avoid generic AI-generated aesthetics:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Cliched color schemes (particularly purple gradients on white backgrounds)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character

Focus on:
- **Typography**: Choose fonts that are beautiful, unique, and interesting (JetBrains Mono, Syne, Fira Code, Outfit, Space Grotesk, Cabinet Grotesk).
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions. High-impact moments with staggered reveals (`animation-delay`).
- **Backgrounds**: Layer CSS gradients, use geometric patterns, or add contextual effects matching the overall aesthetic.

## Fixed Stage Invariants

- Viewport wrapper fills the browser window (`100vw`, `100vh`, `overflow: hidden`).
- Slide stage is fixed at `1920×1080` (or configured aspect ratio).
- The stage scales uniformly to fit the viewport via `transform: scale(min(viewportWidth/1920, viewportHeight/1080))`.
- Slide visibility controlled by `.active` / `.visible` classes using `visibility`, `opacity`, and `pointer-events`. Never use `display: none` / `display: block` which break flex child layouts.
- Content density: low density (speaker-led: 1-3 bullets max, big visual punch) vs high density (reading-first: 4-6 cards/points).
