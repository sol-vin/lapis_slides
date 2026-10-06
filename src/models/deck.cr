require "yaml"
require "./slide"
require "./palette"

module LapisSlides
  class Deck
    getter raw : YAML::Any
    getter title : String
    getter subtitle : String
    getter author : String
    getter theme : String
    getter width : Int32
    getter height : Int32
    getter slides : Array(Slide)

    def initialize(@raw : YAML::Any, @slides : Array(Slide))
      @title = @raw["title"]?.try(&.as_s) || "Lapis for Crystal"
      @subtitle = @raw["subtitle"]?.try(&.as_s) || "Next-Gen Gameplay Toolchain for Godot 4.8+"
      @author = @raw["author"]?.try(&.as_s) || "sol.vin"
      @theme = @raw["theme"]?.try(&.as_s) || "theme.css"
      @width = @raw["resolution"]?.try(&.["width"]?.try(&.as_i)) || 1280
      @height = @raw["resolution"]?.try(&.["height"]?.try(&.as_i)) || 720
    end

    def self.load(deck_file : String, slides_dir : String) : Deck
      raw = File.exists?(deck_file) ? YAML.parse(File.read(deck_file)) : YAML.parse("title: Lapis Presentation")
      slides = Array(Slide).new

      if order = raw["slides"]?.try(&.as_a)
        order.each do |item|
          name = item.as_s
          file = File.join(slides_dir, name.ends_with?(".yml") ? name : "#{name}.yml")
          if File.exists?(file)
            slides << Slide.from_file(file)
          else
            STDERR.puts "[WARN] Slide file not found: #{file}"
          end
        end
      else
        Dir.glob(File.join(slides_dir, "*.yml")).sort.each do |file|
          slides << Slide.from_file(file)
        end
      end

      Deck.new(raw, slides)
    end
  end
end
