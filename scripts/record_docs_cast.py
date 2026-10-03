import json

def generate_docs_cast(output_path="casts/lapis_docs_cli_tui.cast"):
    events = []
    
    # Start with cleared terminal and prompt
    events.append([0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"])
    prompt = "\x1b[1;32mian@workstation\x1b[0m:\x1b[1;34m~/lapis/template\x1b[0m$ "
    
    t = 0.2
    
    def type_command(start_time, cmd):
        cur = start_time
        events.append([round(cur, 3), "o", prompt])
        cur += 0.25
        for ch in cmd:
            cur += 0.032
            events.append([round(cur, 3), "o", ch])
        cur += 0.18
        events.append([round(cur, 3), "o", "\r\n"])
        return round(cur, 3)

    # -------------------------------------------------------------
    # 1. CLI Lookup: Godot ClassDB API
    # -------------------------------------------------------------
    t = type_command(t, 'lapis docs lookup gd "CharacterBody3D.move_and_slide"')
    t += 0.15
    out1 = (
        "\x1b[36m╭──────────────────────────────────────────────────────────────────────────────╮\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m \x1b[1;33m[Godot 4.x Engine API]\x1b[0m \x1b[1mCharacterBody3D.move_and_slide\x1b[0m                       \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m╰──────────────────────────────────────────────────────────────────────────────╯\x1b[0m\r\n"
        "\x1b[90mInheritance:\x1b[0m \x1b[36mPhysicsBody3D < CollisionObject3D < Node3D\x1b[0m\r\n"
        "\x1b[1mSIGNATURE:\x1b[0m\r\n"
        "  \x1b[1;32mfunc move_and_slide() -> bool\x1b[0m\r\n"
        "\x1b[90mRETURNS:\x1b[0m \x1b[36mbool\x1b[0m (true if collided during motion)\r\n"
    )
    events.append([round(t, 3), "o", out1])
    t += 2.2

    # -------------------------------------------------------------
    # 2. CLI Lookup: Crystal Standard Library
    # -------------------------------------------------------------
    t = type_command(t, 'lapis docs lookup stdlib "Channel"')
    t += 0.15
    out2 = (
        "\x1b[35m╭──────────────────────────────────────────────────────────────────────────────╮\x1b[0m\r\n"
        "\x1b[35m│\x1b[0m \x1b[1;35m[Crystal Core Standard Library]\x1b[0m \x1b[1mChannel(T)\x1b[0m                                     \x1b[35m│\x1b[0m\r\n"
        "\x1b[35m╰──────────────────────────────────────────────────────────────────────────────╯\x1b[0m\r\n"
        "\x1b[1mSIGNATURE:\x1b[0m\r\n"
        "  \x1b[1;32mclass Channel(T)\x1b[0m\r\n"
        "\x1b[1mDESCRIPTION:\x1b[0m\r\n"
        "  Concurrent communication conduit between fibers with M:N scheduler.\r\n"
        "  Cross-thread workers must use buffered channels: \x1b[36mChannel(T).new(capacity)\x1b[0m.\r\n"
    )
    events.append([round(t, 3), "o", out2])
    t += 2.2

    # -------------------------------------------------------------
    # 3. CLI Search: Rapid full-text search
    # -------------------------------------------------------------
    t = type_command(t, 'lapis docs search "concurrency"')
    t += 0.15
    out3 = (
        "\r\n\x1b[1;37m=== Documentation Search Results for 'concurrency' (6 matches) ===\x1b[0m\r\n"
        "  \x1b[33m[GUIDE]\x1b[0m  \x1b[1mguide:concurrency:A_FIBERS_AND_COOPERATIVE_AWAIT\x1b[0m — Fibers & Await\r\n"
        "  \x1b[33m[GUIDE]\x1b[0m  \x1b[1mguide:concurrency:B_OS_THREADS_AND_CHANNELS\x1b[0m — Multi-core Threads\r\n"
        "  \x1b[33m[GUIDE]\x1b[0m  \x1b[1mguide:concurrency:C_MAIN_THREAD_DISPATCH\x1b[0m — Main Queue Dispatch\r\n"
        "  \x1b[35m[STDLIB]\x1b[0m \x1b[1mChannel(T)\x1b[0m — Concurrent communication conduit between fibers\r\n"
        "  \x1b[35m[STDLIB]\x1b[0m \x1b[1mMutex\x1b[0m — Re-entrant mutual exclusion primitive for worker threads\r\n"
        "  \x1b[32m[CRYSTAL]\x1b[0m\x1b[1mWorkerPool\x1b[0m — Background task scheduler and fiber pool\r\n"
    )
    events.append([round(t, 3), "o", out3])
    t += 2.4

    # -------------------------------------------------------------
    # 4. Launch TUI Explorer: lapis docs tui
    # -------------------------------------------------------------
    t = type_command(t, 'lapis docs tui')
    t += 0.2
    # Clear screen and enter TUI
    events.append([round(t, 3), "o", "\x1b[?25l\x1b[2J\x1b[H"])
    t += 0.05

    # Helper to render the TUI screen at 86 columns x 22 lines
    def render_tui(active_pill, search_box, symbols_list, selected_idx, right_lines):
        lines = []
        # Line 1: Header
        lines.append(" \x1b[1;36m:: LAPIS UNIFIED DOCUMENTATION EXPLORER ::\x1b[0m     \x1b[90m│ Indexed: 3,412 symbols\x1b[0m")
        
        # Line 2: Context Pills
        pills = [
            (1, "All"),
            (2, "Godot (GD)"),
            (3, "Crystal (CR)"),
            (4, "Guides (DOC)"),
            (5, "Stdlib (STD)")
        ]
        pill_str = " "
        for num, name in pills:
            tag = f"[ {num}: {name} ]"
            if num == active_pill:
                pill_str += f"\x1b[1;37;48;5;238m{tag}\x1b[0m "
            else:
                pill_str += f"\x1b[90m{tag}\x1b[0m "
        lines.append(pill_str)
        
        # Line 3: Search box
        lines.append(f" {search_box}")
        
        # Line 4: Divider
        lines.append(" " + "\x1b[90m" + "─" * 84 + "\x1b[0m")
        
        # Lines 5 to 19: Split layout (Left: 34 cols, Divider: 1 col, Right: 48 cols)
        left_header = f" \x1b[1;37mSYMBOLS ({len(symbols_list)} MATCHES)\x1b[0m"
        left_header_padded = left_header + " " * max(0, 36 - 19)
        lines.append(f"{left_header_padded}\x1b[90m│\x1b[0m {right_lines[0] if len(right_lines) > 0 else ''}")
        
        for i in range(14):
            # Left entry
            if i < len(symbols_list):
                sym_badge, sym_name = symbols_list[i]
                is_sel = (i == selected_idx)
                cur = "►" if is_sel else " "
                if is_sel:
                    left_cell = f" \x1b[1;37;48;5;236m{cur} {sym_badge} {sym_name:<18}\x1b[0m"
                else:
                    left_cell = f"  {sym_badge} {sym_name:<19}"
            else:
                left_cell = " " * 35
                
            right_content = right_lines[i + 1] if (i + 1) < len(right_lines) else ""
            lines.append(f"{left_cell} \x1b[90m│\x1b[0m {right_content}")
            
        # Line 20: Divider
        lines.append(" " + "\x1b[90m" + "─" * 84 + "\x1b[0m")
        
        # Line 21: Controls Footer
        lines.append(" \x1b[1;37m↑/↓: Select │ PgUp/PgDn: Scroll Doc │ 1-5: Context │ /: Search │ Esc/Q: Exit\x1b[0m")
        
        return "\x1b[H" + "\r\n".join(lines)

    # Initial TUI Screen
    syms_initial = [
        ("\x1b[36m[GD:CLASS]\x1b[0m", "CharacterBody3D"),
        ("\x1b[36m[GD:METH] \x1b[0m", "move_and_slide"),
        ("\x1b[36m[GD:PROP] \x1b[0m", "velocity"),
        ("\x1b[32m[CR:CLASS]\x1b[0m", "PlayerController"),
        ("\x1b[33m[DOC:GUIDE]\x1b[0m", "concurrency:fibers"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Channel(T)"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Fiber"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Mutex"),
        ("\x1b[32m[CR:STRUCT]\x1b[0m", "InventoryItem"),
        ("\x1b[32m[CR:NODE] \x1b[0m", "CombatRadar"),
        ("\x1b[36m[GD:METH] \x1b[0m", "is_on_floor"),
        ("\x1b[36m[GD:METH] \x1b[0m", "get_real_velocity"),
        ("\x1b[33m[DOC:GUIDE]\x1b[0m", "concurrency:actor"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Thread"),
    ]
    
    right_charbody = [
        "\x1b[1;33m[Godot 4.x Engine API]\x1b[0m \x1b[1mCharacterBody3D\x1b[0m",
        "\x1b[90mDefined in: godot/scene/3d/physics_body_3d.h\x1b[0m",
        "\x1b[36mInherits: PhysicsBody3D < CollisionObject3D\x1b[0m",
        "",
        "\x1b[1mSIGNATURE:\x1b[0m",
        "  \x1b[1;32;48;5;235mclass CharacterBody3D < PhysicsBody3D\x1b[0m",
        "",
        "\x1b[1mDESCRIPTION:\x1b[0m",
        "Specialized 3D physics body for characters moved",
        "via script. Handles slopes, stair-stepping, and",
        "floor snapping automatically.",
        "",
        "Use \x1b[36mmove_and_slide()\x1b[0m to apply velocity physics.",
        "Query \x1b[36mis_on_floor()\x1b[0m to detect collisions.",
        ""
    ]
    
    events.append([round(t, 3), "o", render_tui(1, "\x1b[36mSearch: [] (Press '/' to search)\x1b[0m", syms_initial, 0, right_charbody)])
    t += 1.6

    # -------------------------------------------------------------
    # 5. Navigate Down: Select move_and_slide
    # -------------------------------------------------------------
    right_move_and_slide = [
        "\x1b[1;33m[Godot 4.x Engine API]\x1b[0m \x1b[1mCharacterBody3D#move_and_slide\x1b[0m",
        "\x1b[90mDefined in: godot/scene/3d/physics_body_3d.h:112\x1b[0m",
        "\x1b[36mInherits: PhysicsBody3D\x1b[0m",
        "",
        "\x1b[1mSIGNATURE:\x1b[0m",
        "  \x1b[1;32;48;5;235mfunc move_and_slide() -> bool\x1b[0m",
        "",
        "\x1b[1mRETURNS:\x1b[0m \x1b[36mbool\x1b[0m (true if collided with body)",
        "",
        "\x1b[1mDESCRIPTION:\x1b[0m",
        "Moves the body based on velocity. If the body",
        "collides with another, it will slide along the",
        "surface rather than stop immediately.",
        "",
        "Mutates \x1b[36mvelocity\x1b[0m when colliding with walls/floors."
    ]
    events.append([round(t, 3), "o", render_tui(1, "\x1b[36mSearch: [] (Press '/' to search)\x1b[0m", syms_initial, 1, right_move_and_slide)])
    t += 2.0

    # -------------------------------------------------------------
    # 6. Interactive Search in TUI: Press '/' then type 'concurrency'
    # -------------------------------------------------------------
    events.append([round(t, 3), "o", render_tui(1, "\x1b[1;33mSearch: [_]\x1b[0m", syms_initial, 1, right_move_and_slide)])
    t += 0.3
    
    query = "concurrency"
    curr_q = ""
    for ch in query:
        curr_q += ch
        t += 0.06
        events.append([round(t, 3), "o", render_tui(1, f"\x1b[1;33mSearch: [{curr_q}_]\x1b[0m", syms_initial, 1, right_move_and_slide)])
    
    t += 0.3
    # Press Enter to finalize search
    syms_filtered = [
        ("\x1b[33m[DOC:GUIDE]\x1b[0m", "concurrency:fibers"),
        ("\x1b[33m[DOC:GUIDE]\x1b[0m", "concurrency:threads"),
        ("\x1b[33m[DOC:GUIDE]\x1b[0m", "concurrency:dispatch"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Channel(T)"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Mutex"),
        ("\x1b[32m[CR:CLASS]\x1b[0m", "WorkerPool")
    ]
    
    right_guide_p1 = [
        "\x1b[1;33m[Lapis Architectural Guide]\x1b[0m \x1b[1mguide:concurrency:fibers\x1b[0m",
        "\x1b[90mDefined in: docs/d_architecture/a_concurrency.cr:14\x1b[0m",
        "",
        "\x1b[1mSIGNATURE:\x1b[0m",
        "  \x1b[1;32;48;5;235mGuide [concurrency]: Fibers & Cooperative Await\x1b[0m",
        "",
        "\x1b[1mDESCRIPTION:\x1b[0m",
        "Comprehensive guide to running Crystal fibers in Godot's",
        "single-threaded scene loop and cooperative yielding.",
        "",
        "\x1b[1;37m### The Three Golden Fiber Invariants\x1b[0m",
        "1. Never call blocking sleep on the main thread.",
        "2. Always cooperatively yield or await engine frames.",
        "3. Route UI and SceneTree operations to main thread.",
        "\x1b[90m[PgDn: Scroll for Code Examples ↓]\x1b[0m"
    ]
    events.append([round(t, 3), "o", render_tui(1, f"\x1b[36mSearch: [{query}] (Press '/' to search)\x1b[0m", syms_filtered, 0, right_guide_p1)])
    t += 2.2

    # -------------------------------------------------------------
    # 7. Scrolling Around: PgDn (Page Down) to inspect code examples
    # -------------------------------------------------------------
    right_guide_p2 = [
        "\x1b[1;33m[Lapis Architectural Guide]\x1b[0m \x1b[1mguide:concurrency:fibers\x1b[0m",
        "\x1b[90m[Offset +8 lines] ────────────────────────────────\x1b[0m",
        "\x1b[1;37m### Yielding Execution in _process\x1b[0m",
        "Pumping spawned fibers cooperatively from main thread:",
        "  \x1b[1;32mdef _process(delta : Float64)\x1b[0m",
        "    \x1b[36mFiber.yield\x1b[0m \x1b[90m# Advance background fibers\x1b[0m",
        "  \x1b[1;32mend\x1b[0m",
        "",
        "\x1b[1;37m### Awaiting Godot Engine Signals\x1b[0m",
        "Fibers suspend cooperatively without blocking OS thread:",
        "  \x1b[36mawait timer.timeout\x1b[0m",
        "  \x1b[36mawait tween.finished\x1b[0m",
        "",
        "\x1b[90m[PgUp: Top ↑ │ PgDn: Worker Threads & Channels ↓]\x1b[0m",
        ""
    ]
    events.append([round(t, 3), "o", render_tui(1, f"\x1b[36mSearch: [{query}] (Press '/' to search)\x1b[0m", syms_filtered, 0, right_guide_p2)])
    t += 2.4

    # Scroll further down (PgDn again)
    right_guide_p3 = [
        "\x1b[1;33m[Lapis Architectural Guide]\x1b[0m \x1b[1mguide:concurrency:fibers\x1b[0m",
        "\x1b[90m[Offset +16 lines] ───────────────────────────────\x1b[0m",
        "\x1b[1;37m### Background OS Threads & Channels\x1b[0m",
        "For CPU-heavy generation (procedural terrain, A* path),",
        "spawn real OS threads with \x1b[35mGodot::Channel(T)\x1b[0m:",
        "  \x1b[36mchannel = Channel(TerrainMesh).new(capacity: 4)\x1b[0m",
        "  \x1b[36mThread.new { compute_terrain(channel) }\x1b[0m",
        "",
        "\x1b[1;37m### Safe Main Thread Dispatch\x1b[0m",
        "  \x1b[36mGodot.on_main_thread do\x1b[0m",
        "    mesh_instance.mesh = channel.receive",
        "  \x1b[36mend\x1b[0m",
        "",
        "\x1b[90m[PgUp: Scroll back up ↑]\x1b[0m"
    ]
    events.append([round(t, 3), "o", render_tui(1, f"\x1b[36mSearch: [{query}] (Press '/' to search)\x1b[0m", syms_filtered, 0, right_guide_p3)])
    t += 2.4

    # Scroll back up (PgUp)
    events.append([round(t, 3), "o", render_tui(1, f"\x1b[36mSearch: [{query}] (Press '/' to search)\x1b[0m", syms_filtered, 0, right_guide_p1)])
    t += 1.4

    # -------------------------------------------------------------
    # 8. Switching Context: Press '5' for Stdlib (STD)
    # -------------------------------------------------------------
    syms_stdlib = [
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Channel(T)"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Fiber"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Mutex"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Thread"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "Atomic(T)"),
        ("\x1b[35m[STD:METH] \x1b[0m", "Channel#send"),
        ("\x1b[35m[STD:METH] \x1b[0m", "Channel#receive"),
        ("\x1b[35m[STD:METH] \x1b[0m", "Mutex#synchronize"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "WaitChannel"),
        ("\x1b[35m[STD:CLASS]\x1b[0m", "ConditionVariable")
    ]
    right_channel = [
        "\x1b[1;35m[Crystal Core Standard Library]\x1b[0m \x1b[1mChannel(T)\x1b[0m",
        "\x1b[90mDefined in: crystal/src/channel.cr:8\x1b[0m",
        "",
        "\x1b[1mSIGNATURE:\x1b[0m",
        "  \x1b[1;32;48;5;235mclass Channel(T)\x1b[0m",
        "",
        "\x1b[1mDESCRIPTION:\x1b[0m",
        "Concurrent communication conduit between fibers with M:N",
        "cooperative scheduler.",
        "",
        "Cross-thread workers must use buffered channels:",
        "  \x1b[36mChannel(T).new(capacity: 16)\x1b[0m",
        "Avoid unbuffered channels on raw Thread.new to prevent",
        "execution context suspension panics.",
        ""
    ]
    events.append([round(t, 3), "o", render_tui(5, "\x1b[36mSearch: [] (Press '/' to search)\x1b[0m", syms_stdlib, 0, right_channel)])
    t += 2.2

    # -------------------------------------------------------------
    # 9. Clean Exit: Press 'q' to return to Shell Prompt
    # -------------------------------------------------------------
    events.append([round(t, 3), "o", "\x1b[?25h\x1b[2J\x1b[H"])
    t += 0.1
    events.append([round(t, 3), "o", prompt])
    t += 3.0
    events.append([round(t, 3), "o", ""])

    with open(output_path, "w", encoding="utf-8") as f:
        header = {
            "version": 2,
            "width": 86,
            "height": 22,
            "timestamp": 1790904120,
            "title": "Lapis Docs CLI & Interactive TUI Explorer",
            "env": {"TERM": "xterm-256color", "SHELL": "lapis"}
        }
        f.write(json.dumps(header) + "\n")
        for ev in events:
            f.write(json.dumps(ev) + "\n")
            
    print(f"Generated {output_path} successfully ({len(events)} events, duration: {round(t, 1)}s)")

if __name__ == "__main__":
    generate_docs_cast()
