require "./spec_helper"

describe LapisSlides::Core::KeynoteChoreographySpec do
  it "calculates durations, word counts, and WPM correctly" do
    cue1 = LapisSlides::Core::StageCue.new(
      LapisSlides::Core::StageCueType::SlideAdvance,
      0,
      "slide_01",
      "Advance to title slide"
    )
    cue1.formatted_timestamp.should eq("00:00")

    beat1 = LapisSlides::Core::KeynoteBeatSpec.new(
      id: "intro_hook",
      title: "The Opening Hook",
      start_second: 0,
      end_second: 60,
      slide_ids: ["slide_01"],
      hook: "Why do we settle for slow engines?",
      spoken_script: "Welcome everyone. Today we are talking about game development performance and ergonomics.",
      stage_cues: [cue1],
      visual_callouts: ["Highlight title text"],
      key_insight: "Performance and joy do not have to be mutually exclusive."
    )

    beat1.duration_seconds.should eq(60)
    beat1.word_count.should eq(12)
    beat1.words_per_minute.should eq(12.0)
    beat1.formatted_time.should eq("00:00 - 01:00")

    chapter = LapisSlides::Core::KeynoteChapterSpec.new(
      act_number: 1,
      act_name: "Act 1",
      title: "The Dilemma",
      start_second: 0,
      end_second: 60,
      narrative_purpose: "Establish the problem",
      beats: [beat1]
    )

    chapter.duration_seconds.should eq(60)
    chapter.total_words.should eq(12)
    chapter.formatted_time.should eq("00:00 - 01:00")
  end

  it "validates continuous 30-minute timelines without errors" do
    b1 = LapisSlides::Core::KeynoteBeatSpec.new("b1", "Beat 1", 0, 900, spoken_script: "Script part one")
    b2 = LapisSlides::Core::KeynoteBeatSpec.new("b2", "Beat 2", 900, 1800, spoken_script: "Script part two")

    chap1 = LapisSlides::Core::KeynoteChapterSpec.new(1, "Act 1", "First Half", 0, 900, "First half", [b1])
    chap2 = LapisSlides::Core::KeynoteChapterSpec.new(2, "Act 2", "Second Half", 900, 1800, "Second half", [b2])

    choreography = LapisSlides::Core::KeynoteChoreographySpec.new(
      title: "Lapis 30-Minute Keynote",
      chapters: [chap1, chap2]
    )

    choreography.total_actual_seconds.should eq(1800)
    errors = LapisSlides::Core::ChoreographyValidator.validate(choreography)
    errors.should be_empty
  end

  it "detects timing mismatches and gaps in choreography" do
    b1 = LapisSlides::Core::KeynoteBeatSpec.new("b1", "Beat 1", 0, 500)
    # Gap: 500 to 600 missing!
    b2 = LapisSlides::Core::KeynoteBeatSpec.new("b2", "Beat 2", 600, 1200)

    chap1 = LapisSlides::Core::KeynoteChapterSpec.new(1, "Act 1", "Gap Test", 0, 1200, "Testing gap", [b1, b2])

    choreography = LapisSlides::Core::KeynoteChoreographySpec.new(
      title: "Invalid Deck",
      target_duration_seconds: 1800,
      chapters: [chap1]
    )

    errors = LapisSlides::Core::ChoreographyValidator.validate(choreography)
    errors.size.should be >= 2
    errors.any? { |e| e.field == "total_duration" }.should be_true
    errors.any? { |e| e.field.includes?("start_second") }.should be_true
  end

  it "compiles markdown with AV cues, speech script, and Q&A playbook" do
    beat = LapisSlides::Core::KeynoteBeatSpec.new(
      id: "beat_01",
      title: "The Opening Hook",
      start_second: 0,
      end_second: 1800,
      slide_ids: ["01", "02"],
      hook: "The core challenge",
      spoken_script: "Welcome to Lapis. Let us begin.",
      stage_cues: [
        LapisSlides::Core::StageCue.new(LapisSlides::Core::StageCueType::SlideAdvance, 0, "01", "Advance to slide 1")
      ],
      key_insight: "Crystal fits Godot 4.8"
    )

    chap = LapisSlides::Core::KeynoteChapterSpec.new(1, "Act 1", "Full Talk", 0, 1800, "Full talk", [beat])
    qa = LapisSlides::Core::QaDefenseItem.new(
      question: "What about GC frame spikes?",
      category: "GC & Performance",
      short_punchy_answer: "Zero allocations on the hot path.",
      technical_deep_dive: "Using Boehm GC with stack structs and custom arenas.",
      trap_to_avoid: "Don't claim GC is completely disabled; explain explicit boundaries."
    )

    choreography = LapisSlides::Core::KeynoteChoreographySpec.new(
      title: "Lapis Keynote",
      chapters: [chap],
      qa_items: [qa]
    )

    md = LapisSlides::Core::KeynoteCompiler.emit_markdown(choreography)
    md.should contain("# 30-Minute Keynote Choreography & Script — Lapis Keynote")
    md.should contain("Act 1")
    md.should contain("What about GC frame spikes?")
    md.should contain("Zero allocations on the hot path")
  end
end
