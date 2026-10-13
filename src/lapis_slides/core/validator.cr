require "./models"

module LapisSlides
  module Core
    struct ValidationIssue
      getter slide_id : String
      getter severity : Symbol
      getter message : String

      def initialize(@slide_id : String, @severity : Symbol, @message : String)
      end

      @[SolvinCodex::HotPath]
      @[SolvinCodex::ZeroAllocation]
      def error? : Bool
        @severity == :error
      end
    end

    # Tier-1 Validator auditing Sunstone decks for 16:9 stage geometry,
    # zero-inline-style invariants, semantic layout schemas, and palette scopes.
    class DeckValidator
      SUPPORTED_LAYOUTS = {
        "intro", "hero", "chapter", "two-column", "three-column", "four-column",
        "code-comparison", "architecture", "dual-mode", "feature-grid",
        "process-flow", "stats", "matrix", "table", "timeline",
        "vertical-timeline", "roadmap-timeline", "calendar-month",
        "calendar-schedule", "radial-cycle", "editorial-split",
        "convergence", "media", "profile", "demo-roadmap", "quote",
        "faq", "closing", "one-left-two-right", "two-left-one-right",
        "one-top-two-bottom", "two-top-one-bottom", "one-left-three-right",
        "three-left-one-right",
      }

      SOLVIN_PALETTES = {
        "warm_paper", "monochrome", "inversion", "monokai", "candy",
        "pastel", "fos", "a64_pal", "a64_ntsc", "amigo", "trash80",
        "classic_green", "aperture", "smile_os", "former_rain", "ranger",
        "bring_me_hope", "disinherited", "game_station", "game_station_2",
        "digital_guy", "playtoy", "entertainment_system", "super_es",
        "spaces_98", "silicon_indigo", "catppuccin_mocha", "rhythm_808",
        "acid_303", "boom_bap_16", "slate_dark", "emerald_matrix",
        "clean_light", "midnight_indigo", "crimson_obsidian",
        "sunset_amber", "nordic_ice", "cyber_neon",
      }

      @[SolvinCodex::HotPath]
      @[SolvinCodex::ZeroAllocation]
      def self.contains_inline_style?(text : String) : Bool
        text.includes?("style=\"") || text.includes?("style='")
      end

      def self.validate(deck : DeckSpec) : Array(ValidationIssue)
        issues = [] of ValidationIssue

        unless deck.stage.aspect_ratio_16_9?
          issues << ValidationIssue.new(
            "deck",
            :error,
            "Stage resolution #{deck.stage.width}x#{deck.stage.height} violates mandatory 16:9 aspect ratio."
          )
        end

        if deck.slides.empty?
          issues << ValidationIssue.new("deck", :error, "Deck contains zero slides.")
        end

        seen_ids = Set(String).new
        deck.slides.each do |slide|
          if seen_ids.includes?(slide.id)
            issues << ValidationIssue.new(slide.id, :error, "Duplicate slide ID '#{slide.id}'.")
          end
          seen_ids << slide.id

          normalized_layout = slide.layout.sub(/-layout\z/, "")
          unless SUPPORTED_LAYOUTS.includes?(normalized_layout)
            issues << ValidationIssue.new(
              slide.id,
              :error,
              "Unsupported semantic layout '#{slide.layout}'."
            )
          end

          unless SOLVIN_PALETTES.includes?(slide.palette)
            issues << ValidationIssue.new(
              slide.id,
              :warning,
              "Palette '#{slide.palette}' is outside standard Sol-Vin / Generic catalog."
            )
          end

          if contains_inline_style?(slide.title) ||
             contains_inline_style?(slide.subtitle) ||
             contains_inline_style?(slide.notes) ||
             slide.pills.any? { |p| contains_inline_style?(p) }
            issues << ValidationIssue.new(
              slide.id,
              :error,
              "Zero-Inline-Styles violation: found inline style attribute in slide '#{slide.id}'."
            )
          end

          if slide.notes.strip.empty?
            issues << ValidationIssue.new(
              slide.id,
              :warning,
              "Slide '#{slide.id}' is missing speaker notes."
            )
          end
        end

        issues
      end
    end
  end
end
