require "./builder"

module LapisSlides
  module DSL
    # Compile-time AST macro to synthesize a static SlideSpec generator method.
    macro def_slide(method_name, id, layout = "two-column", &block)
      def self.{{method_name.id}} : ::LapisSlides::Core::SlideSpec
        ::LapisSlides::DSL.slide({{id}}, {{layout}}) {{block}}
      end
    end

    # Compile-time AST macro to synthesize a static DeckSpec generator method.
    macro def_deck(method_name, title, &block)
      def self.{{method_name.id}} : ::LapisSlides::Core::DeckSpec
        ::LapisSlides::DSL.deck({{title}}) {{block}}
      end
    end
  end
end
