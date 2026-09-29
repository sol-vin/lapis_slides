require "json"

module LapisSlides
  class Palette
    getter id : String
    getter name : String
    getter colors : Hash(String, String)

    def initialize(@id : String, @name : String, @colors : Hash(String, String))
    end

    def self.load_all(json_path : String) : Hash(String, Palette)
      raw_content = File.read(json_path)
      palettes_json = JSON.parse(raw_content).as_a
      result = Hash(String, Palette).new

      palettes_json.each do |item|
        id = item["id"].as_s
        name = item["name"].as_s
        colors_map = Hash(String, String).new
        if colors = item["colors"]?.try(&.as_h)
          colors.each do |k, v|
            colors_map[k] = v.as_s
          end
        end
        result[id] = Palette.new(id, name, colors_map)
      end

      result
    end

    def bg_color : String
      @colors["bg_color"]? || "#0f172a"
    end

    def bg_window : String
      @colors["bg_window"]? || "#1e293b"
    end

    def text_color : String
      @colors["text_color"]? || "#f8fafc"
    end

    def link_color : String
      @colors["link_color"]? || "#38bdf8"
    end

    def border_color : String
      @colors["border_color"]? || "#334155"
    end

    def border_active : String
      @colors["border_active"]? || "#06b6d4"
    end

    def accent_color : String
      @colors["accent_color"]? || "#a855f7"
    end

    def accent_secondary : String
      @colors["accent_secondary"]? || "#10b981"
    end

    def accent_tertiary : String
      @colors["accent_tertiary"]? || "#f59e0b"
    end

    def accent_quaternary : String
      @colors["accent_quaternary"]? || "#f43f5e"
    end

    def shadow_color : String
      @colors["shadow_color"]? || "#000000"
    end

    def cube_color : String
      @colors["cube"]? || text_color
    end

    def cube_hover : String
      @colors["cube_hover"]? || border_active
    end

    def hex_to_rgb(hex : String) : Tuple(Float64, Float64, Float64)
      clean = hex.lchop('#')
      if clean.size == 3
        clean = clean.chars.map { |c| "#{c}#{c}" }.join
      end
      if clean.size == 6
        r = clean[0..1].to_i(16).to_f64 / 255.0
        g = clean[2..3].to_i(16).to_f64 / 255.0
        b = clean[4..5].to_i(16).to_f64 / 255.0
        {r, g, b}
      else
        {0.8, 0.8, 0.8}
      end
    end

    def text_dim : String
      @colors["text_dim"]? || @colors["resume_job_meta"]? || "#94a3b8"
    end

    def emoji_color_matrix : String
      tr, tg, tb = hex_to_rgb(accent_color)

      # Strict monochrome color matrix filter limiting all emoji colors to the slide's accent_color
      # Input luminance L = 0.2126 * R + 0.7152 * G + 0.0722 * B
      # Output channel = L * target_channel
      # Every output pixel strictly shares the exact chromaticity of accent_color
      scale = 1.25 # Crisp highlights
      mr = "#{(0.2126 * tr * scale).round(4)} #{(0.7152 * tr * scale).round(4)} #{(0.0722 * tr * scale).round(4)} 0 0"
      mg = "#{(0.2126 * tg * scale).round(4)} #{(0.7152 * tg * scale).round(4)} #{(0.0722 * tg * scale).round(4)} 0 0"
      mb = "#{(0.2126 * tb * scale).round(4)} #{(0.7152 * tb * scale).round(4)} #{(0.0722 * tb * scale).round(4)} 0 0"
      ma = "0 0 0 1 0"

      "#{mr}  #{mg}  #{mb}  #{ma}"
    end

    def css_vars : String
      String.build do |str|
        str << "--bg-color: " << bg_color << "; "
        str << "--bg-window: " << bg_window << "; "
        str << "--text-color: " << text_color << "; "
        str << "--text-dim: " << text_dim << "; "
        str << "--link-color: " << link_color << "; "
        str << "--border-color: " << border_color << "; "
        str << "--border-active: " << border_active << "; "
        str << "--accent-color: " << accent_color << "; "
        str << "--accent-secondary: " << accent_secondary << "; "
        str << "--accent-tertiary: " << accent_tertiary << "; "
        str << "--accent-quaternary: " << accent_quaternary << "; "
        str << "--shadow-color: " << shadow_color << "; "
        str << "--cube: " << cube_color << "; "
        str << "--cube-hover: " << cube_hover << "; "
        str << "--emoji-filter: url(#emoji-filter-" << @id << "); "
      end
    end
  end
end
