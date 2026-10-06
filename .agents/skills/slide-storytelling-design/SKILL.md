---
name: slide-storytelling-design
description: Design engaging, high-retention technical presentations, slide narratives, and visual structures. Use when planning slide outlines, designing conference talks, refining speaker notes, balancing code-to-text density, or auditing slide decks for clarity and flow.
---

# Slide Storytelling & Technical Presentation Design

A pragmatic guide for crafting compelling developer conference talks, technical keynotes, and system architecture presentations.

---

## 1. Narrative Arc: The "Hook, Agony, Remedy, Triumph" Framework

Technical audiences tune out when overwhelmed with dry syntax. Structure the deck with an emotional and engineering arc:

1. **The Hook (Slides 1–3)**: What impossible or painful challenge are we tackling? Why does this matter today?
2. **The Agony / Anti-Patterns (Slides 4–12)**: Show real, familiar pain points in existing approaches (e.g. untyped dynamic bugs, slow interpreter loops, memory bloat, manual boilerplate).
3. **The Paradigm Shift (Slides 13–18)**: Introduce the core breakthrough (e.g. compile-time macros, native C ABI zero-overhead binding, type-safe DSL).
4. **The Remedy / Deep Dive (Slides 19–35)**: Concrete code comparisons, live architectural diagrams, real-world engine integration, and idiomatic patterns.
5. **The Triumph / Proof (Slides 36–40)**: Hard benchmarks (throughput, GC allocations, frame times), real games built with the stack.
6. **Call to Action / Outro (Slides 41–43)**: Quickstart, repo link, documentation QR code, community links.

---

## 2. Cognitive Load & Slide Economy Rules

- **One Thesis Per Slide**: If a slide needs two unrelated titles, it must be two slides.
- **The 3-Second Test**: The audience should grasp the slide's purpose within 3 seconds of looking at it while listening to the speaker.
- **Code Snippet Hygiene**:
  - Keep snippets under 12–15 lines.
  - Highlight the exact diff or salient line (`select(&.valid?).map(&.name)` vs manual loops).
  - Never display unreadable, tiny wall-of-code blocks. Split into progressive steps if necessary.
- **Consistent Visual Semantics**:
  - Use red/warning badges strictly for anti-patterns, pitfalls, and legacy code.
  - Use emerald/cyan/accent badges for modern solutions and key takeaways.
  - Keep typography scale hierarchical: Slide Badge &rarr; Title &rarr; Subtitle &rarr; Code &rarr; Key Takeaway.

---

## 3. Speaker Notes Best Practices

- Speaker notes are not a script to read word-for-word; they are anchors:
  - Bullet 1: The spoken hook (what to say first).
  - Bullet 2: The visual callout (point audience attention to a specific part of the slide).
  - Bullet 3: The technical insight or metric to emphasize before advancing.
