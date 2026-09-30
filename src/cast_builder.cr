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
    CLEAR_SCREEN = "#{ESC}[2J#{ESC}[H"
    CURSOR_HIDE = "#{ESC}[?25l"

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

      def type_command(cmd : String, prompt : String, char_delay : Float64 = 0.04_f64)
        emit(0.2_f64, prompt)
        cmd.each_char do |c|
          emit(char_delay, c.to_s)
        end
        emit(0.2_f64, "\r\n")
      end

      def save(path : String, width : Int32, height : Int32, title : String)
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

    def self.render_tui_frame(progress_pct : Int32, active_phase_idx : Int32, log_lines : Array(String), all_done : Bool = false) : String
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
        str << CLEAR_SCREEN << CURSOR_HIDE
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

    def self.build_all(output_dir : String)
      Dir.mkdir_p(output_dir)

      # 1. TUI Test Dashboard Cast
      tui_session = Session.new
      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      tui_session.type_command("lapis test --tui", prompt, 0.05_f64)

      logs = [] of String
      logs << "#{C_CYAN}► Phase: Core Language & Math Spec Suites#{C_RESET}"
      tui_session.emit(0.3_f64, render_tui_frame(5, 0, logs))

      logs << "#{C_DIM}[10:24:08]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Vector2 / Vector3 SIMD math"
      tui_session.emit(0.35_f64, render_tui_frame(18, 1, logs))

      logs << "#{C_DIM}[10:24:09]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Variant roundtrip & Dictionary"
      tui_session.emit(0.35_f64, render_tui_frame(32, 2, logs))

      logs << "#{C_DIM}[10:24:10]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Monotonic 64-bit ID check_alive!"
      tui_session.emit(0.4_f64, render_tui_frame(46, 3, logs))

      logs << "#{C_DIM}[10:24:12]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} ToolTester2D & ToolTester3D @tool"
      tui_session.emit(0.4_f64, render_tui_frame(62, 4, logs))

      logs << "#{C_DIM}[10:24:13]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Signal fiber awaiting & timers"
      tui_session.emit(0.35_f64, render_tui_frame(78, 5, logs))

      logs << "#{C_DIM}[10:24:14]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} CharacterBody3D & AStar2D pathing"
      tui_session.emit(0.4_f64, render_tui_frame(90, 6, logs))

      logs << "#{C_DIM}[10:24:16]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} assert_no_leak: ΔObjects == 0"
      tui_session.emit(0.4_f64, render_tui_frame(97, 7, logs))

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
      tui_session.emit(0.5_f64, render_tui_frame(100, 6, final_logs, all_done: true))

      # Simulate interactive arrow key navigation
      tui_session.emit(0.7_f64, render_tui_frame(100, 5, final_logs, all_done: true))
      tui_session.emit(0.4_f64, render_tui_frame(100, 6, final_logs, all_done: true))
      tui_session.emit(2.5_f64, "")
      tui_session.save(File.join(output_dir, "test_runner_tui.cast"), 86, 19, "Lapis Unified Test Runner TUI Dashboard")

      # 2. CLI Lifecycle Cast
      cli_session = Session.new
      cli_session.emit(0.1_f64, CLEAR_SCREEN)

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects#{C_RESET}$ "
      cli_session.type_command("lapis init void_runner --template=3d-action", p1, 0.035_f64)
      cli_session.emit(0.15_f64, "#{C_CYAN}[Scaffold]#{C_RESET} Initializing 3D Action project 'void_runner'...\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} project.godot (Godot 4.8.0-custom)\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} shard.yml (libgodot ~> 0.8.2)\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} src/main.cr (Root Game Host)\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} scenes/main.tscn & scenes/player.tscn\r\n")
      cli_session.emit(0.2_f64, "#{C_GREEN}[Success]#{C_RESET} Project initialized! Run 'cd void_runner && lapis editor'\r\n\r\n")

      p2 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      cli_session.type_command("lapis editor", p2, 0.035_f64)
      cli_session.emit(0.15_f64, "#{C_CYAN}[Editor]#{C_RESET} Launching Godot Editor with dynamic shadow hot-reloading...\r\n")
      cli_session.emit(0.1_f64, "  #{C_DIM}» Loading shadow bridge: bin/crystal_bridge.dll#{C_RESET}\r\n")
      cli_session.emit(0.1_f64, "  #{C_DIM}» Mounted GDExtension hook: addons/crystal_integration#{C_RESET}\r\n")
      cli_session.emit(0.2_f64, "  #{C_GREEN}✓#{C_RESET} Editor active. Press #{C_BOLD}F5#{C_RESET} to compile & live-reload game.dll.\r\n\r\n")

      cli_session.type_command("lapis run -d", p2, 0.035_f64)
      cli_session.emit(0.15_f64, "#{C_MAGENTA}[Debugger]#{C_RESET} Attaching radare2 native debugger (r2 -d bin/game.exe)...\r\n")
      cli_session.emit(0.1_f64, "  Process 14828 attached. Symbols loaded from bin/game.pdb.\r\n")
      cli_session.emit(0.1_f64, "  #{C_CYAN}[0x00401000]>#{C_RESET} #{C_YELLOW}dc#{C_RESET}  # Continue execution\r\n")
      cli_session.emit(0.2_f64, "  #{C_GREEN}✓#{C_RESET} Standalone engine running under hardware watchpoints.\r\n")
      cli_session.emit(2.8_f64, "")
      cli_session.save(File.join(output_dir, "lapis_cli_lifecycle.cast"), 80, 18, "Lapis CLI Project Lifecycle")

      # 3. Portable Packaging Cast
      pkg_session = Session.new
      pkg_session.emit(0.1_f64, CLEAR_SCREEN)

      p_pkg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      pkg_session.type_command("lapis package game --portable --embed-pck --release -n VoidRunner", p_pkg, 0.03_f64)

      pkg_session.emit(0.15_f64, "#{C_CYAN}[PackageGame]#{C_RESET} Compiling release binary with LLVM -O3 optimizations...\r\n")
      pkg_session.emit(0.3_f64, "  #{C_GREEN}✓#{C_RESET} Compiled bin/game.dll (stripped, LTO enabled) in 2.4s\r\n")
      pkg_session.emit(0.2_f64, "#{C_CYAN}[PackageGame]#{C_RESET} Generating standalone project pack: VoidRunner.pck...\r\n")
      pkg_session.emit(0.25_f64, "  #{C_GREEN}✓#{C_RESET} Exported PCK archive via Godot headless (42.8 MB)\r\n")
      pkg_session.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Staged crystal_bridge.dll, gc.dll, pcre2-8.dll, iconv-2.dll\r\n")
      pkg_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Auto-generated .godot/extension_list.cfg manifest\r\n")

      pkg_session.emit(0.3_f64, "#{C_MAGENTA}[PackageGame]#{C_RESET} Embedding PCK directly into binary footer (GDPC magic)...\r\n")
      pkg_session.emit(0.25_f64, "  #{C_GREEN}✓#{C_RESET} Injected 44,882,912 bytes PCK payload\r\n")
      pkg_session.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Appended 12-byte GDPC trailer [Magic: 0x43504447, Offset: 0x0041B000]\r\n")
      pkg_session.emit(0.2_f64, "  #{C_GREEN}✓#{C_RESET} Generated turnkey executable: #{C_BOLD}bin/VoidRunner_portable.exe#{C_RESET}\r\n")
      pkg_session.emit(0.25_f64, "  #{C_GREEN}✓#{C_RESET} Compressed release zip: #{C_CYAN}bin/VoidRunner-portable.zip#{C_RESET} (18.4 MB)\r\n\r\n")

      pkg_session.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[SUCCESS]#{C_RESET} Standalone game packaged with zero runtime toolchain dependencies!\r\n")
      pkg_session.emit(0.1_f64, "Ready for Steam, itch.io, or instant flash-drive play.\r\n")
      pkg_session.emit(2.8_f64, "")
      pkg_session.save(File.join(output_dir, "lapis_package.cast"), 84, 18, "Lapis Portable Packaging with GDPC Trailer")
    end
  end
end

if PROGRAM_NAME.includes?("cast_builder")
  output_dir = ARGV.size > 0 ? ARGV[0] : File.expand_path("casts", Dir.current)
  LapisSlides::CastBuilder.build_all(output_dir)
end
