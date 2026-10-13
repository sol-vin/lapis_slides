require "html"
require "./models"
require "./validator"

module LapisSlides
  module Core
    # Tier-1 Compiler emitting Sunstone YAML manifests, modular slide YAMLs,
    # zero-inline-style semantic HTML, and SLIDES.md speaker scripts.
    class DeckCompiler
      def self.emit_deck_yaml(deck : DeckSpec) : String
        String.build do |io|
          io << "title: " << deck.title.inspect << "\n"
          io << "subtitle: " << deck.subtitle.inspect << "\n"
          io << "author: " << deck.author.inspect << "\n"
          io << "author_url: " << deck.author_url.inspect << "\n"
          io << "theme: " << deck.theme.inspect << "\n"
          io << "width: " << deck.stage.width << "\n"
          io << "height: " << deck.stage.height << "\n\n"
          io << "header:\n"
          io << "  enabled: " << deck.header_enabled << "\n"
          io << "  label: " << deck.header_label.inspect << "\n"
          io << "  cube: " << deck.header_cube << "\n\n"
          io << "footer_left: " << deck.footer_left.inspect << "\n"
          io << "footer_center: " << deck.footer_center.inspect << "\n"
          io << "footer_right: " << deck.footer_right.inspect << "\n"
          io << "default_palette: " << deck.default_palette.inspect << "\n\n"
          io << "slides:\n"
          deck.slides.each do |slide|
            io << "  - slides/" << slide.id << ".yml\n"
          end
        end
      end

      def self.emit_slide_yaml(slide : SlideSpec) : String
        String.build do |io|
          io << "id: " << slide.id.inspect << "\n"
          io << "layout: " << slide.layout.inspect << "\n"
          io << "badge: " << slide.badge.inspect << "\n"
          io << "badge_color: " << slide.badge_color.inspect << "\n"
          io << "palette: " << slide.palette.inspect << "\n"
          io << "title: " << slide.title.inspect << "\n"
          io << "subtitle: " << slide.subtitle.inspect << "\n"

          case slide.layout
          when "intro"
            io << "author: " << slide.author.inspect << "\n" unless slide.author.empty?
            io << "author_role: " << slide.author_role.inspect << "\n" unless slide.author_role.empty?
            unless slide.pills.empty?
              io << "pills:\n"
              slide.pills.each { |p| io << "  - " << p.inspect << "\n" }
            end
          when "chapter"
            io << "chapter_number: " << slide.chapter_number.inspect << "\n"
            io << "cube: " << slide.cube << "\n"
            io << "cube_size: " << slide.cube_size << "\n"
            unless slide.pillars.empty?
              io << "pillars:\n"
              slide.pillars.each do |p|
                io << "  - title: " << p.title.inspect << "\n"
                io << "    desc: " << p.desc.inspect << "\n"
                io << "    icon: " << p.icon.inspect << "\n"
                io << "    color: " << p.color.inspect << "\n"
              end
            end
          when "two-column"
            io << "ratio: " << slide.ratio.inspect << "\n"
            if left = slide.left
              emit_slot_yaml(io, "left", left)
            end
            if right = slide.right
              emit_slot_yaml(io, "right", right)
            end
          when "code-comparison"
            if before = slide.before
              emit_comparison_side_yaml(io, "before", before)
            end
            if after = slide.after
              emit_comparison_side_yaml(io, "after", after)
            end
          when "architecture"
            unless slide.tiers.empty?
              io << "tiers:\n"
              slide.tiers.each do |t|
                io << "  - title: " << t.title.inspect << "\n"
                io << "    label: " << t.label.inspect << "\n"
                io << "    badge: " << t.badge.inspect << "\n"
                io << "    color: " << t.color.inspect << "\n"
                io << "    columns: " << t.columns << "\n"
                io << "    blocks:\n"
                t.blocks.each do |b|
                  io << "      - title: " << b.title.inspect << "\n"
                  io << "        desc: " << b.desc.inspect << "\n"
                end
              end
            end
          when "dual-mode"
            io << "banner: " << slide.banner.inspect << "\n" unless slide.banner.empty?
            unless slide.modes.empty?
              io << "modes:\n"
              slide.modes.each do |m|
                io << "  - title: " << m.title.inspect << "\n"
                io << "    badge: " << m.badge.inspect << "\n"
                io << "    color: " << m.color.inspect << "\n"
                io << "    flow: " << m.flow.inspect << "\n"
                io << "    desc: " << m.desc.inspect << "\n"
                io << "    specs:\n"
                m.specs.each do |sp|
                  io << "      - icon: " << sp.icon.inspect << "\n"
                  io << "        label: " << sp.label.inspect << "\n"
                  io << "        value: " << sp.value.inspect << "\n"
                end
              end
            end
            io << "summary: " << slide.summary.inspect << "\n" unless slide.summary.empty?
          when "feature-grid"
            if hf = slide.hero_feature
              io << "hero_feature:\n"
              io << "  title: " << hf.title.inspect << "\n"
              io << "  badge: " << hf.badge.inspect << "\n"
              io << "  color: " << hf.color.inspect << "\n"
              io << "  code: |\n"
              hf.code.lines.each { |line| io << "    " << line << "\n" }
              io << "  desc: " << hf.desc.inspect << "\n"
            end
            unless slide.features.empty?
              io << "features:\n"
              slide.features.each do |f|
                io << "  - title: " << f.title.inspect << "\n"
                io << "    badge: " << f.badge.inspect << "\n"
                io << "    color: " << f.color.inspect << "\n"
                io << "    items:\n"
                f.items.each { |it| io << "      - " << it.inspect << "\n" }
              end
            end
          when "process-flow"
            unless slide.steps.empty?
              io << "steps:\n"
              slide.steps.each do |st|
                io << "  - step: " << st.step.inspect << "\n"
                io << "    title: " << st.title.inspect << "\n"
                io << "    badge: " << st.badge.inspect << "\n"
                io << "    color: " << st.color.inspect << "\n"
                io << "    icon: " << st.icon.inspect << "\n"
                io << "    desc: " << st.desc.inspect << "\n"
              end
            end
          when "stats"
            unless slide.metrics.empty?
              io << "metrics:\n"
              slide.metrics.each do |m|
                io << "  - value: " << m.value.inspect << "\n"
                io << "    label: " << m.label.inspect << "\n"
                io << "    delta: " << m.delta.inspect << "\n"
                io << "    color: " << m.color.inspect << "\n"
                io << "    icon: " << m.icon.inspect << "\n"
                if prog = m.progress
                  io << "    progress: " << prog << "\n"
                end
                unless m.sparkline.empty?
                  io << "    sparkline: [" << m.sparkline.join(", ") << "]\n"
                end
                io << "    desc: " << m.desc.inspect << "\n"
              end
            end
          when "matrix"
            unless slide.headers.empty?
              io << "headers:\n"
              slide.headers.each { |h| io << "  - " << h.inspect << "\n" }
            end
            unless slide.rows.empty?
              io << "rows:\n"
              slide.rows.each do |row|
                io << "  - [" << row.map(&.inspect).join(", ") << "]\n"
              end
            end
            io << "summary: " << slide.summary.inspect << "\n" unless slide.summary.empty?
          when "timeline"
            unless slide.timeline_cards.empty?
              io << "cards:\n"
              slide.timeline_cards.each do |c|
                io << "  - year: " << c.year.inspect << "\n"
                io << "    title: " << c.title.inspect << "\n"
                io << "    phase: " << c.phase.inspect << "\n"
                io << "    color: " << c.color.inspect << "\n"
                io << "    items:\n"
                c.items.each { |it| io << "      - " << it.inspect << "\n" }
              end
            end
          when "closing"
            unless slide.closing_cards.empty?
              io << "cards:\n"
              slide.closing_cards.each do |c|
                io << "  - title: " << c.title.inspect << "\n"
                io << "    badge: " << c.badge.inspect << "\n"
                io << "    icon: " << c.icon.inspect << "\n"
                io << "    color: " << c.color.inspect << "\n"
                io << "    link: " << c.link.inspect << "\n"
                io << "    desc: " << c.desc.inspect << "\n"
              end
            end
            io << "quickstart: " << slide.quickstart.inspect << "\n" unless slide.quickstart.empty?
            io << "signature: " << slide.signature.inspect << "\n" unless slide.signature.empty?
          end

          unless slide.notes.empty?
            io << "notes: |\n"
            slide.notes.lines.each { |line| io << "  " << line << "\n" }
          end
        end
      end

      private def self.emit_slot_yaml(io : IO, key : String, slot : SlotSpec)
        io << key << ":\n"
        io << "  type: " << slot.slot_type.inspect << "\n"
        io << "  title: " << slot.title.inspect << "\n"
        case slot.slot_type
        when "code"
          io << "  tag: " << slot.tag.inspect << "\n" unless slot.tag.empty?
          io << "  lang: " << slot.lang.inspect << "\n"
          io << "  code: |\n"
          slot.code.lines.each { |line| io << "    " << line << "\n" }
        when "chart"
          io << "  chart_type: " << slot.chart_type.inspect << "\n"
          io << "  badge: " << slot.badge.inspect << "\n" unless slot.badge.empty?
          io << "  color: " << slot.color.inspect << "\n"
          io << "  highlight_color: " << slot.highlight_color.inspect << "\n"
          io << "  highlight_index: " << slot.highlight_index << "\n"
          io << "  labels:\n"
          slot.labels.each { |lbl| io << "    - " << lbl.inspect << "\n" }
          io << "  values:\n"
          slot.values.each { |val| io << "    - " << val << "\n" }
        else
          io << "  color: " << slot.color.inspect << "\n"
          io << "  items:\n"
          slot.items.each { |it| io << "    - " << it.inspect << "\n" }
        end
      end

      private def self.emit_comparison_side_yaml(io : IO, key : String, side : ComparisonSideSpec)
        io << key << ":\n"
        io << "  title: " << side.title.inspect << "\n"
        io << "  lang: " << side.lang.inspect << "\n"
        io << "  code: |\n"
        side.code.lines.each { |line| io << "    " << line << "\n" }
        io << "  points:\n"
        side.points.each { |pt| io << "    - " << pt.inspect << "\n" }
      end

      # Emit clean zero-inline-style semantic HTML (`index.html`) for the deck
      def self.emit_semantic_html(deck : DeckSpec) : String
        String.build do |io|
          io << "<!DOCTYPE html>\n"
          io << "<html lang=\"en\" data-theme=\"" << HTML.escape(deck.theme) << "\">\n"
          io << "<head>\n"
          io << "  <meta charset=\"utf-8\">\n"
          io << "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
          io << "  <title>" << HTML.escape(deck.title) << " — " << HTML.escape(deck.subtitle) << "</title>\n"
          io << "  <link rel=\"stylesheet\" href=\"theme.css\">\n"
          io << "</head>\n"
          io << "<body data-stage-width=\"" << deck.stage.width << "\" data-stage-height=\"" << deck.stage.height << "\">\n"
          io << "  <div class=\"reveal\">\n"
          io << "    <div class=\"slides\">\n"
          deck.slides.each_with_index do |slide, idx|
            io << "      <section id=\"" << HTML.escape(slide.id) << "\" "
            io << "data-layout=\"" << HTML.escape(slide.layout) << "\" "
            io << "data-palette=\"" << HTML.escape(slide.palette) << "\" "
            io << "data-slide-number=\"" << (idx + 1) << "\">\n"
            io << "        <header class=\"slide-header\">\n"
            io << "          <span class=\"slide-badge\" data-color=\"" << HTML.escape(slide.badge_color) << "\">" << HTML.escape(slide.badge) << "</span>\n"
            io << "          <h2>" << HTML.escape(slide.title) << "</h2>\n"
            io << "          <p class=\"slide-subtitle\">" << HTML.escape(slide.subtitle) << "</p>\n"
            io << "        </header>\n"
            io << "        <aside class=\"notes\">" << HTML.escape(slide.notes) << "</aside>\n"
            io << "      </section>\n"
          end
          io << "    </div>\n"
          io << "  </div>\n"
          io << "</body>\n"
          io << "</html>\n"
        end
      end

      # Emit speaker reference Markdown (`SLIDES.md`)
      def self.emit_speaker_markdown(deck : DeckSpec) : String
        String.build do |io|
          io << "# " << deck.title << "\n\n"
          io << "> **" << deck.subtitle << "**  \n"
          io << "> Author: " << deck.author << " | Theme: `" << deck.theme << "` | Stage: `" << deck.stage.width << "x" << deck.stage.height << "`\n\n"
          io << "---\n\n"
          deck.slides.each_with_index do |slide, idx|
            io << "## Slide " << (idx + 1) << ": " << slide.title << " (`" << slide.id << "`)\n\n"
            io << "- **Layout**: `" << slide.layout << "`\n"
            io << "- **Palette**: `" << slide.palette << "`\n"
            io << "- **Badge**: `" << slide.badge << "`\n"
            io << "- **Subtitle**: " << slide.subtitle << "\n\n"
            unless slide.notes.empty?
              io << "### Speaker Notes\n\n"
              io << slide.notes.strip << "\n\n"
            end
            io << "---\n\n"
          end
        end
      end

      # Write full Sunstone project directory (`deck.yml`, `slides/*.yml`, `SLIDES.md`, `index.html`)
      def self.write_project(deck : DeckSpec, target_dir : String) : Tuple(String, Int32)
        slides_dir = File.join(target_dir, "slides")
        Dir.mkdir_p(slides_dir)

        deck_yml_path = File.join(target_dir, "deck.yml")
        File.write(deck_yml_path, emit_deck_yaml(deck))

        deck.slides.each do |slide|
          slide_path = File.join(slides_dir, "#{slide.id}.yml")
          File.write(slide_path, emit_slide_yaml(slide))
        end

        File.write(File.join(target_dir, "SLIDES.md"), emit_speaker_markdown(deck))
        File.write(File.join(target_dir, "index.html"), emit_semantic_html(deck))

        {deck_yml_path, deck.slides.size}
      end
    end
  end
end
