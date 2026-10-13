require "./spec_helper"
require "file_utils"

describe LapisSlides::Core::DeckCompiler do
  it "emits valid deck.yml manifest" do
    deck = LapisSlides.deck("Lapis Flagship") do |d|
      d.subtitle("Native Godot 4.8 in Crystal")
      d.author("sol.vin")
      d.stage(1280, 720)
      d.slide("01_hero", "intro") { |s| s.title("Hero") }
      d.slide("02_arch", "architecture") { |s| s.title("Arch") }
    end

    yaml = LapisSlides::Core::DeckCompiler.emit_deck_yaml(deck)
    yaml.should contain("title: \"Lapis Flagship\"")
    yaml.should contain("subtitle: \"Native Godot 4.8 in Crystal\"")
    yaml.should contain("width: 1280")
    yaml.should contain("height: 720")
    yaml.should contain("- slides/01_hero.yml")
    yaml.should contain("- slides/02_arch.yml")
  end

  it "emits semantic HTML adhering to Zero-Inline-Styles invariant" do
    deck = LapisSlides.deck("Lapis Flagship") do |d|
      d.stage(1280, 720)
      d.slide("01_hero", "intro") do |s|
        s.title("Hero Title")
        s.subtitle("Subtitle Here")
        s.palette("warm_paper")
        s.notes("Speaker notes for hero.")
      end
    end

    html = LapisSlides::Core::DeckCompiler.emit_semantic_html(deck)
    html.should contain("<!DOCTYPE html>")
    html.should contain("data-stage-width=\"1280\"")
    html.should contain("data-layout=\"intro\"")
    html.should contain("data-palette=\"warm_paper\"")
    # Verify no inline styles
    html.includes?("style=").should be_false
  end

  it "emits speaker markdown outline with all slide sections" do
    deck = LapisSlides.deck("Lapis Flagship") do |d|
      d.subtitle("Native Godot 4.8")
      d.author("sol.vin")
      d.slide("01_hero", "intro") do |s|
        s.title("Hero Title")
        s.notes("These are speaker notes.")
      end
    end

    md = LapisSlides::Core::DeckCompiler.emit_speaker_markdown(deck)
    md.should contain("# Lapis Flagship")
    md.should contain("## Slide 1: Hero Title (`01_hero`)")
    md.should contain("These are speaker notes.")
  end

  it "writes full project tree to disk" do
    deck = LapisSlides.deck("Lapis Deck") do |d|
      d.slide("01_cover", "intro") { |s| s.title("Cover") }
    end

    temp_dir = File.join(Dir.tempdir, "lapis_slides_test_#{Time.utc.to_unix_ms}")
    begin
      path, count = LapisSlides::Core::DeckCompiler.write_project(deck, temp_dir)
      count.should eq(1)
      File.exists?(File.join(temp_dir, "deck.yml")).should be_true
      File.exists?(File.join(temp_dir, "slides", "01_cover.yml")).should be_true
      File.exists?(File.join(temp_dir, "index.html")).should be_true
      File.exists?(File.join(temp_dir, "SLIDES.md")).should be_true
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
end
