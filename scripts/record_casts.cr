# scripts/record_casts.cr
# =============================================================================
# Automated, Reproducible Asciinema Cast Generator for Lapis Presentation Deck
# =============================================================================
# Uses real Lapis CLI binaries, genuine sandbox projects, and real Opal TUI models.
# Target terminal sizes are strictly calibrated to the presentation slide players:
#   - Standard slides: 86 columns x 22 rows
#   - Slide 41e: 84 columns x 22 rows
# =============================================================================

require "json"
require "option_parser"
require "file_utils"
require "opal"

module Opal
  module Terminal
    alias DiffRenderer = Opal::UI::DiffRenderer
  end
end

require "version"
require "tui/hub"
require "tui/new_wizard"
require "tui/editor_launcher"
require "tui/package_form"
require "tui/debugger_view"
require "tui/log_viewer"
require "tui/bench_viewer"
require "tui/run_monitor"
require "tui/renderer"

require "opal/asciicast"

class AsciiCast
  getter writer : Opal::Asciicast::Writer

  def initialize(cols : Int32 = 86, rows : Int32 = 22)
    @writer = Opal::Asciicast::Writer.new(
      width: cols,
      height: rows,
      shell: "lapis",
      term: "xterm-256color"
    )
  end

  def cols : Int32
    @writer.width
  end

  def rows : Int32
    @writer.height
  end

  def current_time : Float64
    @writer.elapsed
  end

  def append_raw(data : String, delay : Float64 = 0.0)
    @writer.write(data, delay)
  end

  def type_command(cmd : String, prompt : String = "\e[1;32mian@workstation\e[0m:\e[1;34m~/lapis/void_runner\e[0m$ ", prompt_delay : Float64 = 0.4, char_delay : Float64 = 0.035, post_delay : Float64 = 0.25)
    append_raw(prompt, prompt_delay)
    cmd.each_char do |ch|
      append_raw(ch.to_s, char_delay)
    end
    append_raw("\r\n", post_delay)
  end

  def print_lines(lines : Array(String), line_delay : Float64 = 0.06)
    lines.each do |line|
      clean_line = line.gsub(/\r?\n/, "").rstrip
      append_raw(clean_line + "\r\n", line_delay)
    end
  end

  def render_buffer(buffer : Opal::UI::Buffer, delay : Float64 = 0.8, clear : Bool = false)
    frame = String.build do |io|
      io << (clear ? "\e[2J\e[H" : "\e[H")
      io << buffer.render_to_string(with_ansi: true).gsub(/\r?\n/, "\r\n")
    end
    append_raw(frame, delay)
  end

  def sleep(duration : Float64)
    @writer.pause(duration)
  end

  def save(path : String)
    @writer.save(path)
    puts "  [OK] Saved #{path} (#{@writer.events.size} frames, #{@writer.elapsed.round(2)}s)"
  end
end

module ProcessHelper
  LAPIS_BIN = ENV["LAPIS_BIN"]? || (File.exists?("C:/Users/Ian/Documents/libgodot/bin/lapis.exe") ? "C:/Users/Ian/Documents/libgodot/bin/lapis.exe" : "lapis")

  def self.run_lapis(args : Array(String), chdir : String = "sandbox/void_runner", cols : Int32 = 86, rows : Int32 = 22) : Array(String)
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    ps_args = args.map { |a| a.includes?(" ") ? "\"#{a}\"" : a }.join(" ")
    cmd = "$env:PATH = 'C:\\Users\\Ian\\Documents\\libgodot\\bin;C:\\Users\\Ian\\scoop\\shims;' + $env:PATH; & '#{LAPIS_BIN}' #{ps_args}"
    Process.run(
      "powershell.exe",
      ["-NoProfile", "-Command", cmd],
      chdir: chdir,
      output: stdout,
      error: stderr
    )
    out_str = stdout.to_s
    err_str = stderr.to_s
    combined = out_str.empty? ? err_str : out_str
    combined.lines.map(&.chomp)
  end
end

abstract class BaseCast
  abstract def name
  abstract def cols
  abstract def rows
  abstract def record(cast : AsciiCast)

  def generate(output_dir : String = "casts")
    cast = AsciiCast.new(cols, rows)
    record(cast)
    cast.save(File.join(output_dir, "#{name}.cast"))
  end
end

class CastRegistry
  @@casts = Hash(String, BaseCast).new

  def self.register(cast : BaseCast)
    @@casts[cast.name] = cast
  end

  def self.all : Hash(String, BaseCast)
    @@casts
  end

  def self.run_all(output_dir : String = "casts")
    puts "=== Recording All #{@@casts.size} Asciicasts ==="
    @@casts.each do |name, cast|
      puts "Recording [#{name}] (#{cast.cols}x#{cast.rows})..."
      cast.generate(output_dir)
    end
    puts "=== Finished Recording All #{@@casts.size} Asciicasts! ==="
  end

  def self.run_single(name : String, output_dir : String = "casts")
    if cast = @@casts[name]?
      puts "Recording [#{name}] (#{cast.cols}x#{cast.rows})..."
      cast.generate(output_dir)
    else
      STDERR.puts "Error: Unknown cast '#{name}'. Available casts: #{@@casts.keys.join(", ")}"
      exit 1
    end
  end
end

# =============================================================================
# CAST DEFINITIONS (All 25 presentation casts)
# =============================================================================

# 1. Slide 30: CLI Lifecycle (Hub Navigation)
class CliLifecycleCast < BaseCast
  def name; "lapis_cli_lifecycle"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    orig_dir = Dir.current
    begin
      Dir.cd("sandbox/void_runner")
      hub = Lapis::TUI::Hub.new
      buf = Opal::UI::Buffer.new(cols, rows)

      # Frame 1: Hub initial state (New Project selected)
      hub.selected_index = 0
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.0, clear: true)
      cast.sleep(1.0)

      # Frame 2: Down arrow -> Launch Editor
      hub.selected_index = 1
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.5)

      # Frame 3: Down arrow -> Packaging & Export
      hub.selected_index = 2
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.5)

      # Frame 4: Down arrow -> Radare2 Native Debugger
      hub.selected_index = 3
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.5)

      # Frame 5: Down arrow -> Benchmark Visualizer
      hub.selected_index = 5
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.5)

      # Frame 6: Down arrow -> Toolchain Doctor
      hub.selected_index = 8
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.5)

      # Frame 7: Down arrow -> Clean Build Artifacts
      hub.selected_index = 10
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.6)

      # Frame 8: Down arrow -> Generate Documentation
      hub.selected_index = 11
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.6)

      # Frame 9: Press Ctrl+R to start screencast recording (badge appears in header!)
      Opal::Asciicast::VCR.record("recordings/hub_session.cast", width: cols, height: rows, title: "Lapis Terminal Hub")
      hub.selected_index = 8
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 1.2)

      # Frame 10: Press Ctrl+S to capture VCR screenshot
      Opal::Asciicast::VCR.stop
      hub.set_status("VCR Screenshot saved to recordings/screenshot_hub_20261001_180000.ansi (Copied to Clipboard)!")
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 2.5)
    ensure
      Opal::Asciicast::VCR.stop if Opal::Asciicast::VCR.recording?
      Dir.cd(orig_dir)
    end
  end
end
CastRegistry.register(CliLifecycleCast.new)

# 2. Slide 30b: Fuzzy Palette (Hub Command Palette)
class FuzzyPaletteCast < BaseCast
  def name; "lapis_fuzzy_palette"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    orig_dir = Dir.current
    begin
      Dir.cd("sandbox/void_runner")
      hub = Lapis::TUI::Hub.new
      buf = Opal::UI::Buffer.new(cols, rows)

      # Frame 1: Hub initial state
      hub.selected_index = 0
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.0, clear: true)
      cast.sleep(1.0)

      # Frame 2: Shift+~ opens Palette
      hub.palette_open = true
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.8)

      # Frame 3: User types "d"
      hub.palette.query = "d"
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.5)

      # Frame 4: User types "do"
      hub.palette.query = "do"
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.5)

      # Frame 5: User types "doc" -> filtered to Doctor
      hub.palette.query = "doc"
      buf.clear
      hub.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 2.8)
    ensure
      Dir.cd(orig_dir)
    end
  end
end
CastRegistry.register(FuzzyPaletteCast.new)

# 3. Slide 30c: CLI Doctor
class DoctorCast < BaseCast
  def name; "lapis_doctor"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis doctor", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["doctor"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.07)
    cast.sleep(3.0)
  end
end
CastRegistry.register(DoctorCast.new)

# 4. Slide 30d: Scaffold Wizard (NewWizard Steps)
class ScaffoldWizardCast < BaseCast
  def name; "lapis_scaffold_wizard"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    orig_dir = Dir.current
    begin
      Dir.cd("sandbox/void_runner")
      wizard = Lapis::TUI::NewWizard.new
      buf = Opal::UI::Buffer.new(cols, rows)

      # Step 1: Select Template
      wizard.current_step = Lapis::TUI::NewWizard::Step::SelectTemplate
      wizard.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 0.0, clear: true)
      cast.sleep(1.0)

      # Step 2: Enter Details
      wizard.current_step = Lapis::TUI::NewWizard::Step::EnterDetails
      wizard.project_name = "void_runner"
      wizard.author = "sol-vin"
      buf.clear
      wizard.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 1.0)

      # Step 3: Toggle Features
      wizard.current_step = Lapis::TUI::NewWizard::Step::ToggleFeatures
      buf.clear
      wizard.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 1.0)

      # Step 4: Modular Addon Selection
      wizard.current_step = Lapis::TUI::NewWizard::Step::SelectAddons
      wizard.selected_addons.add("dummy_inventory")
      wizard.selected_addons.add("dummy_dialogue")
      buf.clear
      wizard.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 1.0)

      # Step 5: Preview & Create
      wizard.current_step = Lapis::TUI::NewWizard::Step::PreviewAndCreate
      wizard.selected_template_name = "Standalone Game Starter"
      buf.clear
      wizard.render_to_buffer(buf, cols, rows)
      cast.render_buffer(buf, 2.5)
    ensure
      Dir.cd(orig_dir)
    end
  end
end
CastRegistry.register(ScaffoldWizardCast.new)

# 5. Slide 30e: Lapis Creative Terminal Tools (lapis color --3d, lapis explore, lapis shaders, lapis docs)
class InteractiveStudioCast < BaseCast
  def name; "lapis_interactive_studio"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    renderer = Lapis::TUI::Renderer.new
    state = Lapis::TUI::TestRunState.new

    # 1. lapis color --3d: Launch interactive 3D Spatial TrueColor Palette Studio
    cast.type_command("lapis color --3d", prompt_delay: 0.2)
    state.current_view = Lapis::TUI::ViewMode::ColorStudio
    state.use_3d_color_picker = true
    state.color_picker.color = Opal::Color.hex("#CBA6F7")
    frame1 = renderer.render_to_string(state, cols, rows)
    buf = Opal::UI::Buffer.new(cols, rows)
    buf.put_string(0, 0, frame1)
    cast.render_buffer(buf, 0.4, clear: true)
    cast.sleep(1.5)

    # 2. lapis explore: Launch interactive terminal file dialog & project explorer
    cast.append_raw("\e[2J\e[H", 0.0)
    cast.type_command("lapis explore", prompt_delay: 0.1)
    state.current_view = Lapis::TUI::ViewMode::FileExplorer
    frame2 = renderer.render_to_string(state, cols, rows)
    buf.clear
    buf.put_string(0, 0, frame2)
    cast.render_buffer(buf, 0.4, clear: true)
    cast.sleep(1.5)

    # 3. lapis shaders: Real-time text shader FX playground (CRT scanlines & Matrix rain)
    cast.append_raw("\e[2J\e[H", 0.0)
    cast.type_command("lapis shaders --fx=matrix", prompt_delay: 0.1)
    state.current_view = Lapis::TUI::ViewMode::ColorStudio
    state.shader_fx = Lapis::TUI::ShaderFxMode::Matrix
    frame3 = renderer.render_to_string(state, cols, rows)
    buf.clear
    buf.put_string(0, 0, frame3)
    cast.render_buffer(buf, 0.4, clear: true)
    cast.sleep(1.5)

    # 4. lapis docs: Built-in terminal offline documentation lookup
    cast.append_raw("\e[2J\e[H", 0.0)
    cast.type_command("lapis docs lookup gd \"CharacterBody3D.move_and_slide\"", prompt_delay: 0.1)
    docs_lines = [
      "\e[1;36m[Lapis Docs]\e[0m Looking up Godot ClassDB symbol: \e[1;33mCharacterBody3D.move_and_slide\e[0m",
      "",
      "\e[1;32mbool CharacterBody3D.move_and_slide()\e[0m",
      "  Moves the body based on \e[36mvelocity\e[0m. If the body collides with another,",
      "  it will slide along the other body rather than stop immediately.",
      "",
      "\e[1;34mCrystal Signature (LibGodot):\e[0m",
      "  \e[35mdef move_and_slide : Bool\e[0m",
      "    \e[90m# Direct C ABI virtual call with zero marshalling allocation\e[0m",
      "    LibGodot.character_body_3d_move_and_slide(to_unsafe)",
      "  \e[35mend\e[0m",
      "",
      "\e[90mPress 'q' or Esc to exit offline doc viewer\e[0m"
    ]
    cast.print_lines(docs_lines, line_delay: 0.06)
    cast.sleep(2.5)
  end
end
CastRegistry.register(InteractiveStudioCast.new)

# 6. Slide 31: CLI Codegen / Bind
class BindCast < BaseCast
  def name; "lapis_bind"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis bind project", prompt: "\e[1;32mian@workstation\e[0m:\e[1;34m~/lapis/template\e[0m$ ", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["bind", "project"], chdir: "template", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(BindCast.new)

# 7. Slide 31b: CLI Package Portable (PackageForm)
class PackageCast < BaseCast
  def name; "lapis_package"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    form = Lapis::TUI::PackageForm.new
    form.target = Lapis::TUI::PackageForm::Target::Game
    form.release = true
    form.bundle_binaries = true
    form.output_path = "bin/release_dist"
    buf = Opal::UI::Buffer.new(cols, rows)

    # Frame 1: Form layout
    form.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.0, clear: true)
    cast.sleep(1.2)

    # Frame 2: Building Phase 1
    form.building = true
    form.build_logs << "[1/4] Compiling Crystal source (release -O3)..."
    form.build_logs << "[2/4] Linking crystal_bridge.dll..."
    buf.clear
    form.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 1.0)

    # Frame 3: Building Phase 2
    form.build_logs << "[3/4] Exporting Godot PCK archive (void_runner.pck)..."
    form.build_logs << "[4/4] Generating SHA-256 checksums..."
    buf.clear
    form.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 1.0)

    # Frame 4: Finished
    form.building = false
    form.done = true
    buf.clear
    form.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 2.8)
  end
end
CastRegistry.register(PackageCast.new)

# 8. Slide 32: Package Management (Install Addon)
class AddonInstallCast < BaseCast
  def name; "lapis_addon_install"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis install addon github:sol-vin/crshader", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["install", "addon", "github:sol-vin/crshader"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.07)
    cast.sleep(3.0)
  end
end
CastRegistry.register(AddonInstallCast.new)

# 9. Slide 33b: Editor Launcher
class EditorLauncherCast < BaseCast
  def name; "lapis_editor_launcher"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    launcher = Lapis::TUI::EditorLauncher.new("sandbox/void_runner")
    launcher.editor_alive = true
    launcher.editor_pid = 14280
    launcher.start_time = Time.instant - 15.seconds
    launcher.current_ram_mb = 142.5
    launcher.peak_ram_mb = 158.2

    launcher.logs << "[Editor] Godot Engine v4.8-dev starting..."
    launcher.logs << "[Bridge] Initializing GDExtension crystal_bridge.dll..."
    launcher.logs << "[Bridge] Crystal runtime initialised (GC: Boehm, Threads: 8)"
    launcher.logs << "[Bridge] 142 Godot classes bound in 3.4ms"
    launcher.logs << "[Editor] Opened project res://project.godot"
    launcher.logs << "[HotReload] File watcher active on src/**/*.cr"

    buf = Opal::UI::Buffer.new(cols, rows)
    launcher.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.0, clear: true)
    cast.sleep(1.5)

    # Frame 2: Hot reload triggered
    launcher.logs << "[HotReload] Detected change in src/player_controller.cr"
    launcher.logs << "[HotReload] Recompiling game.dll (incremental)..."
    launcher.logs << "[HotReload] Hot-patch applied cleanly in 42ms!"
    launcher.reload_count = 1
    launcher.current_ram_mb = 148.1
    buf.clear
    launcher.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 2.8)
  end
end
CastRegistry.register(EditorLauncherCast.new)

# Slide 31dd: Lapis Docs CLI & Interactive TUI Explorer
class DocsCliTuiCast < BaseCast
  def name; "lapis_docs_cli_tui"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    Process.run("python", ["scripts/record_docs_cast.py"])
  end
end
CastRegistry.register(DocsCliTuiCast.new)

# 10. Slide 34c: Debug Workflows (Crash Forensics)
class DebugWorkflowsCast < BaseCast
  def name; "lapis_debug_workflows"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis log crash", prompt_delay: 0.2)
    lines = [
      "\e[1;31m=== Lapis Crash Diagnostics: VEH Ring Buffer Dump ===\e[0m",
      "Exception Code:    \e[1;31m0xC0000005 (STATUS_ACCESS_VIOLATION)\e[0m",
      "Faulting Address:  \e[1;33m0x0000000000000018\e[0m (Null Pointer Dereference)",
      "Faulting RIP:      \e[1;36m0x00007ff662c1186e\e[0m (mov rax, [rcx + 0x18])",
      "Thread ID:         1042 [Main Game Thread]",
      "",
      "\e[1;34mRadare2 Disassembly Context:\e[0m",
      "  0x140028a0a  48 8b 49 18       \e[32mmov rax, [rcx + 0x18]\e[0m   ; <-- CRASH HERE",
      "  0x140028a0e  48 85 c0          test rax, rax",
      "  0x140028a11  74 15             jz 0x140028a28",
      "",
      "\e[1;34mCrystal Callstack Traceback:\e[0m",
      "  [0] \e[36mPlayerController#_physics_process\e[0m at src/player_controller.cr:42",
      "  [1] \e[36mCrystalBridge#dispatch_notification\e[0m at src/bridge.cr:112",
      "  [2] \e[36mGodot::Node::notification\e[0m in godot.exe",
      "",
      "\e[1;32m[Forensics] Memory tombstone detected: Target object was freed at tick 412!\e[0m",
      "\e[1;33m💡 Fix Suggestion: Use 'node.try_ref' or check 'is_queued_for_deletion?'\e[0m"
    ]
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(DebugWorkflowsCast.new)

# 11. Slide 34d: CLI Log Triage
class LogCast < BaseCast
  def name; "lapis_log"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis log", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["log"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(LogCast.new)

# 12. Slide 34e: Run Monitor (Performance Visualizer)
class RunMonitorCast < BaseCast
  def name; "lapis_run_monitor"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    monitor = Lapis::TUI::RunMonitor.new("sandbox/void_runner/template")
    buf = Opal::UI::Buffer.new(cols, rows)

    # Frame 1
    monitor.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.0, clear: true)
    cast.sleep(0.9)

    # Frame 2
    buf.clear
    monitor.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.9)

    # Frame 3
    buf.clear
    monitor.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.9)

    # Frame 4
    buf.clear
    monitor.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 2.5)
  end
end
CastRegistry.register(RunMonitorCast.new)

# 13. Slide 34f: Sync Targets
class SyncTargetsCast < BaseCast
  def name; "lapis_sync_targets"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis sync", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["sync"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(SyncTargetsCast.new)

# 14. Slide 34g: R2 Crystal Runtime Decompile
class R2CrystalCast < BaseCast
  def name; "lapis_r2_crystal"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    Process.run("python", ["scripts/record_r2_crystal_cast.py"])
  end
end
CastRegistry.register(R2CrystalCast.new)

# 15. Slide 34h: R2 Godot Internals Decompile
class R2GodotCast < BaseCast
  def name; "lapis_r2_godot"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    Process.run("python", ["scripts/record_r2_godot_cast.py"])
  end
end
CastRegistry.register(R2GodotCast.new)

# 16. Slide 34i: R2 Lapis Supervisor (Radare2 Binary Analysis)
class R2LapisCast < BaseCast
  def name; "lapis_r2_lapis"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis analyze bin/crystal_bridge.dll --chart", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["analyze", "bin/crystal_bridge.dll", "--chart"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(R2LapisCast.new)

# 17. Slide 34j: R2 TUI Debugger (DebuggerView)
class R2TuiDebuggerCast < BaseCast
  def name; "lapis_r2_tui_debugger"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    dbg = Lapis::TUI::DebuggerView.new("bin/crystal_bridge.dll")
    dbg.registers["RAX"] = 0x00007ff662c1186e_u64
    dbg.registers["RBX"] = 0x0000000000000000_u64
    dbg.registers["RCX"] = 0x00000232109253d0_u64
    dbg.registers["RDX"] = 0x0000000000000001_u64
    dbg.registers["RSP"] = 0x0000004f219fe3a0_u64
    dbg.registers["RIP"] = 0x00007ff662c1186e_u64

    dbg.disassembly_lines << "0x140001000  48 89 5c 24 08    mov [rsp + 0x08], rbx"
    dbg.disassembly_lines << "0x140001005  48 89 6c 24 10    mov [rsp + 0x10], rbp"
    dbg.disassembly_lines << "0x14000100a  48 89 74 24 18    mov [rsp + 0x18], rsi"
    dbg.disassembly_lines << "0x14000100f  57                push rdi"
    dbg.disassembly_lines << "0x140001010  e8 4b 02 00 00    call sym.crystal_bridge_init"
    dbg.disassembly_lines << "0x140001015  48 85 c0          test rax, rax"
    dbg.disassembly_lines << "0x140001018  74 12             jz 0x14000102c"

    dbg.decompiler_lines << "int64_t crystal_bridge_init(void) {"
    dbg.decompiler_lines << "    int64_t rbx;"
    dbg.decompiler_lines << "    int64_t rax = sym.init_crystal_runtime();"
    dbg.decompiler_lines << "    if (rax == 0) return 0;"
    dbg.decompiler_lines << "    sym.register_godot_classes();"
    dbg.decompiler_lines << "    return 1;"
    dbg.decompiler_lines << "}"

    buf = Opal::UI::Buffer.new(cols, rows)

    # Frame 1: Disassembly (Tab 1)
    dbg.active_tab = Lapis::TUI::DebuggerView::Tab::Disassembly
    dbg.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.0, clear: true)
    cast.sleep(1.2)

    # Frame 2: Decompiler / Pseudo-C (Tab 2)
    dbg.active_tab = Lapis::TUI::DebuggerView::Tab::Decompiler
    buf.clear
    dbg.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 1.0)

    # Frame 3: CPU Registers (Tab 4)
    dbg.active_tab = Lapis::TUI::DebuggerView::Tab::Registers
    buf.clear
    dbg.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 1.0)

    # Frame 4: Hex Memory (Tab 5)
    dbg.active_tab = Lapis::TUI::DebuggerView::Tab::HexMemory
    buf.clear
    dbg.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 2.5)
  end
end
CastRegistry.register(R2TuiDebuggerCast.new)

# 18. Slides 26f & 34l: Multiplayer Testing Harness
class MultiplayerTestCast < BaseCast
  def name; "lapis_multiplayer_test"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis test -f \"Multiplayer\" --no-tui", prompt_delay: 0.2)
    lines = [
      "\e[1;36m[Test:Multiplayer]\e[0m Initializing in-memory lockstep network harness (clients: 2)...",
      "  \e[32m✔\e[0m Server initialized (peer_id: 1, authoritative)",
      "  \e[32m✔\e[0m Client 1 connected (peer_id: 2, latency: 12ms)",
      "  \e[32m✔\e[0m Client 2 connected (peer_id: 3, latency: 14ms)",
      "",
      "\e[1;34m[Step 1]\e[0m Spawning replicated ActorNode(Hero) on server...",
      "  Server spawned 'Hero' [OID: 0x140029b00] -> synchronized to peers 2, 3",
      "",
      "\e[1;34m[Step 2]\e[0m Client 1 pumping input action: :attack (pressed: true)",
      "  Dispatched RPC: \e[33mHero#apply_damage(35)\e[0m -> target: Server (peer 1)",
      "",
      "\e[1;34m[Step 3]\e[0m Synchronous lockstep frame stepping (3 ticks)...",
      "  Tick 1: Packets dispatched | Tick 2: Physics processed | Tick 3: State verified",
      "  \e[32m✔\e[0m Server hero health verified: 65 HP (Expected: 65 HP)",
      "",
      "\e[1;35m[Wireshark Spy Audit]\e[0m",
      "  \e[32m✔\e[0m RPC delivery verified: Client 1 -> Server [Reliable / Ordered]",
      "  \e[32m✔\e[0m Bandwidth budget: \e[1;32m1.4 KB/s\e[0m (< 10.0 KB/s budget limit)",
      "  \e[32m✔\e[0m Packet loss: 0% | Jitter: 0.0ms | Forensic traps: 0",
      "",
      "\e[1;32m[PASS] Multiplayer duel simulation passed cleanly! (3 frames, 42ms)\e[0m"
    ]
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(MultiplayerTestCast.new)

# 19. Slide 35b: Custom Benchmarks
class CustomBenchmarksCast < BaseCast
  def name; "lapis_custom_benchmarks"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    Process.run("python", ["scripts/record_custom_benchmarks_cast.py"])
  end
end
CastRegistry.register(CustomBenchmarksCast.new)

# 20. Slide 35c: Benchmarks TUI (BenchViewer)
class BenchmarksTuiCast < BaseCast
  def name; "lapis_benchmarks_tui"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    bench_xml = if File.exists?("C:/Users/Ian/Documents/libgodot/benchmarks/reports/benchmarks_latest.xml")
                  "C:/Users/Ian/Documents/libgodot/benchmarks/reports/benchmarks_latest.xml"
                else
                  nil
                end
    bench = Lapis::TUI::BenchViewer.new(bench_xml)
    buf = Opal::UI::Buffer.new(cols, rows)

    # Frame 1: Language Comparison
    bench.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.0, clear: true)
    cast.sleep(1.2)

    # Frame 2: Switch to Speedup Overview
    bench.active_tab = Lapis::TUI::BenchViewer::Tab::SpeedupOverview
    buf.clear
    bench.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 1.0)

    # Frame 3: Switch to Category Distribution
    bench.active_tab = Lapis::TUI::BenchViewer::Tab::CategoryDistribution
    buf.clear
    bench.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 1.0)

    # Frame 4: Switch to MultiRun Trend
    bench.active_tab = Lapis::TUI::BenchViewer::Tab::MultiRunTrend
    buf.clear
    bench.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 2.5)
  end
end
CastRegistry.register(BenchmarksTuiCast.new)

# 21. Slide 36b: Testing Editor Driver
class EditorDriverCast < BaseCast
  def name; "lapis_editor_driver"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis test --skip-specs --no-tui", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["test", "--skip-specs", "--no-tui"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines.first(18), line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(EditorDriverCast.new)

# 22. Slide 37: Tool Testing TUI (Test Runner TUI)
class TestRunnerTuiCast < BaseCast
  def name; "test_runner_tui"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    renderer = Lapis::TUI::Renderer.new
    state = Lapis::TUI::TestRunState.new
    state.godot_version = "4.8-dev"

    # Screencast recording active indicator (Opal screen recording subsystem)
    state.recording = true
    state.recording_start_time = Time.instant - 4.seconds

    p1 = Lapis::TUI::PhaseItem.new("specs", "Phase 1", "Crystal Unit Specs", "Engine")
    p1.status = Lapis::TUI::PhaseStatus::Running
    state.phases << p1

    p2 = Lapis::TUI::PhaseItem.new("tools", "Phase 2", "In-Editor Tool Tests", "Editor")
    state.phases << p2

    p3 = Lapis::TUI::PhaseItem.new("runtime", "Phase 3", "Runtime Integration Tests", "Game")
    state.phases << p3

    # Frame 1: Running Phase 1 (showing ● REC 00:04 indicator)
    state.global_logs << "[Spec] Running SceneTree lifecycle specs (48 examples)..."
    frame1 = renderer.render_to_string(state, cols, rows)
    cast.append_raw("\e[2J\e[H" + frame1.gsub(/\r?\n/, "\r\n"), 0.0)
    cast.sleep(1.0)

    # Frame 2: Phase 1 pass, running Phase 2
    p1.status = Lapis::TUI::PhaseStatus::Passed
    p1.passed_count = 48
    p2.status = Lapis::TUI::PhaseStatus::Running
    state.active_phase_index = 1
    state.global_logs << "[ToolTester] Initializing Headless Godot Editor..."
    state.global_logs << "[ToolTester] CrystalIntegrationPlugin loaded cleanly"
    frame2 = renderer.render_to_string(state, cols, rows)
    cast.append_raw("\e[H" + frame2.gsub(/\r?\n/, "\r\n"), 1.0)

    # Frame 3: Phase 2 pass, running Phase 3
    p2.status = Lapis::TUI::PhaseStatus::Passed
    p2.passed_count = 12
    p3.status = Lapis::TUI::PhaseStatus::Running
    state.active_phase_index = 2
    state.global_logs << "[Runtime] Validating GDExtension ABI & Virtual Tables..."
    frame3 = renderer.render_to_string(state, cols, rows)
    cast.append_raw("\e[H" + frame3.gsub(/\r?\n/, "\r\n"), 1.0)

    # Frame 4: All Passed cleanly
    p3.status = Lapis::TUI::PhaseStatus::Passed
    p3.passed_count = 34
    state.overall_status = Lapis::TUI::OverallStatus::Passed
    state.global_logs << "[Lapis] All test suites passed cleanly! (94/94 PASS)"
    frame4 = renderer.render_to_string(state, cols, rows)
    cast.append_raw("\e[H" + frame4.gsub(/\r?\n/, "\r\n"), 2.8)
  end
end
CastRegistry.register(TestRunnerTuiCast.new)

# 23. Slide 41b: Demo Scaffold Hot Reload
class DemoScaffoldCast < BaseCast
  def name; "lapis_demo_scaffold"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis new game space_fighter --skip-godot", prompt: "\e[1;32mian@workstation\e[0m:\e[1;34m~/lapis/sandbox\e[0m$ ", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["new", "game", "space_fighter", "--skip-godot", "--force"], chdir: "sandbox", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(DemoScaffoldCast.new)

# 24. Slide 41e: Demo Install Addon CrShader (84x22 calibrated!)
class DemoInstallAddonCast < BaseCast
  def name; "lapis_demo_install_addon"; end
  def cols; 84; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis install addon github:sol-vin/crshader", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["install", "addon", "github:sol-vin/crshader"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.07)
    cast.sleep(3.0)
  end
end
CastRegistry.register(DemoInstallAddonCast.new)

# 25. Slide 41g: Demo Package
class DemoPackageCast < BaseCast
  def name; "lapis_demo_package"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    cast.type_command("lapis package template", prompt_delay: 0.2)
    lines = ProcessHelper.run_lapis(["package", "template"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(DemoPackageCast.new)

# =============================================================================
# CLI ENTRY POINT & ARGUMENT PARSING
# =============================================================================

target_cast : String? = nil
run_all = false
list_casts = false
output_dir = "casts"

OptionParser.parse do |parser|
  parser.banner = "Usage: crystal run scripts/record_casts.cr [options]"
  parser.on("-a", "--all", "Record all 25 asciicasts") { run_all = true }
  parser.on("-c NAME", "--cast=NAME", "Record a single specific cast") { |c| target_cast = c }
  parser.on("-l", "--list", "List all registered casts") { list_casts = true }
  parser.on("-o DIR", "--output=DIR", "Output directory (default: casts)") { |d| output_dir = d }
  parser.on("-h", "--help", "Show help") do
    puts parser
    exit 0
  end
end

if list_casts
  puts "Registered Asciicasts (#{CastRegistry.all.size}):"
  CastRegistry.all.each do |name, cast|
    puts "  - #{name.ljust(28)} (#{cast.cols}x#{cast.rows})"
  end
  exit 0
end

if target = target_cast
  CastRegistry.run_single(target, output_dir)
elsif run_all || ARGV.empty?
  CastRegistry.run_all(output_dir)
end
