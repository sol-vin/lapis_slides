require "yaml"

module LapisSlides
  class Slide
    getter raw : YAML::Any
    getter id : String
    getter title : String
    getter subtitle : String
    getter badge : String
    getter badge_color : String
    getter palette : String
    getter layout : String
    getter notes : String
    getter file_path : String

    def initialize(@raw : YAML::Any, @file_path : String)
      @id = @raw["id"]?.try(&.as_s) || File.basename(@file_path, ".yml")
      @title = @raw["title"]?.try(&.as_s) || "Untitled Slide"
      @subtitle = @raw["subtitle"]?.try(&.as_s) || ""
      @badge = @raw["badge"]?.try(&.as_s) || "LAPIS"
      @badge_color = @raw["badge_color"]?.try(&.as_s) || "blue"
      @palette = @raw["palette"]?.try(&.as_s) || "monokai"
      @layout = @raw["layout"]?.try(&.as_s) || "two-column-layout"
      @notes = @raw["notes"]?.try(&.as_s) || ""
    end

    def self.from_file(file_path : String) : Slide
      content = File.read(file_path)
      raw = YAML.parse(content)
      Slide.new(raw, file_path)
    end
  end
end
