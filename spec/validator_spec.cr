require "./spec_helper"

describe LapisSlides::Core::DeckValidator do
  it "passes validation on clean 16:9 deck with supported layouts" do
    deck = LapisSlides.deck("Lapis Flagship") do |d|
      d.stage(1280, 720)
      d.default_palette("warm_paper")
      d.slide("01_hero", "intro") do |s|
        s.title("Lapis for Crystal")
        s.subtitle("Native Speed")
        s.palette("warm_paper")
        s.notes("Welcome to the presentation!")
      end
      d.slide("02_arch", "architecture") do |s|
        s.title("Architecture")
        s.palette("warm_paper")
        s.notes("Explaining the tiers.")
      end
    end

    issues = LapisSlides.validate(deck)
    errors = issues.select(&.error?)
    errors.should be_empty
  end

  it "flags error on non-16:9 aspect ratio" do
    deck = LapisSlides.deck("Bad Aspect") do |d|
      d.stage(1024, 768) # 4:3
      d.slide("01_intro", "intro") do |s|
        s.title("Test")
        s.notes("Notes")
      end
    end

    issues = LapisSlides.validate(deck)
    issues.any? { |i| i.error? && i.message.includes?("16:9") }.should be_true
  end

  it "flags error on duplicate slide IDs" do
    deck = LapisSlides.deck("Duplicate IDs") do |d|
      d.stage(1280, 720)
      d.slide("dup_id", "intro") { |s| s.title("Slide 1"); s.notes("Note 1") }
      d.slide("dup_id", "intro") { |s| s.title("Slide 2"); s.notes("Note 2") }
    end

    issues = LapisSlides.validate(deck)
    issues.any? { |i| i.error? && i.message.includes?("Duplicate slide ID") }.should be_true
  end

  it "flags error on unsupported layout" do
    deck = LapisSlides.deck("Invalid Layout") do |d|
      d.stage(1280, 720)
      d.slide("bad_layout", "unsupported-magic-layout") do |s|
        s.title("Broken")
        s.notes("Notes")
      end
    end

    issues = LapisSlides.validate(deck)
    issues.any? { |i| i.error? && i.message.includes?("Unsupported semantic layout") }.should be_true
  end

  it "flags zero-inline-style violations in text and pills" do
    deck = LapisSlides.deck("Style Violation") do |d|
      d.stage(1280, 720)
      d.slide("inline_style", "intro") do |s|
        s.title("<span style=\"color: red;\">Illegal Style</span>")
        s.notes("Notes")
      end
    end

    issues = LapisSlides.validate(deck)
    issues.any? { |i| i.error? && i.message.includes?("Zero-Inline-Styles violation") }.should be_true
  end
end
