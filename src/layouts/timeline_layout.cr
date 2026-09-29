require "./layout_renderer"

module LapisSlides
  class TimelineLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body timeline-container\" style=\"display: flex; flex-direction: column; gap: 0.6rem; align-items: stretch; flex: 1;\">\n"

        if cards = slide.raw["cards"]?.try(&.as_a)
          # Visual Timeline Rail Track with Year Steps
          str << "          <div class=\"timeline-rail-wrap\">\n"
          str << "            <div class=\"timeline-line\"></div>\n"
          str << "            <div class=\"timeline-track\">\n"
          cards.each do |c|
            year = c["year"]?.try(&.as_s) || begin
              ph = c["phase"]?.try(&.as_s) || ""
              if ph.includes?("•")
                ph.split("•").last.strip
              else
                "ERA"
              end
            end
            str << "              <div class=\"timeline-step\">\n"
            str << "                <span class=\"timeline-year\">" << LayoutRenderer.tint_emojis(HTML.escape(year)) << "</span>\n"
            str << "                <span class=\"timeline-dot\"></span>\n"
            str << "              </div>\n"
          end
          str << "            </div>\n"
          str << "          </div>\n"

          # Cards Grid Underneath Track
          str << "          <div class=\"timeline-cards\">\n"
          cards.each do |c|
            title = c["title"]?.try(&.as_s) || ""
            phase = c["phase"]?.try(&.as_s) || ""
            color = c["color"]?.try(&.as_s) || "blue"
            items = Array(String).new
            if raw_items = c["items"]?.try(&.as_a)
              raw_items.each { |it| items << LayoutRenderer.extract_item_text(it) }
            end

            str << "            <div class=\"timeline-card " << color << "\">\n"
            str << "              <div class=\"timeline-card-header\">\n"
            if !phase.empty?
              str << "                <span class=\"timeline-card-pill\">" << LayoutRenderer.tint_emojis(HTML.escape(phase)) << "</span>\n"
            end
            str << "                <div class=\"timeline-card-title\">" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</div>\n"
            str << "              </div>\n"
            str << "              <ul class=\"card-list\">\n"
            items.each do |it|
              str << "                <li>" << LayoutRenderer.tint_emojis(it) << "</li>\n"
            end
            str << "              </ul>\n"
            str << "            </div>\n"
          end
          str << "          </div>\n"
        end

        str << "        </div>"
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << "\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if cards = slide.raw["cards"]?.try(&.as_a)
          str << "- **Timeline Milestones**:\n"
          cards.each do |c|
            phase = c["phase"]?.try(&.as_s) || ""
            year = c["year"]?.try(&.as_s) || ""
            title = c["title"]?.try(&.as_s) || ""
            header_str = [phase, year, title].reject(&.empty?).join(" • ")
            str << "  - **" << header_str << "**:\n"
            if raw_items = c["items"]?.try(&.as_a)
              raw_items.each do |it|
                str << "    - " << LayoutRenderer.clean_text(LayoutRenderer.extract_item_text(it)) << "\n"
              end
            end
          end
        end

        if !slide.notes.empty?
          str << "- **Presenter Script**:\n"
          str << "  > *\"" << slide.notes.strip.gsub("\n", " ") << "\"*\n"
        end
        str << "\n---\n"
      end
    end
  end
end
