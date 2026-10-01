import json
import os
import sys

CASTS_DIR = r"c:\Users\Ian\Documents\GitHub\lapis_slides\casts"
os.makedirs(CASTS_DIR, exist_ok=True)

def make_cast(filename, title, events, width=86, height=22):
    path = os.path.join(CASTS_DIR, filename)
    header = {
        "version": 2,
        "width": width,
        "height": height,
        "timestamp": 1727700000,
        "title": title,
        "env": {"TERM": "xterm-256color", "SHELL": "/bin/bash"}
    }
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(header) + "\n")
        for ts, op, data in events:
            f.write(json.dumps([round(ts, 3), op, data]) + "\n")
    print(f"Generated {filename}: {len(events)} events, duration ~{events[-1][0]:.1f}s")

def type_cmd(events, start_t, prompt, cmd, speed=0.045):
    t = start_t
    events.append((t, "o", prompt))
    t += 0.2
    for char in cmd:
        events.append((t, "o", char))
        t += speed
    t += 0.15
    events.append((t, "o", "\r\n"))
    return t + 0.1

# ==============================================================================
# 1. lapis_benchmarks_tui.cast (~60s)
# ==============================================================================
def gen_benchmarks_tui():
    events = []
    events.append((0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    prompt = "\x1b[1m\x1b[32mdeveloper@lapis-dev\x1b[0m:\x1b[34m~/projects/void_runner\x1b[0m$ "
    
    t = type_cmd(events, 0.2, prompt, "lapis benchmarks --tui --all-languages -i 3")
    
    events.append((t, "o", "\x1b[35m[Lapis]\x1b[0m Initializing Benchmark Harness v0.0.255...\r\n"))
    t += 0.3
    events.append((t, "o", "\x1b[36m  ⠋\x1b[0m Compiling benchmarks in release mode (-O3 -s)..."))
    t += 0.5
    events.append((t, "o", "\r\x1b[2K\x1b[36m  ⠙\x1b[0m Compiling benchmarks in release mode (-O3 -s)..."))
    t += 0.5
    events.append((t, "o", "\r\x1b[2K\x1b[32m  ✔\x1b[0m Native Crystal & Foreign Harnesses compiled (3.2s)\r\n"))
    t += 0.4
    events.append((t, "o", "\x1b[?25l\x1b[2J\x1b[H")) # Hide cursor, clear screen for TUI

    # TUI Header & Frames
    header = (
        "\x1b[1;37;44m ╔══════════════════════════════════════════════════════════════════════════════════╗ \x1b[0m\r\n"
        "\x1b[1;37;44m ║ LAPIS PERFORMANCE BENCHMARK DASHBOARD                      RUNNING SUITES [3/3]   ║ \x1b[0m\r\n"
        "\x1b[1;37;44m ║ Target: Godot 4.8.0-dev6 │ Crystal: 1.15.0 (-O3) │ Platform: windows-x64 │ Iters: 3 ║ \x1b[0m\r\n"
        "\x1b[1;37;44m ╚══════════════════════════════════════════════════════════════════════════════════╝ \x1b[0m\r\n"
    )

    suites = [
        ("01. N-Body Physics (10k)", 184.2, 3.1, "59.4x"),
        ("02. Perlin Noise (256x256)", 92.4, 2.8, "33.0x"),
        ("03. A* Pathing (1k agents)", 64.8, 4.2, "15.4x"),
        ("04. Raycast Spatial Octree", 45.6, 5.1, " 8.9x"),
        ("05. Matrix 4x4 SIMD (100k)", 38.1, 1.4, "27.2x"),
        ("06. Procedural Dungeon Gen", 112.5, 3.9, "28.8x"),
        ("07. Particle Sim (50k)", 78.3, 2.1, "37.3x"),
        ("08. Multiplayer RPC Sync", 54.2, 1.8, "30.1x"),
    ]

    # Progressive execution from 4.0s to 32.0s
    for idx, (name, gd_ms, cr_ms, ratio) in enumerate(suites):
        progress_pct = int(((idx + 1) / len(suites)) * 100)
        bar_len = int(progress_pct / 100 * 36)
        bar = "█" * bar_len + "░" * (36 - bar_len)
        
        frame = "\x1b[H" + header
        frame += f"\x1b[1;36m Progress: [{bar}] {progress_pct}% (Suite {idx+1}/{len(suites)} • 3 iters)\x1b[0m\r\n"
        frame += "\x1b[36m┌─ BENCHMARK SUITES ──────────────┐ ┌─ LIVE PERFORMANCE & SPEEDUP RATIOS ───────────┐\x1b[0m\r\n"
        
        for s_i, (s_name, s_gd, s_cr, s_rat) in enumerate(suites):
            if s_i < idx:
                frame += f"│ \x1b[32m✔\x1b[0m {s_name:<25} │ │ GDScript: {s_gd:>5.1f} ms │ Crystal: {s_cr:>4.1f} ms [\x1b[1;32m{s_rat:>6}\x1b[0m] │\r\n"
            elif s_i == idx:
                frame += f"│ \x1b[1;33m►\x1b[0m \x1b[1;37m{s_name:<25}\x1b[0m │ │ GDScript: {s_gd:>5.1f} ms │ Crystal: {s_cr:>4.1f} ms [\x1b[1;33mRUNNING\x1b[0m] │\r\n"
            else:
                frame += f"│   {s_name:<25} │ │ GDScript:       -  │ Crystal:       -  [  PEND  ] │\r\n"
        
        frame += "\x1b[36m└─────────────────────────────────┘ └───────────────────────────────────────────────┘\x1b[0m\r\n"
        frame += "\x1b[2m [↑↓/jk] Select Suite  [Enter] Detailed Metrics Modal  [q] Exit  [?] Help\x1b[0m\r\n"
        
        events.append((t, "o", frame))
        t += 3.4

    # All suites complete banner
    t += 0.5
    events.append((t, "o", "\x1b[14;39H\x1b[1;32mALL 8 SUITES COMPLETE (Mean: 30.1x)\x1b[0m"))
    t += 1.5

    # User interacts: navigates with arrow key to Suite 01
    events.append((t, "o", "\x1b[6;3H\x1b[1;32m►\x1b[0m \x1b[1;37m01. N-Body Physics (10k)\x1b[0m"))
    t += 1.0

    # User presses [Enter] -> Modal opens
    modal = (
        "\x1b[7;4H\x1b[1;37;45m ┌─ DETAIL: 01. N-Body Gravitational Physics (10,000 Bodies) ────────────────────┐ \x1b[0m"
        "\x1b[8;4H\x1b[1;37;45m │ Workload: 50,000 steps velocity-verlet orbital integration                    │ \x1b[0m"
        "\x1b[9;4H\x1b[1;37;45m │ Iteration 1: 3.12 ms │ Iteration 2: 3.08 ms │ Iteration 3: 3.10 ms             │ \x1b[0m"
        "\x1b[10;4H\x1b[1;37;45m │ Statistics: Min 3.08 ms │ Median 3.10 ms │ Max 3.12 ms │ StdDev: ±0.02 ms      │ \x1b[0m"
        "\x1b[11;4H\x1b[1;37;45m │ Multi-Language Shootout Comparison:                                           │ \x1b[0m"
        "\x1b[12;4H\x1b[1;37;45m │   • Crystal (Lapis) :   3.10 ms [ Baseline 1.0x - Inlined AVX2 SIMD ]         │ \x1b[0m"
        "\x1b[13;4H\x1b[1;37;45m │   • C++ (-O3)       :   3.75 ms [ 1.21x of Crystal - Zero GC overhead ]        │ \x1b[0m"
        "\x1b[14;4H\x1b[1;37;45m │   • Rust            :   4.72 ms [ 1.52x of Crystal - Ownership bounds checks ] │ \x1b[0m"
        "\x1b[15;4H\x1b[1;37;45m │   • C# (.NET 8)     :  15.03 ms [ 4.85x of Crystal - P/Invoke & JIT overhead ] │ \x1b[0m"
        "\x1b[16;4H\x1b[1;37;45m │   • GDScript        : 184.20 ms [ 59.41x slower - Bytecode interpreter VM ]   │ \x1b[0m"
        "\x1b[17;4H\x1b[1;37;45m │ Memory Allocations in Hot Loop: 0 bytes (Flat Stack-Contiguous Structs)       │ \x1b[0m"
        "\x1b[18;4H\x1b[1;37;45m └───────────────────────────────────────────── [Esc / Enter] Close Modal ───────┘ \x1b[0m"
    )
    events.append((t, "o", modal))
    t += 7.0

    # User closes modal and exits TUI
    events.append((t, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    t += 0.8

    # Compare HTML command
    t = type_cmd(events, t, prompt, "lapis benchmarks compare html --tag 4.8-dev6 --previous-tag 4.8-dev5")
    
    events.append((t, "o", "\x1b[35m[Lapis]\x1b[0m Loading previous baseline: \x1b[36mbenchmarks/reports/benchmarks_4.8-dev5.xml\x1b[0m\r\n"))
    t += 0.5
    events.append((t, "o", "\x1b[35m[Lapis]\x1b[0m Evaluating performance regression thresholds across 8 suites...\r\n\r\n"))
    t += 0.4
    
    reg_rows = [
        ("01. N-Body Physics (10k)", "3.10 ms", "3.15 ms", "+1.6% faster", True),
        ("02. Perlin Noise (256x256)", "2.80 ms", "2.84 ms", "+1.4% faster", True),
        ("03. A* Pathing (1k agents)", "4.20 ms", "4.31 ms", "+2.6% faster", True),
        ("04. Raycast Spatial Octree", "5.10 ms", "5.12 ms", "+0.4% (noise)", True),
        ("05. Matrix 4x4 SIMD (100k)", "1.40 ms", "1.42 ms", "+1.4% (noise)", True),
        ("06. Procedural Dungeon Gen", "3.90 ms", "4.05 ms", "+3.7% faster", True),
        ("07. Particle Sim (50k)", "2.10 ms", "2.15 ms", "+2.3% faster", True),
        ("08. Multiplayer RPC Sync", "1.80 ms", "1.95 ms", "+7.7% faster", True),
    ]

    for name, curr, prev, delta, passed in reg_rows:
        events.append((t, "o", f"  \x1b[32m✔\x1b[0m \x1b[1m{name:<27}\x1b[0m : {curr} vs {prev} (\x1b[32m{delta}\x1b[0m)\r\n"))
        t += 0.35

    events.append((t, "o", "\r\n\x1b[1;32m[PASS]\x1b[0m Regression Gate: 0 regressions detected. Mean: +2.6% performance gain.\r\n"))
    t += 0.4
    events.append((t, "o", "  \x1b[36m✔ Generated:\x1b[0m benchmarks/reports/comparison_4.8-dev6_vs_4.8-dev5.html\r\n"))
    events.append((t + 0.1, "o", "  \x1b[36m✔ Generated:\x1b[0m benchmarks/reports/comparison_4.8-dev6_vs_4.8-dev5.svg\r\n"))
    events.append((t + 0.2, "o", "  \x1b[36m✔ Updated:\x1b[0m   benchmarks/history.xml (Run ID #42 logged)\r\n"))
    t += 0.8
    events.append((t, "o", prompt))
    t += 2.0
    events.append((60.2, "o", ""))

    make_cast("lapis_benchmarks_tui.cast", "Lapis Performance Benchmark Suite & TUI Visualizer", events)

# ==============================================================================
# 2. lapis_r2_tui_debugger.cast (~60s)
# ==============================================================================
def gen_r2_tui_debugger():
    events = []
    events.append((0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    prompt = "\x1b[1m\x1b[32mdeveloper@lapis-dev\x1b[0m:\x1b[34m~/projects/void_runner\x1b[0m$ "
    
    t = type_cmd(events, 0.2, prompt, "lapis decompile bin/game.dll --tui")
    
    events.append((t, "o", "\x1b[35m[Lapis]\x1b[0m Initializing Native Radare2 Debugger & Decompiler...\r\n"))
    t += 0.3
    events.append((t, "o", "\x1b[36m  ⠋\x1b[0m Loading symbols from bin/game.pdb and cradare2 engine..."))
    t += 0.5
    events.append((t, "o", "\r\x1b[2K\x1b[32m  ✔\x1b[0m Symbol table indexed: 3,412 symbols (PDB/DWARF matched)\r\n"))
    t += 0.4
    events.append((t, "o", "\x1b[?25l\x1b[2J\x1b[H"))

    def render_tui_nav(active_tab_num):
        tabs = [
            ("1", "Disassembly (pdf)"),
            ("2", "Pseudo-C (pdc)"),
            ("3", "Crystal Source (cl)"),
            ("4", "Registers (dr)"),
            ("5", "Hex Memory (px)"),
            ("6", "Call Stack (dbt)"),
            ("7", "Binary Metrics"),
        ]
        out = "\x1b[1;37;44m ╔══════════════════════════════════════════════════════════════════════════════════╗ \x1b[0m\r\n"
        out += "\x1b[1;37;44m ║ LAPIS NATIVE DEBUGGER & REVERSE ENGINEERING STUDIO (cradare2)                    ║ \x1b[0m\r\n"
        out += "\x1b[1;37;44m ╚══════════════════════════════════════════════════════════════════════════════════╝ \x1b[0m\r\n "
        for num, title in tabs:
            if num == str(active_tab_num):
                out += f"\x1b[1;30;46m [{num}] {title} \x1b[0m "
            else:
                out += f"\x1b[2;37m [{num}] {title} \x1b[0m "
        out += "\r\n\x1b[36m──────────────────────────────────────────────────────────────────────────────────────\x1b[0m\r\n"
        return out

    # Tab 1: Disassembly
    tab1 = render_tui_nav(1)
    tab1 += (
        "\x1b[1;33m; -- sym.Player__physics_process (rip=0x14001a420):\x1b[0m\r\n"
        "\x1b[36m0x14001a420\x1b[0m  \x1b[32m55\x1b[0m                    \x1b[1mpush\x1b[0m rbp\r\n"
        "\x1b[36m0x14001a421\x1b[0m  \x1b[32m4889e5\x1b[0m                \x1b[1mmov\x1b[0m rbp, rsp\r\n"
        "\x1b[36m0x14001a424\x1b[0m  \x1b[32m4883ec40\x1b[0m              \x1b[1msub\x1b[0m rsp, 0x40\r\n"
        "\x1b[36m0x14001a428\x1b[0m  \x1b[32m48894d10\x1b[0m              \x1b[1mmov\x1b[0m qword [rbp - 0x10], rcx\r\n"
        "\x1b[36m0x14001a42c\x1b[0m  \x1b[32mf20f104138\x1b[0m            \x1b[1mmovsd\x1b[0m xmm0, qword [rcx + 0x38]  \x1b[35m; Player#velocity.y\x1b[0m\r\n"
        "\x1b[36m0x14001a432\x1b[0m  \x1b[32mf20f5c0520420000\x1b[0m      \x1b[1msubsd\x1b[0m xmm0, qword [rip + 0x4220] \x1b[35m; GRAVITY * delta\x1b[0m\r\n"
        "\x1b[36m0x14001a43a\x1b[0m  \x1b[32mf20f114138\x1b[0m            \x1b[1mmovsd\x1b[0m qword [rcx + 0x38], xmm0\r\n"
        "\x1b[36m0x14001a440\x1b[0m  \x1b[32me87b120000\x1b[0m              \x1b[1mcall\x1b[0m sym.CharacterBody3D_move_and_slide\r\n"
        "\x1b[36m0x14001a445\x1b[0m  \x1b[32m488b4d10\x1b[0m              \x1b[1mmov\x1b[0m rcx, qword [rbp - 0x10]\r\n"
        "\x1b[36m0x14001a449\x1b[0m  \x1b[32m80794801\x1b[0m              \x1b[1mcmp\x1b[0m byte [rcx + 0x48], 1      \x1b[35m; on_floor?\x1b[0m\r\n"
        "\x1b[36m0x14001a44d\x1b[0m  \x1b[32m7512\x1b[0m                  \x1b[1mjne\x1b[0m 0x14001a461\r\n"
        "\r\n\x1b[2m [1-7] Tabs  [n] Next Instruction  [s] Step Into  [c] Continue  [q] Exit\x1b[0m"
    )
    events.append((t, "o", tab1))
    t += 5.0

    # User steps instruction: RIP changes
    events.append((t, "o", "\x1b[7;1H\x1b[1;32m► \x1b[36m0x14001a42c\x1b[0m  \x1b[32mf20f104138\x1b[0m            \x1b[1;33mmovsd\x1b[0m xmm0, qword [rcx + 0x38]  \x1b[35m; Player#velocity.y\x1b[0m"))
    t += 3.0

    # Switch to Tab 2: Pseudo-C
    tab2 = render_tui_nav(2)
    tab2 += (
        "\x1b[1;33m// Decompiled Pseudo-C (pdc) via radare2 cradare2 engine:\x1b[0m\r\n"
        "\x1b[32mvoid\x1b[0m \x1b[1mPlayer__physics_process\x1b[0m(\x1b[36mPlayer*\x1b[0m this, \x1b[32mdouble\x1b[0m delta) {\r\n"
        "    \x1b[35m// Vector3 velocity calculation\x1b[0m\r\n"
        "    this->velocity.y -= \x1b[33m9.80665\x1b[0m * delta;\r\n"
        "    \r\n"
        "    \x1b[35m// GDExtension C-ABI direct virtual dispatch\x1b[0m\r\n"
        "    \x1b[1mCharacterBody3D_move_and_slide\x1b[0m((\x1b[36mCharacterBody3D*\x1b[0m)this);\r\n"
        "    \r\n"
        "    \x1b[35m// Jump impulse triggering\x1b[0m\r\n"
        "    \x1b[32mif\x1b[0m (this->is_on_floor && \x1b[1mInput_is_action_just_pressed\x1b[0m(\x1b[33m\"jump\"\x1b[0m)) {\r\n"
        "        this->velocity.y = \x1b[33m4.50000\x1b[0m;\r\n"
        "    }\r\n"
        "}\r\n\r\n"
        "\x1b[2m [1-7] Tabs  [e] Export C file  [b] Set Breakpoint  [q] Exit\x1b[0m"
    )
    events.append((t, "o", "\x1b[H" + tab2))
    t += 6.0

    # Switch to Tab 3: Crystal Source
    tab3 = render_tui_nav(3)
    tab3 += (
        "\x1b[1;33m# Crystal Source Mapping (cl) -> src/player_controller.cr:\x1b[0m\r\n"
        "\x1b[36m19:\x1b[0m class PlayerController < Godot::CharacterBody3D\r\n"
        "\x1b[36m20:\x1b[0m   GRAVITY = 9.8_f64\r\n"
        "\x1b[32m21:\x1b[0m   def _physics_process(delta : Float64) : Nil\r\n"
        "\x1b[32m22:\x1b[0m     velocity.y -= GRAVITY * delta\r\n"
        "\x1b[32m23:\x1b[0m     move_and_slide\r\n"
        "\x1b[1;33m24:\x1b[0m \x1b[1;31m●\x1b[0m   if on_floor? && Input.action_just_pressed?(:jump)\r\n"
        "\x1b[32m25:\x1b[0m       velocity.y = 4.5_f64\r\n"
        "\x1b[32m26:\x1b[0m     end\r\n"
        "\x1b[32m27:\x1b[0m   end\r\n"
        "\x1b[36m28:\x1b[0m end\r\n\r\n"
        "\x1b[2m [1-7] Tabs  [G] Jump to Line  [Space] Toggle Gutter Breakpoint  [q] Exit\x1b[0m"
    )
    events.append((t, "o", "\x1b[H" + tab3))
    t += 5.0

    # Switch to Tab 4: CPU Registers
    tab4 = render_tui_nav(4)
    tab4 += (
        "\x1b[1;33m; Live 64-Bit CPU Registers (dr) at breakpoint hit:\x1b[0m\r\n"
        "\x1b[36mRAX:\x1b[0m \x1b[1;32m0x0000000000000001\x1b[0m │ \x1b[36mRBX:\x1b[0m 0x00007ff6a4820000 │ \x1b[36mRCX:\x1b[0m \x1b[1;32m0x000001a43b2e9040\x1b[0m\r\n"
        "\x1b[36mRDX:\x1b[0m 0x0000000000000010 │ \x1b[36mRSI:\x1b[0m 0x000001a43b2e9120 │ \x1b[36mRDI:\x1b[0m 0x0000000000000000\r\n"
        "\x1b[36mR8 :\x1b[0m 0x000001a43b2e9040 │ \x1b[36mR9 :\x1b[0m 0x0000000000000000 │ \x1b[36mR10:\x1b[0m 0x00007ff6a4850020\r\n"
        "\x1b[36mR11:\x1b[0m 0x0000000000000246 │ \x1b[36mR12:\x1b[0m 0x0000000000000000 │ \x1b[36mR13:\x1b[0m 0x0000000000000000\r\n"
        "\x1b[36mRIP:\x1b[0m \x1b[1;33m0x00007ff6a481a42c\x1b[0m │ \x1b[36mRSP:\x1b[0m 0x0000005d4f3fe970 │ \x1b[36mRBP:\x1b[0m 0x0000005d4f3fe9b0\r\n"
        "\x1b[36mXMM0:\x1b[0m 0.000000 (Float64) │ \x1b[36mXMM1:\x1b[0m 0.016667 (delta=60Hz) │ \x1b[36mXMM2:\x1b[0m 9.806650 (gravity)\r\n"
        "\x1b[36mEFLAGS:\x1b[0m [ \x1b[32mCF\x1b[0m \x1b[32mZF\x1b[0m TF \x1b[32mIF\x1b[0m DF OF ] (Diff highlighted from prior step)\r\n\r\n"
        "\x1b[2m [1-7] Tabs  [w] Add Watchpoint  [d] Step In  [q] Exit\x1b[0m"
    )
    events.append((t, "o", "\x1b[H" + tab4))
    t += 5.0

    # Switch to Tab 5: Hex Memory
    tab5 = render_tui_nav(5)
    tab5 += (
        "\x1b[1;33m; Opal HexViewer (px 128 @ 0x000001a43b2e9040 - Player Instance):\x1b[0m\r\n"
        "\x1b[36m0x000001a43b2e9040\x1b[0m  \x1b[32m40 90 2e 3b a4 01 00 00\x1b[0m  \x1b[34m08 00 00 00 00 00 00 00\x1b[0m  |@..;............|\r\n"
        "\x1b[36m0x000001a43b2e9050\x1b[0m  \x1b[33m00 00 00 00 00 00 24 40\x1b[0m  \x1b[32m00 00 00 00 00 00 00 00\x1b[0m  |......$@........|\r\n"
        "\x1b[36m0x000001a43b2e9060\x1b[0m  00 00 00 00 00 00 00 00  01 00 00 00 00 00 00 00  |................|\r\n"
        "\x1b[36m0x000001a43b2e9070\x1b[0m  80 a4 81 a4 f6 7f 00 00  e0 a5 81 a4 f6 7f 00 00  |................|\r\n"
        "\x1b[35m[ObjectDB Header Identified]:\x1b[0m Instance ID: 0x800000000000 │ RefCount: 1 │ ClassDB: PlayerController\r\n\r\n"
        "\x1b[2m [1-7] Tabs  [g] Go to Address  [u] Inspect as UTF-8  [q] Exit\x1b[0m"
    )
    events.append((t, "o", "\x1b[H" + tab5))
    t += 5.0

    # User exits TUI
    events.append((t, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    t += 0.6

    # Run ObjectDB Inspector command
    t = type_cmd(events, t, prompt, "lapis decompile bin/game.dll --object 0x000001a43b2e9040")
    events.append((t, "o", 
        "\x1b[1;36m=== Godot ObjectDB Forensics & Header Decoder ===\x1b[0m\r\n"
        "  Target Address   : \x1b[33m0x000001a43b2e9040\x1b[0m\r\n"
        "  Engine Class     : \x1b[32mCharacterBody3D\x1b[0m (Inherits: Node3D -> Node -> Object)\r\n"
        "  Crystal Script   : \x1b[1;37mPlayerController\x1b[0m (src/player_controller.cr)\r\n"
        "  64-Bit ID        : \x1b[36m140737488355328\x1b[0m (0x800000000000)\r\n"
        "  Reference Count  : 1 (Owned by SceneTree root)\r\n"
        "  Lifecycle State  : Inside Tree (Active in Physics Pipeline)\r\n"
        "  Method Table     : 14 bound methods registered in GDExtension ClassDB\r\n\r\n"
    ))
    t += 4.5

    # Run Variant decoder
    t = type_cmd(events, t, prompt, "lapis decompile bin/game.dll --variant 0x000001a43b2e9058")
    events.append((t, "o", 
        "\x1b[1;36m=== Godot Variant Payload Decoder ===\x1b[0m\r\n"
        "  Memory Address   : \x1b[33m0x000001a43b2e9058\x1b[0m\r\n"
        "  Variant Type ID  : \x1b[32mType 9\x1b[0m (\x1b[1mVector3\x1b[0m)\r\n"
        "  Decoded Payload  : \x1b[1;37mVector3(0.000, 10.000, 0.000)\x1b[0m\r\n"
        "  Byte Layout      : [00 00 00 00] [00 00 24 40] [00 00 00 00] (Contiguous 12-byte float triplet)\r\n\r\n"
    ))
    t += 3.5

    # Run crash triage
    t = type_cmd(events, t, prompt, "lapis log crash")
    events.append((t, "o", 
        "\x1b[1;35m=== Lapis Crash Diagnostics & Forensics Report ===\x1b[0m\r\n"
        "  Crash Dump File  : \x1b[36mlog/crash.log\x1b[0m\r\n"
        "  Status           : \x1b[1;32mCLEAN - Zero crash events recorded\x1b[0m\r\n"
        "  Active Watchdogs : Hardware Memory Protection active (0xC0000005 guard active)\r\n"
        "  ObjectDB Leaks   : 0 orphaned instance pointers detected\r\n"
    ))
    t += 1.5
    events.append((t, "o", prompt))
    t += 2.0
    events.append((60.1, "o", ""))

    make_cast("lapis_r2_tui_debugger.cast", "Lapis Native Radare2 Debugger, Decompiler & Object Forensics", events)

# ==============================================================================
# 3. lapis_debug_workflows.cast (~60s)
# ==============================================================================
def gen_debug_workflows():
    events = []
    events.append((0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    prompt = "\x1b[1m\x1b[32mdeveloper@lapis-dev\x1b[0m:\x1b[34m~/projects/void_runner\x1b[0m$ "
    
    # Workflow 1: Editor under radare2
    t = type_cmd(events, 0.2, prompt, "lapis editor --debug -p template --quit-after=12")
    events.append((t, "o", "\x1b[35m[Lapis]\x1b[0m Spawning Godot Editor v4.8.0-dev6 under radare2 supervisor...\r\n"))
    t += 0.4
    events.append((t, "o", "\x1b[36m[r2]\x1b[0m Attaching to target PID 14208 (godot.windows.editor.x86_64.exe)\r\n"))
    events.append((t + 0.1, "o", "\x1b[36m[r2]\x1b[0m Binding Gutter Breakpoints from src/player_controller.cr:24...\r\n"))
    t += 1.0
    events.append((t, "o", "\x1b[32m[Godot]\x1b[0m Engine core initialized. Loading GDExtension 'bin/crystal_bridge.dll'...\r\n"))
    events.append((t + 0.2, "o", "\x1b[32m[Godot]\x1b[0m Scene tree started: res://scenes/main.tscn\r\n"))
    t += 1.5
    events.append((t, "o", "\r\n\x1b[1;31m[r2 BREAKPOINT HIT]\x1b[0m Process 14208 paused at \x1b[1;33msrc/player_controller.cr:24\x1b[0m\r\n"))
    events.append((t + 0.1, "o", "  \x1b[36mFunction:\x1b[0m PlayerController#_physics_process(delta=0.016667)\r\n"))
    events.append((t + 0.2, "o", "  \x1b[36mInstruction:\x1b[0m 0x14001a449: cmp byte [rcx + 0x48], 1 (on_floor? == true)\r\n"))
    t += 1.2
    
    # Interactive r2 prompt in terminal
    r2_prompt = "\x1b[1;35m[0x14001a449]> \x1b[0m"
    t = type_cmd(events, t, r2_prompt, "dr rip rcx")
    events.append((t, "o", "rip = 0x00007ff6a481a449\r\nrcx = 0x000001a43b2e9040 (PlayerController instance)\r\n"))
    t += 1.5
    
    t = type_cmd(events, t, r2_prompt, "ds 2")
    events.append((t, "o", "Stepped 2 instructions. Now at 0x14001a44f.\r\n"))
    t += 1.2

    t = type_cmd(events, t, r2_prompt, "dc")
    events.append((t, "o", "Continuing execution...\r\n"))
    t += 2.0
    events.append((t, "o", "\x1b[33m[Lapis]\x1b[0m Auto-quit timer expired (12s). Gracefully exiting Godot Editor...\r\n"))
    events.append((t + 0.2, "o", "\x1b[32m✔\x1b[0m Godot Editor session terminated cleanly (Exit Code: 0)\r\n\r\n"))
    t += 1.5

    # Workflow 2: Standalone run with monitor & crash interception
    t = type_cmd(events, t, prompt, "lapis run -d --monitor -p template")
    events.append((t, "o", "\x1b[35m[Lapis]\x1b[0m Launching standalone game runner with real-time TUI telemetry...\r\n"))
    t += 0.8
    events.append((t, "o", "\x1b[?25l\x1b[2J\x1b[H"))

    # Live telemetry view
    for step in range(3):
        fps = 60 - step
        ram = 48.2 + (step * 0.4)
        mon_frame = (
            "\x1b[H\x1b[1;37;44m ╔══════════════════════════════════════════════════════════════════════════════════╗ \x1b[0m\r\n"
            f"\x1b[1;37;44m ║ LAPIS RUNTIME TELEMETRY MONITOR │ FPS: {fps} [60Hz VSYNC] │ RAM: {ram:.1f} MB         ║ \x1b[0m\r\n"
            "\x1b[1;37;44m ╚══════════════════════════════════════════════════════════════════════════════════╝ \x1b[0m\r\n"
            " \x1b[36mFPS History:\x1b[0m  \x1b[32m████████████████████████████████████████████████████████████\x1b[0m 60.0 FPS\r\n"
            " \x1b[36mRAM History:\x1b[0m  \x1b[34m▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄\x1b[0m 48.6 MB\r\n"
            " \x1b[36mFibers:\x1b[0m 3 active (Main, Network, Audio) │ \x1b[36mGC Collections:\x1b[0m 0 (Zero Allocations in hot loop)\r\n"
        )
        events.append((t, "o", mon_frame))
        t += 2.0

    # Synthetic crash injection
    events.append((t, "o", "\r\n\x1b[1;41;37m CRASH DETECTED: EXCEPTION_ACCESS_VIOLATION (0xC0000005) \x1b[0m\r\n"))
    t += 0.5
    events.append((t, "o", "\x1b[35m[Crash Forensics]\x1b[0m Classifying boundary fault...\r\n"))
    t += 0.8
    events.append((t, "o", 
        "  \x1b[33mFaulting Address:\x1b[0m 0x0000000000000008 (Illegal Read at Null Pointer + 0x8)\r\n"
        "  \x1b[33mBoundary Class  :\x1b[0m \x1b[1;31m[GameCode]\x1b[0m (Fault originated in user game logic)\r\n"
        "  \x1b[33mEngine State    :\x1b[0m \x1b[32m[GDExtensionBridge UNCORRUPTED]\x1b[0m (0 engine memory leaks)\r\n"
        "  \x1b[33mStack Origin    :\x1b[0m src/my_node.cr:42 in 'MyNode#on_enemy_hit'\r\n"
        "  \x1b[32m✔ Snapshot staged:\x1b[0m log/crash.log (Full register & thread backtrace dumped)\r\n"
    ))
    t += 4.0
    events.append((t, "o", "\x1b[?25h\r\n"))

    # Tail crash log
    t = type_cmd(events, t, prompt, "lapis log tail crash -n 12")
    events.append((t, "o", 
        "\x1b[1;36m=== log/crash.log (Most Recent Backtrace Snapshot) ===\x1b[0m\r\n"
        "  Frame #0: 0x140024108 in MyNode#on_enemy_hit at src/my_node.cr:42\r\n"
        "  Frame #1: 0x140023840 in Signal#emit at src/libgodot/signals.cr:96\r\n"
        "  Frame #2: 0x140019200 in Enemy#take_damage at src/enemy.cr:18\r\n"
        "  Registers: RAX=0x0000000000000000 RBX=0x000001a43b2e9040 RIP=0x140024108\r\n"
        "  Cause: Attempted to call '.health' on nil 'enemy_target' variable\r\n"
        "  Resolution: Add nil-guard or safe navigation: 'enemy_target.try(&.health)'\r\n"
    ))
    t += 3.0
    events.append((t, "o", prompt))
    t += 2.0
    events.append((60.1, "o", ""))

    make_cast("lapis_debug_workflows.cast", "Lapis Command-Line & In-Editor Debugging Workflows", events)

# ==============================================================================
# 4. lapis_multiplayer_test.cast (~60s)
# ==============================================================================
def gen_multiplayer_test():
    events = []
    events.append((0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    prompt = "\x1b[1m\x1b[32mdeveloper@lapis-dev\x1b[0m:\x1b[34m~/projects/void_runner\x1b[0m$ "
    
    t = type_cmd(events, 0.2, prompt, 'lapis test -f "Multiplayer" --verbose')
    events.append((t, "o", "\x1b[35m[Lapis]\x1b[0m Starting Automated Test Harness (Multiplayer Filter Active)...\r\n"))
    t += 0.4
    events.append((t, "o", "\x1b[36m  ⠋\x1b[0m Initializing Lapis::Multiplayer::Harness (1 Server + 2 Clients)...\r\n"))
    t += 0.8
    events.append((t, "o", "\x1b[32m  ✔\x1b[0m In-memory loopback transport bound: [Peer 1: Host] [Peer 2: Client A] [Peer 3: Client B]\r\n\r\n"))
    t += 0.6

    test_steps = [
        ("Register RPC endpoints: @[RPC(mode: :call_local, sync: :unreliable_ordered)]", 2.5),
        ("Server broadcasts authoritative snapshot state to Peers [2, 3]", 3.0),
        ("Injecting simulated network jitter: 45ms latency variance, 5% packet drop", 3.5),
        ("Wireshark Capture: Packet #0104 [SEQ: 1248 | CH: 1 | LEN: 36 bytes | TYPE: TRANSFORM]", 3.0),
        ("Wireshark Capture: Packet #0105 [SEQ: 1249 | CH: 1 | LEN: 12 bytes | TYPE: RPC_JUMP]", 2.8),
        ("Client B drops packet #0104 -> Delta compression reconciles via snapshot ack", 3.5),
        ("Client-side prediction reconciles player transform within 0.002 units error", 3.0),
        ("Triggering Cooperative Lockstep Debugger breakpoint on Host (Peer 1)...", 3.5),
        ("Peers [2, 3] enter synchronized pause mode (zero socket timeouts detected)", 4.0),
        ("Resuming Host execution -> Clock synchronization restores sub-millisecond drift", 3.5),
        ("Multiplayer ownership migration: Peer 2 disconnects -> Host claims node authority", 3.0),
        ("Verifying zero orphaned ObjectDB instances across network boundary", 2.5),
    ]

    for idx, (desc, duration) in enumerate(test_steps):
        events.append((t, "o", f"  \x1b[36m[{idx+1:02d}/12]\x1b[0m {desc}...\r\n"))
        t += duration * 0.7
        events.append((t, "o", f"  \x1b[32m✔ PASS\x1b[0m Assertion satisfied ({duration*12.4:.1f} ms)\r\n"))
        t += 0.4

    events.append((t, "o", "\r\n\x1b[1;32m════════════════════════════════════════════════════════════════════════════════════\x1b[0m\r\n"))
    events.append((t + 0.1, "o", "\x1b[1;32m  ✔ 12/12 MULTIPLAYER NETWORK SPECS PASSED (0 failures, 0 timeouts, 0 leaks)\x1b[0m\r\n"))
    events.append((t + 0.2, "o", "\x1b[1;32m════════════════════════════════════════════════════════════════════════════════════\x1b[0m\r\n"))
    t += 1.5
    events.append((t, "o", prompt))
    t += 2.0
    events.append((60.1, "o", ""))

    make_cast("lapis_multiplayer_test.cast", "Lapis Multiplayer Lockstep Testing & Network Capture Harness", events)

# ==============================================================================
# 5. lapis_cli_lifecycle.cast (~60s)
# ==============================================================================
def gen_cli_lifecycle():
    events = []
    events.append((0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    prompt = "\x1b[1m\x1b[32mdeveloper@lapis-dev\x1b[0m:\x1b[34m~/projects/void_runner\x1b[0m$ "
    
    # 1. Run lapis (interactive hub)
    t = type_cmd(events, 0.2, prompt, "lapis")
    events.append((t, "o", "\x1b[?25l\x1b[2J\x1b[H"))
    
    hub_view = (
        "\x1b[1;37;44m ╔══════════════════════════════════════════════════════════════════════════════════╗ \x1b[0m\r\n"
        "\x1b[1;37;44m ║ LAPIS UNIFIED COMMAND CENTER & DEVELOPER DASHBOARD (v0.0.255)                    ║ \x1b[0m\r\n"
        "\x1b[1;37;44m ║ Project: void_runner │ Godot: 4.8.0-dev6 │ Crystal: 1.15.0 │ Platform: win-x64   ║ \x1b[0m\r\n"
        "\x1b[1;37;44m ╚══════════════════════════════════════════════════════════════════════════════════╝ \x1b[0m\r\n\r\n"
        " \x1b[1;36mActive Toolchain Health:\x1b[0m\r\n"
        "  • Crystal Compiler : \x1b[32mCrystal 1.15.0 (LLVM 18.1.8)\x1b[0m [OK]\r\n"
        "  • Godot Binary     : \x1b[32mgodot.windows.editor.x86_64.exe\x1b[0m [OK]\r\n"
        "  • Radare2 Native R2: \x1b[32mradare2 5.9.8 (cradare2)\x1b[0m [OK]\r\n"
        "  • GDExtension API  : \x1b[32m824 classes bound\x1b[0m [OK]\r\n"
        "  • Game Library     : \x1b[32mbin/game.dll (Compiled, Staged)\x1b[0m [OK]\r\n\r\n"
        " \x1b[1;33mSingle-Key Hotkey Actions:\x1b[0m\r\n"
        "  \x1b[1;37m[ B ]\x1b[0m Build Project (-O3)        \x1b[1;37m[ T ]\x1b[0m Run Automated Specs\r\n"
        "  \x1b[1;37m[ D ]\x1b[0m Run Doctor Diagnostics      \x1b[1;37m[ E ]\x1b[0m Launch Godot Editor\r\n"
        "  \x1b[1;37m[ R ]\x1b[0m Run Standalone Game         \x1b[1;37m[ / ]\x1b[0m Opal Command Palette\r\n"
        "  \x1b[1;37m[ S ]\x1b[0m Scaffold New Addon/Game     \x1b[1;37m[ Q ]\x1b[0m Exit Command Center\r\n\r\n"
        "\x1b[2m Press hotkey to trigger action directly... [D pressed]\x1b[0m"
    )
    events.append((t, "o", hub_view))
    t += 6.0
    
    # 2. Doctor runs
    events.append((t, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    t += 0.4
    t = type_cmd(events, t, prompt, "lapis doctor --verbose")
    events.append((t, "o", 
        "\x1b[35m=== Lapis: Environment Diagnostics & Toolchain Doctor ===\x1b[0m\r\n\r\n"
        "Diagnostic Matrix Results (6/6 Subsystems Verified):\r\n"
        "\x1b[36m┌────────┬────────────────────┬────────────────────────────────────────────┬─────────┐\x1b[0m\r\n"
        "│ \x1b[1mStatus\x1b[0m │ \x1b[1mComponent\x1b[0m          │ \x1b[1mDiagnostic Detail\x1b[0m                          │ \x1b[1mAction\x1b[0m  │\r\n"
        "\x1b[36m├────────┼────────────────────┼────────────────────────────────────────────┼─────────┤\x1b[0m\r\n"
        "│ \x1b[42;37m PASS \x1b[0m │ Crystal Compiler   │ Crystal 1.15.0 (LLVM 18.1.8, target x86_64)│ Ready   │\r\n"
        "│ \x1b[42;37m PASS \x1b[0m │ Godot Engine       │ Godot Engine v4.8.0.dev6 [3f1a9b]          │ Ready   │\r\n"
        "│ \x1b[42;37m PASS \x1b[0m │ Radare2 Native R2  │ radare2 5.9.8 0 @ windows-x64 (cradare2)   │ Ready   │\r\n"
        "│ \x1b[42;37m PASS \x1b[0m │ GDExtension API    │ extension_api.json matched (824 classes)   │ Ready   │\r\n"
        "│ \x1b[42;37m PASS \x1b[0m │ C++ Bridge Loader  │ MSVC cl.exe 19.38 / x64 C++17 support      │ Ready   │\r\n"
        "│ \x1b[42;37m PASS \x1b[0m │ Windows CRT DLLs   │ gc.dll, pcre2-8.dll, iconv-2.dll staged    │ Ready   │\r\n"
        "\x1b[36m└────────┴────────────────────┴────────────────────────────────────────────┴─────────┘\x1b[0m\r\n\r\n"
        "  \x1b[32m✔\x1b[0m Fiber scheduler & thread-affinity barriers validated\r\n"
        "  \x1b[32m✔\x1b[0m Toolchain Readiness: 100% (Zero configuration gaps detected)\r\n\r\n"
    ))
    t += 7.0

    # 3. Clean dry run & shadows
    t = type_cmd(events, t, prompt, "lapis clean --dry-run")
    events.append((t, "o", 
        "\x1b[35m[Lapis]\x1b[0m Previewing clean targets (dry run)...\r\n"
        "  • 8 stale Windows shadow DLLs (*_loaded_*.dll/pdb): 142.4 MB\r\n"
        "  • Intermediate .crystal/ cache build artifacts:     84.1 MB\r\n"
        "  • Total reclaimable disk space:                    \x1b[1;32m226.5 MB\x1b[0m\r\n\r\n"
    ))
    t += 4.0

    t = type_cmd(events, t, prompt, "lapis clean --shadows")
    events.append((t, "o", 
        "\x1b[35m[Lapis]\x1b[0m Purging locked Windows shadow DLLs (*_loaded_*)...\r\n"
        "  \x1b[32m✔\x1b[0m Removed 8 stale shadow files without closing Godot Editor (142.4 MB freed)\r\n\r\n"
    ))
    t += 3.0

    # 4. Sync targets
    t = type_cmd(events, t, prompt, "lapis sync")
    events.append((t, "o", 
        "\x1b[35m[Lapis]\x1b[0m Synchronizing build artifacts across all project targets...\r\n"
        "  • Staging bin/crystal_bridge.dll -> test/bin/crystal_bridge.dll\r\n"
        "  • Staging bin/game.dll           -> test/bin/game.dll\r\n"
        "  • Staging addons/manifests       -> template/addons/\r\n"
        "  \x1b[32m✔\x1b[0m All 4 target directories synchronized cleanly.\r\n\r\n"
    ))
    t += 4.0

    # 5. Export templates explain
    t = type_cmd(events, t, prompt, "lapis export-templates explain")
    events.append((t, "o", 
        "\x1b[1;35m=== Lapis: Crystal Export Templates Architecture ===\x1b[0m\r\n"
        "  Godot Export Templates provide the pre-compiled native runner binary for each OS.\r\n"
        "  Lapis bundles Crystal libraries as shared GDExtension libraries that load at boot:\r\n"
        "    • Windows : godot.windows.template_release.x86_64.exe + game.dll\r\n"
        "    • Linux   : godot.linuxbsd.template_release.x86_64    + libgame.so\r\n"
        "    • macOS   : Godot.app (Universal Binary)              + libgame.dylib\r\n"
        "  \x1b[32m✔\x1b[0m Current version: Godot 4.8.dev6 templates installed in AppData/Roaming\r\n\r\n"
    ))
    t += 5.0

    # 6. IDE setup
    t = type_cmd(events, t, prompt, "lapis ide setup vscode")
    events.append((t, "o", 
        "\x1b[35m[Lapis]\x1b[0m Configuring VS Code workspace with Crystalline LSP & Radare2...\r\n"
        "  \x1b[32m✔ Generated:\x1b[0m .vscode/settings.json (Crystalline daemon & syntax bindings)\r\n"
        "  \x1b[32m✔ Generated:\x1b[0m .vscode/tasks.json (Build Game, Test, Sync, Clean)\r\n"
        "  \x1b[32m✔ Generated:\x1b[0m .vscode/launch.json (Native Radare2 Gutter Debugger Configuration)\r\n"
        "  \x1b[1;32m[OK] IDE workspace ready!\x1b[0m\r\n"
    ))
    t += 2.0
    events.append((t, "o", prompt))
    t += 2.0
    events.append((60.2, "o", ""))

    make_cast("lapis_cli_lifecycle.cast", "Lapis Command Center, Diagnostics & Full Project Lifecycle", events)

# ==============================================================================
# 6. lapis_interactive_studio.cast (~60s)
# ==============================================================================
def gen_interactive_studio():
    events = []
    events.append((0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    prompt = "\x1b[1m\x1b[32mdeveloper@lapis-dev\x1b[0m:\x1b[34m~/projects/void_runner\x1b[0m$ "
    
    # 1. 3D Color Studio
    t = type_cmd(events, 0.2, prompt, "lapis color --3d --shape=cube")
    events.append((t, "o", "\x1b[?25l\x1b[2J\x1b[H"))
    
    # Render rotating 3D RGB Cube frames
    cube_angles = ["Yaw: 15° Pitch: 25°", "Yaw: 35° Pitch: 30°", "Yaw: 55° Pitch: 35°"]
    for ang in cube_angles:
        cube_view = (
            "\x1b[H\x1b[1;37;45m ╔══════════════════════════════════════════════════════════════════════════════════╗ \x1b[0m\r\n"
            f"\x1b[1;37;45m ║ OPAL TRUECOLOR 3D SPATIAL PALETTE STUDIO │ {ang:<30} ║ \x1b[0m\r\n"
            "\x1b[1;37;45m ╚══════════════════════════════════════════════════════════════════════════════════╝ \x1b[0m\r\n\r\n"
            "                 \x1b[38;2;255;100;100m.-----------------------.\x1b[0m\r\n"
            "                \x1b[38;2;255;150;100m/                       /|\x1b[0m\r\n"
            "               \x1b[38;2;255;200;100m/                       / |\x1b[0m\r\n"
            "              \x1b[38;2;200;255;100m/                       /  |\x1b[0m\r\n"
            "             \x1b[38;2;100;255;150m*-----------------------*   |\x1b[0m\r\n"
            "             \x1b[38;2;100;200;255m|   \x1b[1;37mCURSOR\x1b[0m              \x1b[38;2;100;200;255m|   |\x1b[0m\r\n"
            "             \x1b[38;2;150;150;255m|    \x1b[1;38;2;168;85;247m[ #A855F7 ]\x1b[0m        \x1b[38;2;150;150;255m|   |\x1b[0m\r\n"
            "             \x1b[38;2;200;100;255m|   RGB: (168, 85, 247) |   |\x1b[0m\r\n"
            "             \x1b[38;2;255;100;200m|   Hex: Purple Accent  |   *\x1b[0m\r\n"
            "             \x1b[38;2;255;100;150m|                       |  /\x1b[0m\r\n"
            "             \x1b[38;2;255;100;100m*-----------------------* / \x1b[0m\r\n"
            "              \x1b[38;2;200;100;100m|                       |/  \x1b[0m\r\n"
            "              \x1b[38;2;150;100;100m'-----------------------'   \x1b[0m\r\n\r\n"
            "\x1b[2m [Arrow Keys] Rotate 3D Cube  [W/S] Zoom In/Out  [Enter] Select Color  [q] Cancel\x1b[0m"
        )
        events.append((t, "o", cube_view))
        t += 2.0

    # User selects color
    events.append((t, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    t += 0.5
    events.append((t, "o", "Selected Color: \x1b[1;97m#A855F7\x1b[0m (RGB: 168, 85, 247) - Saved to theme cache.\r\n\r\n"))
    t += 1.5

    # 2. Terminal File Explorer
    t = type_cmd(events, t, prompt, "lapis explore src/")
    events.append((t, "o", "\x1b[?25l\x1b[2J\x1b[H"))
    
    file_view = (
        "\x1b[1;37;46m ╔══════════════════════════════════════════════════════════════════════════════════╗ \x1b[0m\r\n"
        "\x1b[1;37;46m ║ OPAL INTERACTIVE TERMINAL FILE EXPLORER & PROJECT BROWSER                         ║ \x1b[0m\r\n"
        "\x1b[1;37;46m ╚══════════════════════════════════════════════════════════════════════════════════╝ \x1b[0m\r\n"
        " \x1b[36mLocation:\x1b[0m \x1b[1mC:\\Users\\developer\\projects\\void_runner\\src\\\x1b[0m\r\n\r\n"
        "  \x1b[34m📁 .. (parent)\x1b[0m\r\n"
        "  \x1b[34m📁 docs/\x1b[0m                  12 files     [Directory]\r\n"
        "  \x1b[34m📁 generated/\x1b[0m             824 files    [GDExtension Class Bindings]\r\n"
        "  \x1b[32m📄 main.cr\x1b[0m                1.4 KB       Crystal Source\r\n"
        "  \x1b[1;33m► 📄 player_controller.cr\x1b[0m   \x1b[1;37m3.8 KB       CharacterBody3D Controller (Active)\x1b[0m\r\n"
        "  \x1b[32m📄 game_hud.cr\x1b[0m            2.1 KB       Control Node UI\r\n"
        "  \x1b[32m📄 enemy_spawner.cr\x1b[0m       4.6 KB       Node3D Spawner\r\n\r\n"
        "\x1b[2m [↑↓] Navigate  [Enter] Open File  [/] Fuzzy Filter  [q] Exit\x1b[0m"
    )
    events.append((t, "o", file_view))
    t += 5.0
    
    events.append((t, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    t += 0.5
    events.append((t, "o", "Selected File: \x1b[1;96msrc/player_controller.cr\x1b[0m (Node Class: PlayerController)\r\n\r\n"))
    t += 1.5

    # 3. Shaders FX Playground
    t = type_cmd(events, t, prompt, "lapis shaders")
    events.append((t, "o", "\x1b[1;36m✨ Opal Text Shader Playground\x1b[0m\r\n"))
    events.append((t + 0.1, "o", "Activating real-time CRT scanlines and terminal phosphor glow...\r\n"))
    t += 1.0
    
    crt_fx = (
        "\x1b[2J\x1b[H\x1b[1;32m"
        "======================================================================================\r\n"
        "  ██████╗ ██████╗  █████╗ ██╗      ███████╗██╗  ██╗\r\n"
        " ██╔═══██╗██╔══██╗██╔══██╗██║      ██╔════╝██║  ██║  [CRT PHOSPHOR SCANLINES ACTIVE]\r\n"
        " ██║   ██║██████╔╝███████║██║█████╗█████╗  ╚█████╔╝  Scan Frequency: 60 Hz\r\n"
        " ██║   ██║██╔═══╝ ██╔══██║██║╚════╝██╔══╝   ██╔═██╗   Curvature Warp: 0.15\r\n"
        " ╚██████╔╝██║     ██║  ██║███████╗ ██║      ██║  ██╗  Bloom Luminance: 1.25\r\n"
        "  ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝ ╚═╝      ╚═╝  ╚═╝\r\n"
        "======================================================================================\r\n\x1b[0m"
        " \x1b[2m[Matrix Stream Running in ANSI buffer... Zero GC churn]\x1b[0m\r\n\r\n"
    )
    events.append((t, "o", crt_fx))
    t += 6.0
    events.append((t, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    t += 0.5

    # 4. Docs TUI
    t = type_cmd(events, t, prompt, 'lapis docs tui "concurrency"')
    events.append((t, "o", "\x1b[?25l\x1b[2J\x1b[H"))
    
    docs_view = (
        "\x1b[1;37;44m ╔══════════════════════════════════════════════════════════════════════════════════╗ \x1b[0m\r\n"
        "\x1b[1;37;44m ║ LAPIS INTERACTIVE DOCUMENTATION EXPLORER │ Search: 'concurrency'                 ║ \x1b[0m\r\n"
        "\x1b[1;37;44m ╚══════════════════════════════════════════════════════════════════════════════════╝ \x1b[0m\r\n"
        " \x1b[36m┌─ SEARCH RESULTS (4) ────────────┐ ┌─ GUIDE: Concurrency & Main Thread Dispatch ────┐\x1b[0m\r\n"
        " │ \x1b[1;32m► Guide: Concurrency Patterns\x1b[0m  │ │ \x1b[1mThread Safety Policy:\x1b[0m                             │\r\n"
        " │   Stdlib: Fiber (M:N scheduler) │ │ Godot's SceneTree is strictly single-threaded.  │\r\n"
        " │   Stdlib: Channel(T)            │ │ Crystal background fibers must dispatch node   │\r\n"
        " │   Guide: Multiplayer RPC        │ │ mutations via \x1b[33mGodot.main_thread do ... end\x1b[0m.     │\r\n"
        " │                                 │ │                                                │\r\n"
        " │                                 │ │ \x1b[1mExample:\x1b[0m                                       │\r\n"
        " │                                 │ │   spawn do                                     │\r\n"
        " │                                 │ │     data = fetch_procedural_chunk              │\r\n"
        " │                                 │ │     Godot.main_thread { mesh.update(data) }    │\r\n"
        " │                                 │ │   end                                          │\r\n"
        " \x1b[36m└─────────────────────────────────┘ └────────────────────────────────────────────────┘\x1b[0m\r\n"
        "\x1b[2m [↑↓] Navigate Guides  [Tab] Switch Pane  [/] New Query  [q] Exit Explorer\x1b[0m"
    )
    events.append((t, "o", docs_view))
    t += 7.0
    
    events.append((t, "o", "\x1b[2J\x1b[H\x1b[?25h"))
    t += 0.5
    events.append((t, "o", prompt))
    t += 2.0
    events.append((60.1, "o", ""))

    make_cast("lapis_interactive_studio.cast", "Lapis Creative Terminal Tools: 3D Color Studio, File Explorer & Shaders", events)

if __name__ == "__main__":
    gen_benchmarks_tui()
    gen_r2_tui_debugger()
    gen_debug_workflows()
    gen_multiplayer_test()
    gen_cli_lifecycle()
    gen_interactive_studio()
    print("All 6 asciicasts generated successfully!")
