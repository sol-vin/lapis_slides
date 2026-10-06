require "./layout_renderer"

module LapisSlides
  class MatrixLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      headers = Array(String).new
      if raw_headers = slide.raw["headers"]?.try(&.as_a)
        raw_headers.each { |h| headers << h.as_s }
      end

      rows = Array(Array(String)).new
      if raw_rows = slide.raw["rows"]?.try(&.as_a)
        raw_rows.each do |r|
          row_items = Array(String).new
          if r.as_a?
            r.as_a.each { |cell| row_items << cell.as_s }
          end
          rows << row_items
        end
      end

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body\" style=\"display: flex; flex-direction: column; gap: 0.8rem; flex: 1;\">\n"
        str << "          <table class=\"matrix-table\" style=\"width: 100%; border-collapse: collapse;\">\n"

        if !headers.empty?
          str << "            <thead>\n              <tr>\n"
          headers.each do |h|
            str << "                <th>" << h << "</th>\n"
          end
          str << "              </tr>\n            </thead>\n"
        end

        str << "            <tbody>\n"
        rows.each do |row|
          str << "              <tr>\n"
          row.each do |cell|
            str << "                <td>" << cell << "</td>\n"
          end
          str << "              </tr>\n"
        end
        str << "            </tbody>\n"
        str << "          </table>\n"

        if summary = slide.raw["summary"]?.try(&.as_s)
          str << "          <div class=\"takeaway-banner\" style=\"padding: 0.5rem 1rem; background: var(--bg-window); border: 1.5px solid var(--accent-color); border-radius: 8px; font-size: 0.9rem;\">\n"
          str << "            " << summary << "\n"
          str << "          </div>\n"
        end

        str << "        </div>"
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      headers = Array(String).new
      if raw_headers = slide.raw["headers"]?.try(&.as_a)
        raw_headers.each { |h| headers << LayoutRenderer.clean_text(h.as_s) }
      end

      rows = Array(Array(String)).new
      if raw_rows = slide.raw["rows"]?.try(&.as_a)
        raw_rows.each do |r|
          row_items = Array(String).new
          if r.as_a?
            r.as_a.each { |cell| row_items << LayoutRenderer.clean_text(cell.as_s) }
          end
          rows << row_items
        end
      end

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << "\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if !headers.empty?
          str << "- **Feature Comparison Matrix**:\n"
          str << "| " << headers.join(" | ") << " |\n"
          str << "| " << (["---"] * headers.size).join(" | ") << " |\n"
          rows.each do |r|
            str << "| " << r.join(" | ") << " |\n"
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
