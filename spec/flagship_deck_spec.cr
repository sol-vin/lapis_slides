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
    width.should eq(1280)
    height.should eq(720)
    (width * 9).should eq(height * 16)
  end

  it "verifies 1:1 parity between slides listed in deck.yml and YAML files in data/slides" do
    deck_path = File.join(__DIR__, "..", "deck.yml")
    deck_yaml = YAML.parse(File.read(deck_path))
    slides = deck_yaml["slides"].as_a.map(&.as_s)

    slides.size.should be >= 100

    slides_dir = File.join(__DIR__, "..", "data", "slides")
    slides.each do |slide_id|
      slide_file = File.join(slides_dir, "#{slide_id}.yml")
      File.exists?(slide_file).should be_true, "Missing slide file: #{slide_file}"
    end

    disk_slides = Dir.glob(File.join(slides_dir, "*.yml")).map { |f| File.basename(f, ".yml") }
    orphaned = disk_slides - slides
    orphaned.should be_empty, "Orphaned slide YAML files found in data/slides: #{orphaned.join(", ")}"
  end

  it "verifies every slide YAML satisfies Zero-Inline-Styles invariant and valid YAML schema" do
    slides_dir = File.join(__DIR__, "..", "data", "slides")
    Dir.glob(File.join(slides_dir, "*.yml")).each do |file|
      content = File.read(file)
      content.includes?("style=\"").should be_false, "Inline style found in #{File.basename(file)}"
      content.includes?("style='").should be_false, "Inline style found in #{File.basename(file)}"

      yaml = YAML.parse(content)
      yaml["id"]?.should_not be_nil, "Slide #{File.basename(file)} missing 'id'"
      yaml["layout"]?.should_not be_nil, "Slide #{File.basename(file)} missing 'layout'"
      if yaml["layout"].as_s.includes?("three-column")
        cols = yaml["columns"]?.try(&.as_a?)
        cols.should_not be_nil, "Slide #{File.basename(file)} with three-column layout must define a 'columns:' array"
        cols.not_nil!.size.should eq(3), "Slide #{File.basename(file)} with three-column layout must have 3 columns"
      end
    end
  end

  it "verifies compiled artifacts index.html and SLIDES.md exist, are non-empty, and contain every slide in deck.yml" do
    html_path = File.join(__DIR__, "..", "index.html")
    slides_md_path = File.join(__DIR__, "..", "SLIDES.md")

    File.exists?(html_path).should be_true
    File.size(html_path).should be > 100_000

    html_content = File.read(html_path)
    deck_yaml = YAML.parse(File.read(File.join(__DIR__, "..", "deck.yml")))
    deck_yaml["slides"].as_a.each do |slide_entry|
      slide_id = slide_entry.as_s
      html_content.includes?(%Q(id="slide-#{slide_id}")).should be_true, "Compiled index.html is missing slide-#{slide_id}"
    end

    File.exists?(slides_md_path).should be_true
    File.size(slides_md_path).should be > 50_000
  end
end
