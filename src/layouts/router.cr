require "./layout_renderer"
require "./hero_layout"
require "./intro_layout"
require "./code_comparison_layout"
require "./two_column_layout"
require "./three_column_layout"
require "./four_column_layout"
require "./matrix_layout"
require "./timeline_layout"
require "./media_layout"
require "./architecture_layout"
require "./profile_layout"
require "./dual_mode_layout"
require "./demo_roadmap_layout"
require "./closing_layout"

module LapisSlides
  class LayoutRouter
    @@renderers = {
      "hero-layout"                => IntroLayout.new.as(LayoutRenderer),
      "intro-layout"               => IntroLayout.new.as(LayoutRenderer),
      "code-comparison-layout"     => CodeComparisonLayout.new.as(LayoutRenderer),
      "antipattern-compare-layout" => CodeComparisonLayout.new.as(LayoutRenderer),
      "two-column-layout"          => TwoColumnLayout.new.as(LayoutRenderer),
      "three-column-layout"    => ThreeColumnLayout.new.as(LayoutRenderer),
      "four-column-layout"     => FourColumnLayout.new.as(LayoutRenderer),
      "matrix-layout"          => MatrixLayout.new.as(LayoutRenderer),
      "timeline-layout"        => TimelineLayout.new.as(LayoutRenderer),
      "media-layout"           => MediaLayout.new.as(LayoutRenderer),
      "architecture-layout"    => ArchitectureLayout.new.as(LayoutRenderer),
      "profile-layout"         => ProfileLayout.new.as(LayoutRenderer),
      "dual-mode-layout"       => DualModeLayout.new.as(LayoutRenderer),
      "demo-roadmap-layout"    => DemoRoadmapLayout.new.as(LayoutRenderer),
      "closing-layout"         => ClosingLayout.new.as(LayoutRenderer),
    }

    def self.renderer_for(layout_name : String) : LayoutRenderer
      @@renderers[layout_name]? || @@renderers["two-column-layout"]
    end
  end
end
