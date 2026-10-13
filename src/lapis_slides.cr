require "./lapis_slides/codex"
require "./lapis_slides/core/stage"
require "./lapis_slides/core/models"
require "./lapis_slides/core/validator"
require "./lapis_slides/core/compiler"
require "./lapis_slides/dsl/builder"
require "./lapis_slides/dsl/macros"

module LapisSlides
  VERSION = "0.2.40"

  # Convenience delegation to Tier-2 DSL builders
  def self.deck(title : String = "Lapis for Crystal", &block : DSL::DeckBuilder ->) : Core::DeckSpec
    DSL.deck(title, &block)
  end

  def self.slide(id : String, layout : String = "two-column", &block : DSL::SlideBuilder ->) : Core::SlideSpec
    DSL.slide(id, layout, &block)
  end

  # Tier-1 Invariant validation
  def self.validate(deck : Core::DeckSpec) : Array(Core::ValidationIssue)
    Core::DeckValidator.validate(deck)
  end
end
