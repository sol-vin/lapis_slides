require "./spec_helper"

describe LapisSlides::Core::StageResolution do
  describe "#aspect_ratio_16_9?" do
    it "verifies standard 16:9 resolutions" do
      LapisSlides::Core::StageResolution::STANDARD_960x540.aspect_ratio_16_9?.should be_true
      LapisSlides::Core::StageResolution::HD_1280x720.aspect_ratio_16_9?.should be_true
      LapisSlides::Core::StageResolution::FULL_HD_1920x1080.aspect_ratio_16_9?.should be_true
    end

    it "rejects non-16:9 aspect ratios" do
      res_4_3 = LapisSlides::Core::StageResolution.new(1024, 768)
      res_4_3.aspect_ratio_16_9?.should be_false

      res_16_10 = LapisSlides::Core::StageResolution.new(1920, 1200)
      res_16_10.aspect_ratio_16_9?.should be_false
    end

    it "handles zero and negative dimensions safely" do
      LapisSlides::Core::StageResolution.new(0, 0).aspect_ratio_16_9?.should be_false
      LapisSlides::Core::StageResolution.new(-16, -9).aspect_ratio_16_9?.should be_false
    end
  end

  describe "#compute_scale" do
    it "calculates uniform scaling factor constrained by viewport dimensions" do
      stage = LapisSlides::Core::StageResolution::HD_1280x720
      # Matching ratio: 2560x1440 -> scale is 2.0
      stage.compute_scale(2560, 1440).should eq(2.0)

      # Width-constrained: 640x720 -> scale is 0.5
      stage.compute_scale(640, 720).should eq(0.5)

      # Height-constrained: 1280x360 -> scale is 0.5
      stage.compute_scale(1280, 360).should eq(0.5)
    end
  end
end
