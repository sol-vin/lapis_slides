require "json"

module LapisSlides
  module CastBuilder
    ESC = "\u001b"
    C_RESET = "#{ESC}[0m"
    C_BOLD = "#{ESC}[1m"
    C_DIM = "#{ESC}[2m"
    C_CYAN = "#{ESC}[36m"
    C_GREEN = "#{ESC}[32m"
    C_YELLOW = "#{ESC}[33m"
    C_MAGENTA = "#{ESC}[35m"
    C_BLUE = "#{ESC}[34m"
    C_RED = "#{ESC}[31m"
    CLEAR_SCREEN = "#{ESC}[2J#{ESC}[H"
    CURSOR_HIDE = "#{ESC}[?25l"
    CURSOR_SHOW = "#{ESC}[?25h"
    CURSOR_HOME = "#{ESC}[H"

    class Session
      getter events : Array(JSON::Any)
      getter current_time : Float64

      def initialize
        @events = [] of JSON::Any
        @current_time = 0.0_f64
      end

      def emit(delay : Float64, text : String)
        @current_time += delay
        arr = [
          JSON::Any.new(@current_time.round(3)),
          JSON::Any.new("o"),
          JSON::Any.new(text)
        ]
        @events << JSON::Any.new(arr)
      end

      def pause(seconds : Float64)
        @current_time += seconds
      end

      def clear_screen(advance : Float64 = 0.05)
        emit(advance, "#{CLEAR_SCREEN}#{CURSOR_SHOW}")
      end

      def home_cursor(advance : Float64 = 0.02)
        emit(advance, CURSOR_HOME)
      end

      # Simulates human typing cadence with randomized character jitter
      def type_command(cmd : String, prompt : String, cps : Float64 = 22.0)
        emit(0.2_f64, prompt)
        delay_per_char = 1.0 / cps
        cmd.each_char do |c|
          jitter = (rand * 0.02) - 0.01
          actual_delay = Math.max(0.015, delay_per_char + jitter)
          emit(actual_delay, c.to_s)
        end
        emit(0.25_f64, "\r\n")
      end

      # Animated Braille spinner
      def spinner(message : String, frames_count : Int32 = 14, delay : Float64 = 0.07)
        spinners = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        frames_count.times do |i|
          s = spinners[i % spinners.size]
          emit(delay, "\r\e[2K  \e[36m#{s}\e[0m #{message}")
        end
      end

      def spinner_done(message : String, delay : Float64 = 0.15)
        emit(delay, "\r\e[2K  \e[32m✔\e[0m #{message}\r\n")
      end

      # In-place dynamic progress bar
      def progress_bar(label : String, total_steps : Int32 = 10, step_delay : Float64 = 0.09, &block : Int32 -> String)
        total_steps.times do |step|
          pct = ((step + 1) * 100) // total_steps
          blocks = (pct * 20) // 100
          bar_fill = "█" * blocks
          bar_empty = "░" * (20 - blocks)
          detail = yield(step + 1)
          emit(step_delay, "\r\e[2K  #{label} [\e[36m#{bar_fill}\e[90m#{bar_empty}\e[0m] \e[1m#{pct}%\e[0m #{detail}")
        end
        emit(0.15, "\r\n")
      end

      def save(path : String, width : Int32, height : Int32, title : String)
        # Ensure final frame hold is recorded in event timeline
        if @events.size > 1
          arr = [JSON::Any.new(@current_time.round(3)), JSON::Any.new("o"), JSON::Any.new("")]
          @events << JSON::Any.new(arr)
        end

        File.open(path, "w") do |file|
          header = {
            "version" => JSON::Any.new(2_i64),
            "width" => JSON::Any.new(width.to_i64),
            "height" => JSON::Any.new(height.to_i64),
            "timestamp" => JSON::Any.new(1727680000_i64),
            "title" => JSON::Any.new(title),
            "env" => JSON::Any.new({
              "TERM" => JSON::Any.new("xterm-256color"),
              "SHELL" => JSON::Any.new("/bin/bash")
            })
          }
          file.puts header.to_json

          @events.each do |ev|
            file.puts ev.to_json
          end
        end
        puts "✓ Generated #{path} (#{@events.size} frames, #{@current_time.round(2)}s duration)"
      end
    end

    def self.render_tui_frame(progress_pct : Int32, active_phase_idx : Int32, log_lines : Array(String), all_done : Bool = false, initial : Bool = false) : String
      status_text = all_done ? "#{C_BOLD}#{C_GREEN}ALL PASSED ✔#{C_RESET}" : "#{C_YELLOW}RUNNING...#{C_RESET}"
      filled_blocks = (progress_pct / 100.0 * 40).to_i
      empty_blocks = 40 - filled_blocks
      bar = "#{C_CYAN}#{"█" * filled_blocks}#{C_DIM}#{"░" * empty_blocks}#{C_RESET}"

      phases = [
        {"01. Core Language & Math", progress_pct >= 15},
        {"02. Variant Conversions", progress_pct >= 28},
        {"03. GC & Monotonic Guards", progress_pct >= 42},
        {"04. Headless In-Editor @tool", progress_pct >= 56},
        {"05. Async Signal Awaiting", progress_pct >= 70},
        {"06. 45+ Engine Spec Suites", progress_pct >= 85},
        {"07. Zero-Leak Verification", progress_pct >= 95},
        {"08. In-Editor Test Docks", progress_pct >= 100}
      ]

      String.build do |str|
        str << (initial ? "#{CLEAR_SCREEN}#{CURSOR_HIDE}" : "#{CURSOR_HOME}#{CURSOR_HIDE}")
        str << "#{C_MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════╗#{C_RESET}\r\n"
        str << "#{C_MAGENTA}║#{C_RESET} #{C_BOLD}🔮 LAPIS UNIFIED TEST SUITE DASHBOARD#{C_RESET}                                #{status_text}  #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}║#{C_RESET} Host: windows │ Godot: 4.8.0-custom │ Crystal: v1.15.0 │ Time: 00:14.2            #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}║#{C_RESET} [#{bar}] #{sprintf("%3d", progress_pct)}% (45/45 suites • 420+ specs)        #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}╚════════════════════════════════════════════════════════════════════════════════════╝#{C_RESET}\r\n"
        str << "#{C_CYAN}┌─ TEST PHASES (45 SUITES) ──────┐#{C_RESET} #{C_CYAN}┌─ LIVE EXECUTION LOG STREAM ─────────────────────┐#{C_RESET}\r\n"

        8.times do |i|
          p_name, p_done = phases[i]
          is_active = (i == active_phase_idx)
          mark = p_done ? "#{C_GREEN}✔#{C_RESET}" : (is_active ? "#{C_YELLOW}►#{C_RESET}" : " ")
          selector = is_active ? "#{C_CYAN}►#{C_RESET}" : " "
          p_str = sprintf("%-26s", p_name)
          left_col = "│ #{selector} #{mark} #{p_str} │"

          r_text = i < log_lines.size ? log_lines[i] : ""
          r_padded = sprintf("%-47s", r_text)
          right_col = "│ #{r_padded} │"

          str << "#{left_col} #{right_col}\r\n"
        end

        str << "#{C_CYAN}└────────────────────────────────┘ └─────────────────────────────────────────────────┘#{C_RESET}\r\n"
        str << " #{C_DIM}[↑↓/jk] Select Phase  [Enter] Drill-down Modal  [q] Exit  [?] Help#{C_RESET}\r\n"
      end
    end

    def self.render_bench_tui_frame(progress_pct : Int32, active_idx : Int32, log_lines : Array(String), all_done : Bool = false, initial : Bool = false) : String
      status_text = all_done ? "#{C_BOLD}#{C_GREEN}ALL RUNS ✔#{C_RESET}" : "#{C_YELLOW}PROFILING...#{C_RESET}"
      filled_blocks = (progress_pct / 100.0 * 38).to_i
      empty_blocks = 38 - filled_blocks
      bar = "#{C_CYAN}#{"█" * filled_blocks}#{C_DIM}#{"░" * empty_blocks}#{C_RESET}"

      benchmarks = [
        {"01. N-Body Physics (10k)", progress_pct >= 15},
        {"02. Perlin Noise (256x256)", progress_pct >= 30},
        {"03. A* Pathing (1k agents)", progress_pct >= 45},
        {"04. Raycast Spatial Octree", progress_pct >= 60},
        {"05. Matrix 4x4 SIMD (100k)", progress_pct >= 75},
        {"06. Procedural Dungeon Gen", progress_pct >= 85},
        {"07. Particle Sim (50k)", progress_pct >= 95},
        {"08. Multiplayer RPC Sync", progress_pct >= 100}
      ]

      String.build do |str|
        str << (initial ? "#{CLEAR_SCREEN}#{CURSOR_HIDE}" : "#{CURSOR_HOME}#{CURSOR_HIDE}")
        str << "#{C_MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════╗#{C_RESET}\r\n"
        str << "#{C_MAGENTA}║#{C_RESET} #{C_BOLD}⚡ LAPIS PERFORMANCE BENCHMARK DASHBOARD#{C_RESET}                            #{status_text}  #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}║#{C_RESET} Host: windows-x64 │ Engine: Godot 4.8-custom │ Crystal: -O3 │ Iterations: 3        #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}║#{C_RESET} [#{bar}] #{sprintf("%3d", progress_pct)}% (8/8 benchmarks • 3 iters)        #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}╚════════════════════════════════════════════════════════════════════════════════════╝#{C_RESET}\r\n"
        str << "#{C_CYAN}┌─ BENCHMARKS (8 SUITES) ────────┐#{C_RESET} #{C_CYAN}┌─ LIVE PERFORMANCE & SPEEDUP RATIOS ─────────────┐#{C_RESET}\r\n"

        8.times do |i|
          b_name, b_done = benchmarks[i]
          is_active = (i == active_idx)
          mark = b_done ? "#{C_GREEN}✔#{C_RESET}" : (is_active ? "#{C_YELLOW}►#{C_RESET}" : " ")
          selector = is_active ? "#{C_CYAN}►#{C_RESET}" : " "
          b_str = sprintf("%-26s", b_name)
          left_col = "│ #{selector} #{mark} #{b_str} │"

          r_text = i < log_lines.size ? log_lines[i] : ""
          r_padded = sprintf("%-47s", r_text)
          right_col = "│ #{r_padded} │"

          str << "#{left_col} #{right_col}\r\n"
        end

        str << "#{C_CYAN}└────────────────────────────────┘ └─────────────────────────────────────────────────┘#{C_RESET}\r\n"
        str << " #{C_DIM}[↑↓/jk] Select Benchmark  [Enter] Detailed Metrics Modal  [q] Exit  [?] Help#{C_RESET}"
      end
    end

    # 1. Unified Test Runner TUI (Slide 37)
    def self.build_test_runner_cast(output_dir : String)
      tui_session = Session.new
      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      tui_session.type_command("lapis test --tui", prompt, 22.0)

      logs = [] of String
      logs << "#{C_CYAN}► Phase: Core Language & Math Spec Suites#{C_RESET}"
      tui_session.emit(0.3_f64, render_tui_frame(5, 0, logs, initial: true))

      logs << "#{C_DIM}[10:24:08]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Vector2 / Vector3 SIMD math"
      tui_session.emit(0.55_f64, render_tui_frame(18, 1, logs))

      logs << "#{C_DIM}[10:24:09]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Variant roundtrip & Dictionary"
      tui_session.emit(0.55_f64, render_tui_frame(32, 2, logs))

      logs << "#{C_DIM}[10:24:10]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Monotonic 64-bit ID check_alive!"
      tui_session.emit(0.6_f64, render_tui_frame(46, 3, logs))

      logs << "#{C_DIM}[10:24:12]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} ToolTester2D & ToolTester3D @tool"
      tui_session.emit(0.6_f64, render_tui_frame(62, 4, logs))

      logs << "#{C_DIM}[10:24:13]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Signal fiber awaiting & timers"
      tui_session.emit(0.55_f64, render_tui_frame(78, 5, logs))

      logs << "#{C_DIM}[10:24:14]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} CharacterBody3D & AStar2D pathing"
      tui_session.emit(0.6_f64, render_tui_frame(90, 6, logs))

      logs << "#{C_DIM}[10:24:16]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} assert_no_leak: ΔObjects == 0"
      tui_session.emit(0.6_f64, render_tui_frame(97, 7, logs))

      final_logs = [
        "#{C_DIM}[10:24:12]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} CharacterBody3D physics step",
        "#{C_DIM}[10:24:13]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} AStar2D pathfinding routing",
        "#{C_DIM}[10:24:14]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Multiplayer RPC synchronized",
        "#{C_DIM}[10:24:15]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} GDExtension ClassDB dispatch",
        "#{C_DIM}[10:24:16]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} assert_no_leak: ΔObjects == 0",
        "",
        "#{C_BOLD}#{C_GREEN}ALL 45 SUITES PASSED (420+ specs, 0 leaks)#{C_RESET}",
        "#{C_CYAN}Completed in 14.2s • Peak Memory: 38.4 MB#{C_RESET}"
      ]
      tui_session.emit(0.8_f64, render_tui_frame(100, 6, final_logs, all_done: true))
      tui_session.emit(1.0_f64, render_tui_frame(100, 5, final_logs, all_done: true))
      tui_session.emit(0.8_f64, render_tui_frame(100, 6, final_logs, all_done: true))
      tui_session.pause(3.5)
      tui_session.save(File.join(output_dir, "test_runner_tui.cast"), 86, 19, "Lapis Unified Test Runner TUI Dashboard")
    end

    # 2. CLI Command Center & Scaffolding (Slide 30)
    def self.build_cli_lifecycle_cast(output_dir : String)
      cli_session = Session.new
      cli_session.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      cli_session.type_command("lapis", prompt, 22.0)

      # Command Center Header & Telemetry
      cli_session.emit(0.15_f64, "\r\n#{C_BOLD}#{ESC}[45;37m 🔮 LAPIS COMMAND CENTER #{C_RESET} #{C_CYAN}Unified Crystal Engine Toolchain for Godot (v0.8.2)#{C_RESET}\r\n\r\n")
      cli_session.emit(0.1_f64, "  #{C_BOLD}#{C_CYAN}Project:#{C_RESET} #{C_BOLD}void_runner#{C_RESET} (branch: #{C_MAGENTA}main#{C_RESET} • commit 7f41a8c)\r\n")
      cli_session.emit(0.1_f64, "  #{C_BOLD}#{C_CYAN}Platform:#{C_RESET} #{C_BOLD}windows-x86_64#{C_RESET} │ #{C_BOLD}#{C_CYAN}Godot:#{C_RESET} #{C_CYAN}4.8.0-custom#{C_RESET} │ #{C_BOLD}#{C_CYAN}Crystal:#{C_RESET} #{C_BOLD}v1.15.0 [LLVM 18.1.8]#{C_RESET}\r\n")
      cli_session.emit(0.1_f64, "  #{C_BOLD}#{C_CYAN}Bridge DLL:#{C_RESET} #{C_BOLD}#{C_GREEN}Ready (bin/crystal_bridge.dll)#{C_RESET} │ #{C_BOLD}#{C_CYAN}Game DLL:#{C_RESET} #{C_BOLD}#{C_GREEN}Development (Shadow Active)#{C_RESET}\r\n\r\n")

      # Hotkey Menu
      cli_session.emit(0.2_f64, "#{C_BOLD}Select an action (or press hotkey):#{C_RESET}\r\n")
      cli_session.emit(0.08_f64, "  #{C_CYAN}🔍 [ / ]#{C_RESET} Open Spotlight Command Palette (Search all 25+ commands)\r\n")
      cli_session.emit(0.08_f64, "  #{C_YELLOW}🔨 [ B ]#{C_RESET} Build Game Library & Bridge (lapis build)\r\n")
      cli_session.emit(0.08_f64, "  #{C_GREEN}🧪 [ T ]#{C_RESET} Run Test Suites & Specs (lapis test --tui)\r\n")
      cli_session.emit(0.08_f64, "  #{C_BLUE}🩺 [ D ]#{C_RESET} Environment & Toolchain Diagnostics (lapis doctor)\r\n")
      cli_session.emit(0.08_f64, "  #{C_MAGENTA}🎮 [ E ]#{C_RESET} Launch Godot Editor with Hot-Reloading (lapis editor)\r\n")
      cli_session.emit(0.08_f64, "  #{C_CYAN}✨ [ S ]#{C_RESET} #{C_BOLD}Scaffold New Game or Addon (lapis new)#{C_RESET} #{C_GREEN}◄ Selected#{C_RESET}\r\n")
      cli_session.emit(0.08_f64, "  #{C_YELLOW}📜 [ L ]#{C_RESET} Inspect Multi-Channel Logs & Traces (lapis log)\r\n\r\n")
      cli_session.pause(1.2)

      # Trigger S action (Scaffold)
      cli_session.emit(0.3_f64, "#{C_CYAN}[Scaffold]#{C_RESET} Scaffolding 3D Action project 'void_runner'...\r\n")
      cli_session.spinner("Creating scene tree and crystal template files...", frames_count: 14)
      cli_session.spinner_done("Scaffold generated in 0.34s")
      cli_session.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} project.godot (Godot 4.8.0-custom)\r\n")
      cli_session.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} shard.yml (libgodot ~> 0.8.2)\r\n")
      cli_session.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} src/main.cr (Root Game Host)\r\n")
      cli_session.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} scenes/main.tscn & scenes/player.tscn\r\n")
      cli_session.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Project initialized! Run 'cd void_runner && lapis editor'\r\n")
      cli_session.pause(3.5)
      cli_session.save(File.join(output_dir, "lapis_cli_lifecycle.cast"), 86, 19, "Lapis Command Center & Project Lifecycle")
    end

    # 3. Spotlight Command Palette & Typo Recovery (Slide 30b)
    def self.build_fuzzy_palette_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis docotr", p1, 20.0)
      sess.emit(0.15_f64, "#{C_RED}[ERROR] Unknown command 'docotr'#{C_RESET}\r\n")
      sess.emit(0.2_f64, "  #{C_YELLOW}💡 Did you mean: lapis doctor? (Levenshtein distance: 1)#{C_RESET}\r\n")
      sess.emit(0.1_f64, "  #{C_DIM}Run 'lapis --help' for a full list of commands.#{C_RESET}\r\n\r\n")
      sess.pause(1.2)

      sess.type_command("lapis --palette", p1, 22.0)
      sess.emit(0.15_f64, "#{C_BOLD}Search Command to Execute: #{C_CYAN}bench#{C_RESET}\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}┌──────────────────────────────────────────────────────────────────────────────────┐#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}#{C_GREEN}► ⚡ lapis benchmarks --tui  - Real-time AVX2 SIMD compute speedup dashboard#{C_RESET}   │\r\n")
      sess.emit(0.08_f64, "│    ⚡ lapis benchmarks run    - Execute benchmark comparison suites              │\r\n")
      sess.emit(0.08_f64, "│    🔬 lapis decompile         - Side-by-side assembly & pseudo-C decompiler      │\r\n")
      sess.emit(0.08_f64, "│    🔨 lapis build             - Compile Crystal game library & GDExtension bridge │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}└──────────────────────────────────────────────────────────────────────────────────┘#{C_RESET}\r\n")
      sess.emit(0.1_f64, "  #{C_DIM}[↑↓] Navigate  [Enter] Execute  [Esc] Cancel#{C_RESET}\r\n\r\n")
      sess.pause(1.5)

      sess.type_command("lapis deco", p1, 20.0)
      sess.emit(0.2_f64, "#{ESC}[1A\r#{p1}lapis decompile #{C_DIM}# Auto-completed via shell completion engine#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Shell autocompletion active for PowerShell, Bash, Zsh, and Fish\r\n")
      sess.pause(3.5)
      sess.save(File.join(output_dir, "lapis_fuzzy_palette.cast"), 86, 19, "Lapis Command Palette & Typo Recovery")
    end

    # 4. Environment Diagnostics & Toolchain Doctor (Slide 30c)
    def self.build_doctor_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis doctor --verbose", p1, 22.0)

      sess.emit(0.15_f64, "#{C_CYAN}[Doctor]#{C_RESET} Diagnosing Lapis development environment...\r\n")
      sess.spinner("Scanning Crystal compiler & LLVM backend...", frames_count: 10)
      sess.spinner_done("Crystal v1.15.0 verified (LLVM 18.1.8, target x86_64)")

      sess.spinner("Probing Godot engine binary & GDExtension v2 ABI...", frames_count: 10)
      sess.spinner_done("Godot Engine v4.8.0.custom_build [3f1a9b] verified")

      sess.spinner("Auditing native radare2 debugger & symbols...", frames_count: 8)
      sess.spinner_done("radare2 5.9.8 verified @ windows-x64 (cradare2)")

      sess.emit(0.2_f64, "\r\n#{C_BOLD}Diagnostic Matrix Results:#{C_RESET}\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}┌────────┬────────────────────┬────────────────────────────────────────────┬─────────┐#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{C_BOLD}Status#{C_RESET} │ #{C_BOLD}Component#{C_RESET}          │ #{C_BOLD}Diagnostic Detail#{C_RESET}                          │ #{C_BOLD}Action#{C_RESET}    │\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}├────────┼────────────────────┼────────────────────────────────────────────┼─────────┤#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Crystal Compiler   │ Crystal 1.15.0 (LLVM 18.1.8, target x86_64)│ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Godot Engine       │ Godot Engine v4.8.0.custom_build [3f1a9b]  │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Radare2 Native R2  │ radare2 5.9.8 0 @ windows-x64 (cradare2)   │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ GDExtension API    │ extension_api.json matched (824 classes)   │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ C++ Bridge Loader  │ MSVC cl.exe 19.38 / x64 C++17 support      │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Windows CRT DLLs   │ gc.dll, pcre2-8.dll, iconv-2.dll staged    │ Ready   │\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}└────────┴────────────────────┴────────────────────────────────────────────┴─────────┘#{C_RESET}\r\n\r\n")

      # Live Readiness Gauge
      sess.emit(0.12_f64, "#{C_BOLD}Toolchain Readiness Gauge: 100% (6/6 components verified)#{C_RESET}\r\n")
      sess.emit(0.15_f64, "#{C_GREEN}[████████████████████████████████████████████████████████] 100% READY#{C_RESET}\r\n")
      sess.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} 0 configuration gaps detected. Zero-config development active!\r\n")
      sess.pause(3.5)
      sess.save(File.join(output_dir, "lapis_doctor.cast"), 86, 19, "Lapis Environment Diagnostics & Toolchain Doctor")
    end

    # 5. ClassDB Reflection & Rapid Codegen (Slide 31)
    def self.build_bind_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis bind --dump-extension-api", p1, 22.0)

      sess.emit(0.15_f64, "#{C_CYAN}[ClassDB:Dump]#{C_RESET} Extracting engine API from godot.exe...\r\n")
      sess.spinner("Dumping extension_api.json via GDExtension v2...", frames_count: 12)
      sess.spinner_done("Dumped extension_api.json (Godot 4.8.0-custom, 6.2 MB) in 0.42s")

      sess.emit(0.15_f64, "#{C_YELLOW}[Codegen:Analyze]#{C_RESET} Parsing ClassDB engine metadata...\r\n")
      sess.spinner("Parsing classes, enums, virtual methods, properties...", frames_count: 12)
      sess.spinner_done("Analyzed 824 classes, 1,418 enums, 8,912 methods, 2,140 properties")

      sess.emit(0.15_f64, "#{C_MAGENTA}[Codegen:Emit]#{C_RESET} Synthesizing strongly-typed Crystal bindings...\r\n")
      sess.progress_bar("Emitting classes", total_steps: 10) do |step|
        count = (step * 824) // 10
        "(#{count}/824 files generated)"
      end

      sess.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Generated src/libgodot/generated/classes/ (824 files)\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Generated src/libgodot/generated/enums.cr (1,418 enums)\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Inlined direct ptrcall dispatches (zero runtime reflection overhead)\r\n")
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Typed engine bindings synthesized in 1.18s! 0 compilation errors.\r\n")
      sess.pause(3.5)
      sess.save(File.join(output_dir, "lapis_bind.cast"), 86, 19, "Lapis Codegen & ClassDB Reflection")
    end

    # 6. Portable Packaging (Slide 31b)
    def self.build_package_cast(output_dir : String)
      pkg_session = Session.new
      pkg_session.clear_screen

      p_pkg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      pkg_session.type_command("lapis package game --portable --embed-pck --release -n VoidRunner", p_pkg, 22.0)

      pkg_session.emit(0.15_f64, "#{C_CYAN}[Package]#{C_RESET} Compiling release binary with LLVM -O3 optimizations...\r\n")
      pkg_session.spinner("Running Crystal compiler with --release -O3 --no-debug...", frames_count: 14)
      pkg_session.spinner_done("Compiled bin/game.dll (2.1 MB) & bin/game.exe in 2.1s")

      pkg_session.emit(0.15_f64, "#{C_MAGENTA}[Package]#{C_RESET} Bundling Godot scene pack & runtime libraries...\r\n")
      pkg_session.spinner("Bundling scene assets into PCK archive...", frames_count: 10)
      pkg_session.spinner_done("Created dist/VoidRunner.pck (42.8 MB)")

      pkg_session.emit(0.15_f64, "#{C_CYAN}[Package:GDPC]#{C_RESET} Injecting 12-byte GDPC trailer for standalone single-file binary...\r\n")
      pkg_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Embedded PCK payload at EOF offset 0x0041B000 (44,882,912 bytes)\r\n")
      pkg_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Appended GDPC magic trailer [0x43504447]\r\n")
      pkg_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Generated turnkey single-file executable: #{C_BOLD}bin/VoidRunner.exe#{C_RESET}\r\n")
      pkg_session.emit(0.15_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Turnkey standalone executable packaged (zero external dependencies)!\r\n")
      pkg_session.pause(3.5)
      pkg_session.save(File.join(output_dir, "lapis_package.cast"), 86, 19, "Lapis Portable Packaging with GDPC Trailer")
    end

    # 7. Addon Management (Slide 32)
    def self.build_addon_install_cast(output_dir : String)
      addon_session = Session.new
      addon_session.clear_screen

      p_addon = "#{C_BOLD}#{C_GREEN}dev@lapis#{C_RESET}:#{C_BLUE}~/game#{C_RESET}$ "
      addon_session.type_command("lapis addon install github:sol-vin/combat_system@v1.2", p_addon, 22.0)

      addon_session.emit(0.15_f64, "#{C_CYAN}[Addon:Resolve]#{C_RESET} Resolving GitHub release asset for windows-x86_64...\r\n")
      addon_session.spinner("Downloading precompiled binary package...", frames_count: 12)
      addon_session.spinner_done("Downloaded combat_system-windows.zip (1.4 MB)")

      addon_session.emit(0.15_f64, "#{C_MAGENTA}[Addon:Audit]#{C_RESET} Inspecting GDExtension binary headers & symbols...\r\n")
      addon_session.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Entrypoint verified: combat_system_init (x86_64 ABI v1)\r\n")
      addon_session.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Hardening check: ASLR enabled, DEP/NX enabled, 0 poison hooks\r\n")

      addon_session.emit(0.15_f64, "#{C_YELLOW}[Shards:Negotiator]#{C_RESET} Checking multi-addon shard dependencies...\r\n")
      addon_session.spinner("Negotiating transitive shard versions...", frames_count: 10)
      addon_session.spinner_done("Negotiated crshader v0.2 across 5 addons: 0 conflicts")

      addon_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Extracted to addons/combat_system/\r\n")
      addon_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Generated typed Crystal API: src/bindings/combat_system.cr\r\n")
      addon_session.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}✓ Addon 'combat_system' installed successfully! Ready with autocomplete.#{C_RESET}\r\n")
      addon_session.pause(3.5)
      addon_session.save(File.join(output_dir, "lapis_addon_install.cast"), 86, 19, "Lapis Addon Management & Shard Negotiation")
    end

    # 8. Side-by-Side Decompile & Native Debug (Slide 34c)
    def self.build_debug_workflows_cast(output_dir : String)
      dbg_session = Session.new
      dbg_session.clear_screen

      p_dbg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      dbg_session.type_command("lapis decompile bin/game.dll \"Player#_physics_process\" --side-by-side", p_dbg, 22.0)

      dbg_session.emit(0.15_f64, "#{C_CYAN}┌─ Disassembly (pdf) ──────────────┬─ Pseudo-C (pdc) ──────────────────────────┐#{C_RESET}\r\n")
      dbg_session.emit(0.06_f64, "│ #{C_DIM}0x1400021b0#{C_RESET}  push rbp            │ #{C_BLUE}int64_t#{C_RESET} Player::_physics_process(#{C_BLUE}double#{C_RESET} dt) {   │\r\n")
      dbg_session.emit(0.06_f64, "│ #{C_DIM}0x1400021b1#{C_RESET}  mov rbp, rsp        │   #{C_MAGENTA}if#{C_RESET} (!this->check_alive()) raise();       │\r\n")
      dbg_session.emit(0.06_f64, "│ #{C_DIM}0x1400021b4#{C_RESET}  call sym.check_alive│   Vector2 vel = this->get_velocity() * dt; │\r\n")
      dbg_session.emit(0.06_f64, "│ #{C_DIM}0x1400021b9#{C_RESET}  movss xmm0, [rdx]   │   #{C_MAGENTA}return#{C_RESET} this->move_and_slide();           │\r\n")
      dbg_session.emit(0.06_f64, "│ #{C_DIM}0x1400021bd#{C_RESET}  call sym.move_slide │ }                                         │\r\n")
      dbg_session.emit(0.06_f64, "#{C_CYAN}└──────────────────────────────────┴───────────────────────────────────────────┘#{C_RESET}\r\n\r\n")
      dbg_session.pause(1.5)

      dbg_session.type_command("lapis run -d", p_dbg, 22.0)
      dbg_session.emit(0.15_f64, "#{C_CYAN}[Debug]#{C_RESET} Launching game under radare2 native debugger...\r\n")
      dbg_session.spinner("Attaching process & loading symbol table...", frames_count: 10)
      dbg_session.spinner_done("Process attached (PID 14820). Symbols loaded for game.dll")
      dbg_session.emit(0.15_f64, "#{C_YELLOW}[Breakpoint]#{C_RESET} Hit sym.Player#_physics_process at player.cr:42\r\n")
      dbg_session.emit(0.18_f64, "#{C_GREEN}[Forensics]#{C_RESET} RCX = 0x0000021b3759c2f0 (InstanceID: 4120894102) -> VALID ObjectDB\r\n")
      dbg_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Dead-pointer check: Object is alive. Resuming execution.\r\n")
      dbg_session.pause(3.5)
      dbg_session.save(File.join(output_dir, "lapis_debug_workflows.cast"), 86, 19, "Lapis Debug Helper & Side-by-Side Decompilation")
    end

    # 9. Multi-Channel Log Triage & Fuzzy Search (Slide 34d)
    def self.build_log_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis log tail all -f", p1, 22.0)

      sess.emit(0.15_f64, "#{C_DIM}[10:32:01.104]#{C_RESET} #{C_BLUE}[GODOT]  #{C_RESET} Server initialized on port 7777 (UDP/ENet)\r\n")
      sess.emit(0.12_f64, "#{C_DIM}[10:32:01.118]#{C_RESET} #{C_MAGENTA}[CRYSTAL]#{C_RESET} GC heap initialized (Boehm-Demers-Weiser v8.2.6)\r\n")
      sess.emit(0.12_f64, "#{C_DIM}[10:32:01.125]#{C_RESET} #{C_GREEN}[GAME]   #{C_RESET} Player spawned: Player<CharacterBody3D#1482>\r\n")
      sess.emit(0.12_f64, "#{C_DIM}[10:32:01.210]#{C_RESET} #{C_MAGENTA}[CRYSTAL]#{C_RESET} Signal emitted: health_changed(current: 95, max: 100)\r\n\r\n")
      sess.pause(1.2)

      sess.type_command("lapis log --interactive", p1, 22.0)
      sess.emit(0.15_f64, "#{C_CYAN}┌─ Log Inspector: all (2,841 lines) ──────────────────────────────────────────────┐#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ Filter: #{C_YELLOW}health#{C_RESET}                                                                  │\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}#{C_GREEN}> [10:32:01.210] [CRYSTAL] Signal: health_changed(current: 95, max: 100)#{C_RESET}        │\r\n")
      sess.emit(0.08_f64, "│   [10:32:01.450] [GAME]    HealthPickup collected by player                     │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}├─ Context Preview (Line 412) ────────────────────────────────────────────────────┤#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{C_DIM}410: [10:32:01.205] [GAME] Damage received: 5 dmg from SpikeHazard#{C_RESET}             │\r\n")
      sess.emit(0.06_f64, "│ #{C_DIM}411: [10:32:01.208] [CRYSTAL] Player#take_damage: hp decremented to 95#{C_RESET}        │\r\n")
      sess.emit(0.06_f64, "│ #{C_BOLD}412: [10:32:01.210] [CRYSTAL] Signal emitted: health_changed(current: 95, max: 100)#{C_RESET}│\r\n")
      sess.emit(0.06_f64, "│ #{C_DIM}413: [10:32:01.212] [GODOT] UI HealthBar updated: value = 95%#{C_RESET}                 │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}└─────────────────────────────────────────────────────────────────────────────────┘#{C_RESET}\r\n")
      sess.emit(0.1_f64, "  #{C_DIM}[↑↓] Select Line  [Enter] Full Context  [/] Refilter  [q] Exit#{C_RESET}\r\n")
      sess.pause(3.5)
      sess.save(File.join(output_dir, "lapis_log.cast"), 86, 19, "Lapis Multi-Channel Log Triage & Fuzzy Search")
    end

    # 10. Performance Benchmarks TUI (Slide 35c)
    def self.build_benchmarks_cast(output_dir : String)
      bench_session = Session.new
      p_bench = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      bench_session.type_command("lapis benchmarks --tui", p_bench, 22.0)

      b_logs = [] of String
      b_logs << "#{C_CYAN}► Category: Compute Simulation (LLVM AVX2)#{C_RESET}"
      bench_session.emit(0.3_f64, render_bench_tui_frame(5, 0, b_logs, initial: true))

      b_logs << "GDScript: 184.2 ms │ Crystal: 3.1 ms #{C_BOLD}#{C_GREEN}[ 59.4x ]#{C_RESET}"
      bench_session.emit(0.55_f64, render_bench_tui_frame(20, 1, b_logs))

      b_logs << "GDScript:  92.4 ms │ Crystal: 2.8 ms #{C_BOLD}#{C_GREEN}[ 33.0x ]#{C_RESET}"
      bench_session.emit(0.55_f64, render_bench_tui_frame(35, 2, b_logs))

      b_logs << "GDScript:  64.8 ms │ Crystal: 4.2 ms #{C_BOLD}#{C_GREEN}[ 15.4x ]#{C_RESET}"
      bench_session.emit(0.6_f64, render_bench_tui_frame(50, 3, b_logs))

      b_logs << "GDScript:  45.6 ms │ Crystal: 5.1 ms #{C_BOLD}#{C_GREEN}[  8.9x ]#{C_RESET}"
      bench_session.emit(0.6_f64, render_bench_tui_frame(65, 4, b_logs))

      b_logs << "GDScript:  38.1 ms │ Crystal: 1.4 ms #{C_BOLD}#{C_GREEN}[ 27.2x ]#{C_RESET}"
      bench_session.emit(0.55_f64, render_bench_tui_frame(80, 5, b_logs))

      b_logs << "GDScript: 112.5 ms │ Crystal: 3.9 ms #{C_BOLD}#{C_GREEN}[ 28.8x ]#{C_RESET}"
      bench_session.emit(0.6_f64, render_bench_tui_frame(92, 6, b_logs))

      b_final_logs = [
        "GDScript: 184.2 ms │ Crystal: 3.1 ms #{C_BOLD}#{C_GREEN}[ 59.4x ]#{C_RESET}",
        "GDScript:  92.4 ms │ Crystal: 2.8 ms #{C_BOLD}#{C_GREEN}[ 33.0x ]#{C_RESET}",
        "GDScript:  64.8 ms │ Crystal: 4.2 ms #{C_BOLD}#{C_GREEN}[ 15.4x ]#{C_RESET}",
        "GDScript:  45.6 ms │ Crystal: 5.1 ms #{C_BOLD}#{C_GREEN}[  8.9x ]#{C_RESET}",
        "GDScript:  38.1 ms │ Crystal: 1.4 ms #{C_BOLD}#{C_GREEN}[ 27.2x ]#{C_RESET}",
        "GDScript: 112.5 ms │ Crystal: 3.9 ms #{C_BOLD}#{C_GREEN}[ 28.8x ]#{C_RESET}",
        "",
        "#{C_BOLD}#{C_GREEN}ALL 8 BENCHMARKS COMPLETE (Mean Speedup: 28.9x)#{C_RESET}"
      ]
      bench_session.emit(0.8_f64, render_bench_tui_frame(100, 6, b_final_logs, all_done: true))
      bench_session.emit(1.0_f64, render_bench_tui_frame(100, 4, b_final_logs, all_done: true))
      bench_session.emit(0.8_f64, render_bench_tui_frame(100, 5, b_final_logs, all_done: true))
      bench_session.pause(3.5)
      bench_session.save(File.join(output_dir, "lapis_benchmarks_tui.cast"), 86, 19, "Lapis Benchmark Suite ANSI TUI Dashboard")
    end

    # 11. Custom Benchmarking CLI & HTML Report (Slide 70 / 35b_custom_benchmarks)
    def self.build_custom_benchmarks_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      sess.type_command("lapis benchmarks run --group PathfindingCrowd --chart --html", prompt, 22.0)

      sess.emit(0.15_f64, "#{C_CYAN}[Benchmarks:Build]#{C_RESET} Compiling benchmark harness with AVX2 SIMD...\r\n")
      sess.spinner("Compiling benchmark suite with -O3 -s...", frames_count: 12)
      sess.spinner_done("Harness compiled in 0.94s (AVX2 SIMD vectorization enabled)")

      sess.emit(0.15_f64, "#{C_YELLOW}[Benchmarks:Warmup]#{C_RESET} Executing warmup iterations...\r\n")
      sess.spinner("Warming up JIT cache and thread pool (10 iterations)...", frames_count: 10)
      sess.spinner_done("Warmup complete • Cache primed")

      sess.emit(0.15_f64, "#{C_MAGENTA}[Benchmarks:Run]#{C_RESET} Profiling 'PathfindingCrowd' (5,000 active agents)...\r\n")
      sess.progress_bar("Executing iterations", total_steps: 10) do |step|
        "Iteration #{step}/10 (sample count: #{step * 5_000})"
      end

      # Comparison Results Table
      sess.emit(0.15_f64, "\r\n#{C_BOLD}Benchmark Results: PathfindingCrowd (5,000 Agents)#{C_RESET}\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}┌──────────────────────────┬──────────────┬────────────────┬───────────┐#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{C_BOLD}Implementation#{C_RESET}           │ #{C_BOLD}Median Time#{C_RESET}  │ #{C_BOLD}Throughput#{C_RESET}     │ #{C_BOLD}Speedup#{C_RESET}   │\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}├──────────────────────────┼──────────────┼────────────────┼───────────┤#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{C_BOLD}#{C_GREEN}Crystal (SIMD AVX2)#{C_RESET}      │     #{C_GREEN}0.82 ms#{C_RESET}  │  6,097 agt/fr  │ #{C_BOLD}#{C_GREEN}15.4x 🚀#{C_RESET}  │\r\n")
      sess.emit(0.06_f64, "│ GDScript (Baseline)      │    12.63 ms  │    395 agt/fr  │ 1.0x (ref)│\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}└──────────────────────────┴──────────────┴────────────────┴───────────┘#{C_RESET}\r\n")

      # Visual outputs
      sess.emit(0.12_f64, "  #{C_GREEN}✔#{C_RESET} Rendered SVG comparison chart: #{C_CYAN}reports/benchmarks/pathfinding_crowd.svg#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✔#{C_RESET} Generated interactive HTML: #{C_CYAN}reports/benchmarks/pathfinding_crowd.html#{C_RESET}\r\n")
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Custom benchmark group complete! Report open in browser.\r\n")
      sess.pause(3.5)
      sess.save(File.join(output_dir, "lapis_custom_benchmarks.cast"), 86, 19, "Lapis Custom Benchmark Execution & HTML Report")
    end

    # 12. Multiplayer Test Simulation Harness (Slide 26f)
    def self.build_multiplayer_test_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      sess.type_command("lapis test spec/suites/test_multiplayer.cr", prompt, 22.0)

      sess.emit(0.15_f64, "#{C_CYAN}[Multiplayer:Harness]#{C_RESET} Spinning up simulated topology (1 Server, 2 Clients)...\r\n")
      sess.spinner("Initializing in-memory ENet mesh and virtual peer sockets...", frames_count: 10)
      sess.spinner_done("Server (peer 1), Client 1 (peer 2), Client 2 (peer 3) connected")

      sess.emit(0.12_f64, "#{C_YELLOW}[Multiplayer:Input]#{C_RESET} Pumping virtual actions & RPC dispatches...\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Client 1 injected input action: :attack (pressed: true)\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Client 1 dispatched reliable RPC: apply_damage(35) to server\r\n")

      sess.emit(0.12_f64, "#{C_MAGENTA}[Multiplayer:Lockstep]#{C_RESET} Stepping 3 network & physics frame ticks...\r\n")
      sess.spinner("Synchronously advancing frame ticks across all peers...", frames_count: 10)
      sess.spinner_done("3 frames stepped synchronously • Server hero health: 65 HP")

      sess.emit(0.15_f64, "#{C_CYAN}[Wireshark:Spy]#{C_RESET} Auditing packet transmissions & bandwidth...\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Verified RPC transmission: from: 2, to: 1, method: apply_damage\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Bandwidth cap verified: 1.2 KB/s (threshold: < 10.0 KB/s)\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Zero-leak check: 0 leaked multiplayer peer allocations\r\n")
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}ALL MULTIPLAYER TESTS PASSED (7 tests, 28 assertions, 0 flakiness)#{C_RESET}\r\n")
      sess.pause(3.5)
      sess.save(File.join(output_dir, "lapis_multiplayer_test.cast"), 86, 19, "Lapis Multiplayer Simulation & Wireshark Spy Auditing")
    end

    # 13. Headless Editor Driver Testing (Slide 36b)
    def self.build_editor_driver_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      sess.type_command("lapis test spec/editor_driver_spec.cr", prompt, 22.0)

      sess.emit(0.15_f64, "#{C_CYAN}[EditorDriver]#{C_RESET} Launching headless Godot Editor...\r\n")
      sess.spinner("Starting godot --headless --editor --audio-driver Dummy...", frames_count: 12)
      sess.spinner_done("Headless editor running (PID 18492, audio: Dummy, rendering: opengl3)")

      sess.emit(0.15_f64, "#{C_YELLOW}[EditorDriver:Tool]#{C_RESET} Verifying in-editor @tool nodes...\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} ToolTester2D & ToolTester3D mounted in scene viewport\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}✓#{C_RESET} Clicked @[ExportToolButton(\"Reset Stats\")] programmatically\r\n")

      sess.emit(0.15_f64, "#{C_MAGENTA}[EditorDriver:HotReload]#{C_RESET} Stress-testing live GDExtension reload cycles...\r\n")
      sess.spinner("Reload Cycle 1/3: recompiling bin/game.dll under active editor...", frames_count: 10)
      sess.spinner_done("Cycle 1/3: Shadow loaded game_8421_1.dll in 0.38s (0 file locks)")

      sess.spinner("Reload Cycle 2/3: recompiling bin/game.dll under active editor...", frames_count: 10)
      sess.spinner_done("Cycle 2/3: Shadow loaded game_8421_2.dll in 0.35s (0 file locks)")

      sess.spinner("Reload Cycle 3/3: recompiling bin/game.dll under active editor...", frames_count: 10)
      sess.spinner_done("Cycle 3/3: Shadow loaded game_8421_3.dll in 0.36s (0 file locks)")

      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Zero dead pointers, zero access violations, exit code 0\r\n")
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}ALL EDITOR TESTS PASSED (5 tests, 18 assertions, 0 leaks)#{C_RESET}\r\n")
      sess.pause(3.5)
      sess.save(File.join(output_dir, "lapis_editor_driver.cast"), 86, 19, "Lapis Headless Editor Testing & Reload Cycles")
    end

    # 14. Demo 1: Scaffold & Windows Hot Reload (Slide 41b)
    def self.build_demo_scaffold_cast(output_dir : String)
      demo1_session = Session.new
      demo1_session.clear_screen

      p_demo1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects#{C_RESET}$ "
      demo1_session.type_command("lapis init dungeon_crawl --template=3d-action", p_demo1, 22.0)
      demo1_session.spinner("Scaffolding 3D Action template with Crystal bindings...", frames_count: 12)
      demo1_session.spinner_done("Created project.godot, shard.yml, src/main.cr, scenes/")
      demo1_session.emit(0.1_f64, "#{C_GREEN}✓#{C_RESET} Scaffolding complete! Initialized 'dungeon_crawl'.\r\n\r\n")
      demo1_session.pause(1.2)

      p_demo1_sub = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      demo1_session.type_command("lapis editor", p_demo1_sub, 22.0)
      demo1_session.emit(0.2_f64, "#{C_GREEN}✓#{C_RESET} Godot 4.8-dev6 launched (GDExtension bridge loaded)\r\n")
      demo1_session.emit(0.15_f64, "#{C_CYAN}[Editor]#{C_RESET} Dynamic shadow hot-reloading active.\r\n\r\n")

      demo1_session.emit(0.4_f64, "#{C_DIM}# [Editing src/player.cr: modified speed = 12.0_f32, pressed F5]#{C_RESET}\r\n")
      demo1_session.emit(0.2_f64, "#{C_CYAN}[EditorPlugin]#{C_RESET} F5 rebuild triggered: compiling bin/game.dll...\r\n")
      demo1_session.emit(0.25_f64, "#{C_MAGENTA}[Bridge]#{C_RESET} Timestamped shadow loaded: game_8421_1727641200.dll\r\n")
      demo1_session.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}✓ 0 file locks on Windows • Game reloaded in 0.42s!#{C_RESET}\r\n")
      demo1_session.pause(3.5)
      demo1_session.save(File.join(output_dir, "lapis_demo_scaffold.cast"), 86, 19, "Lapis Demo: Scaffolding & Windows Hot Reload")
    end

    # 15. Demo 3: Installing CrShader Addon (Slide 41e)
    def self.build_demo_install_addon_cast(output_dir : String)
      demo3_session = Session.new
      demo3_session.clear_screen

      p_demo3 = "#{C_BOLD}#{C_GREEN}dev@lapis#{C_RESET}:#{C_BLUE}~/game#{C_RESET}$ "
      demo3_session.type_command("lapis install addon github:sol-vin/crshader --shard --bind", p_demo3, 22.0)

      demo3_session.emit(0.2_f64, "#{C_CYAN}[Addon]#{C_RESET} Resolving 'github:sol-vin/crshader' from GitHub Releases...\r\n")
      demo3_session.spinner("Downloading precompiled crshader release...", frames_count: 10)
      demo3_session.spinner_done("Extracted to addons/crshader/")
      demo3_session.emit(0.08_f64, "        ├── crshader.gdextension\r\n")
      demo3_session.emit(0.08_f64, "        ├── plugin.cfg & plugin.gd\r\n")
      demo3_session.emit(0.08_f64, "        └── bin/crshader.dll\r\n")
      demo3_session.emit(0.15_f64, "#{C_CYAN}[Config]#{C_RESET} Auto-enabled 'res://addons/crshader/plugin.cfg' in project.godot\r\n")
      demo3_session.emit(0.2_f64, "#{C_MAGENTA}[Shard]#{C_RESET}  Added dependency to shard.yml:\r\n")
      demo3_session.emit(0.08_f64, "         crshader:\r\n")
      demo3_session.emit(0.08_f64, "           github: sol-vin/crshader\r\n")
      demo3_session.emit(0.2_f64, "#{C_YELLOW}[Bind]#{C_RESET}   Generated typed Crystal API: src/bindings/crshader.cr\r\n")
      demo3_session.emit(0.15_f64, "#{C_CYAN}[Sync]#{C_RESET}   Synchronized bridge & runtime DLLs across bin/\r\n")
      demo3_session.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}✓ CrShader v0.2.0 installed & ready with full Crystal autocomplete!#{C_RESET}\r\n")
      demo3_session.pause(3.5)
      demo3_session.save(File.join(output_dir, "lapis_demo_install_addon.cast"), 86, 19, "Lapis Demo: Ecosystem Addon Installation")
    end

    # 16. Demo 5: Release Build & Distribution Packaging (Slide 41g)
    def self.build_demo_package_cast(output_dir : String)
      demo5_session = Session.new
      demo5_session.clear_screen

      p_demo5 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      demo5_session.type_command("lapis build --release --opt=3", p_demo5, 22.0)

      demo5_session.emit(0.2_f64, "#{C_CYAN}[Lapis]#{C_RESET} Compiling release binaries with -O3 -s...\r\n")
      demo5_session.spinner("Running Crystal compiler with LLVM -O3 optimizations...", frames_count: 12)
      demo5_session.spinner_done("Compiled bin/game.dll (2.1 MB) & bin/game.exe (3.4 MB) in 2.1s")
      demo5_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Stripped debug symbols & elided trace logging\r\n\r\n")
      demo5_session.pause(1.2)

      demo5_session.type_command("lapis package game --release -n DungeonCrawl", p_demo5, 22.0)
      demo5_session.emit(0.2_f64, "#{C_MAGENTA}[Package]#{C_RESET} Bundling Godot PCK archive: dist/DungeonCrawl.pck\r\n")
      demo5_session.emit(0.15_f64, "#{C_MAGENTA}[Package]#{C_RESET} Staging runtime libraries: gc.dll, pcre2-8.dll, libgodot.dll\r\n")
      demo5_session.emit(0.15_f64, "#{C_MAGENTA}[Package]#{C_RESET} Bundling GDExtension bridge & crshader addon\r\n")
      demo5_session.emit(0.2_f64, "#{C_MAGENTA}[Package]#{C_RESET} Creating standalone archive: dist/DungeonCrawl-windows-x64.zip\r\n")
      demo5_session.emit(0.2_f64, "#{C_CYAN}[Package]#{C_RESET} Computing cryptographic SHA256 hashes...\r\n")
      demo5_session.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Created dist/DungeonCrawl-windows-x64.zip (48.2 MB)\r\n")
      demo5_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} SHA256: 8a4f91b7e41c30d43a7582e... verified\r\n")
      demo5_session.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}✓ Ready to ship to Steam, itch.io, or direct download!#{C_RESET}\r\n")
      demo5_session.pause(3.5)
      demo5_session.save(File.join(output_dir, "lapis_demo_package.cast"), 86, 19, "Lapis Demo: Release Build & Distribution Packaging")
    end

    def self.build_all(output_dir : String)
      Dir.mkdir_p(output_dir)
      build_test_runner_cast(output_dir)
      build_cli_lifecycle_cast(output_dir)
      build_fuzzy_palette_cast(output_dir)
      build_doctor_cast(output_dir)
      build_bind_cast(output_dir)
      build_package_cast(output_dir)
      build_addon_install_cast(output_dir)
      build_debug_workflows_cast(output_dir)
      build_log_cast(output_dir)
      build_benchmarks_cast(output_dir)
      build_custom_benchmarks_cast(output_dir)
      build_multiplayer_test_cast(output_dir)
      build_editor_driver_cast(output_dir)
      build_demo_scaffold_cast(output_dir)
      build_demo_install_addon_cast(output_dir)
      build_demo_package_cast(output_dir)
    end
  end
end

if PROGRAM_NAME.includes?("cast_builder")
  output_dir = ARGV.size > 0 ? ARGV[0] : File.expand_path("casts", Dir.current)
  LapisSlides::CastBuilder.build_all(output_dir)
end
