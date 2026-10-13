require "./spec_helper"
require "yaml"

describe "Flagship Lapis Slide Deck in Sunstone" do
  it "verifies deck.yml manifest exists and adheres to Sol-Vin 16:9 standards" do
    deck_path = File.join(__DIR__, "..", "deck.yml")
    File.exists?(deck_path).should be_true

    content = File.read(deck_path)
    deck_yaml = YAML.parse(content)

    deck_yaml["title"].as_s.should eq("Lapis for Crystal")
    deck_yaml["theme"].as_s.should eq("sol.vin")

    res = deck_yaml["resolution"]
    width = res["width"].as_i
    height = res["height"].as_i
    stage = LapisSlides::Core::StageResolution.new(width, height)
    stage.aspect_ratio_16_9?.should be_true
  end

  it "verifies all slides listed in deck.yml exist in data/slides" do
    deck_path = File.join(__DIR__, "..", "deck.yml")
    deck_yaml = YAML.parse(File.read(deck_path))
    slides = deck_yaml["slides"].as_a

    slides.size.should be >= 100

    slides_dir = File.join(__DIR__, "..", "data", "slides")
    slides.each do |slide_entry|
      slide_id = slide_entry.as_s
      slide_file = File.join(slides_dir, "#{slide_id}.yml")
      File.exists?(slide_file).should be_true, "Missing slide file: #{slide_file}"
    end
  end

  it "verifies every slide YAML satisfies Zero-Inline-Styles invariant and valid YAML schema" do
    slides_dir = File.join(__DIR__, "..", "data", "slides")
    Dir.glob(File.join(slides_dir, "*.yml")).each do |file|
      content = File.read(file)
      # Check Zero-Inline-Styles
      content.includes?("style=\"").should be_false, "Inline style found in #{File.basename(file)}"
      content.includes?("style='").should be_false, "Inline style found in #{File.basename(file)}"

      yaml = YAML.parse(content)
      yaml["id"]?.should_not be_nil, "Slide #{File.basename(file)} missing 'id'"
      yaml["layout"]?.should_not be_nil, "Slide #{File.basename(file)} missing 'layout'"
    end
  end

  it "verifies compiled artifacts index.html and SLIDES.md exist and are non-empty" do
    html_path = File.join(__DIR__, "..", "index.html")
    slides_md_path = File.join(__DIR__, "..", "SLIDES.md")

    File.exists?(html_path).should be_true
    File.size(html_path).should be > 100_000

    File.exists?(slides_md_path).should be_true
    File.size(slides_md_path).should be > 50_000
  end

  it "verifies conference CFP.md and 30-minute KEYNOTE_30MIN_SCRIPT.md exist and are non-empty" do
    cfp_path = File.join(__DIR__, "..", "CFP.md")
    keynote_path = File.join(__DIR__, "..", "KEYNOTE_30MIN_SCRIPT.md")

    File.exists?(cfp_path).should be_true
    File.size(cfp_path).should be > 5_000

    File.exists?(keynote_path).should be_true
    File.size(keynote_path).should be > 20_000
  end
end

