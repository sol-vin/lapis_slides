import json

def generate_r2_crystal_cast(output_path="casts/lapis_r2_crystal.cast"):
    events = []
    events.append([0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"])
    prompt = "\x1b[1;32mian@workstation\x1b[0m:\x1b[1;34m~/lapis/template\x1b[0m$ "
    
    t = 0.2
    
    def type_cmd(start_t, p, cmd):
        cur = start_t
        events.append([round(cur, 3), "o", p])
        cur += 0.25
        for ch in cmd:
            cur += 0.03
            events.append([round(cur, 3), "o", ch])
        cur += 0.18
        events.append([round(cur, 3), "o", "\r\n"])
        return round(cur, 3)

    # =========================================================================
    # SCENE 1: Crystal Runtime Inspection & Class Discovery on game.dll
    # =========================================================================
    t = type_cmd(t, prompt, "lapis decompile bin/game.dll --crystal")
    t += 0.15
    
    scene1_out = (
        "\x1b[36m╭─ Crystal Runtime Inspection: game.dll ──────────────────────────────────────────────╮\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m Crystal Binary:   \x1b[1;37;42m [✓] DETECTED \x1b[0m    Classes: \x1b[1;37m42\x1b[0m   GC Functions: \x1b[1;37m18\x1b[0m            \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m \x1b[90mMain Entrypoint:\x1b[0m  \x1b[36m*Crystal::main\x1b[0m (\x1b[33m0x140001080\x1b[0m) [Boehm GC Active: GC_malloc]     \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m                                                                              \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m \x1b[1;33mDiscovered Crystal Classes (42):\x1b[0m                                             \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m   • \x1b[1;32mPlayer < CharacterBody3D\x1b[0m           (14 methods, 4 exports, 2 signals)    \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m   • \x1b[1;32mCombatRadar < Node2D\x1b[0m               (8 methods, 3 exports, 1 signal)      \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m   • \x1b[1;32mInventory < RefCounted\x1b[0m             (11 methods, 6 exports)               \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m   • \x1b[1;32mEnemySpawner < Node3D\x1b[0m              (6 methods, 2 exports)                \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m   • \x1b[36mGodot::Node < Godot::Object\x1b[0m        (28 methods, 12 properties)           \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m   \x1b[90m... and 37 more classes (GC roots registered)\x1b[0m                              \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m╰─────────────────────────────────────────────────────────────────────────────╯\x1b[0m\r\n"
    )
    events.append([round(t, 3), "o", scene1_out])
    t += 3.2

    # =========================================================================
    # SCENE 2: AST Symbol Demangling & Side-by-Side Decompilation
    # =========================================================================
    events.append([round(t, 3), "o", "\x1b[2J\x1b[H"])
    t += 0.1
    t = type_cmd(t, prompt, 'lapis decompile bin/game.dll "Player#_physics_process" --side-by-side')
    t += 0.15
    
    scene2_out = (
        "\x1b[1;33m// [AST Demangled] Player#_physics_process(delta : Float64) : Nil (0x1400021b0)\x1b[0m\r\n"
        "\x1b[1;36m// DISASSEMBLY (x86_64)                 │ PSEUDO-C DECOMPILATION (pdca)\x1b[0m\r\n"
        "\x1b[90m────────────────────────────────────────┼─────────────────────────────────────────────\x1b[0m\r\n"
        "0x1400021b0  55          push rbp       \x1b[90m│\x1b[0m \x1b[32mvoid\x1b[0m Player::_physics_process(\x1b[36mf64\x1b[0m delta)\r\n"
        "0x1400021b1  4889e5      mov rbp, rsp   \x1b[90m│\x1b[0m {\r\n"
        "0x1400021b4  4883ec30    sub rsp, 0x30  \x1b[90m│\x1b[0m     \x1b[90m// Inlined Crystal gravity step\x1b[0m\r\n"
        "0x1400021b8  f20f1005    movsd xmm0, d  \x1b[90m│\x1b[0m     this->apply_gravity(delta);\r\n"
        "0x1400021c0  e88b0200    call gravity   \x1b[90m│\x1b[0m     \r\n"
        "0x1400021c5  e8460100    call slide     \x1b[90m│\x1b[0m     \x1b[36mbool\x1b[0m hit = this->move_and_slide();\r\n"
        "0x1400021ca  4885c0      test rax, rax  \x1b[90m│\x1b[0m     \x1b[35mif\x1b[0m (hit) {\r\n"
        "0x1400021cd  7405        jz 0x1400021d4 \x1b[90m│\x1b[0m         this->emit_landed();\r\n"
        "0x1400021cf  e8920000    call landed    \x1b[90m│\x1b[0m     }\r\n"
        "0x1400021d4  4883c430    add rsp, 0x30  \x1b[90m│\x1b[0m }\r\n"
        "0x1400021d8  5d          pop rbp        \x1b[90m│\x1b[0m \x1b[90m// Zero runtime overhead • Direct PtrCall\x1b[0m\r\n"
        "0x1400021d9  c3          ret            \x1b[90m│\x1b[0m \x1b[32m✔ Verified: 0 Heap Allocations in Loop\x1b[0m\r\n"
    )
    events.append([round(t, 3), "o", scene2_out])
    t += 3.5

    # =========================================================================
    # SCENE 3: Live In-Memory Data Structure Layouts (cradare2 / r2)
    # =========================================================================
    events.append([round(t, 3), "o", "\x1b[2J\x1b[H"])
    t += 0.1
    t = type_cmd(t, prompt, "r2 -q0 bin/game.dll")
    t += 0.2
    
    r2_header = "\x1b[2m[cradare2:memory]\x1b[0m Direct in-memory inspection of runtime Crystal structures:\r\n"
    events.append([round(t, 3), "o", r2_header])
    t += 0.4

    # 3a: String inspection
    cmd_str = ">> \x1b[1;33mcradare2.crystal.read_string(0x140040200)\x1b[0m\r\n"
    events.append([round(t, 3), "o", cmd_str])
    t += 0.25
    out_str = (
        "   \x1b[36m[String @ 0x140040200]\x1b[0m type_id: \x1b[1m1\x1b[0m, bytesize: \x1b[1m15\x1b[0m, length: \x1b[1m15\x1b[0m\r\n"
        "   Value: \x1b[32m\"res://main.tscn\"\x1b[0m (UTF-8 buffer @ 0x14004020c)\r\n\r\n"
    )
    events.append([round(t, 3), "o", out_str])
    t += 1.8

    # 3b: Array inspection
    cmd_arr = ">> \x1b[1;33mcradare2.crystal.read_array_header(0x140040500)\x1b[0m\r\n"
    events.append([round(t, 3), "o", cmd_arr])
    t += 0.25
    out_arr = (
        "   \x1b[36m[Array(Vector3) @ 0x140040500]\x1b[0m type_id: \x1b[1m84\x1b[0m, size: \x1b[1m8\x1b[0m, capacity: \x1b[1m16\x1b[0m\r\n"
        "   Buffer Pointer: \x1b[33m0x140040520\x1b[0m \x1b[32m[Zero-Alloc Contiguous Heap]\x1b[0m\r\n\r\n"
    )
    events.append([round(t, 3), "o", out_arr])
    t += 1.8

    # 3c: Slice inspection
    cmd_slice = ">> \x1b[1;33mcradare2.crystal.read_slice_header(0x140040600)\x1b[0m\r\n"
    events.append([round(t, 3), "o", cmd_slice])
    t += 0.25
    out_slice = (
        "   \x1b[36m[Slice(UInt8) @ 0x140040600]\x1b[0m size: \x1b[1m256\x1b[0m, read_only: \x1b[1mfalse\x1b[0m (Stack-Backed)\r\n\r\n"
    )
    events.append([round(t, 3), "o", out_slice])
    t += 1.6

    # 3d: Breakpoint on Demangled Symbol
    cmd_db = ">> \x1b[1;33mdb \"sym.Player#_physics_process:Float64\"\x1b[0m\r\n"
    events.append([round(t, 3), "o", cmd_db])
    t += 0.25
    out_db = "   \x1b[1;32m✔\x1b[0m Breakpoint #1 set at \x1b[1;37mPlayer#_physics_process(Float64)\x1b[0m [0x1400021b0]\r\n\r\n"
    events.append([round(t, 3), "o", out_db])
    t += 2.0

    # Exit r2
    t = type_cmd(t, ">> ", "quit")
    t += 0.3
    events.append([round(t, 3), "o", prompt])
    t += 2.5
    events.append([round(t, 3), "o", ""])

    with open(output_path, "w", encoding="utf-8") as f:
        header = {
            "version": 2,
            "width": 86,
            "height": 22,
            "timestamp": 1790904120,
            "title": "Radare2 Crystal Runtime Inspection & Memory Layouts",
            "env": {"TERM": "xterm-256color", "SHELL": "lapis"}
        }
        f.write(json.dumps(header) + "\n")
        for ev in events:
            f.write(json.dumps(ev) + "\n")
            
    print(f"Generated {output_path} successfully ({len(events)} events, duration: {round(t, 1)}s)")

if __name__ == "__main__":
    generate_r2_crystal_cast()
