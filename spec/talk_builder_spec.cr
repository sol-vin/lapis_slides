require "./spec_helper"

describe "LapisSlides Talk DSL" do
  it "builds a complete CFP submission using declarative syntax" do
    cfp = LapisSlides.cfp("Lapis for Crystal") do |c|
      c.subtitle("Zen Ergonomics & Native Speed")
      c.alt_title("Zero-Cost Abstractions at 120 FPS")
      c.format("30-Minute Keynote", minutes: 30)
      c.audience("Intermediate to Advanced", ["Game Engine Devs", "Systems Programmers"])
      c.prerequisite("Basic familiarity with game loops and compiled languages")
      c.elevator_pitch("Lapis brings Crystal to Godot 4.8 GDExtension.")
      c.short_abstract("A 30-minute deep dive into high-performance Crystal bindings for Godot 4.8.")
      c.detailed_abstract("Full proposal exploring C ABI, AST macros, zero-allocation hot paths, and benchmarks.")
      c.takeaway("Eliminate C++ compile times without sacrificing native performance.")
      c.takeaway("Automate ClassDB bindings using Crystal AST macros.")
      c.takeaway("Achieve deterministic 120 FPS with zero-allocation game loops.")
      c.section("The Dilemma", 5, ["Dynamic vs static tradeoffs"])
      c.section("The Architecture", 15, ["GDExtension C FFI and Macro DSL"])
      c.section("The Crucible & Benchmarks", 10, ["100k transforms and live demo"])
      c.target_conference("GodotCon 2026", city: "Berlin", track: "Core Architecture")
      c.speaker(name: "Ian Rash", handle: "sol.vin")
      c.technical_requirement("1080p 16:9 HDMI projector")
      c.tag("godot")
      c.tag("crystal")
    end

    cfp.title.should eq("Lapis for Crystal")
    cfp.alternative_titles.should eq(["Zero-Cost Abstractions at 120 FPS"])
    cfp.duration_minutes.should eq(30)
    cfp.outline_total_minutes.should eq(30)
    cfp.target_conferences.first.name.should eq("GodotCon 2026")
    cfp.tags.should eq(["godot", "crystal"])

    errors = LapisSlides.validate_cfp(cfp)
    errors.should be_empty
  end

  it "builds a choreographed 30-minute keynote using declarative syntax" do
    keynote = LapisSlides.keynote("Lapis Keynote") do |k|
      k.subtitle("The Architecture of Compiled Joy")
      k.speaker("Ian Rash (sol.vin)")
      k.target_duration(1800)
      k.qa_buffer(180)

      k.act(1, "The Hook & The Dilemma", from: 0, to: 600, purpose: "Hook the audience and present the core dilemma") do |act|
        act.beat("hook", "The Dilemma", from: 0, to: 600) do |b|
          b.slide("01", "02")
          b.hook("Why do we compromise?")
          b.say("Welcome everyone. Today we are presenting Lapis.")
          b.cue(LapisSlides::Core::StageCueType::SlideAdvance, "01", at: 0, instruction: "Title slide")
          b.visual_callout("Point to title")
          b.insight("Language ergonomics matter.")
          b.tone("Energetic and focused")
        end
      end

      k.act(2, "The Architecture & Deep Dive", from: 600, to: 1800, purpose: "Deep systems breakdown and live demo") do |act|
        act.beat("deep_dive", "Architecture", from: 600, to: 1800) do |b|
          b.slide("03", "04")
          b.hook("Under the hood")
          b.say("Here is how GDExtension binds cleanly with Crystal.")
          b.cue(LapisSlides::Core::StageCueType::TerminalDemo, "asciinema", at: 900, instruction: "Trigger demo")
          b.insight("Direct C ABI eliminates overhead.")
        end
      end

      k.qa(
        question: "Can I mix GDScript and Lapis?",
        category: "Ergonomics",
        short_ans: "Yes, seamlessly through Godot's ClassDB.",
        deep_dive: "Lapis classes register as native Godot Object types.",
        trap: "Don't claim GDScript isn't needed; highlight complementary strengths."
      )
    end

    keynote.title.should eq("Lapis Keynote")
    keynote.total_actual_seconds.should eq(1800)
    keynote.chapters.size.should eq(2)
    keynote.qa_items.size.should eq(1)

    errors = LapisSlides.validate_choreography(keynote)
    errors.should be_empty
  end
end
