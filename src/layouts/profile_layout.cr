require "./layout_renderer"

module LapisSlides
  class ProfileLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      stats = slide.raw["stats"]?.try(&.as_a)
      cards = slide.raw["cards"]?.try(&.as_a) || slide.raw["columns"]?.try(&.as_a)

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body profile-layout-body\">\n"

        if stats && !stats.empty?
          str << "          <div class=\"profile-stats-ribbon\">\n"
          stats.each do |st|
            icon = st["icon"]?.try(&.as_s) || "★"
            val = st["value"]?.try(&.as_s) || ""
            lbl = st["label"]?.try(&.as_s) || ""
            str << "            <div class=\"profile-stat-chip\">\n"
            str << "              <span class=\"stat-icon\">" << LayoutRenderer.tint_emojis(HTML.escape(icon)) << "</span>\n"
            str << "              <div class=\"stat-meta\">\n"
            str << "                <span class=\"stat-value\">" << LayoutRenderer.tint_emojis(HTML.escape(val)) << "</span>\n"
            str << "                <span class=\"stat-label\">" << LayoutRenderer.tint_emojis(HTML.escape(lbl)) << "</span>\n"
            str << "              </div>\n"
            str << "            </div>\n"
          end
          str << "          </div>\n"
        end

        if cards && !cards.empty?
          str << "          <div class=\"profile-bento-grid\">\n"
          cards.each do |c|
            title = c["title"]?.try(&.as_s) || ""
            color = c["color"]?.try(&.as_s) || "blue"
            badge = c["badge"]?.try(&.as_s)
            items = Array(String).new
            if raw_items = c["items"]?.try(&.as_a)
              raw_items.each { |it| items << LayoutRenderer.extract_item_text(it) }
            end

            str << "            <div class=\"card profile-card " << color << "\">\n"
            str << "              <div class=\"card-title " << color << "\">\n"
            str << "                <span>" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</span>\n"
            if badge
              str << "                <span class=\"badge-pill " << color << "\" style=\"font-size: 0.62rem; margin-left: auto;\">" << HTML.escape(badge) << "</span>\n"
            end
            str << "              </div>\n"
            str << "              <ul class=\"card-list\">\n"
            items.each do |item|
              str << "                <li>" << LayoutRenderer.tint_emojis(item) << "</li>\n"
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
      stats = slide.raw["stats"]?.try(&.as_a)
      cards = slide.raw["cards"]?.try(&.as_a) || slide.raw["columns"]?.try(&.as_a)

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << "\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if stats && !stats.empty?
          stat_strs = stats.map do |st|
            icon = st["icon"]?.try(&.as_s) || ""
            val = st["value"]?.try(&.as_s) || ""
            lbl = st["label"]?.try(&.as_s) || ""
            "#{icon} #{val} (#{lbl})"
          end
          str << "- **Key Credentials & Stats**: " << stat_strs.join(" | ") << "\n"
        end

        if cards && !cards.empty?
          cards.each do |c|
            title = c["title"]?.try(&.as_s) || "Details"
            badge = c["badge"]?.try(&.as_s)
            header_text = badge ? "#{title} [#{badge}]" : title
            str << "- **" << header_text << "**:\n"
            if raw_items = c["items"]?.try(&.as_a)
              raw_items.each do |it|
                str << "  - " << LayoutRenderer.clean_text(LayoutRenderer.extract_item_text(it)) << "\n"
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
