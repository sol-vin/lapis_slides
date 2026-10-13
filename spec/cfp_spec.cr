require "./spec_helper"

describe LapisSlides::Core::CfpSubmissionSpec do
  it "initializes with correct defaults and calculations" do
    cfp = LapisSlides::Core::CfpSubmissionSpec.new(
      title: "Lapis for Crystal",
      subtitle: "Native Machine Speed in Godot 4.8+",
      elevator_pitch: "Crystal brings compiled performance and zen ergonomics to Godot.",
      short_abstract: "This talk introduces Lapis, the high-performance Crystal toolchain for Godot 4.8 GDExtension.",
      detailed_abstract: "In this session, we explore the architecture of Lapis for Godot Engine 4.8...",
      key_takeaways: [
        "Eliminate C++ build times without losing C ABI performance",
        "Use Crystal AST macros to avoid ClassDB boilerplate",
        "Master zero-allocation patterns under the Boehm GC"
      ],
      outline: [
        LapisSlides::Core::CfpOutlineSection.new("The Dilemma", 5, ["GDScript vs C++"]),
        LapisSlides::Core::CfpOutlineSection.new("The Solution", 15, ["Crystal AST"]),
        LapisSlides::Core::CfpOutlineSection.new("Under the Hood & Benchmarks", 10, ["100k transforms"])
      ],
      target_conferences: [
        LapisSlides::Core::ConferenceTargetSpec.new("GodotCon 2026", "Berlin", "Nov 2026", "Core Engine", "https://godotcon.org", 500)
      ]
    )

    cfp.title.should eq("Lapis for Crystal")
    cfp.outline_total_minutes.should eq(30)
    cfp.abstract_word_count.should be > 5
    cfp.key_takeaways.size.should eq(3)

    errors = LapisSlides::Core::CfpValidator.validate(cfp)
    errors.should be_empty
  end

  it "validates required fields, takeaway counts, and duration alignment" do
    invalid_cfp = LapisSlides::Core::CfpSubmissionSpec.new(
      title: "",
      elevator_pitch: "",
      short_abstract: "",
      detailed_abstract: "",
      duration_minutes: 30,
      key_takeaways: ["Only one takeaway"],
      outline: [
        LapisSlides::Core::CfpOutlineSection.new("Part 1", 10)
      ],
      target_conferences: [] of LapisSlides::Core::ConferenceTargetSpec
    )

    errors = LapisSlides::Core::CfpValidator.validate(invalid_cfp)
    errors.size.should be >= 5
    errors.any? { |e| e.field == "title" }.should be_true
    errors.any? { |e| e.field == "elevator_pitch" }.should be_true
    errors.any? { |e| e.field == "key_takeaways" }.should be_true
    errors.any? { |e| e.field == "outline" }.should be_true
    errors.any? { |e| e.field == "target_conferences" }.should be_true
  end

  it "compiles markdown with structured sections and speaker credentials" do
    cfp = LapisSlides::Core::CfpSubmissionSpec.new(
      title: "Lapis for Crystal",
      subtitle: "Native Machine Speed in Godot 4.8+",
      alternative_titles: ["Zero-Cost Abstractions at 120 FPS"],
      elevator_pitch: "Crystal brings compiled performance to Godot.",
      short_abstract: "Introduces Lapis for Godot 4.8.",
      detailed_abstract: "Detailed proposal explaining GDExtension, AST macros, and benchmarks.",
      key_takeaways: [
        "Direct C ABI without C++ compile overhead",
        "Declarative Two-Tier DSL architecture",
        "GC tuning for deterministic 120 FPS"
      ],
      outline: [
        LapisSlides::Core::CfpOutlineSection.new("Introduction", 5),
        LapisSlides::Core::CfpOutlineSection.new("Deep Dive", 25)
      ],
      target_conferences: [
        LapisSlides::Core::ConferenceTargetSpec.new("GodotCon", "Berlin", "2026", "Engine", "https://godotcon.org")
      ],
      speaker: LapisSlides::Core::SpeakerBioSpec.new(
        name: "Ian Rash",
        handle: "sol.vin",
        standard_bio: "Ian Rash is a systems programmer and game developer."
      )
    )

    md = LapisSlides::Core::CfpCompiler.emit_markdown(cfp)
    md.should contain("# Conference Call for Proposals (CFP) — Lapis for Crystal")
    md.should contain("Zero-Cost Abstractions at 120 FPS")
    md.should contain("GodotCon")
    md.should contain("CVE-2019-11014")
    md.should contain("Solo Oasis: Unlimited Places")
  end
end
