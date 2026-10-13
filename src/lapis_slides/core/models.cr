require "./stage"

module LapisSlides
  module Core
    # Pure Tier-1 value structs representing Sunstone semantic slide components.

    struct SlotSpec
      getter slot_type : String
      getter title : String
      getter tag : String
      getter lang : String
      getter code : String
      getter color : String
      getter badge : String
      getter items : Array(String)
      getter chart_type : String
      getter highlight_color : String
      getter highlight_index : Int32
      getter labels : Array(String)
      getter values : Array(Float64)

      def initialize(
        @slot_type : String = "card",
        @title : String = "",
        @tag : String = "",
        @lang : String = "crystal",
        @code : String = "",
        @color : String = "accent",
        @badge : String = "",
        @items : Array(String) = [] of String,
        @chart_type : String = "bar",
        @highlight_color : String = "#10b981",
        @highlight_index : Int32 = 0,
        @labels : Array(String) = [] of String,
        @values : Array(Float64) = [] of Float64
      )
      end
    end

    struct ComparisonSideSpec
      getter title : String
      getter lang : String
      getter code : String
      getter points : Array(String)

      def initialize(
        @title : String,
        @lang : String = "crystal",
        @code : String = "",
        @points : Array(String) = [] of String
      )
      end
    end

    struct PillarSpec
      getter title : String
      getter desc : String
      getter icon : String
      getter color : String

      def initialize(
        @title : String,
        @desc : String,
        @icon : String = "bolt",
        @color : String = "emerald"
      )
      end
    end

    struct ArchBlockSpec
      getter title : String
      getter desc : String

      def initialize(@title : String, @desc : String)
      end
    end

    struct ArchTierSpec
      getter title : String
      getter label : String
      getter badge : String
      getter color : String
      getter columns : Int32
      getter blocks : Array(ArchBlockSpec)

      def initialize(
        @title : String,
        @label : String,
        @badge : String = "LAYER",
        @color : String = "accent",
        @columns : Int32 = 3,
        @blocks : Array(ArchBlockSpec) = [] of ArchBlockSpec
      )
      end
    end

    struct ModeSpecItem
      getter icon : String
      getter label : String
      getter value : String

      def initialize(@icon : String, @label : String, @value : String)
      end
    end

    struct DualModeSpec
      getter title : String
      getter badge : String
      getter color : String
      getter flow : String
      getter desc : String
      getter specs : Array(ModeSpecItem)

      def initialize(
        @title : String,
        @badge : String,
        @color : String,
        @flow : String,
        @desc : String,
        @specs : Array(ModeSpecItem) = [] of ModeSpecItem
      )
      end
    end

    struct FeatureHeroSpec
      getter title : String
      getter badge : String
      getter color : String
      getter code : String
      getter desc : String

      def initialize(
        @title : String,
        @badge : String = "CORE",
        @color : String = "accent",
        @code : String = "",
        @desc : String = ""
      )
      end
    end

    struct FeatureCardSpec
      getter title : String
      getter badge : String
      getter color : String
      getter items : Array(String)

      def initialize(
        @title : String,
        @badge : String = "MODULE",
        @color : String = "emerald",
        @items : Array(String) = [] of String
      )
      end
    end

    struct ProcessStepSpec
      getter step : String
      getter title : String
      getter badge : String
      getter color : String
      getter icon : String
      getter desc : String

      def initialize(
        @step : String,
        @title : String,
        @badge : String,
        @color : String,
        @icon : String,
        @desc : String
      )
      end
    end

    struct MetricSpec
      getter value : String
      getter label : String
      getter delta : String
      getter color : String
      getter icon : String
      getter desc : String
      getter progress : Float64?
      getter sparkline : Array(Int32)

      def initialize(
        @value : String,
        @label : String,
        @delta : String,
        @color : String = "accent",
        @icon : String = "bolt",
        @desc : String = "",
        @progress : Float64? = nil,
        @sparkline : Array(Int32) = [] of Int32
      )
      end
    end

    struct TimelineCardSpec
      getter year : String
      getter title : String
      getter phase : String
      getter color : String
      getter items : Array(String)

      def initialize(
        @year : String,
        @title : String,
        @phase : String,
        @color : String = "emerald",
        @items : Array(String) = [] of String
      )
      end
    end

    struct ClosingCardSpec
      getter title : String
      getter badge : String
      getter icon : String
      getter color : String
      getter link : String
      getter desc : String

      def initialize(
        @title : String,
        @badge : String,
        @icon : String,
        @color : String,
        @link : String,
        @desc : String
      )
      end
    end

    struct SlideSpec
      getter id : String
      getter layout : String
      getter badge : String
      getter badge_color : String
      getter palette : String
      getter title : String
      getter subtitle : String
      getter author : String
      getter author_role : String
      getter pills : Array(String)
      getter notes : String
      getter ratio : String
      getter left : SlotSpec?
      getter right : SlotSpec?
      getter before : ComparisonSideSpec?
      getter after : ComparisonSideSpec?
      getter chapter_number : String
      getter cube : Bool
      getter cube_size : Int32
      getter pillars : Array(PillarSpec)
      getter tiers : Array(ArchTierSpec)
      getter banner : String
      getter modes : Array(DualModeSpec)
      getter hero_feature : FeatureHeroSpec?
      getter features : Array(FeatureCardSpec)
      getter steps : Array(ProcessStepSpec)
      getter metrics : Array(MetricSpec)
      getter headers : Array(String)
      getter rows : Array(Array(String))
      getter summary : String
      getter timeline_cards : Array(TimelineCardSpec)
      getter closing_cards : Array(ClosingCardSpec)
      getter quickstart : String
      getter signature : String

      def initialize(
        @id : String,
        @layout : String = "two-column",
        @badge : String = "LAPIS",
        @badge_color : String = "accent",
        @palette : String = "warm_paper",
        @title : String = "Untitled Slide",
        @subtitle : String = "",
        @author : String = "",
        @author_role : String = "",
        @pills : Array(String) = [] of String,
        @notes : String = "",
        @ratio : String = "1:1",
        @left : SlotSpec? = nil,
        @right : SlotSpec? = nil,
        @before : ComparisonSideSpec? = nil,
        @after : ComparisonSideSpec? = nil,
        @chapter_number : String = "01",
        @cube : Bool = true,
        @cube_size : Int32 = 160,
        @pillars : Array(PillarSpec) = [] of PillarSpec,
        @tiers : Array(ArchTierSpec) = [] of ArchTierSpec,
        @banner : String = "",
        @modes : Array(DualModeSpec) = [] of DualModeSpec,
        @hero_feature : FeatureHeroSpec? = nil,
        @features : Array(FeatureCardSpec) = [] of FeatureCardSpec,
        @steps : Array(ProcessStepSpec) = [] of ProcessStepSpec,
        @metrics : Array(MetricSpec) = [] of MetricSpec,
        @headers : Array(String) = [] of String,
        @rows : Array(Array(String)) = [] of Array(String),
        @summary : String = "",
        @timeline_cards : Array(TimelineCardSpec) = [] of TimelineCardSpec,
        @closing_cards : Array(ClosingCardSpec) = [] of ClosingCardSpec,
        @quickstart : String = "",
        @signature : String = ""
      )
      end
    end

    struct DeckSpec
      getter title : String
      getter subtitle : String
      getter author : String
      getter author_url : String
      getter theme : String
      getter stage : StageResolution
      getter header_enabled : Bool
      getter header_label : String
      getter header_cube : Bool
      getter footer_left : String
      getter footer_center : String
      getter footer_right : String
      getter default_palette : String
      getter slides : Array(SlideSpec)

      def initialize(
        @title : String,
        @subtitle : String = "",
        @author : String = "Sol.vin Team",
        @author_url : String = "https://github.com/sol-vin/lapis_slides",
        @theme : String = "sol.vin",
        @stage : StageResolution = StageResolution::STANDARD_960x540,
        @header_enabled : Bool = true,
        @header_label : String = "LAPIS // GODOT 4.8 IN CRYSTAL",
        @header_cube : Bool = true,
        @footer_left : String = "💎 {title} • {subtitle}",
        @footer_center : String = "{author} ({palette})",
        @footer_right : String = "Slide {slide_num} / {total_slides}",
        @default_palette : String = "warm_paper",
        @slides : Array(SlideSpec) = [] of SlideSpec
      )
      end
    end
  end
end
