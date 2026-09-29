require "./layout_renderer"

module LapisSlides
  class DualModeLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      modes = slide.raw["modes"]?.try(&.as_a)
      banner = slide.raw["banner"]?.try(&.as_s)
      summary = slide.raw["summary"]?.try(&.as_s)

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body dual-mode-body\" style=\"display: flex; flex-direction: column; gap: 0.75rem; flex: 1;\">\n"

        if banner
          str << "          <div class=\"self-hosted-banner\">\n"
          str << "            <span class=\"banner-icon\">💎</span>\n"
          str << "            <div class=\"banner-text\">" << LayoutRenderer.tint_emojis(banner) << "</div>\n"
          str << "          </div>\n"
        end

        if modes
          str << "          <div class=\"dual-mode-grid\">\n"
          modes.each do |m|
            title = m["title"]?.try(&.as_s) || ""
            badge = m["badge"]?.try(&.as_s) || ""
            flow = m["flow"]?.try(&.as_s) || ""
            color = m["color"]?.try(&.as_s) || "cyan"
            desc = m["desc"]?.try(&.as_s) || ""

            str << "            <div class=\"dual-mode-card " << color << "\">\n"
            str << "              <div class=\"dual-mode-header\">\n"
            str << "                <div class=\"dual-mode-title-wrap\">\n"
            str << "                  <h3 class=\"dual-mode-title\">" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</h3>\n"
            if !badge.empty?
              str << "                  <span class=\"badge-pill " << color << "\">" << HTML.escape(badge) << "</span>\n"
            end
            str << "                </div>\n"
            if !flow.empty?
              str << "                <div class=\"dual-mode-flow\">\n"
              str << "                  <code>" << flow << "</code>\n"
              str << "                </div>\n"
            end
            str << "              </div>\n"

            if specs = m["specs"]?.try(&.as_a)
              str << "              <div class=\"dual-mode-specs\">\n"
              specs.each do |s|
                label = s["label"]?.try(&.as_s) || ""
                value = s["value"]?.try(&.as_s) || ""
                icon = s["icon"]?.try(&.as_s) || "•"
                str << "                <div class=\"dual-mode-spec-row\">\n"
                str << "                  <span class=\"spec-label\"><span class=\"spec-icon\">" << LayoutRenderer.tint_emojis(icon) << "</span> " << HTML.escape(label) << "</span>\n"
                str << "                  <span class=\"spec-value\">" << LayoutRenderer.tint_emojis(value) << "</span>\n"
                str << "                </div>\n"
              end
              str << "              </div>\n"
            end

            if !desc.empty?
              str << "              <div class=\"dual-mode-desc\">\n"
              str << "                " << LayoutRenderer.tint_emojis(desc) << "\n"
              str << "              </div>\n"
            end

            str << "            </div>\n"
          end
          str << "          </div>\n"
        end

        if summary
          str << "          <div class=\"dual-mode-summary\">\n"
          str << "            " << LayoutRenderer.tint_emojis(summary) << "\n"
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

        if banner = slide.raw["banner"]?.try(&.as_s)
          str << "- **Architecture Highlight**: " << LayoutRenderer.clean_text(banner) << "\n"
        end

        if modes = slide.raw["modes"]?.try(&.as_a)
          modes.each do |m|
            title = m["title"]?.try(&.as_s) || ""
            badge = m["badge"]?.try(&.as_s) || ""
            str << "- **" << title << " (" << badge << ")**:\n"
            if flow = m["flow"]?.try(&.as_s)
              str << "  - *Flow*: `" << LayoutRenderer.clean_text(flow) << "`\n"
            end
            if specs = m["specs"]?.try(&.as_a)
              specs.each do |s|
                label = s["label"]?.try(&.as_s) || ""
                value = s["value"]?.try(&.as_s) || ""
                str << "  - **" << label << "**: " << LayoutRenderer.clean_text(value) << "\n"
              end
            end
          end
        end

        if summary = slide.raw["summary"]?.try(&.as_s)
          str << "- **Takeaway**: " << LayoutRenderer.clean_text(summary) << "\n"
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
