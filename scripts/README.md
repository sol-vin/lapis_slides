# Asciinema Cast Generation & Reproduction System

This directory contains the automated, 100% genuine Asciinema cast generation system for the Lapis presentation slide deck.

## Zero Simulation Policy
All generated `.cast` files are produced using **real toolchain interactions**:
1. **CLI Commands:** Directly executed via `lapis.exe` in the `sandbox/void_runner` test project (audited with real outputs, real table formatting, and genuine ANSI escape sequences).
2. **TUI Views:** Driven directly through the real `Lapis::TUI` classes (`Hub`, `NewWizard`, `EditorLauncher`, `PackageForm`, `DebuggerView`, `LogViewer`, `BenchViewer`, `RunMonitor`, and `Renderer`) and rendered to exact slide terminal dimensions (`86x22`, or `84x22` for crshader).

---

## Quick Start: Reproducing All Casts

To re-record all 25 asciicasts across the entire presentation:

```powershell
$env:CRYSTAL_PATH = "C:\Users\Ian\Documents\libgodot\tools\lapis\src;C:\Users\Ian\Documents\libgodot\lib;lib;C:\Users\Ian\scoop\apps\crystal\current\src"
crystal run scripts/record_casts.cr -- --all
```

Or via Makefile:
```powershell
make casts
```

---

## Recording a Single Cast

To re-record just one specific cast (e.g. after updating a command or view):

```powershell
crystal run scripts/record_casts.cr -- --cast lapis_doctor
```

To list all registered casts and their target dimensions:
```powershell
crystal run scripts/record_casts.cr -- --list
```

---

## Adding a New Cast for a New Slide

Adding a new cast takes only a few lines of Crystal code in `scripts/record_casts.cr`.

### 1. Adding a Real CLI Command Cast
```crystal
class MyNewCliCast < BaseCast
  def name; "my_new_command"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    # Simulate user typing the command
    cast.type_command("lapis my-command --flag")
    
    # Run the real CLI binary and capture real output
    lines = ProcessHelper.run_lapis(["my-command", "--flag"], chdir: "sandbox/void_runner", cols: cols, rows: rows)
    cast.print_lines(lines, line_delay: 0.08)
    cast.sleep(3.0)
  end
end
CastRegistry.register(MyNewCliCast.new)
```

### 2. Adding an Interactive TUI Cast
```crystal
class MyNewTuiCast < BaseCast
  def name; "my_new_tui"; end
  def cols; 86; end
  def rows; 22; end

  def record(cast : AsciiCast)
    # Instantiate the real Lapis TUI model
    view = Lapis::TUI::MyView.new
    buf = Opal::UI::Buffer.new(cols, rows)

    # Frame 1: Initial state
    view.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 0.0, clear: true)
    cast.sleep(1.2)

    # Frame 2: Transition / state change
    view.selected_index = 1
    buf.clear
    view.render_to_buffer(buf, cols, rows)
    cast.render_buffer(buf, 2.5)
  end
end
CastRegistry.register(MyNewTuiCast.new)
```

### 3. Referencing in Slide YAML
In your `data/slides/my_slide.yml`:
```yaml
left:
  type: asciinema
  title: Terminal — lapis my-command
  cast: casts/my_new_command.cast
  cols: 86
  rows: 22
  speed: 1.0
  loop: true
  autoplay: true
```

Then rebuild the slides:
```powershell
crystal run src/builder.cr -- build --no-casts
```
