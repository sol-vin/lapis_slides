import json

def generate_r2_godot_cast(output_path="casts/lapis_r2_godot.cast"):
    events = []
    events.append([0.05, "o", "\x1b[2J\x1b[H\x1b[?25h"])
    prompt = "\x1b[1;32mian@workstation\x1b[0m:\x1b[1;34m~/lapis/template\x1b[0m$ "
    p_r2 = "\x1b[1;35m[0x140001080]>\x1b[0m "
    
    t = 0.2
    
    def type_cmd(start_t, p, cmd):
        cur = start_t
        events.append([round(cur, 3), "o", p])
        cur += 0.25
        for ch in cmd:
            cur += 0.028
            events.append([round(cur, 3), "o", ch])
        cur += 0.18
        events.append([round(cur, 3), "o", "\r\n"])
        return round(cur, 3)

    # =========================================================================
    # SCENE 1: Integration Status & Custom ClassDB Nodes in Template Directory
    # =========================================================================
    t = type_cmd(t, prompt, "lapis decompile bin/game.dll --godot")
    t += 0.15
    
    scene1_out = (
        "\x1b[36m╭─ Godot Engine Integration Status ───────────────────────────────────────────╮\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m Engine Core:        \x1b[1;32m[✓] Godot 4.8.0-dev7 (x86_64, Double Precision)\x1b[0m          \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m GDExtension Bridge: \x1b[1;32m[✓] crystal_bridge.dll (Compiled with Crystal 1.15.0)\x1b[0m    \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m Game Logic DLL:     \x1b[1;32m[✓] game.dll [ALIVE • Dynamic Hot-Reload Ready]\x1b[0m          \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m│\x1b[0m Editor Plugin DLL:  \x1b[1;32m[✓] plugin.dll [Active in SceneTree]\x1b[0m                     \x1b[36m│\x1b[0m\r\n"
        "\x1b[36m╰─────────────────────────────────────────────────────────────────────────────╯\x1b[0m\r\n"
        "\r\n"
        "\x1b[1;33mDiscovered ClassDB Classes (6 custom project nodes):\x1b[0m\r\n"
        "  • \x1b[1;32mPlayer < CharacterBody3D\x1b[0m (0x180b6accc)\r\n"
        "      def \x1b[36m_physics_process\x1b[0m @ 0x1400021b0 │ def \x1b[36mtake_damage\x1b[0m @ 0x1400024f0\r\n"
        "  • \x1b[1;32mCombatRadar < Node2D\x1b[0m (0x180b6b53c)\r\n"
        "      def \x1b[36m_draw\x1b[0m @ 0x140003100 │ def \x1b[36mscan_targets\x1b[0m @ 0x1400032e0\r\n"
        "  • \x1b[1;32mInventory < RefCounted\x1b[0m (0x180b6b55c)\r\n"
        "      def \x1b[36madd_item\x1b[0m @ 0x140004120 │ def \x1b[36mserialize\x1b[0m @ 0x140004380\r\n"
        "  • \x1b[1;32mEnemySpawner < Node3D\x1b[0m (0x180b6c35c)\r\n"
        "      def \x1b[36mspawn_wave\x1b[0m @ 0x140005200 │ def \x1b[36mset_difficulty\x1b[0m @ 0x140005410\r\n"
        "  • \x1b[1;32mGameHUD < CanvasLayer\x1b[0m (0x180b6d6dc)\r\n"
        "      def \x1b[36mupdate_health\x1b[0m @ 0x140006090 │ def \x1b[36mflash_damage\x1b[0m @ 0x140006220\r\n"
        "  • \x1b[1;32mCustomCamera3D < Camera3D\x1b[0m (0x180b6e12c)\r\n"
        "      def \x1b[36mshake\x1b[0m @ 0x140007140 │ def \x1b[36mfollow_target\x1b[0m @ 0x140007300\r\n"
    )
    events.append([round(t, 3), "o", scene1_out])
    t += 4.5

    # =========================================================================
    # SCENE 2: Interactive Radare2 Session with Godot Plugin (ObjectDB & Variant)
    # =========================================================================
    events.append([round(t, 3), "o", "\x1b[2J\x1b[H"])
    t += 0.1
    t = type_cmd(t, prompt, "r2 -q0 bin/game.dll")
    t += 0.2
    
    events.append([round(t, 3), "o", "\x1b[2m# Radare2 Godot Engine Dual-Target Plugin Suite\x1b[0m\r\n"])
    t += 0.3

    # 2a: godot object rcx
    t = type_cmd(t, p_r2, "godot object rcx")
    t += 0.15
    out_obj = (
        "Godot Object @ \x1b[33m0x0000021b3759c2f0\x1b[0m:\r\n"
        "  VTable:       \x1b[36m0x00007ffb12340000\x1b[0m (CharacterBody3D::vftable)\r\n"
        "  Instance ID:  \x1b[1m4120894102\x1b[0m (0x155f9a696) [Monotonic 64-bit]\r\n"
        "  User Data:    \x1b[36m0x0000021b38001000\x1b[0m (Crystal Player instance)\r\n"
        "  Class Name:   \x1b[1;32mPlayer < CharacterBody3D\x1b[0m\r\n"
        "  Status:       \x1b[1;32m[ALIVE] Registered in ObjectDB\x1b[0m\r\n\r\n"
    )
    events.append([round(t, 3), "o", out_obj])
    t += 3.8

    # 2b: godot variant rdx
    t = type_cmd(t, p_r2, "godot variant rdx")
    t += 0.15
    out_var = (
        "Godot Variant @ \x1b[33m0x0000004f210080\x1b[0m:\r\n"
        "  Type:    \x1b[1;36mTransform3D (5)\x1b[0m\r\n"
        "  Value:   Basis((1, 0, 0), (0, 1, 0), (0, 0, 1)), Origin(12.5, 4.0, -8.2)\r\n"
        "  Summary: \x1b[32m3D Coordinate Transform (Position: Vector3(12.5, 4.0, -8.2))\x1b[0m\r\n\r\n"
    )
    events.append([round(t, 3), "o", out_var])
    t += 3.4

    # 2c: godot types & print format
    t = type_cmd(t, p_r2, "godot types")
    t += 0.15
    out_types = (
        "  \x1b[1;32m✔\x1b[0m Registered Godot print formats: pf.godot_object, pf.godot_variant, pf.godot_vector3, pf.godot_transform3d\r\n"
        ">> \x1b[1;33mpf.godot_vector3 @ 0x0000004f210088\x1b[0m\r\n"
        "   0x0000004f210088 = struct godot_vector3 { x: 12.500000, y: 4.000000, z: -8.200000 }\r\n\r\n"
    )
    events.append([round(t, 3), "o", out_types])
    t += 3.4

    # 2d: godot classdb Player
    t = type_cmd(t, p_r2, "godot classdb Player")
    t += 0.15
    out_classdb = (
        "Discovered ClassDB Schema (reconstructed from PE64 exports without PDBs):\r\n"
        "  • \x1b[1;32mPlayer < CharacterBody3D\x1b[0m (0x140002000)\r\n"
        "      def \x1b[36m_ready\x1b[0m @ 0x140002100 │ def \x1b[36m_physics_process\x1b[0m @ 0x1400021b0\r\n"
        "      def \x1b[36mtake_damage\x1b[0m(amount : Int32) @ 0x140002340 (args: 1, return: Void)\r\n"
        "      signal \x1b[33mhealth_changed\x1b[0m(current : Int32, max : Int32)\r\n\r\n"
    )
    events.append([round(t, 3), "o", out_classdb])
    t += 3.8

    # Exit r2
    t = type_cmd(t, p_r2, "quit")
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
            "title": "Radare2 Godot Engine Plugin & ObjectDB Variant Decoders",
            "env": {"TERM": "xterm-256color", "SHELL": "lapis"}
        }
        f.write(json.dumps(header) + "\n")
        for ev in events:
            f.write(json.dumps(ev) + "\n")
            
    print(f"Generated {output_path} successfully ({len(events)} events, duration: {round(t, 1)}s)")

if __name__ == "__main__":
    generate_r2_godot_cast()
