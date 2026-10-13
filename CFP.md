# Conference Call for Proposals (CFP) — Lapis for Crystal: Native Machine Speed, Zen Metaprogramming, and First-Class Godot 4.8 GDExtension

> **Subtitle**: High-Throughput Systems Architecture Meets Joyful Game Engine Ergonomics  
> **Speaker**: Ian Rash (`sol.vin`) | Founder & Systems Architect, Sol-Vin Systems  
> **Format**: 30-Minute Keynote / Featured Presentation (30 Minutes) | **Level**: Intermediate to Advanced

---

## 1. Title Variations

- **Primary Title**: Lapis for Crystal: Native Machine Speed, Zen Metaprogramming, and First-Class Godot 4.8 GDExtension
- **Alternative Title**: Why We Wrote Godot Bindings in Crystal: The Sweet Spot Between C++ Rigor and Ruby Ergonomics
- **Alternative Title**: Zero-Cost Abstractions at 120 FPS: Compiling Crystal into Godot 4.8 GDExtension
- **Alternative Title**: Ditching the C++ Build Wait: High-Throughput Game Systems with Crystal and Godot 4.8

## 2. Target Conferences & Tracks

| Conference | Location | Dates | Track | Word Limit |
| :--- | :--- | :--- | :--- | :--- |
| **GodotCon 2026** | Berlin, Germany | October / November 2026 | `Core Engine & Systems Architecture` | 500 words |
| **FOSDEM 2027** | Brussels, Belgium | February 2027 | `Game Development & Open Source Engines Devroom` | 400 words |
| **Crystal 1.x Conf** | Online / Americas | Late 2026 / Early 2027 | `Systems, Compilers & High-Performance Crystal` | 500 words |
| **Strange Loop / Papers We Love** | St. Louis, MO, USA | September 2026 / 2027 | `Unconventional Systems Languages in Production` | 600 words |

## 3. Elevator Pitch (50 Words)

Game developers have long faced an agonizing dilemma: endure the soul-crushing compilation times and boilerplate of C++, or accept the performance ceilings and runtime type bugs of dynamic scripting. Lapis bridges this divide by binding Crystal to Godot 4.8 via GDExtension—delivering LLVM bare-metal speed with ruby-like zen DSL ergonomics.

## 4. Short Abstract (100–150 Words)

Game loops demand deterministic frame pacing and native execution speed, yet modern game architecture shouldn't require hundreds of lines of C++ boilerplate or minutes waiting for Clang to compile. Enter Lapis: the high-performance Crystal language toolchain and binding layer for Godot Engine 4.8+. In this 30-minute keynote, Ian Rash demonstrates how Lapis marries Crystal's algebraic type system, LLVM code generation, and compile-time AST macros with Godot's direct C ABI GDExtension interface. Attendees will see live declarative node declarations, explore how to eliminate GC pauses on 120 FPS hot paths, inspect generated ELF binaries via radare2, and evaluate head-to-head particle benchmarks against GDScript, C#, and C++.

## 5. Comprehensive Abstract / Proposal

Game engine development is defined by an uncompromising tension: you need absolute machine performance for physics, transforms, and particle systems, but you also need developer joy and rapid iteration to ship compelling gameplay. For years, Godot developers have been forced to split their brains between GDScript (delightful to write, but bound to interpreter overhead and dynamic typing hazards) and C++ (blisteringly fast, but encumbered by slow compilation cycles, manual header maintenance, and brittle ClassDB boilerplate).

Lapis resolves this architectural deadlock by providing first-class Crystal language bindings for Godot Engine 4.8+ through the modern GDExtension C ABI. Crystal combines the syntax elegance and developer happiness of Ruby with the type safety, compile-time AST metaprogramming, and raw execution throughput of LLVM-compiled native code.

In this presentation, we pull back the curtain on how Lapis was built from the bare metal up. We examine the 'Two-Tier Engine & Declarative Builder' pattern that separates pure high-throughput algorithmic primitives from human-friendly declarative macros. We demonstrate how declarative macros like `node`, `prop`, `signal`, and `on_ready` synthesize full ClassDB registrations at compile time—eliminating hundreds of lines of error-prone manual binding code.

Crucially, we confront the elephant in the room: how do you manage a garbage-collected language in a frame-budgeted 120 FPS game? We detail our zero-allocation memory discipline, showcasing stack-allocated structs, custom memory arenas, and the `@hot_path` invariant annotations that guarantee zero heap allocations during the physics tick. We inspect generated ELF binaries under radare2 to prove zero-cost abstractions, and reveal live benchmarks demonstrating 100k transform updates running head-to-head with native C++.

## 6. Key Attendee Takeaways

1. Direct GDExtension C FFI Without C++ Overhead: How Lapis connects directly to Godot 4.8's native C ABI via LibGodot, bypassing C++ name-mangling and bloated template hierarchies.
2. Boilerplate Elimination via Crystal AST Metaprogramming: How declarative macros synthesize complete ClassDB bindings and static type registrations at compile time with zero runtime reflection overhead.
3. Taming the Garbage Collector for 120 FPS Frame Pacing: Concrete techniques for managing the Boehm-Demers-Weiser GC in tight game loops using stack allocation, `@hot_path` zero-allocation invariants, and memory arenas.
4. Signal Piping & Semantic Arity Trimming: How to route and transform multi-argument engine signals into clean, type-safe callbacks without writing glue code.
5. Hard Empirical Benchmarks: Verified throughput data and frame-time graphs comparing Lapis against GDScript, C#, and C++ in 100k particle and transform stress tests.

## 7. Talk Outline & Timed Breakdown (30 Minutes)

### Act I: The Game Developer's Dilemma (4 min)
- The false dichotomy: GDScript iteration ease vs C++ compilation agony
- Real-world costs of dynamic interpreter dispatch, boxing, and runtime type bugs
- Presenter background: security research, game jams, and systems engineering

### Act II: The Paradigm Shift — Crystal meets Godot 4.8 (5 min)
- Crystal's DNA: Ruby-like zen syntax backed by LLVM native machine code and algebraic unions
- The Godot 4.8 GDExtension architecture: LibGodot direct C ABI bridge
- Bootstrapping Lapis: Zero-overhead entry points and shared library lifecycle

### Act III: The Two-Tier DSL & Ergonomics in Action (7 min)
- The Two-Tier Architecture: Decoupling engine primitives from declarative syntax
- Live Code: Declaring `Player < CharacterBody3D`, typed properties, and default values
- Signal piping & arity trimming (3->0 and 3->2 callbacks) with compile-time verification
- Eliminating 50 lines of C++ ClassDB boilerplate with a single Crystal AST macro

### Act IV: Under the Hood — Memory, GC & Systems Rigor (6 min)
- The GC Question: Addressing garbage collection concerns in 60/120 FPS gaming
- Zero-allocation hot paths: Stack allocation, `@hot_path` annotations, and custom memory arenas
- Radare2 binary analysis: Disassembling generated ELF symbols to confirm zero-cost abstraction
- GDExtension hot-reloading inside the Godot 4.8 editor

### Act V: The Crucible — Hard Benchmarks & Real Game (5 min)
- Microbenchmarks: 100,000 transform updates and vector math under pressure
- P99 frame time comparisons: Lapis vs GDScript vs C# vs C++
- Real-world showcase: 'Solo Oasis' retro 3D game running at 144 FPS with flat 0.4ms frame times

### Act VI: The Horizon, Ecosystem & Q&A Defense (3 min)
- The Sol-Vin shard ecosystem: Citrine (PS2!), Diorite (Godot Addons), Opal (TUI), Sunstone (Presentations)
- Open-source roadmap and community links
- Floor open for audience Q&A (supported by prepared technical defense matrix)

## 8. Target Audience & Prerequisites

**Target Audience**:
- Game Engine Developers & Systems Architects
- Godot Creators looking to break through GDScript CPU performance bottlenecks
- C++ and Rust developers frustrated by slow compilation loops and manual binding glue
- Crystal, Ruby, and modern systems language enthusiasts

**Prerequisites**:
- Familiarity with basic game engine loops (process/physics_process), component trees, and static vs dynamic typing concepts.

## 9. Speaker Biography & Credentials

### Ian Rash (`sol.vin`)
**Role**: Founder & Systems Architect, Sol-Vin Systems  
**Location**: United States

**Bio**:
Ian Rash (sol.vin) is a systems programmer, reverse engineer, and game developer with over a decade of active leadership in the Crystal language ecosystem. Holding CompTIA A+ and Network+ certifications and credited with publishing remote exploit CVEs (CVE-2019-11014, CVE-2019-11878), Ian combines low-level binary forensics with game design, having shipped 'Solo Oasis' on Steam and won first place in competitive game jams (Trijam 363, 1dayjam #3). He is the creator of Lapis (Crystal bindings for Godot 4.8), celestine (SVG compiler), and raylib-cr.

**Notable Credentials & Shipped Work**:
- **Published Security CVEs**: CVE-2019-11014, CVE-2019-11878
- **Professional Certifications**: CompTIA A+, CompTIA Network+
- **Shipped Commercial Games**: Solo Oasis: Unlimited Places (Steam & itch.io)
- **Game Jam Honors**: Trijam 363 (1st Place, <3h), 1dayjam #3 (1st Place, 24h)
- **Past Speaking Engagements**: Crystal 1.0 Conf (2021), Raw Crystal (2020)

**Links**:
- Website: <https://sol.vin>
- GitHub: <https://github.com/sol-vin/lapis>
- Steam: <https://store.steampowered.com/app/SoloOasis>
- Organization: <https://github.com/sol-vin>

## 10. Technical Requirements & Setup

- 1080p (1920x1080) 16:9 HDMI projector output
- Podium table with power outlet for developer laptop
- Wireless lapel / headset microphone
- Stable 3.5mm stereo line out or HDMI audio for live audio/synth demos

**Tags**: `godot`, `crystal`, `gdextension`, `game-development`, `systems-programming`, `compilers`, `llvm`, `performance`
