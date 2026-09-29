require "./layout_renderer"

module LapisSlides
  class ArchitectureLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      layers = slide.raw["layers"]?.try(&.as_a)
      side_cards = slide.raw["side_cards"]?.try(&.as_a)

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body\" style=\"gap: 0.80rem; align-items: stretch; max-height: 485px; overflow: hidden;\">\n"

        # LEFT COLUMN: Architecture Layers
        str << "          <div class=\"col-3\" style=\"display: flex; flex-direction: column; gap: 0.08rem; justify-content: space-between;\">\n"

        if layers
          layers.each_with_index do |l, idx|
            num = l["num"]?.try(&.as_s) || "L#{5 - idx}"
            title = l["title"]?.try(&.as_s) || ""
            desc = l["desc"]?.try(&.as_s) || ""
            flow = l["flow"]?.try(&.as_s)
            pills = Array(String).new
            if raw_pills = l["pills"]?.try(&.as_a)
              raw_pills.each { |p| pills << p.as_s }
            end

            layer_num = 5 - idx
            layer_id = "l#{layer_num} layer#{layer_num}"

            str << "            <div class=\"arch-layer-card " << layer_id << "\">\n"
            str << "              <div class=\"arch-layer-header\">\n"
            str << "                <span class=\"arch-layer-num " << layer_id << "\">" << LayoutRenderer.tint_emojis(HTML.escape(num)) << "</span>\n"
            str << "                <span class=\"arch-layer-title\">" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</span>\n"
            if !pills.empty?
              str << "                <div class=\"arch-layer-pills\" style=\"margin-left: auto;\">\n"
              pills.each do |p|
                str << "                  <span class=\"arch-pill " << layer_id << "\">" << LayoutRenderer.tint_emojis(HTML.escape(p)) << "</span>\n"
              end
              str << "                </div>\n"
            end
            str << "              </div>\n"
            str << "              <div class=\"arch-layer-desc\">" << LayoutRenderer.tint_emojis(desc) << "</div>\n"
            str << "            </div>\n"

            if flow
              str << "            <div class=\"arch-layer-flow\">" << LayoutRenderer.tint_emojis(flow) << "</div>\n"
            end
          end
        end

        str << "          </div>\n"

        # RIGHT COLUMN: Side Cards
        str << "          <div class=\"col-2\" style=\"display: flex; flex-direction: column; gap: 0.35rem; justify-content: flex-start;\">\n"

        if side_cards
          side_cards.each do |sc|
            title = sc["title"]?.try(&.as_s) || ""
            color = sc["color"]?.try(&.as_s) || "purple"
            items = Array(String).new
            if raw_items = sc["items"]?.try(&.as_a)
              raw_items.each { |it| items << LayoutRenderer.extract_item_text(it) }
            end

            str << "            <div class=\"arch-side-card " << color << "\">\n"
            str << "              <div class=\"card-title " << color << "\">" << HTML.escape(title) << "</div>\n"
            str << "              <ul class=\"card-list\">\n"
            items.each do |it|
              str << "                <li>" << it << "</li>\n"
            end
            str << "              </ul>\n"
            str << "            </div>\n"
          end
        end

        str << "          </div>\n"
        str << "        </div>"
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      layers = slide.raw["layers"]?.try(&.as_a)
      side_cards = slide.raw["side_cards"]?.try(&.as_a)

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << "\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if layers
          str << "- **Architecture Layers (Top to Bottom)**:\n"
          layers.each do |l|
            str << "  - **" << l["num"]?.try(&.as_s) << ": " << l["title"]?.try(&.as_s) << "**:\n"
            str << "    - " << LayoutRenderer.clean_text(l["desc"]?.try(&.as_s) || "") << "\n"
          end
        end

        if side_cards
          str << "- **Architectural Invariants & Bridges**:\n"
          side_cards.each do |sc|
            str << "  - **" << sc["title"]?.try(&.as_s) << "**:\n"
            if raw_items = sc["items"]?.try(&.as_a)
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
