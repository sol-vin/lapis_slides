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

    ANSI_REGEX = /\e\[[0-9;?]*[a-zA-Z]/

    def self.strip_ansi(str : String) : String
      str.gsub(ANSI_REGEX, "")
    end

    def self.visible_width(str : String) : Int32
      strip_ansi(str).size
    end

    # Truncates or pads a string with ANSI escape codes so its visible printed width is exactly target_width
    def self.fit_visible(str : String, target_width : Int32) : String
      cur_visible = 0
      in_escape = false
      res = String.build do |io|
        str.each_char do |ch|
          if in_escape
            io << ch
            if ch.ascii_letter?
              in_escape = false
            end
          elsif ch == '\e'
            in_escape = true
            io << ch
          else
            if cur_visible < target_width
              io << ch
              cur_visible += 1
            end
          end
        end
        if cur_visible < target_width
          io << (" " * (target_width - cur_visible))
        end
      end
      if cur_visible >= target_width && str.includes?("\e")
        res += C_RESET
      end
      res
    end

    def self.border_line(left_char : String, fill_char : String, right_char : String, total_width : Int32 = 86) : String
      inner = total_width - visible_width(left_char) - visible_width(right_char)
      left_char + (fill_char * Math.max(0, inner)) + right_char
    end

    def self.header_border(title : String, total_width : Int32 = 86) : String
      prefix = "┌─ [ #{title} ] "
      inner = total_width - visible_width(prefix) - 1
      prefix + ("─" * Math.max(0, inner)) + "┐"
    end

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

      # In-place dynamic progress bar (guaranteed <= 86 cols)
      def progress_bar(label : String, total_steps : Int32 = 10, step_delay : Float64 = 0.12, &block : Int32 -> String)
        total_steps.times do |step|
          pct = ((step + 1) * 100) // total_steps
          blocks = (pct * 20) // 100
          bar_fill = "█" * blocks
          bar_empty = "░" * (20 - blocks)
          detail = yield(step + 1)
          line = "  #{label} [\e[36m#{bar_fill}\e[90m#{bar_empty}\e[0m] \e[1m#{pct}%\e[0m #{detail}"
          emit(step_delay, "\r\e[2K#{line}")
        end
        emit(0.15, "\r\n")
      end

      def save(path : String, width : Int32, height : Int32, title : String)
        if File.exists?(path) && File.size(path) > 100
          puts "✓ Preserved genuine recorded cast #{path}"
          return
        end

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

    # Renders the Unified Test Suite Dashboard frame (guaranteed exactly 86 cols per line)
    def self.render_tui_frame(progress_pct : Int32, active_phase_idx : Int32, log_lines : Array(String), all_done : Bool = false, initial : Bool = false) : String
      status_text = all_done ? "#{C_BOLD}#{C_GREEN}ALL PASSED ✔#{C_RESET}" : "#{C_YELLOW}RUNNING...#{C_RESET}"
      filled_blocks = (progress_pct / 100.0 * 36).to_i
      empty_blocks = 36 - filled_blocks
      bar = "#{C_CYAN}#{"█" * filled_blocks}#{C_DIM}#{"░" * empty_blocks}#{C_RESET}"

      phases = [
        {"01. Core Language & Math", progress_pct >= 15},
        {"02. Variant Conversions", progress_pct >= 28},
        {"03. GC & Monotonic Guards", progress_pct >= 42},
        {"04. Headless Tool Specs", progress_pct >= 56},
        {"05. Async Signal Awaiting", progress_pct >= 70},
        {"06. 45+ Modular Suites", progress_pct >= 85},
        {"07. Zero-Leak Proof", progress_pct >= 95},
        {"08. In-Editor Test Docks", progress_pct >= 100}
      ]

      String.build do |str|
        str << (initial ? "#{CLEAR_SCREEN}#{CURSOR_HIDE}" : "#{CURSOR_HOME}#{CURSOR_HIDE}")
        str << "#{C_MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════╗#{C_RESET}\r\n"
        h1 = "#{fit_visible("#{C_BOLD}◆ LAPIS UNIFIED TEST SUITE DASHBOARD#{C_RESET}", 64)} #{fit_visible(status_text, 17)}"
        str << "#{C_MAGENTA}║#{C_RESET} #{h1} #{C_MAGENTA}║#{C_RESET}\r\n"
        h2 = fit_visible("Host: windows │ Godot: 4.8.0-custom │ Crystal: v1.15.0 │ Time: 00:14.2", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h2} #{C_MAGENTA}║#{C_RESET}\r\n"
        h3 = fit_visible("[#{bar}] #{sprintf("%3d", progress_pct)}% (45/45 suites • 420+ specs)", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h3} #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}╚════════════════════════════════════════════════════════════════════════════════════╝#{C_RESET}\r\n"
        
        left_header = border_line("┌─ TEST PHASES (45 SUITES) ", "─", "┐", 33)
        right_header = border_line("┌─ LIVE EXECUTION LOG STREAM ", "─", "┐", 52)
        str << "#{C_CYAN}#{left_header} #{right_header}#{C_RESET}\r\n"

        8.times do |i|
          p_name, p_done = phases[i]
          is_active = (i == active_phase_idx)
          mark = p_done ? "#{C_GREEN}✔#{C_RESET}" : (is_active ? "#{C_YELLOW}►#{C_RESET}" : " ")
          selector = is_active ? "#{C_CYAN}►#{C_RESET}" : " "
          left_col = "│ #{selector} #{mark} #{fit_visible(p_name, 25)} │"

          r_text = i < log_lines.size ? log_lines[i] : ""
          right_col = "│ #{fit_visible(r_text, 48)} │"

          str << "#{left_col} #{right_col}\r\n"
        end

        left_footer = border_line("└", "─", "┘", 33)
        right_footer = border_line("└", "─", "┘", 52)
        str << "#{C_CYAN}#{left_footer} #{right_footer}#{C_RESET}\r\n"
        actions = fit_visible(" [↑↓/jk] Select Phase  [Enter] Drill-down Modal  [q] Exit  [?] Help", 86)
        str << "#{C_DIM}#{actions}#{C_RESET}"
      end
    end

    # Renders an interactive modal drilldown window inside the test dashboard (exactly 86 cols)
    def self.render_tui_modal(title : String, modal_lines : Array(String), initial : Bool = false) : String
      String.build do |str|
        str << (initial ? "#{CLEAR_SCREEN}#{CURSOR_HIDE}" : "#{CURSOR_HOME}#{CURSOR_HIDE}")
        str << "#{C_MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════╗#{C_RESET}\r\n"
        h1 = "#{fit_visible("#{C_BOLD}◆ LAPIS UNIFIED TEST SUITE DASHBOARD#{C_RESET}", 64)} #{fit_visible("#{C_BOLD}#{C_GREEN}ALL PASSED ✔#{C_RESET}", 17)}"
        str << "#{C_MAGENTA}║#{C_RESET} #{h1} #{C_MAGENTA}║#{C_RESET}\r\n"
        h2 = fit_visible("Host: windows │ Godot: 4.8.0-custom │ Crystal: v1.15.0 │ Time: 00:14.2", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h2} #{C_MAGENTA}║#{C_RESET}\r\n"
        h3 = fit_visible("[#{C_CYAN}#{"█" * 36}#{C_RESET}] 100% (45/45 suites • 420+ specs)", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h3} #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}╚════════════════════════════════════════════════════════════════════════════════════╝#{C_RESET}\r\n"
        str << "#{C_CYAN}#{header_border(title, 86)}#{C_RESET}\r\n"

        8.times do |i|
          m_text = i < modal_lines.size ? modal_lines[i] : ""
          str << "#{C_CYAN}│#{C_RESET} #{fit_visible(m_text, 82)} #{C_CYAN}│#{C_RESET}\r\n"
        end

        str << "#{C_CYAN}#{border_line("└", "─", "┘", 86)}#{C_RESET}\r\n"
        actions = fit_visible(" [↑↓] Scroll Specs  [Esc] Return to Dashboard  [R] Re-run Phase  [?] Help", 86)
        str << "#{C_CYAN}#{actions}#{C_RESET}"
      end
    end

    # Renders the Benchmark Dashboard frame (guaranteed exactly 86 cols per line)
    def self.render_bench_tui_frame(progress_pct : Int32, active_idx : Int32, log_lines : Array(String), all_done : Bool = false, initial : Bool = false) : String
      status_text = all_done ? "#{C_BOLD}#{C_GREEN}ALL RUNS ✔#{C_RESET}" : "#{C_YELLOW}PROFILING...#{C_RESET}"
      filled_blocks = (progress_pct / 100.0 * 36).to_i
      empty_blocks = 36 - filled_blocks
      bar = "#{C_CYAN}#{"█" * filled_blocks}#{C_DIM}#{"░" * empty_blocks}#{C_RESET}"

      benchmarks = [
        {"01. N-Body Physics (10k)", progress_pct >= 15},
        {"02. Perlin Noise 256x256", progress_pct >= 30},
        {"03. A* Pathing (1k)", progress_pct >= 45},
        {"04. Raycast Octree SIMD", progress_pct >= 60},
        {"05. Matrix 4x4 (100k)", progress_pct >= 75},
        {"06. Procedural Dungeon", progress_pct >= 85},
        {"07. Particle Sim (50k)", progress_pct >= 95},
        {"08. Multiplayer RPC Sync", progress_pct >= 100}
      ]

      String.build do |str|
        str << (initial ? "#{CLEAR_SCREEN}#{CURSOR_HIDE}" : "#{CURSOR_HOME}#{CURSOR_HIDE}")
        str << "#{C_MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════╗#{C_RESET}\r\n"
        h1 = "#{fit_visible("#{C_BOLD}⚡ LAPIS PERFORMANCE BENCHMARK DASHBOARD#{C_RESET}", 64)} #{fit_visible(status_text, 17)}"
        str << "#{C_MAGENTA}║#{C_RESET} #{h1} #{C_MAGENTA}║#{C_RESET}\r\n"
        h2 = fit_visible("Host: windows-x64 │ Engine: Godot 4.8-custom │ Crystal: -O3 │ Iterations: 3", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h2} #{C_MAGENTA}║#{C_RESET}\r\n"
        h3 = fit_visible("[#{bar}] #{sprintf("%3d", progress_pct)}% (8/8 benchmarks • 3 iters)", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h3} #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}╚════════════════════════════════════════════════════════════════════════════════════╝#{C_RESET}\r\n"
        
        left_header = border_line("┌─ BENCHMARKS (8 SUITES) ", "─", "┐", 33)
        right_header = border_line("┌─ LIVE PERFORMANCE & SPEEDUP RATIOS ", "─", "┐", 52)
        str << "#{C_CYAN}#{left_header} #{right_header}#{C_RESET}\r\n"

        8.times do |i|
          b_name, b_done = benchmarks[i]
          is_active = (i == active_idx)
          mark = b_done ? "#{C_GREEN}✔#{C_RESET}" : (is_active ? "#{C_YELLOW}►#{C_RESET}" : " ")
          selector = is_active ? "#{C_CYAN}►#{C_RESET}" : " "
          left_col = "│ #{selector} #{mark} #{fit_visible(b_name, 25)} │"

          r_text = i < log_lines.size ? log_lines[i] : ""
          right_col = "│ #{fit_visible(r_text, 48)} │"

          str << "#{left_col} #{right_col}\r\n"
        end

        left_footer = border_line("└", "─", "┘", 33)
        right_footer = border_line("└", "─", "┘", 52)
        str << "#{C_CYAN}#{left_footer} #{right_footer}#{C_RESET}\r\n"
        actions = fit_visible(" [↑↓/jk] Select Benchmark  [Enter] Detailed Metrics Modal  [q] Exit  [?] Help", 86)
        str << "#{C_DIM}#{actions}#{C_RESET}"
      end
    end

    # Renders an interactive modal drilldown window inside the benchmark dashboard (exactly 86 cols)
    def self.render_bench_modal(title : String, modal_lines : Array(String), initial : Bool = false) : String
      String.build do |str|
        str << (initial ? "#{CLEAR_SCREEN}#{CURSOR_HIDE}" : "#{CURSOR_HOME}#{CURSOR_HIDE}")
        str << "#{C_MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════╗#{C_RESET}\r\n"
        h1 = "#{fit_visible("#{C_BOLD}⚡ LAPIS PERFORMANCE BENCHMARK DASHBOARD#{C_RESET}", 64)} #{fit_visible("#{C_BOLD}#{C_GREEN}ALL RUNS ✔#{C_RESET}", 17)}"
        str << "#{C_MAGENTA}║#{C_RESET} #{h1} #{C_MAGENTA}║#{C_RESET}\r\n"
        h2 = fit_visible("Host: windows-x64 │ Engine: Godot 4.8-custom │ Crystal: -O3 │ Iterations: 3", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h2} #{C_MAGENTA}║#{C_RESET}\r\n"
        h3 = fit_visible("[#{C_CYAN}#{"█" * 36}#{C_RESET}] 100% (8/8 benchmarks • 3 iters)", 82)
        str << "#{C_MAGENTA}║#{C_RESET} #{h3} #{C_MAGENTA}║#{C_RESET}\r\n"
        str << "#{C_MAGENTA}╚════════════════════════════════════════════════════════════════════════════════════╝#{C_RESET}\r\n"
        str << "#{C_CYAN}#{header_border(title, 86)}#{C_RESET}\r\n"

        8.times do |i|
          m_text = i < modal_lines.size ? modal_lines[i] : ""
          str << "#{C_CYAN}│#{C_RESET} #{fit_visible(m_text, 82)} #{C_CYAN}│#{C_RESET}\r\n"
        end

        str << "#{C_CYAN}#{border_line("└", "─", "┘", 86)}#{C_RESET}\r\n"
        actions = fit_visible(" [↑↓] Scroll Metrics  [Esc] Return to Dashboard  [R] Re-profile  [?] Help", 86)
        str << "#{C_CYAN}#{actions}#{C_RESET}"
      end
    end

    # 1. Unified Test Runner TUI (Slide 85 / 37_tool_testing_tui.yml) - ~31.5s
    def self.build_test_runner_cast(output_dir : String)
      tui_session = Session.new
      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      tui_session.type_command("lapis test --tui", prompt, 22.0)

      logs = [] of String
      logs << "#{C_CYAN}► Phase 01: Core Language & Math Spec Suites#{C_RESET}"
      tui_session.emit(0.3_f64, render_tui_frame(5, 0, logs, initial: true))

      logs << "#{C_DIM}[10:24:08]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Vector2 / Vector3 SIMD math"
      tui_session.emit(1.1_f64, render_tui_frame(18, 1, logs))

      logs << "#{C_DIM}[10:24:09]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Variant roundtrip & Dictionary"
      tui_session.emit(1.1_f64, render_tui_frame(32, 2, logs))

      logs << "#{C_DIM}[10:24:10]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Monotonic 64-bit ID check_alive!"
      tui_session.emit(1.1_f64, render_tui_frame(46, 3, logs))

      logs << "#{C_DIM}[10:24:12]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} ToolTester2D & ToolTester3D @tool"
      tui_session.emit(1.1_f64, render_tui_frame(62, 4, logs))

      logs << "#{C_DIM}[10:24:13]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} Signal fiber awaiting & timers"
      tui_session.emit(1.1_f64, render_tui_frame(78, 5, logs))

      logs << "#{C_DIM}[10:24:14]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} CharacterBody3D & AStar2D pathing"
      tui_session.emit(1.1_f64, render_tui_frame(90, 6, logs))

      logs << "#{C_DIM}[10:24:16]#{C_RESET} #{C_GREEN}[PASS]#{C_RESET} assert_no_leak: ΔObjects == 0"
      tui_session.emit(1.1_f64, render_tui_frame(97, 7, logs))

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
      tui_session.emit(1.3_f64, render_tui_frame(100, 7, final_logs, all_done: true))

      # Interactive TUI Phase Navigation (Arrow keys: ↓)
      tui_session.emit(1.0_f64, render_tui_frame(100, 0, final_logs, all_done: true))
      tui_session.emit(0.7_f64, render_tui_frame(100, 1, final_logs, all_done: true))
      tui_session.emit(0.7_f64, render_tui_frame(100, 2, final_logs, all_done: true))
      tui_session.emit(0.7_f64, render_tui_frame(100, 3, final_logs, all_done: true))

      # Drill-down Modal on Phase 04: Headless In-Editor @tool (Press Enter)
      modal_phase4 = [
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ToolTester2D#{C_RESET}: Headless Node2D instancing in editor tree (0.12s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ToolTester3D#{C_RESET}: Camera3D & Gizmo handle synchronization (0.18s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ExportToolButton#{C_RESET}: Programmatic 'Reset Stats' button click (0.04s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}InspectorPlugin#{C_RESET}: Custom property editor layout & dock (0.09s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}EditorInterface#{C_RESET}: Headless command palette mock trigger (0.07s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}HotReloadCycle#{C_RESET}: In-memory ClassDB type table cache (0.11s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}SceneTreeTeardown#{C_RESET}: Clean queue_free() of test nodes (0.02s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ZeroDeadPointers#{C_RESET}: 0 dangling ObjectDB pointer references (0.00s)"
      ]
      tui_session.emit(1.0_f64, render_tui_modal("Phase 04: Headless In-Editor @tool (Modal Detail)", modal_phase4))

      # Scroll specs in modal
      modal_phase4_scrolled = [
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ExportToolButton#{C_RESET}: Programmatic 'Reset Stats' button click (0.04s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}InspectorPlugin#{C_RESET}: Custom property editor layout & dock (0.09s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}EditorInterface#{C_RESET}: Headless command palette mock trigger (0.07s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}HotReloadCycle#{C_RESET}: In-memory ClassDB type table cache (0.11s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}SceneTreeTeardown#{C_RESET}: Clean queue_free() of test nodes (0.02s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ZeroDeadPointers#{C_RESET}: 0 dangling ObjectDB pointer references (0.00s)",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ResourcePreload#{C_RESET}: PackedScene instantiate without editor frame drop",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}UndoRedoManager#{C_RESET}: Editor action history stack validation (0.03s)"
      ]
      tui_session.emit(1.5_f64, render_tui_modal("Phase 04: Headless In-Editor @tool (Modal Detail)", modal_phase4_scrolled))
      tui_session.pause(1.8)

      # Press Esc -> Return to Dashboard
      tui_session.emit(0.6_f64, render_tui_frame(100, 3, final_logs, all_done: true))

      # Navigate down to Phase 07: Zero-Leak Verification
      tui_session.emit(0.7_f64, render_tui_frame(100, 4, final_logs, all_done: true))
      tui_session.emit(0.7_f64, render_tui_frame(100, 5, final_logs, all_done: true))
      tui_session.emit(0.7_f64, render_tui_frame(100, 6, final_logs, all_done: true))

      # Drill-down Modal on Phase 07: Zero-Leak Verification (Press Enter)
      modal_phase7 = [
        "  #{C_BOLD}ObjectDB Monotonic Tracking#{C_RESET}: 64-bit ID allocation cycle verified",
        "  #{C_CYAN}Performance Monitors#{C_RESET}:   OBJECT_COUNT:      1,248 -> 1,248  #{C_GREEN}(Δ 0 leaks)#{C_RESET}",
        "  #{C_CYAN}Performance Monitors#{C_RESET}:   OBJECT_NODE_COUNT:    42 ->    42  #{C_GREEN}(Δ 0 leaks)#{C_RESET}",
        "  #{C_CYAN}Engine Static Memory#{C_RESET}:   38.4 MB -> 38.4 MB                 #{C_GREEN}(Δ 0 B)#{C_RESET}",
        "  #{C_MAGENTA}Boehm GC Heap State#{C_RESET}:    12.1 MB / 14 collections / 0 unmapped pages",
        "  #{C_MAGENTA}Fiber Scheduler Queue#{C_RESET}:  0 orphaned fibers, 0 leaked worker channels",
        "  #{C_BLUE}C++ Bridge Pointers#{C_RESET}:    0 unreferenced GDExtension handle wrappers",
        "  #{C_BOLD}#{C_GREEN}Quantitative Result:      ZERO MEMORY LEAKS MATHEMATICALLY VERIFIED ✔#{C_RESET}"
      ]
      tui_session.emit(1.0_f64, render_tui_modal("Phase 07: Zero-Leak Verification (Quantitative Proof)", modal_phase7))
      tui_session.pause(2.5)

      # Press Esc -> Return to Dashboard
      tui_session.emit(0.6_f64, render_tui_frame(100, 6, final_logs, all_done: true))

      # Navigate to Phase 08: In-Editor Test Docks
      tui_session.emit(0.7_f64, render_tui_frame(100, 7, final_logs, all_done: true))

      # Drill-down Modal on Phase 08: In-Editor Test Docks (Press Enter)
      modal_phase8 = [
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}TestRunnerDock#{C_RESET}: Bottom editor panel instantiated with tab containers",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}TreeHierarchy#{C_RESET}: Live tree item expansion for 45 test suite categories",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}OutputSyncBridge#{C_RESET}: Real-time ANSI colored output redirection to editor console",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}RunSelectedAction#{C_RESET}: Re-runs single test suite on button click without reload",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}MemoryCounterMonitor#{C_RESET}: Live delta meter widget integrated in status bar",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}ClassDBIntegrity#{C_RESET}: 0 namespace collisions between editor and game classes",
        "  #{C_GREEN}✔#{C_RESET} #{C_BOLD}EditorPluginCleanup#{C_RESET}: Clean removal of dock controls upon plugin disable",
        "  #{C_BOLD}#{C_GREEN}Phase 08 Status: In-editor test apparatus fully verified with 0 warnings ✔#{C_RESET}"
      ]
      tui_session.emit(1.0_f64, render_tui_modal("Phase 08: In-Editor Test Docks (UI Apparatus)", modal_phase8))
      tui_session.pause(2.5)

      # Press Esc -> Return to Dashboard
      tui_session.emit(0.6_f64, render_tui_frame(100, 7, final_logs, all_done: true))
      tui_session.pause(3.5)

      tui_session.save(File.join(output_dir, "test_runner_tui.cast"), 86, 19, "Lapis Unified Test Runner TUI Dashboard")
    end

    # 2. CLI Command Center & Scaffolding (Slide 30) - ~30.5s
    def self.build_cli_lifecycle_cast(output_dir : String)
      cli_session = Session.new
      cli_session.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      cli_session.type_command("lapis", prompt, 20.0)

      # 1. Command Center Header & Telemetry
      cli_session.emit(0.2_f64, "\r\n#{C_BOLD}#{ESC}[45;37m ◆ LAPIS COMMAND CENTER #{C_RESET} #{C_CYAN}Unified Crystal Engine Toolchain for Godot (v0.0.255)#{C_RESET}\r\n\r\n")
      cli_session.emit(0.12_f64, "  #{C_BOLD}#{C_CYAN}Project:#{C_RESET} #{C_BOLD}void_runner#{C_RESET} (branch: #{C_MAGENTA}main#{C_RESET} • commit febe80b)\r\n")
      cli_session.emit(0.12_f64, "  #{C_BOLD}#{C_CYAN}Platform:#{C_RESET} #{C_BOLD}windows-x86_64#{C_RESET} │ #{C_BOLD}#{C_CYAN}Godot:#{C_RESET} #{C_CYAN}4.8.0-dev6#{C_RESET} │ #{C_BOLD}#{C_CYAN}Crystal:#{C_RESET} #{C_BOLD}v1.15.0 [LLVM 18.1.8]#{C_RESET}\r\n")
      cli_session.emit(0.12_f64, "  #{C_BOLD}#{C_CYAN}Bridge DLL:#{C_RESET} #{C_BOLD}#{C_GREEN}Ready (bin/crystal_bridge.dll)#{C_RESET} │ #{C_BOLD}#{C_CYAN}Game DLL:#{C_RESET} #{C_BOLD}#{C_GREEN}Development (Shadow Active)#{C_RESET}\r\n\r\n")

      # Hotkey Menu Navigation
      cli_session.emit(0.3_f64, "#{C_BOLD}Select an action (or press hotkey):#{C_RESET}\r\n")
      cli_session.emit(0.1_f64, "  #{C_CYAN}🔍 [ / ]#{C_RESET} Open Spotlight Command Palette (Search all 30+ commands)\r\n")
      cli_session.emit(0.1_f64, "  #{C_YELLOW}🔨 [ B ]#{C_RESET} Build Game Library & Bridge (lapis build -r)\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}🧪 [ T ]#{C_RESET} Run Test Suites & Specs (lapis test --tui)\r\n")
      cli_session.emit(0.1_f64, "  #{C_BLUE}🩺 [ D ]#{C_RESET} Environment & Toolchain Diagnostics (lapis doctor)\r\n")
      cli_session.emit(0.1_f64, "  #{C_MAGENTA}🎮 [ E ]#{C_RESET} Launch Godot Editor with Hot-Reloading (lapis editor)\r\n")
      cli_session.emit(0.1_f64, "  #{C_CYAN}✨ [ S ]#{C_RESET} Scaffold New Game or Addon (lapis new)\r\n")
      cli_session.emit(0.1_f64, "  #{C_YELLOW}📜 [ L ]#{C_RESET} Inspect Multi-Channel Logs & Traces (lapis log)\r\n\r\n")
      cli_session.pause(4.0)

      # 2. Trigger Doctor
      cli_session.type_command("lapis doctor --verbose", prompt, 20.0)
      cli_session.emit(0.2_f64, "#{C_BOLD}Diagnostic Matrix Results (6/6 Subsystems Verified):#{C_RESET}\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} Crystal Compiler   : Crystal 1.15.0 (LLVM 18.1.8, target x86_64)   [PASS]\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} Godot Engine       : Godot Engine v4.8.0.dev6 [3f1a9b]             [PASS]\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} Radare2 Native R2  : radare2 5.9.8 0 @ windows-x64 (cradare2 ABI)  [PASS]\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} GDExtension API    : extension_api.json matched (824 classes)      [PASS]\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} C++ Bridge Loader  : MSVC cl.exe 19.38 / x64 C++17 support         [PASS]\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} Windows CRT DLLs   : gc.dll, pcre2-8.dll, iconv-2.dll staged       [PASS]\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} Fiber scheduler & thread-affinity barriers validated\r\n\r\n")
      cli_session.pause(5.0)

      # 3. Clean dry run & shadows
      cli_session.type_command("lapis clean --dry-run", prompt, 20.0)
      cli_session.emit(0.2_f64, "#{C_CYAN}[Lapis]#{C_RESET} Previewing candidate clean targets (dry run)...\r\n")
      cli_session.emit(0.1_f64, "  • 8 stale Windows shadow DLLs (*_loaded_*.dll/pdb): 142.4 MB\r\n")
      cli_session.emit(0.1_f64, "  • Intermediate .crystal/ cache build artifacts:     84.1 MB\r\n")
      cli_session.emit(0.1_f64, "  • Total reclaimable disk space: #{C_BOLD}#{C_GREEN}226.5 MB#{C_RESET}\r\n\r\n")
      cli_session.pause(3.5)

      cli_session.type_command("lapis clean --shadows", prompt, 20.0)
      cli_session.emit(0.2_f64, "  #{C_GREEN}✔#{C_RESET} Purged 8 stale shadow DLLs without closing Godot Editor (142.4 MB freed)\r\n\r\n")
      cli_session.pause(3.0)

      # 4. Sync targets
      cli_session.type_command("lapis sync", prompt, 20.0)
      cli_session.emit(0.2_f64, "#{C_CYAN}[Lapis]#{C_RESET} Synchronizing binaries across workspace targets...\r\n")
      cli_session.emit(0.1_f64, "  • Synchronized bin/game.dll -> template/bin/game.dll\r\n")
      cli_session.emit(0.1_f64, "  • Synchronized bin/crystal_bridge.dll -> test/bin/crystal_bridge.dll\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} All 4 target workspaces synchronized in 180ms.\r\n\r\n")
      cli_session.pause(3.5)

      # 5. Export templates explain
      cli_session.type_command("lapis export-templates explain", prompt, 20.0)
      cli_session.emit(0.2_f64, "#{C_BOLD}=== Crystal Export Templates Architecture ===#{C_RESET}\r\n")
      cli_session.emit(0.1_f64, "  • Windows : godot.windows.template_release.x86_64.exe + game.dll\r\n")
      cli_session.emit(0.1_f64, "  • Linux   : godot.linuxbsd.template_release.x86_64    + libgame.so\r\n")
      cli_session.emit(0.1_f64, "  • macOS   : Godot.app (Universal Mach-O)             + libgame.dylib\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔#{C_RESET} Installed templates: Godot 4.8.dev6 verified in AppData/Roaming\r\n\r\n")
      cli_session.pause(4.0)

      # 6. IDE setup
      cli_session.type_command("lapis ide setup vscode", prompt, 20.0)
      cli_session.emit(0.2_f64, "  #{C_GREEN}✔ Created:#{C_RESET} .vscode/settings.json (Crystalline LSP daemon binding)\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔ Created:#{C_RESET} .vscode/tasks.json (Build Game, Test, Sync, Clean)\r\n")
      cli_session.emit(0.1_f64, "  #{C_GREEN}✔ Created:#{C_RESET} .vscode/launch.json (Radare2 native gutter debugger)\r\n")
      cli_session.emit(0.1_f64, "  #{C_BOLD}#{C_GREEN}[OK] Ready for zero-config development!#{C_RESET}\r\n")
      cli_session.pause(4.0)

      cli_session.save(File.join(output_dir, "lapis_cli_lifecycle.cast"), 86, 22, "Lapis Command Center, Diagnostics & Full Project Lifecycle")
    end

    # 3. Spotlight Command Palette & Typo Recovery (Slide 30b) - ~30.5s
    def self.build_fuzzy_palette_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis docotr", p1, 18.0)
      sess.emit(0.2_f64, "#{C_RED}[ERROR] Unknown command 'docotr'#{C_RESET}\r\n")
      sess.emit(0.25_f64, "  #{C_YELLOW}💡 Did you mean: lapis doctor? (Levenshtein distance: 1)#{C_RESET}\r\n")
      sess.emit(0.15_f64, "  #{C_DIM}Run 'lapis --help' for a full list of commands.#{C_RESET}\r\n\r\n")
      sess.pause(3.5)

      sess.type_command("lapis pacakge", p1, 18.0)
      sess.emit(0.2_f64, "#{C_RED}[ERROR] Unknown command 'pacakge'#{C_RESET}\r\n")
      sess.emit(0.25_f64, "  #{C_YELLOW}💡 Did you mean: lapis package? (Levenshtein distance: 2)#{C_RESET}\r\n\r\n")
      sess.pause(3.2)

      sess.type_command("lapis --palette", p1, 18.0)
      sess.emit(0.2_f64, "#{C_BOLD}Search Command to Execute: #{C_CYAN}pkg#{C_RESET}\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}┌──────────────────────────────────────────────────────────────────────────────────┐#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}#{C_GREEN}► 📦 lapis package game      - Bundle portable executable with embedded PCK#{C_RESET}        │\r\n")
      sess.emit(0.08_f64, "│    📦 lapis package addon     - Create redistributable GDExtension zip archive   │\r\n")
      sess.emit(0.08_f64, "│    📦 lapis package release   - Build full multi-platform release distribution   │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}└──────────────────────────────────────────────────────────────────────────────────┘#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_DIM}[↑↓] Navigate  [Enter] Execute  [Esc] Cancel#{C_RESET}\r\n\r\n")
      sess.pause(3.8)

      # Backspace and retype "bench"
      sess.emit(0.2_f64, "#{ESC}[6A\r#{C_BOLD}Search Command to Execute: #{C_CYAN}bench#{C_RESET} \r\n")
      sess.emit(0.08_f64, "#{C_CYAN}┌──────────────────────────────────────────────────────────────────────────────────┐#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}#{C_GREEN}► ⚡ lapis benchmarks --tui  - Real-time AVX2 SIMD compute speedup dashboard#{C_RESET}      │\r\n")
      sess.emit(0.08_f64, "│    ⚡ lapis benchmarks run    - Execute benchmark comparison suites              │\r\n")
      sess.emit(0.08_f64, "│    🔬 lapis decompile         - Side-by-side assembly & pseudo-C decompiler      │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}└──────────────────────────────────────────────────────────────────────────────────┘#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_DIM}[↑↓] Navigate  [Enter] Execute  [Esc] Cancel#{C_RESET}\r\n\r\n")
      sess.pause(3.8)

      # Tab autocompletion demonstration (safe line length <= 86 cols)
      sess.type_command("lapis decompile", p1, 16.0)
      sess.emit(0.15_f64, "  #{C_GREEN}✔#{C_RESET} [Tab] Autocompleted via shell completion (Bash, Zsh, PowerShell, Fish)\r\n")
      sess.pause(7.0)
      sess.save(File.join(output_dir, "lapis_fuzzy_palette.cast"), 86, 19, "Lapis Command Palette & Typo Recovery")
    end

    # 4. Environment Diagnostics & Toolchain Doctor (Slide 30c) - ~30.0s
    def self.build_doctor_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis doctor --verbose", p1, 18.0)

      sess.emit(0.2_f64, "#{C_CYAN}[Doctor]#{C_RESET} Diagnosing Lapis development environment...\r\n")
      sess.spinner("Scanning Crystal compiler & LLVM backend...", frames_count: 32, delay: 0.08)
      sess.spinner_done("Crystal v1.15.0 verified (LLVM 18.1.8, target x86_64)")

      sess.spinner("Probing Godot engine binary & GDExtension v2 ABI...", frames_count: 32, delay: 0.08)
      sess.spinner_done("Godot Engine v4.8.0.custom_build [3f1a9b] verified")

      sess.spinner("Auditing native radare2 debugger & symbols...", frames_count: 30, delay: 0.08)
      sess.spinner_done("radare2 5.9.8 verified @ windows-x64 (cradare2)")

      sess.spinner("Auditing MSVC cl.exe & C++17 loader bridge...", frames_count: 30, delay: 0.08)
      sess.spinner_done("MSVC cl.exe 19.38 / x64 C++17 support verified")

      sess.spinner("Probing runtime DLLs (gc.dll, pcre2-8.dll, libgodot.dll)...", frames_count: 30, delay: 0.08)
      sess.spinner_done("Runtime DLL dependencies present in bin/ and verified")

      sess.spinner("Verifying thread-safety & fiber execution contexts...", frames_count: 28, delay: 0.08)
      sess.spinner_done("Fiber scheduler & thread-affinity barriers validated")

      sess.emit(0.25_f64, "\r\n#{C_BOLD}Diagnostic Matrix Results:#{C_RESET}\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}┌────────┬────────────────────┬────────────────────────────────────────────┬─────────┐#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{C_BOLD}Status#{C_RESET} │ #{C_BOLD}Component#{C_RESET}          │ #{C_BOLD}Diagnostic Detail#{C_RESET}                          │ #{C_BOLD}Action#{C_RESET}  │\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}├────────┼────────────────────┼────────────────────────────────────────────┼─────────┤#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Crystal Compiler   │ Crystal 1.15.0 (LLVM 18.1.8, target x86_64)│ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Godot Engine       │ Godot Engine v4.8.0.custom_build [3f1a9b]  │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Radare2 Native R2  │ radare2 5.9.8 0 @ windows-x64 (cradare2)   │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ GDExtension API    │ extension_api.json matched (824 classes)   │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ C++ Bridge Loader  │ MSVC cl.exe 19.38 / x64 C++17 support      │ Ready   │\r\n")
      sess.emit(0.06_f64, "│ #{ESC}[42;37m PASS #{C_RESET} │ Windows CRT DLLs   │ gc.dll, pcre2-8.dll, iconv-2.dll staged    │ Ready   │\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}└────────┴────────────────────┴────────────────────────────────────────────┴─────────┘#{C_RESET}\r\n\r\n")

      # Live Readiness Gauge
      sess.emit(0.15_f64, "#{C_BOLD}Toolchain Readiness Gauge: 100% (6/6 components verified)#{C_RESET}\r\n")
      sess.emit(0.2_f64, "#{C_GREEN}[████████████████████████████████████████████████████████] 100% READY#{C_RESET}\r\n")
      sess.emit(0.15_f64, "  #{C_GREEN}✔#{C_RESET} 0 configuration gaps detected. Zero-config development active!\r\n")
      sess.pause(11.5)
      sess.save(File.join(output_dir, "lapis_doctor.cast"), 86, 19, "Lapis Environment Diagnostics & Toolchain Doctor")
    end

    # 5. ClassDB Reflection & Rapid Codegen (Slide 31) - ~30.5s
    def self.build_bind_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis bind --dump-extension-api", p1, 18.0)

      sess.emit(0.2_f64, "#{C_CYAN}[ClassDB:Dump]#{C_RESET} Extracting engine API from godot.exe...\r\n")
      sess.spinner("Dumping extension_api.json via GDExtension v2...", frames_count: 34, delay: 0.08)
      sess.spinner_done("Dumped extension_api.json (Godot 4.8.0-custom, 6.2 MB) in 0.42s")

      sess.emit(0.2_f64, "#{C_YELLOW}[Codegen:Analyze]#{C_RESET} Parsing ClassDB engine metadata...\r\n")
      sess.spinner("Parsing classes, enums, virtual methods, properties...", frames_count: 34, delay: 0.08)
      sess.spinner_done("Analyzed 824 classes, 1,418 enums, 8,912 methods, 2,140 properties")

      sess.emit(0.2_f64, "#{C_MAGENTA}[Codegen:Emit]#{C_RESET} Synthesizing strongly-typed Crystal bindings...\r\n")
      sess.progress_bar("Emitting classes", total_steps: 12, step_delay: 0.35) do |step|
        count = (step * 824) // 12
        "(#{count}/824 files generated)"
      end

      sess.emit(0.15_f64, "#{C_CYAN}[Codegen:Ptrcall]#{C_RESET} Inlining direct ptrcall dispatches...\r\n")
      sess.spinner("Inlining method pointer tables & zero-overhead vcalls...", frames_count: 32, delay: 0.08)
      sess.spinner_done("Inlined 8,912 methods with direct function pointers")

      sess.spinner("Verifying generated bindings with crystal build check...", frames_count: 28, delay: 0.08)
      sess.spinner_done("Zero compilation errors • Syntax verified")

      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Generated src/libgodot/generated/classes/ (824 files)\r\n")
      sess.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Generated src/libgodot/generated/enums.cr (1,418 enums)\r\n")
      sess.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Syntax validation: crystal run src/libgodot/verify.cr (0 errors)\r\n")
      sess.pause(3.2)
      sess.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Typed engine bindings synthesized in 1.18s! 0 compilation errors.\r\n")
      sess.pause(7.5)
      sess.save(File.join(output_dir, "lapis_bind.cast"), 86, 19, "Lapis Codegen & ClassDB Reflection")
    end

    # 5b. Project & Addon Scaffolding Wizard (Slide 30d) - ~30.5s
    def self.build_scaffold_wizard_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects#{C_RESET}$ "
      sess.type_command("lapis cli -n", p1, 18.0)

      # TUI Wizard Step 1: Browse options
      sess.emit(0.2_f64, "#{C_CYAN}:: LAPIS PROJECT & ADDON SCAFFOLDING WIZARD ::#{C_RESET}\r\n")
      sess.emit(0.08_f64, "#{C_DIM}Create standalone games, redistributable GDExtension addons, or showcase examples#{C_RESET}\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.08_f64, "#{C_YELLOW}Step 1: Select Project Type#{C_RESET}\r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}► [*] [GAME] Standalone Game Project#{C_RESET}\r\n")
      sess.emit(0.08_f64, "        A complete Godot game project with Crystal gameplay nodes and scenes.\r\n")
      sess.emit(0.08_f64, "    [ ] [ADDON] Redistributable GDExtension Addon\r\n")
      sess.emit(0.08_f64, "        Reusable extension package with export plugin, manifests, and shard specs.\r\n")
      sess.emit(0.08_f64, "    [ ] [EXAMPLE] Showcase Example\r\n")
      sess.emit(0.08_f64, "        Self-contained demo showcasing features and patterns.\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_CYAN}Tab / ↑↓: Navigate Fields │ Enter: Next │ F: Choose Folder │ Esc: Exit Wizard#{C_RESET}\r\n\r\n")
      sess.pause(2.5)

      # Move down to ADDON
      sess.emit(0.2_f64, "#{ESC}[9A\r")
      sess.emit(0.08_f64, "    [ ] [GAME] Standalone Game Project                                            \r\n")
      sess.emit(0.08_f64, "        A complete Godot game project with Crystal gameplay nodes and scenes.     \r\n")
      sess.emit(0.08_f64, "  #{C_GREEN}► [*] [ADDON] Redistributable GDExtension Addon#{C_RESET}                                 \r\n")
      sess.emit(0.08_f64, "        Reusable extension package with export plugin, manifests, and shard specs.\r\n")
      sess.emit(0.08_f64, "    [ ] [EXAMPLE] Showcase Example                                                \r\n")
      sess.emit(0.08_f64, "        Self-contained demo showcasing features and patterns.                     \r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_CYAN}Tab / ↑↓: Navigate Fields │ Enter: Next │ F: Choose Folder │ Esc: Exit Wizard#{C_RESET}\r\n\r\n")
      sess.pause(2.2)

      # Move back to GAME & Confirm
      sess.emit(0.2_f64, "#{ESC}[9A\r")
      sess.emit(0.08_f64, "  #{C_GREEN}► [*] [GAME] Standalone Game Project#{C_RESET}                                          \r\n")
      sess.emit(0.08_f64, "        A complete Godot game project with Crystal gameplay nodes and scenes.     \r\n")
      sess.emit(0.08_f64, "    [ ] [ADDON] Redistributable GDExtension Addon                                 \r\n")
      sess.emit(0.08_f64, "        Reusable extension package with export plugin, manifests, and shard specs.\r\n")
      sess.emit(0.08_f64, "    [ ] [EXAMPLE] Showcase Example                                                \r\n")
      sess.emit(0.08_f64, "        Self-contained demo showcasing features and patterns.                     \r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_CYAN}Tab / ↑↓: Navigate Fields │ Enter: Next │ F: Choose Folder │ Esc: Exit Wizard#{C_RESET}\r\n\r\n")
      sess.pause(1.8)

      # Step 2 Details & Instant Creation
      sess.emit(0.3_f64, "#{C_CYAN}[Scaffold]#{C_RESET} Initializing standalone game 'void_runner' in ./void_runner...\r\n")
      sess.spinner("Creating scene tree, crystal sources, and engine configuration...", frames_count: 34, delay: 0.08)
      sess.spinner_done("Scaffold generated in 0.38s")
      sess.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} project.godot (Godot 4.8.0-custom)\r\n")
      sess.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} shard.yml (libgodot ~> 0.8.2)\r\n")
      sess.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} src/main.cr (Root Game Host & Player character node)\r\n")
      sess.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} scenes/main.tscn & scenes/player.tscn\r\n\r\n")
      sess.pause(3.2)

      # Direct CLI command
      sess.type_command("lapis scaffold game void_runner", p1, 18.0)
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Project 'void_runner' ready! Run 'cd void_runner && lapis editor'\r\n")
      sess.pause(10.5)
      sess.save(File.join(output_dir, "lapis_scaffold_wizard.cast"), 86, 20, "Lapis Scaffolding Wizard & CLI")
    end

    # 6. Portable Packaging (Slide 31b) - ~30.5s
    def self.build_package_cast(output_dir : String)
      pkg_session = Session.new
      pkg_session.clear_screen

      p_pkg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      pkg_session.type_command("lapis cli -p", p_pkg, 18.0)

      # 1. Interactive TUI Form
      pkg_session.emit(0.2_f64, "#{C_MAGENTA}:: LAPIS PACKAGING & EXPORT CENTER ::#{C_RESET}\r\n")
      pkg_session.emit(0.08_f64, "#{C_DIM}Configure export targets, bundles, optimizations, and release installers#{C_RESET}\r\n")
      pkg_session.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      pkg_session.emit(0.08_f64, "  Target Artifact:     ( ) Playable Game      #{C_GREEN}(*) Portable Executable#{C_RESET}\r\n")
      pkg_session.emit(0.08_f64, "                       ( ) GDExtension Addon  ( ) Windows Installer (.exe)\r\n")
      pkg_session.emit(0.08_f64, "  Release Mode:        #{C_GREEN}[X] Optimized (--release -O3)#{C_RESET}\r\n")
      pkg_session.emit(0.08_f64, "  Bundle Deps:         #{C_GREEN}[X] Include runtime DLLs (gc.dll, crystal_bridge.dll)#{C_RESET}\r\n")
      pkg_session.emit(0.08_f64, "  Destination Dir:     [ bin/release_dist ]\r\n")
      pkg_session.emit(0.08_f64, "  Release Version:     [ 1.0.0 ]\r\n")
      pkg_session.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      pkg_session.emit(0.12_f64, "  #{C_CYAN}Tab / ↑↓: Navigate Fields │ Space: Toggle Option │ Enter: Start Build │ Esc: Back#{C_RESET}\r\n\r\n")
      pkg_session.pause(4.0)

      # 2. Build Execution inside TUI
      pkg_session.emit(0.3_f64, "#{C_CYAN}[Build]#{C_RESET} Compiling release binary with LLVM -O3 optimizations...\r\n")
      pkg_session.spinner("Running Crystal compiler with --release -O3 --no-debug...", frames_count: 36, delay: 0.08)
      pkg_session.spinner_done("Compiled bin/game.dll (2.1 MB) & bin/game.exe in 2.1s")

      pkg_session.emit(0.2_f64, "#{C_MAGENTA}[GDPC]#{C_RESET} Injecting 12-byte GDPC trailer for standalone single-file binary...\r\n")
      pkg_session.progress_bar("Embedding PCK payload", total_steps: 12, step_delay: 0.32) do |step|
        pct = (step * 100) // 12
        "#{pct}% (offset 0x0041B000)"
      end
      pkg_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Appended GDPC magic trailer [0x43504447]\r\n")
      pkg_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Output: #{C_BOLD}bin/release_dist/VoidRunner.exe#{C_RESET} (SHA-256: 8a4f91b7e402...)\r\n\r\n")
      pkg_session.pause(3.2)

      # 3. Direct CLI Command execution
      pkg_session.type_command("lapis package game --portable --embed-pck --release -n VoidRunner", p_pkg, 18.0)
      pkg_session.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Turnkey standalone executable packaged (zero external dependencies)!\r\n")
      pkg_session.pause(7.5)
      pkg_session.save(File.join(output_dir, "lapis_package.cast"), 86, 20, "Lapis Portable Packaging with GDPC Trailer")
    end

    # 7. Addon Management (Slide 32) - ~30.0s
    def self.build_addon_install_cast(output_dir : String)
      addon_session = Session.new
      addon_session.clear_screen

      p_addon = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      addon_session.type_command("lapis addon search combat", p_addon, 18.0)
      addon_session.emit(0.2_f64, "#{C_CYAN}[Addon:Search]#{C_RESET} Searching community ecosystem for 'combat'...\r\n")
      addon_session.emit(0.1_f64, "  #{C_GREEN}► sol-vin/combat_system@v1.2#{C_RESET}  - Deterministic combat state machine (GDExtension)\r\n\r\n")
      addon_session.pause(3.5)

      addon_session.type_command("lapis addon install github:sol-vin/combat_system@v1.2", p_addon, 18.0)

      addon_session.emit(0.2_f64, "#{C_CYAN}[Addon:Resolve]#{C_RESET} Resolving GitHub release asset for windows-x86_64...\r\n")
      addon_session.spinner("Downloading precompiled binary package...", frames_count: 36, delay: 0.08)
      addon_session.spinner_done("Downloaded combat_system-windows.zip (1.4 MB)")

      addon_session.emit(0.2_f64, "#{C_MAGENTA}[Addon:Audit]#{C_RESET} Inspecting GDExtension binary headers & symbols...\r\n")
      addon_session.spinner("Validating x86_64 PE export directory & symbols...", frames_count: 30, delay: 0.08)
      addon_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Entrypoint verified: combat_system_init (x86_64 ABI v1)\r\n")
      addon_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Hardening check: ASLR enabled, DEP/NX enabled, 0 poison hooks\r\n")

      addon_session.emit(0.2_f64, "#{C_YELLOW}[Shards:Negotiator]#{C_RESET} Checking multi-addon shard dependencies...\r\n")
      addon_session.spinner("Negotiating transitive shard versions...", frames_count: 34, delay: 0.08)
      addon_session.spinner_done("Negotiated crshader v0.2 across 5 addons: 0 conflicts")

      addon_session.spinner("Synthesizing typed Crystal bindings for combat_system...", frames_count: 30, delay: 0.08)
      addon_session.spinner_done("Generated src/bindings/combat_system.cr")

      addon_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Extracted to addons/combat_system/\r\n")
      addon_session.emit(0.1_f64, "  #{C_GREEN}✓#{C_RESET} Enabled in project.godot (extension_list.cfg updated)\r\n")
      addon_session.pause(3.2)
      addon_session.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}✓ Addon 'combat_system' installed successfully! Ready with autocomplete.#{C_RESET}\r\n")
      addon_session.pause(7.5)
      addon_session.save(File.join(output_dir, "lapis_addon_install.cast"), 86, 20, "Lapis Addon Management & Shard Negotiation")
    end

    # 7b. Persistent Editor Launcher & Supervisor (Slide 33b) - ~31.0s
    def self.build_editor_launcher_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis cli -e", p1, 18.0)

      # TUI Supervisor Header & Panes
      sess.emit(0.2_f64, "#{C_CYAN}:: LAPIS EDITOR SUPERVISOR & LIVE LOG WATCHER ::#{C_RESET}      Project: void_runner\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.08_f64, "┌─ Process Status ────────┐ Log Stream #{C_DIM}[Auto-Scroll: ON] (148 lines)#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ State:      #{C_GREEN}[RUNNING]#{C_RESET}   │ #{C_BLUE}[GODOT]#{C_RESET} Godot Engine v4.8.0.custom_build\r\n")
      sess.emit(0.08_f64, "│ PID:        18420       │ #{C_CYAN}[LAPIS]#{C_RESET} Initialized Crystal bridge DLL\r\n")
      sess.emit(0.08_f64, "│ Uptime:     42s         │ #{C_GREEN}[GAME]#{C_RESET}  Player initialized: CharacterBody3D\r\n")
      sess.emit(0.08_f64, "│ Reloads:    3           │ #{C_GREEN}[GAME]#{C_RESET}  Emitted signal: health_changed (100)\r\n")
      sess.emit(0.08_f64, "├─ Quick Actions ─────────┤ #{C_MAGENTA}[LAPIS]#{C_RESET} Recompiling game.dll on F5 save...\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}[ R ]#{C_RESET} Build & Reload    │ #{C_CYAN}[LAPIS]#{C_RESET} Shadow copy loaded: game_18420_1048.dll\r\n")
      sess.emit(0.08_f64, "│ #{C_RED}[ K ]#{C_RESET} Graceful Kill     │ #{C_GREEN}[GAME]#{C_RESET}  Reload complete in 184ms\r\n")
      sess.emit(0.08_f64, "│ #{C_DIM}[ C ]#{C_RESET} Clear Log Stream  │ #{C_BLUE}[GODOT]#{C_RESET} Scene re-instantiated successfully\r\n")
      sess.emit(0.08_f64, "└─────────────────────────┘\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_CYAN}R: Recompile & Reload │ K: Kill Editor │ Space: Scroll Lock │ Esc: Return#{C_RESET}\r\n\r\n")
      sess.pause(4.0)

      # Trigger R (Hot-recompile action)
      sess.emit(0.3_f64, "#{C_MAGENTA}[Supervisor]#{C_RESET} Hot-reload key [R] triggered. Recompiling game.dll...\r\n")
      sess.spinner("Compiling game library with shadow timestamp...", frames_count: 32, delay: 0.08)
      sess.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Recompiled in 192ms. Shadow DLL swapped: game_18420_1049.dll\r\n\r\n")
      sess.pause(3.5)

      # Graceful Kill
      sess.emit(0.3_f64, "#{C_YELLOW}[Supervisor]#{C_RESET} Key [K] received: Gracefully terminating editor process 18420...\r\n")
      sess.spinner("Sending termination signal & cleaning shadow DLLs...", frames_count: 28, delay: 0.08)
      sess.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Editor process cleanly shutdown. 0 memory leaks, 0 dangling hooks.\r\n\r\n")
      sess.pause(3.5)

      # Direct command
      sess.type_command("lapis editor --path .", p1, 18.0)
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Editor]#{C_RESET} Godot Editor spawned (PID 18424) with active Crystal bridge.\r\n")
      sess.pause(7.5)
      sess.save(File.join(output_dir, "lapis_editor_launcher.cast"), 86, 20, "Lapis Editor Supervisor & Log Watcher")
    end

    # 8. Side-by-Side Decompile & Native Debug (Slide 34c) - ~31.0s
    def self.build_debug_workflows_cast(output_dir : String)
      dbg_session = Session.new
      dbg_session.clear_screen

      p_dbg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      
      # 1. Editor under radare2 with gutter breakpoints
      dbg_session.type_command("lapis editor --debug -p template --quit-after=12", p_dbg, 18.0)
      dbg_session.emit(0.2_f64, "#{C_MAGENTA}[Lapis]#{C_RESET} Spawning Godot Editor v4.8.0-dev6 under radare2 supervisor...\r\n")
      dbg_session.emit(0.1_f64, "#{C_CYAN}[r2]#{C_RESET} Attaching to target PID 14208 (godot.windows.editor.x86_64.exe)\r\n")
      dbg_session.emit(0.1_f64, "#{C_CYAN}[r2]#{C_RESET} Binding Gutter Breakpoints from src/player_controller.cr:24...\r\n")
      dbg_session.emit(0.3_f64, "#{C_GREEN}[Godot]#{C_RESET} Engine core initialized. Loading GDExtension 'bin/crystal_bridge.dll'...\r\n")
      dbg_session.emit(0.3_f64, "#{C_GREEN}[Godot]#{C_RESET} Scene tree started: res://scenes/main.tscn\r\n\r\n")
      dbg_session.pause(2.0)

      dbg_session.emit(0.2_f64, "#{C_BOLD}#{C_RED}[r2 BREAKPOINT HIT]#{C_RESET} Process 14208 paused at #{C_BOLD}#{C_YELLOW}src/player_controller.cr:24#{C_RESET}\r\n")
      dbg_session.emit(0.1_f64, "  #{C_CYAN}Function:#{C_RESET} PlayerController#_physics_process(delta=0.016667)\r\n")
      dbg_session.emit(0.1_f64, "  #{C_CYAN}Instruction:#{C_RESET} 0x14001a449: cmp byte [rcx + 0x48], 1 (on_floor? == true)\r\n")
      dbg_session.pause(2.0)

      r2_prompt = "#{C_BOLD}#{C_MAGENTA}[0x14001a449]> #{C_RESET}"
      dbg_session.type_command("dr rip rcx", r2_prompt, 18.0)
      dbg_session.emit(0.2_f64, "rip = 0x00007ff6a481a449\r\nrcx = 0x000001a43b2e9040 (PlayerController instance)\r\n")
      dbg_session.pause(2.0)

      dbg_session.type_command("ds 2", r2_prompt, 18.0)
      dbg_session.emit(0.2_f64, "Stepped 2 instructions. Now at 0x14001a44f.\r\n")
      dbg_session.pause(2.0)

      dbg_session.type_command("dc", r2_prompt, 18.0)
      dbg_session.emit(0.2_f64, "Continuing execution...\r\n")
      dbg_session.pause(3.0)
      dbg_session.emit(0.2_f64, "#{C_YELLOW}[Lapis]#{C_RESET} Auto-quit timer expired (12s). Exiting Godot Editor cleanly...\r\n")
      dbg_session.emit(0.2_f64, "  #{C_GREEN}✔#{C_RESET} Editor session closed cleanly (Exit Code: 0)\r\n\r\n")
      dbg_session.pause(2.5)

      # 2. Standalone monitor & synthetic crash triage
      dbg_session.type_command("lapis run -d --monitor -p template", p_dbg, 18.0)
      dbg_session.emit(0.2_f64, "#{C_MAGENTA}[Lapis]#{C_RESET} Launching standalone game runner with real-time TUI telemetry...\r\n")
      dbg_session.pause(2.0)

      dbg_session.emit(0.2_f64, "\r\n#{C_BOLD}#{C_RED}[CRASH INTERCEPTED] EXCEPTION_ACCESS_VIOLATION (0xC0000005)#{C_RESET}\r\n")
      dbg_session.emit(0.1_f64, "#{C_MAGENTA}[Crash Forensics]#{C_RESET} Classifying boundary fault...\r\n")
      dbg_session.emit(0.1_f64, "  #{C_YELLOW}Faulting Address:#{C_RESET} 0x0000000000000008 (Illegal Read at Null Pointer + 0x8)\r\n")
      dbg_session.emit(0.1_f64, "  #{C_YELLOW}Boundary Class  :#{C_RESET} #{C_BOLD}#{C_RED}[GameCode]#{C_RESET} (Fault originated in user game logic)\r\n")
      dbg_session.emit(0.1_f64, "  #{C_YELLOW}Engine State    :#{C_RESET} #{C_GREEN}[GDExtensionBridge UNCORRUPTED]#{C_RESET} (0 engine leaks)\r\n")
      dbg_session.emit(0.1_f64, "  #{C_YELLOW}Stack Origin    :#{C_RESET} src/my_node.cr:42 in 'MyNode#on_enemy_hit'\r\n")
      dbg_session.emit(0.1_f64, "  #{C_GREEN}✔ Snapshot staged:#{C_RESET} log/crash.log (Full backtrace dumped)\r\n\r\n")
      dbg_session.pause(4.0)

      # 3. Tail crash log
      dbg_session.type_command("lapis log tail crash -n 12", p_dbg, 18.0)
      dbg_session.emit(0.2_f64, "#{C_BOLD}=== log/crash.log (Most Recent Backtrace Snapshot) ===#{C_RESET}\r\n")
      dbg_session.emit(0.1_f64, "  Frame #0: 0x140024108 in MyNode#on_enemy_hit at src/my_node.cr:42\r\n")
      dbg_session.emit(0.1_f64, "  Frame #1: 0x140023840 in Signal#emit at src/libgodot/signals.cr:96\r\n")
      dbg_session.emit(0.1_f64, "  Frame #2: 0x140019200 in Enemy#take_damage at src/enemy.cr:18\r\n")
      dbg_session.emit(0.1_f64, "  Cause: Attempted to call '.health' on nil 'enemy_target' variable\r\n")
      dbg_session.emit(0.1_f64, "  Resolution: Add safe navigation: 'enemy_target.try(&.health)'\r\n")
      dbg_session.pause(8.0)

      dbg_session.save(File.join(output_dir, "lapis_debug_workflows.cast"), 86, 22, "Lapis Debug Helper & Side-by-Side Decompilation")
    end

    # 9. Multi-Channel Log Triage & Fuzzy Search (Slide 34d) - ~31.0s
    def self.build_log_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis log tail all -f", p1, 18.0)

      sess.emit(0.2_f64, "#{C_DIM}[10:32:01.104]#{C_RESET} #{C_BLUE}[GODOT]  #{C_RESET} Server initialized on port 7777 (UDP/ENet)\r\n")
      sess.emit(1.2_f64, "#{C_DIM}[10:32:01.118]#{C_RESET} #{C_MAGENTA}[CRYSTAL]#{C_RESET} GC heap initialized (Boehm-Demers-Weiser v8.2.6)\r\n")
      sess.emit(1.2_f64, "#{C_DIM}[10:32:01.125]#{C_RESET} #{C_GREEN}[GAME]   #{C_RESET} Player spawned: Player<CharacterBody3D#1482>\r\n")
      sess.emit(1.2_f64, "#{C_DIM}[10:32:01.210]#{C_RESET} #{C_MAGENTA}[CRYSTAL]#{C_RESET} Signal emitted: health_changed(current: 95, max: 100)\r\n")
      sess.emit(1.2_f64, "#{C_DIM}[10:32:01.450]#{C_RESET} #{C_GREEN}[GAME]   #{C_RESET} HealthPickup collected: player hp restored to 100\r\n\r\n")
      sess.pause(3.0)

      sess.emit(0.2_f64, "^C\r\n")
      sess.pause(1.5)

      sess.type_command("lapis log --interactive", p1, 18.0)
      sess.emit(0.2_f64, "#{C_CYAN}┌─ Log Inspector: all (2,841 lines) ──────────────────────────────────────────────┐#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ Filter: #{C_YELLOW}health#{C_RESET}                                                                  │\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}#{C_GREEN}> [10:32:01.210] [CRYSTAL] Signal: health_changed(current: 95, max: 100)#{C_RESET}        │\r\n")
      sess.emit(0.08_f64, "│   [10:32:01.450] [GAME]    HealthPickup collected by player                     │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}├─ Context Preview (Line 412) ────────────────────────────────────────────────────┤#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ #{C_DIM}410: [10:32:01.205] [GAME] Damage received: 5 dmg from SpikeHazard#{C_RESET}             │\r\n")
      sess.emit(0.08_f64, "│ #{C_DIM}411: [10:32:01.208] [CRYSTAL] Player#take_damage: hp decremented to 95#{C_RESET}        │\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}412: [10:32:01.210] [CRYSTAL] Signal emitted: health_changed(current: 95, max: 100)#{C_RESET}│\r\n")
      sess.emit(0.08_f64, "│ #{C_DIM}413: [10:32:01.212] [GODOT] UI HealthBar updated: value = 95%#{C_RESET}                 │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}└─────────────────────────────────────────────────────────────────────────────────┘#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_DIM}[↑↓] Select Line  [Enter] Full Context  [/] Refilter  [q] Exit#{C_RESET}\r\n")
      sess.pause(4.5)

      # Refilter
      sess.emit(0.2_f64, "#{ESC}[1A\r  #{C_CYAN}[Filter]#{C_RESET} Press [/]: Refiltering by channel: #{C_YELLOW}channel:godot#{C_RESET}\r\n")
      sess.pause(3.5)

      # Exit
      sess.emit(0.2_f64, "q\r\n")
      sess.pause(7.5)
      sess.save(File.join(output_dir, "lapis_log.cast"), 86, 20, "Lapis Multi-Channel Log Triage & Fuzzy Search")
    end

    # 9b. Runtime Performance Monitor (Slide 34e) - ~31.5s
    def self.build_run_monitor_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      sess.type_command("lapis cli -r", p1, 18.0)

      # Telemetry Dashboard
      sess.emit(0.2_f64, "#{C_YELLOW}:: LAPIS RUNTIME PERFORMANCE MONITOR ::#{C_RESET} │ Status: #{C_GREEN}[#] RUNNING (PID 9420)#{C_RESET}\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}Target: bin/game.exe │ Uptime: 01:24 │ FPS: 60.0 │ RAM: 48.2 MB (Peak: 52.4 MB)#{C_RESET}\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.08_f64, "┌─ Frame Rate (FPS) ─────────────┐ ┌─ Memory Allocation (MB) ────────┐\r\n")
      sess.emit(0.08_f64, "│ 120 ┤                          │ │ 100 ┤                           │\r\n")
      sess.emit(0.08_f64, "│  90 ┤                          │ │  75 ┤                           │\r\n")
      sess.emit(0.08_f64, "│  60 ┼───────────────────────── │ │  50 ┼────────────────────────── │\r\n")
      sess.emit(0.08_f64, "│  30 ┤                          │ │  25 ┤   #{C_CYAN}▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄#{C_RESET} │\r\n")
      sess.emit(0.08_f64, "│   0 ┴───────────────────────── │ │   0 ┴────────────────────────── │\r\n")
      sess.emit(0.08_f64, "│     14:20:00          14:20:30 │ │     14:20:00           14:20:30 │\r\n")
      sess.emit(0.08_f64, "└────────────────────────────────┘ └─────────────────────────────────┘\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}──────────────────────────────────────────────────────────────────────────────────#{C_RESET}\r\n")
      sess.emit(0.12_f64, "  #{C_CYAN}Ctrl+K / K: Terminate Process │ R: Restart │ Esc / Q: Exit Monitor#{C_RESET}\r\n\r\n")
      sess.pause(4.5)

      # Live Chart update (GC cycle: RAM drops to 38.1 MB)
      sess.emit(0.2_f64, "#{C_MAGENTA}[Telemetry]#{C_RESET} Crystal Boehm GC cycle completed: RAM reclaimed 10.3 MB (now: 38.1 MB)\r\n")
      sess.pause(3.5)

      # Hotkey Restart [R]
      sess.emit(0.3_f64, "#{C_CYAN}[Monitor]#{C_RESET} Hotkey [R] received: Restarting standalone host process...\r\n")
      sess.spinner("Recycling process handle & zeroing memory...", frames_count: 32, delay: 0.08)
      sess.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Process restarted cleanly in 210ms (new PID: 9428, port 7777)\r\n\r\n")
      sess.pause(3.0)

      # Graceful Kill
      sess.emit(0.3_f64, "#{C_YELLOW}[Monitor]#{C_RESET} Hotkey [K] received: Sending graceful termination signal...\r\n")
      sess.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Process 9428 cleanly terminated. Peak RAM: 48.2 MB. 0 memory leaks.\r\n\r\n")
      sess.pause(3.5)

      # Direct command
      sess.type_command("lapis run", p1, 18.0)
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Run]#{C_RESET} Launching standalone host game bin/game.exe...\r\n")
      sess.pause(7.5)
      sess.save(File.join(output_dir, "lapis_run_monitor.cast"), 86, 20, "Lapis Runtime Performance Monitor")
    end

    # 9c. Multi-Target Synchronization (Slide 34f) - ~30.5s
    def self.build_sync_targets_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      p1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/lapis#{C_RESET}$ "
      sess.type_command("lapis sync --verbose", p1, 18.0)

      sess.emit(0.2_f64, "#{C_CYAN}[Sync]#{C_RESET} Synchronizing multi-target workspace binaries & manifests...\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}┌───────────────────────┬────────────┬──────────┬───────────────────────┐#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ #{C_BOLD}Target Workspace#{C_RESET}      │ #{C_BOLD}Bridge DLL#{C_RESET} │ #{C_BOLD}Game DLL#{C_RESET} │ #{C_BOLD}Dependencies Synced#{C_RESET}   │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}├───────────────────────┼────────────┼──────────┼───────────────────────┤#{C_RESET}\r\n")
      sess.emit(0.08_f64, "│ root (Host Game)      │ 2.4 MB #{C_GREEN}✔#{C_RESET}   │ 4.1 MB #{C_GREEN}✔#{C_RESET} │ gc.dll, libgodot.dll  │\r\n")
      sess.emit(0.08_f64, "│ test/bin (Test Suite) │ 2.4 MB #{C_GREEN}✔#{C_RESET}   │ 3.8 MB #{C_GREEN}✔#{C_RESET} │ gc.dll, libgodot.dll  │\r\n")
      sess.emit(0.08_f64, "│ template/bin (Game)   │ 2.4 MB #{C_GREEN}✔#{C_RESET}   │ 2.1 MB #{C_GREEN}✔#{C_RESET} │ gc.dll, libgodot.dll  │\r\n")
      sess.emit(0.08_f64, "│ examples/basic_demo   │ 2.4 MB #{C_GREEN}✔#{C_RESET}   │ 3.2 MB #{C_GREEN}✔#{C_RESET} │ gc.dll, libgodot.dll  │\r\n")
      sess.emit(0.08_f64, "#{C_CYAN}└───────────────────────┴────────────┴──────────┴───────────────────────┘#{C_RESET}\r\n\r\n")
      sess.pause(4.5)

      sess.emit(0.2_f64, "#{C_YELLOW}[Sync:DAG]#{C_RESET} Topologically sorting 4 addon manifests...\r\n")
      sess.spinner("Resolving dependency DAG & version constraints...", frames_count: 34, delay: 0.08)
      sess.spinner_done("Dependency DAG resolved: [crshader -> combat_system -> ui_kit]")

      sess.spinner("Verifying SHA256 checksums across 4 output DLLs...", frames_count: 32, delay: 0.08)
      sess.spinner_done("Checksums matched across all target trees")

      sess.spinner("Checking gc.dll, pcre2-8.dll, libgodot.dll staging...", frames_count: 30, delay: 0.08)
      sess.spinner_done("Runtime staging clean")

      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} extension_list.cfg load order updated (0 cyclic dependencies)\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Windows shadow lock check: 0 locked files across all 4 targets\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Staged runtime dependencies (gc.dll, pcre2-8.dll, libgodot.dll)\r\n")
      sess.pause(3.2)
      sess.emit(0.2_f64, "#{C_BOLD}#{C_GREEN}[Sync:OK]#{C_RESET} 4 workspace targets fully synchronized in 340ms! (0 files locked)\r\n")
      sess.pause(11.0)
      sess.save(File.join(output_dir, "lapis_sync_targets.cast"), 86, 20, "Lapis Multi-Target Workspace Synchronization")
    end

    # 10. Performance Benchmarks TUI (Slide 35c) - ~31.5s
    def self.build_benchmarks_cast(output_dir : String)
      bench_session = Session.new
      p_bench = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      bench_session.type_command("lapis benchmarks --tui", p_bench, 22.0)

      b_logs = [] of String
      b_logs << "#{C_CYAN}► Category: Compute Simulation (LLVM AVX2)#{C_RESET}"
      bench_session.emit(0.3_f64, render_bench_tui_frame(5, 0, b_logs, initial: true))

      b_logs << "GDScript: 184.2 ms │ Crystal: 3.1 ms #{C_BOLD}#{C_GREEN}[ 59.4x ]#{C_RESET}"
      bench_session.emit(1.1_f64, render_bench_tui_frame(20, 1, b_logs))

      b_logs << "GDScript:  92.4 ms │ Crystal: 2.8 ms #{C_BOLD}#{C_GREEN}[ 33.0x ]#{C_RESET}"
      bench_session.emit(1.1_f64, render_bench_tui_frame(35, 2, b_logs))

      b_logs << "GDScript:  64.8 ms │ Crystal: 4.2 ms #{C_BOLD}#{C_GREEN}[ 15.4x ]#{C_RESET}"
      bench_session.emit(1.1_f64, render_bench_tui_frame(50, 3, b_logs))

      b_logs << "GDScript:  45.6 ms │ Crystal: 5.1 ms #{C_BOLD}#{C_GREEN}[  8.9x ]#{C_RESET}"
      bench_session.emit(1.1_f64, render_bench_tui_frame(65, 4, b_logs))

      b_logs << "GDScript:  38.1 ms │ Crystal: 1.4 ms #{C_BOLD}#{C_GREEN}[ 27.2x ]#{C_RESET}"
      bench_session.emit(1.1_f64, render_bench_tui_frame(80, 5, b_logs))

      b_logs << "GDScript: 112.5 ms │ Crystal: 3.9 ms #{C_BOLD}#{C_GREEN}[ 28.8x ]#{C_RESET}"
      bench_session.emit(1.1_f64, render_bench_tui_frame(92, 6, b_logs))

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
      bench_session.emit(1.3_f64, render_bench_tui_frame(100, 7, b_final_logs, all_done: true))

      # Interactive cursor navigation: ↓
      bench_session.emit(1.0_f64, render_bench_tui_frame(100, 0, b_final_logs, all_done: true))

      # Modal Drill-down on 01. N-Body Physics (10k)
      modal_nbody = [
        "  #{C_BOLD}GDScript Baseline#{C_RESET}:  184.2 ms  (Interpreted bytecode, dynamic Variant loops)",
        "  #{C_GREEN}#{C_BOLD}Crystal SIMD AVX2#{C_RESET}:    3.1 ms  (LLVM -O3 autovectorized SIMD registers)",
        "  #{C_MAGENTA}Calculated Speedup#{C_RESET}: 59.4x faster execution",
        "  #{C_CYAN}Throughput#{C_RESET}:         3,225,806 particle interactions / sec",
        "  #{C_CYAN}Memory Allocation#{C_RESET}:  0 B heap allocs / frame (stack-allocated Vector3)",
        "  #{C_CYAN}Instruction Count#{C_RESET}:  GDScript: 4.8M ops  │  Crystal: 82K ops",
        "  #{C_CYAN}L1 Cache Misses#{C_RESET}:    0.4% L1D miss rate (contiguous cache-friendly layout)",
        "  #{C_BOLD}#{C_GREEN}Verification Status: Mathematical parity verified with GDScript baseline ✔#{C_RESET}"
      ]
      bench_session.emit(1.0_f64, render_bench_modal("Benchmark 01: N-Body Physics (10k Particles)", modal_nbody))
      bench_session.pause(2.5)

      # Press Esc -> Return to Dashboard
      bench_session.emit(0.6_f64, render_bench_tui_frame(100, 0, b_final_logs, all_done: true))

      # Navigate down to 03. A* Pathing (1k agents)
      bench_session.emit(0.7_f64, render_bench_tui_frame(100, 1, b_final_logs, all_done: true))
      bench_session.emit(0.7_f64, render_bench_tui_frame(100, 2, b_final_logs, all_done: true))

      # Modal Drill-down on 03. A* Pathing
      modal_astar = [
        "  #{C_BOLD}GDScript Baseline#{C_RESET}:   64.8 ms  (Dictionary open-set, untyped Vector2 array)",
        "  #{C_GREEN}#{C_BOLD}Crystal MinHeap#{C_RESET}:     4.2 ms  (Contiguous binary heap, bitpacked grid nodes)",
        "  #{C_MAGENTA}Calculated Speedup#{C_RESET}: 15.4x faster execution",
        "  #{C_CYAN}Throughput#{C_RESET}:         238,095 agent path traversals / sec",
        "  #{C_CYAN}Heap Allocations#{C_RESET}:   0 B in inner path loop (preallocated grid buffer)",
        "  #{C_CYAN}Memory Footprint#{C_RESET}:   1.2 MB total workspace (vs 18.4 MB GDScript overhead)",
        "  #{C_CYAN}Branch Prediction#{C_RESET}:  99.1% branch hit rate via LLVM static code layout",
        "  #{C_BOLD}#{C_GREEN}Verification Status: Route coordinates match GDScript baseline exactly ✔#{C_RESET}"
      ]
      bench_session.emit(1.0_f64, render_bench_modal("Benchmark 03: A* Pathing (1k Agents)", modal_astar))
      bench_session.pause(2.5)

      # Press Esc -> Return to Dashboard
      bench_session.emit(0.6_f64, render_bench_tui_frame(100, 2, b_final_logs, all_done: true))

      # Navigate down to 05. Matrix 4x4 SIMD (100k)
      bench_session.emit(0.7_f64, render_bench_tui_frame(100, 3, b_final_logs, all_done: true))
      bench_session.emit(0.7_f64, render_bench_tui_frame(100, 4, b_final_logs, all_done: true))

      # Modal Drill-down on 05. Matrix 4x4 SIMD
      modal_matrix = [
        "  #{C_BOLD}GDScript Baseline#{C_RESET}:   38.1 ms  (Transform3D multiplication loop)",
        "  #{C_GREEN}#{C_BOLD}Crystal SIMD AVX2#{C_RESET}:    1.4 ms  (256-bit AVX2 register packing)",
        "  #{C_MAGENTA}Calculated Speedup#{C_RESET}: 27.2x faster execution",
        "  #{C_CYAN}Throughput#{C_RESET}:         71,428,571 matrix multiplications / sec",
        "  #{C_CYAN}Memory Overhead#{C_RESET}:    0 allocs / frame (aligned value-type structs)",
        "  #{C_CYAN}Vector Width#{C_RESET}:       8 single-precision floats per SIMD instruction",
        "  #{C_CYAN}Godot Transform3D#{C_RESET}:  Direct native pointer interop (zero marshalling copy)",
        "  #{C_BOLD}#{C_GREEN}Verification Status: Transform values match Godot Engine C++ baseline ✔#{C_RESET}"
      ]
      bench_session.emit(1.0_f64, render_bench_modal("Benchmark 05: Matrix 4x4 SIMD (100k Transforms)", modal_matrix))
      bench_session.pause(2.5)

      # Return to Dashboard
      bench_session.emit(0.6_f64, render_bench_tui_frame(100, 4, b_final_logs, all_done: true))
      bench_session.emit(0.7_f64, render_bench_tui_frame(100, 5, b_final_logs, all_done: true))
      bench_session.pause(3.5)
      bench_session.save(File.join(output_dir, "lapis_benchmarks_tui.cast"), 86, 19, "Lapis Benchmark Suite ANSI TUI Dashboard")
    end

    # 11. Custom Benchmarking CLI & HTML Report (Slide 70 / 35b_custom_benchmarks) - ~31.0s
    def self.build_custom_benchmarks_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      sess.type_command("lapis benchmarks run --group PathfindingCrowd --chart --html", prompt, 18.0)

      sess.emit(0.2_f64, "#{C_CYAN}[Benchmarks:Build]#{C_RESET} Compiling benchmark harness with AVX2 SIMD...\r\n")
      sess.spinner("Compiling benchmark suite with -O3 -s...", frames_count: 36, delay: 0.08)
      sess.spinner_done("Harness compiled in 0.94s (AVX2 SIMD vectorization enabled)")

      sess.emit(0.2_f64, "#{C_YELLOW}[Benchmarks:Warmup]#{C_RESET} Executing warmup iterations...\r\n")
      sess.spinner("Warming up JIT cache and thread pool (10 iterations)...", frames_count: 34, delay: 0.08)
      sess.spinner_done("Warmup complete • Cache primed")

      sess.emit(0.2_f64, "#{C_MAGENTA}[Benchmarks:Run]#{C_RESET} Profiling 'PathfindingCrowd' (5,000 active agents)...\r\n")
      sess.progress_bar("Executing iterations", total_steps: 12, step_delay: 0.35) do |step|
        "Iter #{step}/12 (#{step * 5}k samples)"
      end

      # Comparison Results Table (fixed line length <= 86 cols)
      sess.emit(0.2_f64, "\r\n#{C_BOLD}Benchmark Results: PathfindingCrowd (5,000 Agents)#{C_RESET}\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}┌──────────────────────────┬──────────────┬────────────────┬───────────┐#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{C_BOLD}Implementation#{C_RESET}           │ #{C_BOLD}Median Time#{C_RESET}  │ #{C_BOLD}Throughput#{C_RESET}     │ #{C_BOLD}Speedup#{C_RESET}   │\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}├──────────────────────────┼──────────────┼────────────────┼───────────┤#{C_RESET}\r\n")
      sess.emit(0.06_f64, "│ #{C_BOLD}#{C_GREEN}Crystal (SIMD AVX2)#{C_RESET}      │     #{C_GREEN}0.82 ms#{C_RESET}  │  6,097 agt/fr  │ #{C_BOLD}#{C_GREEN}15.4x 🚀#{C_RESET}  │\r\n")
      sess.emit(0.06_f64, "│ GDScript (Baseline)      │    12.63 ms  │    395 agt/fr  │ 1.0x (ref)│\r\n")
      sess.emit(0.06_f64, "#{C_CYAN}└──────────────────────────┴──────────────┴────────────────┴───────────┘#{C_RESET}\r\n")

      # Visual outputs
      sess.spinner("Generating high-DPI SVG comparison charts...", frames_count: 30, delay: 0.08)
      sess.emit(0.15_f64, "  #{C_GREEN}✔#{C_RESET} Rendered SVG comparison chart: #{C_CYAN}reports/benchmarks/pathfinding_crowd.svg#{C_RESET}\r\n")
      sess.emit(0.15_f64, "  #{C_GREEN}✔#{C_RESET} Generated interactive HTML: #{C_CYAN}reports/benchmarks/pathfinding_crowd.html#{C_RESET}\r\n")
      sess.pause(3.5)
      sess.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}[Success]#{C_RESET} Custom benchmark group complete! Report open in browser.\r\n")
      sess.pause(7.5)
      sess.save(File.join(output_dir, "lapis_custom_benchmarks.cast"), 86, 19, "Lapis Custom Benchmark Execution & HTML Report")
    end

    # 12. Multiplayer Test Simulation Harness (Slide 26f) - ~31.0s
    def self.build_multiplayer_test_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      sess.type_command("lapis test spec/suites/test_multiplayer.cr", prompt, 18.0)

      sess.emit(0.2_f64, "#{C_CYAN}[Multiplayer:Harness]#{C_RESET} Spinning up simulated topology (1 Server, 2 Clients)...\r\n")
      sess.spinner("Initializing in-memory ENet mesh and virtual peer sockets...", frames_count: 36, delay: 0.08)
      sess.spinner_done("Server (peer 1), Client 1 (peer 2), Client 2 (peer 3) connected")

      sess.emit(0.18_f64, "#{C_YELLOW}[Multiplayer:Input]#{C_RESET} Pumping virtual actions & RPC dispatches...\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Client 1 injected input action: :attack (pressed: true)\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Client 1 dispatched reliable RPC: apply_damage(35) to server\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Client 2 synchronized transform state: Vector3(12.4, 0.0, -8.1)\r\n")

      sess.emit(0.2_f64, "#{C_MAGENTA}[Multiplayer:Lockstep]#{C_RESET} Stepping 3 network & physics frame ticks...\r\n")
      sess.spinner("Synchronously advancing frame ticks across all peers...", frames_count: 36, delay: 0.08)
      sess.spinner_done("3 frames stepped synchronously • Server hero health: 65 HP")

      sess.emit(0.2_f64, "#{C_CYAN}[Wireshark:Spy]#{C_RESET} Auditing packet transmissions & bandwidth...\r\n")
      sess.spinner("Auditing Wireshark packet capture ring buffer...", frames_count: 32, delay: 0.08)
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Verified RPC transmission: from: 2, to: 1, method: apply_damage\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Bandwidth cap verified: 1.2 KB/s (threshold: < 10.0 KB/s)\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Packet delivery: 100% reliable, channel 0, 0 retransmits\r\n")

      sess.emit(0.2_f64, "#{C_YELLOW}[Multiplayer:Anomaly]#{C_RESET} Checking network jitter & forensics triggers...\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Latency jitter: 0.8 ms (well below 50.0 ms threshold)\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Zero-leak check: 0 leaked multiplayer peer allocations\r\n")
      sess.pause(3.5)
      sess.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}ALL MULTIPLAYER TESTS PASSED (7 tests, 28 assertions, 0 flakiness)#{C_RESET}\r\n")
      sess.pause(12.5)
      sess.save(File.join(output_dir, "lapis_multiplayer_test.cast"), 86, 19, "Lapis Multiplayer Simulation & Wireshark Spy Auditing")
    end

    # 13. Headless Editor Driver Testing (Slide 36b) - ~31.5s
    def self.build_editor_driver_cast(output_dir : String)
      sess = Session.new
      sess.clear_screen

      prompt = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/game#{C_RESET}$ "
      sess.type_command("lapis test spec/editor_driver_spec.cr", prompt, 18.0)

      sess.emit(0.2_f64, "#{C_CYAN}[EditorDriver]#{C_RESET} Launching headless Godot Editor...\r\n")
      sess.spinner("Starting godot --headless --editor --audio-driver Dummy...", frames_count: 36, delay: 0.08)
      sess.spinner_done("Headless editor running (PID 18492, audio: Dummy, rendering: opengl3)")

      sess.emit(0.18_f64, "#{C_YELLOW}[EditorDriver:Tool]#{C_RESET} Verifying in-editor @tool nodes...\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} ToolTester2D & ToolTester3D mounted in scene viewport\r\n")
      sess.spinner("Simulating editor UI inspector click on @[ExportToolButton]...", frames_count: 30, delay: 0.08)
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Clicked @[ExportToolButton(\"Reset Stats\")] programmatically\r\n")
      sess.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} InspectorPlugin: Custom property editor layout & dock verified\r\n")

      sess.emit(0.2_f64, "#{C_MAGENTA}[EditorDriver:HotReload]#{C_RESET} Stress-testing live GDExtension reload cycles...\r\n")
      sess.spinner("Reload Cycle 1/3: recompiling bin/game.dll under active editor...", frames_count: 28, delay: 0.08)
      sess.spinner_done("Cycle 1/3: Shadow loaded game_8421_1.dll in 0.38s (0 file locks)")

      sess.spinner("Reload Cycle 2/3: recompiling bin/game.dll under active editor...", frames_count: 28, delay: 0.08)
      sess.spinner_done("Cycle 2/3: Shadow loaded game_8421_2.dll in 0.35s (0 file locks)")

      sess.spinner("Reload Cycle 3/3: recompiling bin/game.dll under active editor...", frames_count: 28, delay: 0.08)
      sess.spinner_done("Cycle 3/3: Shadow loaded game_8421_3.dll in 0.36s (0 file locks)")

      sess.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Zero dead pointers, zero access violations, exit code 0\r\n")
      sess.pause(3.5)
      sess.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}ALL EDITOR TESTS PASSED (5 tests, 18 assertions, 0 leaks)#{C_RESET}\r\n")
      sess.pause(10.0)
      sess.save(File.join(output_dir, "lapis_editor_driver.cast"), 86, 19, "Lapis Headless Editor Testing & Reload Cycles")
    end

    # 14. Demo 1: Scaffold & Windows Hot Reload (Slide 41b) - ~31.0s
    def self.build_demo_scaffold_cast(output_dir : String)
      demo1_session = Session.new
      demo1_session.clear_screen

      p_demo1 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects#{C_RESET}$ "
      demo1_session.type_command("lapis init dungeon_crawl --template=3d-action", p_demo1, 18.0)
      demo1_session.spinner("Scaffolding 3D Action template with Crystal bindings...", frames_count: 36, delay: 0.08)
      demo1_session.spinner_done("Created project.godot, shard.yml, src/main.cr, scenes/")
      demo1_session.emit(0.15_f64, "#{C_GREEN}✓#{C_RESET} Scaffolding complete! Initialized 'dungeon_crawl'.\r\n\r\n")
      demo1_session.pause(3.5)

      p_demo1_sub = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      demo1_session.type_command("lapis editor", p_demo1_sub, 18.0)
      demo1_session.emit(0.25_f64, "#{C_GREEN}✓#{C_RESET} Godot 4.8-dev6 launched (GDExtension bridge loaded)\r\n")
      demo1_session.emit(0.2_f64, "#{C_CYAN}[Editor]#{C_RESET} Dynamic shadow hot-reloading active.\r\n\r\n")
      demo1_session.pause(3.5)

      demo1_session.emit(0.5_f64, "#{C_DIM}# [Editing src/player.cr: modified speed = 12.0_f32, pressed F5]#{C_RESET}\r\n")
      demo1_session.emit(0.25_f64, "#{C_CYAN}[EditorPlugin]#{C_RESET} F5 rebuild triggered: compiling bin/game.dll...\r\n")
      demo1_session.spinner("Compiling game library with LLVM incremental flags...", frames_count: 34, delay: 0.08)
      demo1_session.emit(0.3_f64, "#{C_MAGENTA}[Bridge]#{C_RESET} Timestamped shadow loaded: game_8421_1727641200.dll\r\n")
      demo1_session.pause(3.5)
      demo1_session.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}✓ 0 file locks on Windows • Game reloaded in 0.42s!#{C_RESET}\r\n")
      demo1_session.pause(8.0)
      demo1_session.save(File.join(output_dir, "lapis_demo_scaffold.cast"), 86, 19, "Lapis Demo: Scaffolding & Windows Hot Reload")
    end

    # 15. Demo 3: Installing CrShader Addon (Slide 41e) - ~30.5s
    def self.build_demo_install_addon_cast(output_dir : String)
      demo3_session = Session.new
      demo3_session.clear_screen

      p_demo3 = "#{C_BOLD}#{C_GREEN}dev@lapis#{C_RESET}:#{C_BLUE}~/game#{C_RESET}$ "
      demo3_session.type_command("lapis install addon github:sol-vin/crshader --shard --bind", p_demo3, 18.0)

      demo3_session.emit(0.25_f64, "#{C_CYAN}[Addon]#{C_RESET} Resolving 'github:sol-vin/crshader' from GitHub Releases...\r\n")
      demo3_session.spinner("Downloading precompiled crshader release...", frames_count: 36, delay: 0.08)
      demo3_session.spinner_done("Extracted to addons/crshader/")

      demo3_session.spinner("Verifying cryptographic checksums & release signature...", frames_count: 30, delay: 0.08)
      demo3_session.spinner_done("SHA256 signature verified: 8f2a1b9c4d...")

      demo3_session.emit(0.1_f64, "        ├── crshader.gdextension\r\n")
      demo3_session.emit(0.1_f64, "        ├── plugin.cfg & plugin.gd\r\n")
      demo3_session.emit(0.1_f64, "        └── bin/crshader.dll\r\n")
      demo3_session.emit(0.2_f64, "#{C_CYAN}[Config]#{C_RESET} Auto-enabled 'res://addons/crshader/plugin.cfg' in project.godot\r\n")
      demo3_session.emit(0.25_f64, "#{C_MAGENTA}[Shard]#{C_RESET}  Added dependency to shard.yml:\r\n")
      demo3_session.emit(0.1_f64, "         crshader:\r\n")
      demo3_session.emit(0.1_f64, "           github: sol-vin/crshader\r\n")

      demo3_session.spinner("Synthesizing typed Crystal AST & inline ptrcall dispatches...", frames_count: 32, delay: 0.08)
      demo3_session.emit(0.25_f64, "#{C_YELLOW}[Bind]#{C_RESET}   Generated typed Crystal API: src/bindings/crshader.cr\r\n")
      demo3_session.emit(0.2_f64, "#{C_CYAN}[Sync]#{C_RESET}   Synchronized bridge & runtime DLLs across bin/\r\n")
      demo3_session.pause(3.5)
      demo3_session.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}✓ CrShader v0.2.0 installed & ready with full Crystal autocomplete!#{C_RESET}\r\n")
      demo3_session.pause(12.5)
      demo3_session.save(File.join(output_dir, "lapis_demo_install_addon.cast"), 86, 19, "Lapis Demo: Ecosystem Addon Installation")
    end

    # 16. Demo 5: Release Build & Distribution Packaging (Slide 41g) - ~32.0s
    def self.build_demo_package_cast(output_dir : String)
      demo5_session = Session.new
      demo5_session.clear_screen

      p_demo5 = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/dungeon_crawl#{C_RESET}$ "
      demo5_session.type_command("lapis build --release --opt=3", p_demo5, 18.0)

      demo5_session.emit(0.25_f64, "#{C_CYAN}[Lapis]#{C_RESET} Compiling release binaries with -O3 -s...\r\n")
      demo5_session.spinner("Running Crystal compiler with LLVM -O3 optimizations...", frames_count: 36, delay: 0.08)
      demo5_session.spinner_done("Compiled bin/game.dll (2.1 MB) & bin/game.exe (3.4 MB) in 2.1s")
      demo5_session.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Stripped debug symbols & elided trace logging\r\n\r\n")
      demo5_session.pause(3.2)

      demo5_session.type_command("lapis package game --release -n DungeonCrawl", p_demo5, 18.0)
      demo5_session.progress_bar("Bundling Godot PCK archive", total_steps: 10, step_delay: 0.30) do |step|
        "#{step * 10}% (dist/DungeonCrawl.pck)"
      end
      demo5_session.spinner("Staging gc.dll, pcre2-8.dll, libgodot.dll into package...", frames_count: 28, delay: 0.08)
      demo5_session.spinner_done("Runtime staging clean")

      demo5_session.spinner("Computing cryptographic SHA-256 integrity hash...", frames_count: 28, delay: 0.08)
      demo5_session.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} Created dist/DungeonCrawl-windows-x64.zip (48.2 MB)\r\n")
      demo5_session.emit(0.15_f64, "  #{C_GREEN}✓#{C_RESET} SHA256: 8a4f91b7e41c30d43a7582e... verified\r\n")
      demo5_session.pause(3.5)
      demo5_session.emit(0.25_f64, "#{C_BOLD}#{C_GREEN}✓ Ready to ship to Steam, itch.io, or direct download!#{C_RESET}\r\n")
      demo5_session.pause(8.0)
      demo5_session.save(File.join(output_dir, "lapis_demo_package.cast"), 86, 19, "Lapis Demo: Release Build & Distribution Packaging")
    end

    # 21. Radare2 Crystal Runtime Inspection (Slide 34g) - ~31.0s
    def self.build_r2_crystal_cast(output_dir : String)
      session = Session.new
      session.clear_screen

      p_dbg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      session.type_command("lapis decompile bin/game.dll --crystal", p_dbg, 18.0)

      session.emit(0.2_f64, "#{C_CYAN}┌─ Crystal Runtime Reflection & Symbol Demangling (cradare2) ──────────────────┐#{C_RESET}\r\n")
      session.emit(0.08_f64, "│ #{C_BOLD}Target:#{C_RESET} bin/game.dll (x86_64-windows-msvc)    #{C_BOLD}Entry:#{C_RESET} 0x140001080             │\r\n")
      session.emit(0.08_f64, "│ #{C_BOLD}Runtime:#{C_RESET} Crystal v1.20+ [Execution Contexts]  #{C_BOLD}Boehm GC:#{C_RESET} Active (GC_malloc)   │\r\n")
      session.emit(0.08_f64, "#{C_CYAN}├──────────────────────────────────────────────────────────────────────────────┤#{C_RESET}\r\n")
      session.emit(0.08_f64, "│ Discovered Crystal Classes (3 registered nodes):                             │\r\n")
      session.emit(0.08_f64, "│   • #{C_GREEN}Player < CharacterBody3D#{C_RESET}       (14 methods, 4 exports, 2 signals)        │\r\n")
      session.emit(0.08_f64, "│   • #{C_GREEN}EnemySpawner < Node3D#{C_RESET}          (8 methods, 3 exports, 1 signal)          │\r\n")
      session.emit(0.08_f64, "│   • #{C_GREEN}GameHUD < CanvasLayer#{C_RESET}          (11 methods, 6 exports, 3 signals)        │\r\n")
      session.emit(0.08_f64, "#{C_CYAN}└──────────────────────────────────────────────────────────────────────────────┘#{C_RESET}\r\n\r\n")
      session.pause(3.5)

      session.type_command("r2 -q0 bin/game.dll", p_dbg, 18.0)
      session.emit(0.2_f64, "#{C_DIM}[cradare2:memory]#{C_RESET} Direct in-memory inspection of runtime Crystal structures:\r\n")
      session.pause(0.8)
      session.emit(0.08_f64, ">> #{C_YELLOW}cradare2.crystal.read_string(0x140040200)#{C_RESET}\r\n")
      session.emit(0.08_f64, "   #{C_CYAN}[String @ 0x140040200]#{C_RESET} type_id: 1, bytesize: 11, length: 11\r\n")
      session.emit(0.08_f64, "   Value: #{C_GREEN}\"Void Runner\"#{C_RESET} (UTF-8 buffer @ 0x14004020c)\r\n\r\n")
      session.pause(2.0)

      session.emit(0.08_f64, ">> #{C_YELLOW}cradare2.crystal.read_array_header(0x140040500)#{C_RESET}\r\n")
      session.emit(0.08_f64, "   #{C_CYAN}[Array(Int32) @ 0x140040500]#{C_RESET} type_id: 48, size: 4, capacity: 8\r\n")
      session.emit(0.08_f64, "   Buffer Pointer: 0x140040520 (elements: [100, 250, 500, 1000])\r\n\r\n")
      session.pause(2.0)

      session.emit(0.08_f64, ">> #{C_YELLOW}cradare2.crystal.read_slice_header(0x140040600)#{C_RESET}\r\n")
      session.emit(0.08_f64, "   #{C_CYAN}[Slice(UInt8) @ 0x140040600]#{C_RESET} size: 64, read_only: false\r\n")
      session.emit(0.08_f64, "   Buffer Pointer: 0x140040620 (stack-allocated flat memory)\r\n\r\n")
      session.pause(2.0)

      session.emit(0.08_f64, ">> #{C_YELLOW}db \"sym.Player#_physics_process:Float64\"#{C_RESET}\r\n")
      session.emit(0.08_f64, "   #{C_GREEN}✓#{C_RESET} Breakpoint #1 set at Player#_physics_process(Float64) (0x1400021b0)\r\n")
      session.pause(14.0)
      session.save(File.join(output_dir, "lapis_r2_crystal.cast"), 86, 22, "Radare2 Crystal Runtime Inspection & In-Memory Structures")
    end

    # 22. Radare2 Godot Engine Internals (Slide 34h) - ~32.0s
    def self.build_r2_godot_cast(output_dir : String)
      session = Session.new
      session.clear_screen

      p_r2 = "#{C_BOLD}#{C_MAGENTA}[0x140001080]>#{C_RESET} "
      session.emit(0.1_f64, "#{C_DIM}# Radare2 Godot Engine Dual-Target Plugin Suite#{C_RESET}\r\n")
      session.type_command("godot detect", p_r2, 18.0)

      session.emit(0.15_f64, "Godot Engine Integration Status:\r\n")
      session.emit(0.06_f64, "  Engine Core:        #{C_GREEN}libgodot.dll (Godot 4.8.0-custom)#{C_RESET}\r\n")
      session.emit(0.06_f64, "  GDExtension Bridge: #{C_GREEN}crystal_bridge.dll (API v4.3)#{C_RESET}\r\n")
      session.emit(0.06_f64, "  Game Logic DLL:     #{C_GREEN}game.dll [ALIVE]#{C_RESET}\r\n")
      session.emit(0.06_f64, "  Precision Mode:     float64/float32 mixed\r\n\r\n")
      session.pause(2.5)

      session.type_command("godot object rcx", p_r2, 18.0)
      session.emit(0.15_f64, "Godot Object @ 0x0000021b3759c2f0:\r\n")
      session.emit(0.06_f64, "  VTable:       0x00007ffb12340000 (CharacterBody3D::vftable)\r\n")
      session.emit(0.06_f64, "  Instance ID:  #{C_BOLD}4120894102#{C_RESET} (0x155f9a696) [Monotonic 64-bit]\r\n")
      session.emit(0.06_f64, "  User Data:    0x0000021b38001000 (Crystal Player instance)\r\n")
      session.emit(0.06_f64, "  Class Name:   Player < CharacterBody3D\r\n")
      session.emit(0.06_f64, "  Status:       #{C_BOLD}#{C_GREEN}[ALIVE] Registered in ObjectDB#{C_RESET}\r\n\r\n")
      session.pause(3.0)

      session.type_command("godot variant rdx", p_r2, 18.0)
      session.emit(0.15_f64, "Godot Variant @ 0x0000004f210080:\r\n")
      session.emit(0.06_f64, "  Type:    #{C_CYAN}Vector3 (9)#{C_RESET}\r\n")
      session.emit(0.06_f64, "  Value:   (12.5, 0.0, -4.2)\r\n")
      session.emit(0.06_f64, "  Summary: Vector3(x: 12.5, y: 0.0, z: -4.2)\r\n\r\n")
      session.pause(2.5)

      session.type_command("godot types", p_r2, 18.0)
      session.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Registered Godot formats: pf.godot_object, pf.godot_variant, pf.godot_vector3\r\n")
      session.emit(0.08_f64, ">> #{C_YELLOW}pf.godot_vector3 @ 0x0000004f210088#{C_RESET}\r\n")
      session.emit(0.08_f64, "   0x0000004f210088 = struct godot_vector3 { x: 12.5, y: 0.0, z: -4.2 }\r\n\r\n")
      session.pause(2.0)

      session.type_command("godot classdb Player", p_r2, 18.0)
      session.emit(0.15_f64, "Discovered ClassDB Schema (reconstructed without PDBs):\r\n")
      session.emit(0.06_f64, "  - #{C_GREEN}Player < CharacterBody3D#{C_RESET} (0x140002000)\r\n")
      session.emit(0.06_f64, "      def #{C_CYAN}_ready#{C_RESET} @ 0x140002100 | def #{C_CYAN}_physics_process#{C_RESET} @ 0x1400021b0\r\n")
      session.emit(0.06_f64, "      def #{C_CYAN}take_damage#{C_RESET} @ 0x140002340 (args: 1, return: Void)\r\n")
      session.pause(12.5)
      session.save(File.join(output_dir, "lapis_r2_godot.cast"), 86, 22, "Radare2 Godot Engine Plugin & ObjectDB Variant Decoders")
    end

    # 23. Radare2 Lapis Supervisor & Crash Forensics (Slide 34i) - ~32.0s
    def self.build_r2_lapis_cast(output_dir : String)
      session = Session.new
      session.clear_screen

      p_dbg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      session.emit(0.1_f64, "#{C_BOLD}#{C_RED}[CRASH INTERCEPTED] Exception 0xC0000005 (Access Violation) at 0x1400021b4#{C_RESET}\r\n")
      session.pause(1.5)

      session.type_command("lapis supervisor diagnose", p_dbg, 18.0)
      session.emit(0.15_f64, "#{C_CYAN}=== Editor Supervisor Crash Diagnosis ===#{C_RESET}\r\n")
      session.emit(0.06_f64, "Faulting PC:      #{C_BOLD}0x1400021b4#{C_RESET}\r\n")
      session.emit(0.06_f64, "Faulting Module:  bin/game.dll (offset 0x21b4)\r\n")
      session.emit(0.06_f64, "Fault Boundary:   #{C_BOLD}#{C_YELLOW}GameCode#{C_RESET} (User Gameplay Logic)\r\n")
      session.emit(0.06_f64, "Classification:   Dereferencing dead or deallocated pointer\r\n\r\n")
      session.pause(3.0)

      session.type_command("lapis dead-pointers", p_dbg, 18.0)
      session.spinner("Scanning CPU registers and active stack frames...", frames_count: 24, delay: 0.08)
      session.emit(0.15_f64, "\r\n#{C_BOLD}#{C_RED}CRITICAL HAZARD: 1 dead pointer detected in CPU registers!#{C_RESET}\r\n")
      session.emit(0.06_f64, "  • Register #{C_CYAN}RCX#{C_RESET}: 0x0000021b3759c2f0 (target: Player)\r\n")
      session.emit(0.06_f64, "  • Instance ID:  #{C_BOLD}4120894102#{C_RESET} (FREED in ObjectDB via queue_free!)\r\n")
      session.emit(0.06_f64, "  • Fix: #{C_GREEN}Use node.check_alive! or node.alive? before method dispatch#{C_RESET}\r\n\r\n")
      session.pause(3.5)

      session.type_command("lapis stale-vtables", p_dbg, 18.0)
      session.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} Zero stale vtables detected across all active module boundaries.\r\n")
      session.emit(0.06_f64, "  All VTables point cleanly to active shadow DLL (game_loaded_14820_172774.dll).\r\n\r\n")
      session.pause(2.5)

      session.type_command("lapis map src", p_dbg, 18.0)
      session.emit(0.12_f64, "  #{C_GREEN}✓#{C_RESET} SourceIndexer: Injected 14 nodes, 52 properties, and 18 signals into r2.\r\n")
      session.pause(14.0)
      session.save(File.join(output_dir, "lapis_r2_lapis.cast"), 86, 22, "Radare2 Lapis Supervisor & Dead-Pointer Forensics")
    end

    # 24. Radare2 TUI Debugger Dashboard (Slide 34j) - ~33.0s
    def self.build_r2_tui_debugger_cast(output_dir : String)
      session = Session.new
      session.clear_screen

      p_dbg = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      session.type_command("lapis decompile bin/game.dll --tui", p_dbg, 18.0)
      session.clear_screen(0.05)

      # Draw full double-buffered TUI window
      session.emit(0.05_f64, "#{C_CYAN}┌─ :: RADARE2 NATIVE DEBUGGER & FORENSICS :: ───────────── [MODE: INTERACTIVE] ─┐#{C_RESET}\r\n")
      session.emit(0.03_f64, "│ #{C_BOLD}Disassembly (pdf)#{C_RESET}                 │ #{C_BOLD}Pseudo-C (pdc)#{C_RESET}          │ #{C_BOLD}CPU Registers#{C_RESET}     │\r\n")
      session.emit(0.03_f64, "│ #{C_DIM}0x1400021b0#{C_RESET}  push rbp             │ #{C_BLUE}int64_t#{C_RESET} Player::proc() {│ RAX: #{C_YELLOW}0x140001080#{C_RESET}  │\r\n")
      session.emit(0.03_f64, "│ #{C_DIM}0x1400021b1#{C_RESET}  mov rbp, rsp         │   #{C_MAGENTA}if#{C_RESET} (!this->alive())   │ RBX: #{C_DIM}0x000000064#{C_RESET}  │\r\n")
      session.emit(0.03_f64, "│ #{C_GREEN}=>0x1400021b4#{C_RESET} call sym.check_alive │     raise_disposed();   │ RCX: #{C_CYAN}0x21b3759c2f0#{C_RESET}│\r\n")
      session.emit(0.03_f64, "│ #{C_DIM}0x1400021b9#{C_RESET}  movss xmm0, [rdx]    │   vel = get_vel() * dt; │ RDX: #{C_DIM}0x00004f21008#{C_RESET}│\r\n")
      session.emit(0.03_f64, "│ #{C_DIM}0x1400021bd#{C_RESET}  call sym.move_slide  │   #{C_MAGENTA}return#{C_RESET} move_slide();  │ RIP: #{C_BOLD}#{C_GREEN}0x1400021b4#{C_RESET}  │\r\n")
      session.emit(0.03_f64, "│ #{C_DIM}0x1400021c2#{C_RESET}  pop rbp              │ }                       │ RSP: #{C_DIM}0x000000df810#{C_RESET}│\r\n")
      session.emit(0.03_f64, "│ #{C_DIM}0x1400021c3#{C_RESET}  ret                  │                         │ EFLAGS: #{C_DIM}0x00000246#{C_RESET} │\r\n")
      session.emit(0.03_f64, "#{C_CYAN}├───────────────────────────────────┴─────────────────────────┴───────────────────┤#{C_RESET}\r\n")
      session.emit(0.03_f64, "│ Callstack: #0 0x1400021b4 in Player#_physics_process at src/player.cr:42       │\r\n")
      session.emit(0.03_f64, "│ Memory: 0x21b3759c2f0 │ VTable: 0x7ffb12340000 │ ObjectID: 4120894102 [ALIVE]  │\r\n")
      session.emit(0.03_f64, "#{C_CYAN}└─ [s: Step │ c: Continue │ r: Registers │ f: Hexdump │ ?: Help │ q: Exit] ───────┘#{C_RESET}\r\n")
      session.pause(4.0)

      # Simulate stepping
      session.emit(0.2_f64, "#{C_YELLOW}[Command] Step instruction (F10 / 's') -> RIP advanced to 0x1400021b9#{C_RESET}\r\n")
      session.pause(3.5)

      # Simulate Crash Auto-Swap
      session.emit(0.2_f64, "\r\n#{C_BOLD}#{C_RED}┌─ [CRASH] RADARE2 CRASH FORENSICS [AUTO-SWAP ACTIVE] ───────────────────────────┐#{C_RESET}\r\n")
      session.emit(0.05_f64, "│ #{C_RED}FAULT: 0xC0000005 (ACCESS_VIOLATION) at RIP 0x1400021b4 [game.dll]#{C_RESET}            │\r\n")
      session.emit(0.05_f64, "│ Boundary: #{C_YELLOW}GameCode#{C_RESET} │ Dereferenced dead Object #4120894102 in RCX                 │\r\n")
      session.emit(0.05_f64, "#{C_BOLD}#{C_RED}└────────────────────────────────────────────────────────────────────────────────┘#{C_RESET}\r\n")
      session.pause(21.0)
      session.save(File.join(output_dir, "lapis_r2_tui_debugger.cast"), 86, 22, "Radare2 Interactive TUI Debugger & Crash Forensics Auto-Swap")
    end

    def self.build_interactive_studio_cast(output_dir : String)
      session = Session.new
      session.clear_screen

      p = "#{C_BOLD}#{C_GREEN}developer@lapis-dev#{C_RESET}:#{C_BLUE}~/projects/void_runner#{C_RESET}$ "
      session.type_command("lapis explore src/", p, 18.0)
      session.pause(2.0)
      session.type_command("lapis driver repl", p, 18.0)
      session.pause(2.0)
      session.type_command("lapis cli", p, 18.0)
      session.pause(5.0)
      session.save(File.join(output_dir, "lapis_interactive_studio.cast"), 86, 22, "Lapis Interactive Terminal Studio (Explore, Driver REPL, TUI Hub)")
    end

    def self.build_docs_cli_tui_cast(output_dir : String)
      session = Session.new
      session.clear_screen

      p = "#{C_BOLD}#{C_GREEN}ian@workstation#{C_RESET}:#{C_BLUE}~/lapis/template#{C_RESET}$ "
      session.type_command("lapis docs lookup gd \"CharacterBody3D.move_and_slide\"", p, 20.0)
      session.pause(2.2)
      session.type_command("lapis docs lookup stdlib \"Channel\"", p, 20.0)
      session.pause(2.2)
      session.type_command("lapis docs search \"concurrency\"", p, 20.0)
      session.pause(2.2)
      session.type_command("lapis docs tui", p, 20.0)
      session.pause(10.0)
      session.save(File.join(output_dir, "lapis_docs_cli_tui.cast"), 86, 22, "Lapis Docs CLI & Interactive TUI Explorer")
    end

    def self.build_all(output_dir : String)
      Dir.mkdir_p(output_dir)
      build_test_runner_cast(output_dir)
      build_cli_lifecycle_cast(output_dir)
      build_fuzzy_palette_cast(output_dir)
      build_doctor_cast(output_dir)
      build_scaffold_wizard_cast(output_dir)
      build_bind_cast(output_dir)
      build_package_cast(output_dir)
      build_addon_install_cast(output_dir)
      build_editor_launcher_cast(output_dir)
      build_debug_workflows_cast(output_dir)
      build_log_cast(output_dir)
      build_run_monitor_cast(output_dir)
      build_sync_targets_cast(output_dir)
      build_benchmarks_cast(output_dir)
      build_custom_benchmarks_cast(output_dir)
      build_multiplayer_test_cast(output_dir)
      build_editor_driver_cast(output_dir)
      build_demo_scaffold_cast(output_dir)
      build_demo_install_addon_cast(output_dir)
      build_demo_package_cast(output_dir)
      build_r2_crystal_cast(output_dir)
      build_r2_godot_cast(output_dir)
      build_r2_lapis_cast(output_dir)
      build_r2_tui_debugger_cast(output_dir)
      build_interactive_studio_cast(output_dir)
      build_docs_cli_tui_cast(output_dir)
    end
  end
end

if PROGRAM_NAME.includes?("cast_builder")
  output_dir = ARGV.size > 0 ? ARGV[0] : File.expand_path("casts", Dir.current)
  LapisSlides::CastBuilder.build_all(output_dir)
end
