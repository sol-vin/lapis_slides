require "./layout_renderer"

module LapisSlides
  class IntroLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      cube_size = slide.raw["cube_size"]?.try(&.as_i) || 420
      cards = slide.raw["cards"]?.try(&.as_a)
      quickstart = slide.raw["quickstart"]?.try(&.as_s)
      signature = slide.raw["signature"]?.try(&.as_s) || slide.raw["presenter"]?.try(&.as_s)

      hero_cube = "<div class=\"hero-cube intro-cube\" data-size=\"#{cube_size}\" title=\"Spinning 3D Isometric Cube • Click or Drag to Spin!\"></div>"

      body = String.build do |str|
        # Big wireframe cube in the background
        str << "        " << hero_cube << "\n"

        # Foreground content overlay
        str << "        <div class=\"intro-content\" style=\"position: relative; z-index: 5; display: flex; flex-direction: column; gap: 0.75rem; flex: 1;\">\n"
        str << render_slide_header(slide) << "\n"

        if cards
          str << "          <div class=\"intro-cards-grid\">\n"
          cards.each do |c|
            title = c["title"]?.try(&.as_s) || ""
            badge = c["badge"]?.try(&.as_s) || ""
            icon = c["icon"]?.try(&.as_s) || "★"
            color = c["color"]?.try(&.as_s) || "cyan"
            tagline = c["tagline"]?.try(&.as_s) || c["link"]?.try(&.as_s) || ""
            desc = c["desc"]?.try(&.as_s) || ""

            str << "            <div class=\"intro-card " << color << "\">\n"
            str << "              <div class=\"intro-card-header\">\n"
            str << "                <div class=\"intro-card-title-wrap\">\n"
            str << "                  <span class=\"intro-icon\">" << LayoutRenderer.tint_emojis(icon) << "</span>\n"
            str << "                  <span class=\"intro-title\">" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</span>\n"
            str << "                </div>\n"
            if !badge.empty?
              str << "                <span class=\"badge-pill " << color << "\" style=\"font-size: 0.58rem; margin: 0;\">" << HTML.escape(badge) << "</span>\n"
            end
            str << "              </div>\n"

            if !tagline.empty?
              str << "              <div class=\"intro-tagline\">\n"
              str << "                <code>" << HTML.escape(tagline) << "</code>\n"
              str << "              </div>\n"
            end

            if !desc.empty?
              str << "              <div class=\"intro-desc\">\n"
              str << "                " << LayoutRenderer.tint_emojis(desc) << "\n"
              str << "              </div>\n"
            end

            if raw_items = c["items"]?.try(&.as_a)
              str << "              <ul class=\"card-list intro-card-list\">\n"
              raw_items.each do |it|
                str << "                <li>" << LayoutRenderer.tint_emojis(it.as_s) << "</li>\n"
              end
              str << "              </ul>\n"
            end

            str << "            </div>\n"
          end
          str << "          </div>\n"
        end

        if quickstart
          str << "          <div class=\"intro-quickstart-bar\">\n"
          str << "            <span class=\"intro-quickstart-label\">🚀 Quickstart:</span>\n"
          str << "            <code class=\"intro-quickstart-code\">" << HTML.escape(quickstart) << "</code>\n"
          str << "          </div>\n"
        end

        if signature
          str << "          <div class=\"intro-signature\">\n"
          str << "            " << LayoutRenderer.tint_emojis(signature) << "\n"
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
          str << "- **Key Pillars**:\n"
          cards.each do |c|
            title = c["title"]?.try(&.as_s) || ""
            tagline = c["tagline"]?.try(&.as_s) || c["link"]?.try(&.as_s) || ""
            desc = c["desc"]?.try(&.as_s) || ""
            str << "  - **" << title << "**"
            str << " (`" << tagline << "`)" unless tagline.empty?
            str << ": " << LayoutRenderer.clean_text(desc) << "\n"
          end
        end

        if quickstart = slide.raw["quickstart"]?.try(&.as_s)
          str << "- **Quickstart**: `" << quickstart << "`\n"
        end

        if signature = slide.raw["signature"]?.try(&.as_s) || slide.raw["presenter"]?.try(&.as_s)
          str << "- **Presenter**: " << LayoutRenderer.clean_text(signature) << "\n"
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
