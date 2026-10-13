require "./lapis_slides/codex"
require "./lapis_slides/core/stage"
require "./lapis_slides/core/models"
require "./lapis_slides/core/validator"
require "./lapis_slides/core/compiler"
require "./lapis_slides/core/cfp"
require "./lapis_slides/core/keynote"
require "./lapis_slides/dsl/builder"
require "./lapis_slides/dsl/macros"
require "./lapis_slides/dsl/talk_builder"

module LapisSlides
  VERSION = "0.2.41"

  # Convenience delegation to Tier-2 DSL builders
  def self.deck(title : String = "Lapis for Crystal", &block : DSL::DeckBuilder ->) : Core::DeckSpec
    DSL.deck(title, &block)
  end

  def self.slide(id : String, layout : String = "two-column", &block : DSL::SlideBuilder ->) : Core::SlideSpec
    DSL.slide(id, layout, &block)
  end

  def self.cfp(title : String, &block : DSL::CfpBuilder ->) : Core::CfpSubmissionSpec
    DSL.cfp(title, &block)
  end

  def self.keynote(title : String, &block : DSL::KeynoteBuilder ->) : Core::KeynoteChoreographySpec
    DSL.keynote(title, &block)
  end

  # Tier-1 Invariant validation
  def self.validate(deck : Core::DeckSpec) : Array(Core::ValidationIssue)
    Core::DeckValidator.validate(deck)
  end

  def self.validate_cfp(cfp : Core::CfpSubmissionSpec) : Array(Core::CfpValidationError)
    Core::CfpValidator.validate(cfp)
  end

  def self.validate_choreography(choreography : Core::KeynoteChoreographySpec) : Array(Core::ChoreographyValidationError)
    Core::ChoreographyValidator.validate(choreography)
  end
end

