require "../core/models"
require "../core/validator"
require "../core/compiler"

module LapisSlides
  module DSL
    # Tier-2 Declarative Builder for SlotSpec
    class SlotBuilder
      @slot_type : String
      @title : String = ""
      @tag : String = ""
      @lang : String = "crystal"
      @code : String = ""
      @color : String = "accent"
      @badge : String = ""
      @items = [] of String
      @chart_type : String = "bar"
      @highlight_color : String = "#10b981"
      @highlight_index : Int32 = 0
      @labels = [] of String
      @values = [] of Float64

      def initialize(@slot_type : String = "card")
      end

      def title(val : String) : self
        @title = val
        self
      end

      def tag(val : String) : self
        @tag = val
        self
      end

      def lang(val : String) : self
        @lang = val
        self
      end

      def code(val : String) : self
        @code = val.strip
        self
      end

      def color(val : String) : self
        @color = val
        self
      end

      def badge(val : String) : self
        @badge = val
        self
      end

      def item(val : String) : self
        @items << val
        self
      end

      def chart(chart_type : String = "bar", highlight_color : String = "#10b981", highlight_index : Int32 = 0) : self
        @chart_type = chart_type
        @highlight_color = highlight_color
        @highlight_index = highlight_index
        self
      end

      def series(label : String, value : Float64) : self
        @labels << label
        @values << value
        self
      end

      def build : Core::SlotSpec
        Core::SlotSpec.new(
          slot_type: @slot_type,
          title: @title,
          tag: @tag,
          lang: @lang,
          code: @code,
          color: @color,
          badge: @badge,
          items: @items,
          chart_type: @chart_type,
          highlight_color: @highlight_color,
          highlight_index: @highlight_index,
          labels: @labels,
          values: @values
        )
      end
    end

    # Tier-2 Declarative Builder for Code-Comparison Side
    class ComparisonSideBuilder
      @title : String
      @lang : String = "crystal"
      @code : String = ""
      @points = [] of String

      def initialize(@title : String)
      end

      def lang(val : String) : self
        @lang = val
        self
      end

      def code(val : String) : self
        @code = val.strip
        self
      end

      def point(val : String) : self
        @points << val
        self
      end

      def build : Core::ComparisonSideSpec
        Core::ComparisonSideSpec.new(
          title: @title,
          lang: @lang,
          code: @code,
          points: @points
        )
      end
    end

    # Tier-2 Declarative Builder for Architecture Tier
    class ArchTierBuilder
      @title : String
      @label : String = ""
      @badge : String = "LAYER"
      @color : String = "accent"
      @columns : Int32 = 3
      @blocks = [] of Core::ArchBlockSpec

      def initialize(@title : String)
      end

      def label(val : String) : self
        @label = val
        self
      end

      def badge(val : String) : self
        @badge = val
        self
      end

      def color(val : String) : self
        @color = val
        self
      end

      def columns(val : Int32) : self
        @columns = val
        self
      end

      def block(title : String, desc : String) : self
        @blocks << Core::ArchBlockSpec.new(title, desc)
        self
      end

      def build : Core::ArchTierSpec
        Core::ArchTierSpec.new(
          title: @title,
          label: @label,
          badge: @badge,
          color: @color,
          columns: @columns,
          blocks: @blocks
        )
      end
    end

    # Tier-2 Declarative Builder for DualMode Side
    class DualModeBuilder
      @title : String
      @badge : String = "MODE"
      @color : String = "accent"
      @flow : String = ""
      @desc : String = ""
      @specs = [] of Core::ModeSpecItem

      def initialize(@title : String)
      end

      def badge(val : String) : self
        @badge = val
        self
      end

      def color(val : String) : self
        @color = val
        self
      end

      def flow(val : String) : self
        @flow = val
        self
      end

      def desc(val : String) : self
        @desc = val
        self
      end

      def spec(icon : String, label : String, value : String) : self
        @specs << Core::ModeSpecItem.new(icon, label, value)
        self
      end

      def build : Core::DualModeSpec
        Core::DualModeSpec.new(
          title: @title,
          badge: @badge,
          color: @color,
          flow: @flow,
          desc: @desc,
          specs: @specs
        )
      end
    end

    # Tier-2 Declarative Builder for SlideSpec
    class SlideBuilder
      @id : String
      @layout : String
      @badge : String = "LAPIS"
      @badge_color : String = "accent"
      @palette : String = "warm_paper"
      @title : String = "Untitled Slide"
      @subtitle : String = ""
      @author : String = ""
      @author_role : String = ""
      @pills = [] of String
      @notes : String = ""
      @ratio : String = "1:1"
      @left : Core::SlotSpec? = nil
      @right : Core::SlotSpec? = nil
      @before : Core::ComparisonSideSpec? = nil
      @after : Core::ComparisonSideSpec? = nil
      @chapter_number : String = "01"
      @cube : Bool = true
      @cube_size : Int32 = 160
      @pillars = [] of Core::PillarSpec
      @tiers = [] of Core::ArchTierSpec
      @banner : String = ""
      @modes = [] of Core::DualModeSpec
      @hero_feature : Core::FeatureHeroSpec? = nil
      @features = [] of Core::FeatureCardSpec
      @steps = [] of Core::ProcessStepSpec
      @metrics = [] of Core::MetricSpec
      @headers = [] of String
      @rows = [] of Array(String)
      @summary : String = ""
      @timeline_cards = [] of Core::TimelineCardSpec
      @closing_cards = [] of Core::ClosingCardSpec
      @quickstart : String = ""
      @signature : String = ""

      def initialize(@id : String, @layout : String = "two-column")
      end

      def badge(text : String, color : String = "accent") : self
        @badge = text
        @badge_color = color
        self
      end

      def palette(val : String) : self
        @palette = val
        self
      end

      def title(val : String) : self
        @title = val
        self
      end

      def subtitle(val : String) : self
        @subtitle = val
        self
      end

      def author(name : String, role : String = "") : self
        @author = name
        @author_role = role
        self
      end

      def pill(val : String) : self
        @pills << val
        self
      end

      def notes(val : String) : self
        @notes = val.strip
        self
      end

      def ratio(val : String) : self
        @ratio = val
        self
      end

      def left_slot(slot_type : String, &block : SlotBuilder ->) : self
        b = SlotBuilder.new(slot_type)
        yield b
        @left = b.build
        self
      end

      def right_slot(slot_type : String, &block : SlotBuilder ->) : self
        b = SlotBuilder.new(slot_type)
        yield b
        @right = b.build
        self
      end

      def before(title : String, &block : ComparisonSideBuilder ->) : self
        b = ComparisonSideBuilder.new(title)
        yield b
        @before = b.build
        self
      end

      def after(title : String, &block : ComparisonSideBuilder ->) : self
        b = ComparisonSideBuilder.new(title)
        yield b
        @after = b.build
        self
      end

      def chapter(number : String, cube : Bool = true, cube_size : Int32 = 160) : self
        @chapter_number = number
        @cube = cube
        @cube_size = cube_size
        self
      end

      def pillar(title : String, desc : String, icon : String = "bolt", color : String = "emerald") : self
        @pillars << Core::PillarSpec.new(title, desc, icon, color)
        self
      end

      def tier(title : String, &block : ArchTierBuilder ->) : self
        b = ArchTierBuilder.new(title)
        yield b
        @tiers << b.build
        self
      end

      def banner(val : String) : self
        @banner = val
        self
      end

      def mode(title : String, &block : DualModeBuilder ->) : self
        b = DualModeBuilder.new(title)
        yield b
        @modes << b.build
        self
      end

      def hero_feature(title : String, badge : String, color : String, code : String, desc : String) : self
        @hero_feature = Core::FeatureHeroSpec.new(title, badge, color, code.strip, desc)
        self
      end

      def feature_card(title : String, badge : String, color : String, items : Array(String)) : self
        @features << Core::FeatureCardSpec.new(title, badge, color, items)
        self
      end

      def process_step(step : String, title : String, badge : String, color : String, icon : String, desc : String) : self
        @steps << Core::ProcessStepSpec.new(step, title, badge, color, icon, desc)
        self
      end

      def metric(
        value : String,
        label : String,
        delta : String,
        color : String = "accent",
        icon : String = "bolt",
        desc : String = "",
        progress : Float64? = nil,
        sparkline : Array(Int32) = [] of Int32
      ) : self
        @metrics << Core::MetricSpec.new(value, label, delta, color, icon, desc, progress, sparkline)
        self
      end

      def headers(*cols : String) : self
        @headers = cols.to_a
        self
      end

      def row(*cells : String) : self
        @rows << cells.to_a
        self
      end

      def summary(val : String) : self
        @summary = val
        self
      end

      def timeline_card(year : String, title : String, phase : String, color : String, items : Array(String)) : self
        @timeline_cards << Core::TimelineCardSpec.new(year, title, phase, color, items)
        self
      end

      def closing_card(title : String, badge : String, icon : String, color : String, link : String, desc : String) : self
        @closing_cards << Core::ClosingCardSpec.new(title, badge, icon, color, link, desc)
        self
      end

      def quickstart(val : String) : self
        @quickstart = val
        self
      end

      def signature(val : String) : self
        @signature = val
        self
      end

      def build : Core::SlideSpec
        Core::SlideSpec.new(
          id: @id,
          layout: @layout,
          badge: @badge,
          badge_color: @badge_color,
          palette: @palette,
          title: @title,
          subtitle: @subtitle,
          author: @author,
          author_role: @author_role,
          pills: @pills,
          notes: @notes,
          ratio: @ratio,
          left: @left,
          right: @right,
          before: @before,
          after: @after,
          chapter_number: @chapter_number,
          cube: @cube,
          cube_size: @cube_size,
          pillars: @pillars,
          tiers: @tiers,
          banner: @banner,
          modes: @modes,
          hero_feature: @hero_feature,
          features: @features,
          steps: @steps,
          metrics: @metrics,
          headers: @headers,
          rows: @rows,
          summary: @summary,
          timeline_cards: @timeline_cards,
          closing_cards: @closing_cards,
          quickstart: @quickstart,
          signature: @signature
        )
      end
    end

    # Tier-2 Declarative Builder for DeckSpec
    class DeckBuilder
      @title : String
      @subtitle : String = ""
      @author : String = "Rho (Ρ) • Sol-Vin Keynote Engineering"
      @author_url : String = "https://github.com/sol-vin/lapis_slides"
      @theme : String = "sol.vin"
      @stage : Core::StageResolution = Core::StageResolution::STANDARD_960x540
      @header_enabled : Bool = true
      @header_label : String = "LAPIS // GODOT 4.8 IN CRYSTAL"
      @header_cube : Bool = true
      @footer_left : String = "💎 {title} • {subtitle}"
      @footer_center : String = "{author} ({palette})"
      @footer_right : String = "Slide {slide_num} / {total_slides}"
      @default_palette : String = "warm_paper"
      @slides = [] of Core::SlideSpec

      def initialize(@title : String)
      end

      def subtitle(val : String) : self
        @subtitle = val
        self
      end

      def author(name : String, url : String = "https://github.com/sol-vin/lapis_slides") : self
        @author = name
        @author_url = url
        self
      end

      def theme(val : String) : self
        @theme = val
        self
      end

      def stage(width : Int32, height : Int32) : self
        @stage = Core::StageResolution.new(width, height)
        self
      end

      def header(label : String, enabled : Bool = true, cube : Bool = true) : self
        @header_label = label
        @header_enabled = enabled
        @header_cube = cube
        self
      end

      def footer(left : String, center : String, right : String) : self
        @footer_left = left
        @footer_center = center
        @footer_right = right
        self
      end

      def default_palette(val : String) : self
        @default_palette = val
        self
      end

      def slide(id : String, layout : String = "two-column", &block : SlideBuilder ->) : self
        b = SlideBuilder.new(id, layout)
        yield b
        @slides << b.build
        self
      end

      def add_slide(spec : Core::SlideSpec) : self
        @slides << spec
        self
      end

      def build : Core::DeckSpec
        Core::DeckSpec.new(
          title: @title,
          subtitle: @subtitle,
          author: @author,
          author_url: @author_url,
          theme: @theme,
          stage: @stage,
          header_enabled: @header_enabled,
          header_label: @header_label,
          header_cube: @header_cube,
          footer_left: @footer_left,
          footer_center: @footer_center,
          footer_right: @footer_right,
          default_palette: @default_palette,
          slides: @slides
        )
      end
    end

    def self.deck(title : String, &block : DeckBuilder ->) : Core::DeckSpec
      builder = DeckBuilder.new(title)
      yield builder
      builder.build
    end

    def self.slide(id : String, layout : String = "two-column", &block : SlideBuilder ->) : Core::SlideSpec
      builder = SlideBuilder.new(id, layout)
      yield builder
      builder.build
    end
  end
end
