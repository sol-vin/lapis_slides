require "../codex"

module LapisSlides
  module Core
    # Immutable 16:9 stage geometry primitive enforcing Rho's fixed stage coordinate standard.
    # Pure value struct with zero heap allocations on hot calculation paths.
    struct StageResolution
      getter width : Int32
      getter height : Int32

      STANDARD_960x540  = StageResolution.new(960, 540)
      HD_1280x720       = StageResolution.new(1280, 720)
      FULL_HD_1920x1080 = StageResolution.new(1920, 1080)

      def initialize(@width : Int32 = 960, @height : Int32 = 540)
      end

      # Verify 16:9 aspect ratio invariant without floating-point drift (`width * 9 == height * 16`).
      @[SolvinCodex::HotPath]
      @[SolvinCodex::ZeroAllocation]
      def aspect_ratio_16_9? : Bool
        @width > 0 && @height > 0 && (@width * 9) == (@height * 16)
      end

      # Compute uniform CSS scale factor `min(viewport_w / width, viewport_h / height)`.
      @[SolvinCodex::HotPath]
      @[SolvinCodex::ZeroAllocation]
      def compute_scale(viewport_w : Int32, viewport_h : Int32) : Float64
        return 1.0 if @width <= 0 || @height <= 0
        scale_x = viewport_w.to_f64 / @width.to_f64
        scale_y = viewport_h.to_f64 / @height.to_f64
        scale_x < scale_y ? scale_x : scale_y
      end
    end
  end
end
