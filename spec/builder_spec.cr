require "./spec_helper"

describe LapisSlides::DSL do
  it "builds a two-column slide with fluent SlotBuilders" do
    slide = LapisSlides.slide("test_two_col", "two-column") do |s|
      s.title("Two Column Architecture")
      s.palette("game_station_2")
      s.ratio("3:2")
      s.left_slot("code") do |slot|
        slot.title("server.cr")
        slot.lang("crystal")
        slot.code("puts \"Hello Lapis!\"")
      end
      s.right_slot("card") do |slot|
        slot.title("Performance Highlights")
        slot.color("emerald")
        slot.item("Sub-millisecond latency")
        slot.item("Zero garbage collector pressure")
      end
      s.notes("Explain the two column layout.")
    end

    slide.id.should eq("test_two_col")
    slide.layout.should eq("two-column")
    slide.palette.should eq("game_station_2")
    slide.ratio.should eq("3:2")
    slide.left.should_not be_nil
    slide.left.not_nil!.slot_type.should eq("code")
    slide.left.not_nil!.code.should eq("puts \"Hello Lapis!\"")
    slide.right.should_not be_nil
    slide.right.not_nil!.items.size.should eq(2)
  end

  it "builds a code-comparison slide with before and after blocks" do
    slide = LapisSlides.slide("test_code_comp", "code-comparison") do |s|
      s.title("Imperative vs Declarative")
      s.before("Legacy C++") do |b|
        b.lang("cpp")
        b.code("for(int i=0; i<n; ++i) { ... }")
        b.point("Manual pointer arithmetic")
      end
      s.after("Lapis Crystal") do |a|
        a.lang("crystal")
        a.code("entities.each &.update(delta)")
        a.point("Type-safe iterator optimization")
      end
      s.notes("Compare both paradigms.")
    end

    slide.before.should_not be_nil
    slide.before.not_nil!.title.should eq("Legacy C++")
    slide.after.should_not be_nil
    slide.after.not_nil!.title.should eq("Lapis Crystal")
    slide.after.not_nil!.points.should contain("Type-safe iterator optimization")
  end

  it "builds a layered architecture slide with tiers and blocks" do
    slide = LapisSlides.slide("test_arch", "architecture") do |s|
      s.title("Lapis Engine Tiers")
      s.tier("High-Level Ergonomics") do |t|
        t.label("Layer 2")
        t.color("cyan")
        t.columns(2)
        t.block("Node DSL", "Declarative scene graph macros")
        t.block("Signals & Async", "Fiber-backed reactive streams")
      end
      s.tier("Low-Level Engine") do |t|
        t.label("Layer 1")
        t.color("emerald")
        t.columns(1)
        t.block("GDExtension FFI", "Zero-copy C ABI direct bindings")
      end
      s.notes("Walk through each tier from top to bottom.")
    end

    slide.tiers.size.should eq(2)
    slide.tiers[0].title.should eq("High-Level Ergonomics")
    slide.tiers[0].blocks.size.should eq(2)
    slide.tiers[1].title.should eq("Low-Level Engine")
    slide.tiers[1].blocks.size.should eq(1)
  end

  it "builds dual-mode execution slide" do
    slide = LapisSlides.slide("test_dual_mode", "dual-mode") do |s|
      s.title("Dual Execution Engine")
      s.banner("Unified API across both targets")
      s.mode("Editor Play Mode") do |m|
        m.badge("DEBUG")
        m.color("purple")
        m.desc("Live hot-reloading within Godot 4.8 editor")
        m.spec("bolt", "Reload Latency", "< 50ms")
      end
      s.mode("Standalone Native Binary") do |m|
        m.badge("RELEASE")
        m.color("emerald")
        m.desc("Bare-metal compiled executable with LTO")
        m.spec("rocket", "Frame Time", "0.4ms")
      end
      s.notes("Discuss editor workflows vs production deployment.")
    end

    slide.modes.size.should eq(2)
    slide.modes[0].badge.should eq("DEBUG")
    slide.modes[1].badge.should eq("RELEASE")
  end
end
