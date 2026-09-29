require "./layout_renderer"

module LapisSlides
  class MediaLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      media = slide.raw["media"]?
      card = slide.raw["card"]?

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body\" style=\"display: flex; gap: 1.2rem; align-items: stretch; flex: 1;\">\n"

        if media
          m_src = media["src"]?.try(&.as_s) || ""
          m_title = media["title"]?.try(&.as_s) || "Media"
          m_tag = media["tag"]?.try(&.as_s) || "Video"
          m_type = media["type"]?.try(&.as_s) || "video"

          str << "          <div class=\"code-container col-3\" style=\"display: flex; flex-direction: column; overflow: hidden; border-color: var(--accent-color);\">\n"
          str << "            <div class=\"code-header\">\n"
          str << "              <div class=\"terminal-dots\">\n"
          str << "                <span class=\"terminal-dot red\" title=\"Close\"></span>\n"
          str << "                <span class=\"terminal-dot yellow\" title=\"Minimize\"></span>\n"
          str << "                <span class=\"terminal-dot green\" title=\"Maximize\"></span>\n"
          str << "              </div>\n"
          str << "              <span class=\"code-title\">" << LayoutRenderer.tint_emojis(HTML.escape(m_title)) << "</span>\n"
          str << "              <div class=\"window-controls\">\n"
          str << "                <span class=\"code-lang-tag\">" << HTML.escape(m_tag) << "</span>\n"
          str << "                <span class=\"window-btn close\" title=\"Close\">✕</span>\n"
          str << "              </div>\n"
          str << "            </div>\n"
          str << "            <div style=\"flex: 1; display: flex; flex-direction: column; justify-content: center; align-items: center; background: var(--bg-window); overflow: hidden; position: relative;\">\n"

          if m_type == "video"
            str << "              <video controls preload=\"auto\" playsinline style=\"width: 100%; max-height: 380px; object-fit: contain; outline: none; border: none; display: block;\">\n"
            str << "                <source src=\"" << m_src << "\" type=\"video/mp4\">\n"
            str << "                Your browser does not support the video tag.\n"
            str << "              </video>\n"
          else
            str << "              <img src=\"" << m_src << "\" style=\"max-width: 100%; max-height: 380px; object-fit: contain;\">\n"
          end

          str << "            </div>\n"

          if caption = media["caption"]?
            speaker = caption["speaker"]?.try(&.as_s) || ""
            quote = caption["quote"]?.try(&.as_s) || ""
            str << "            <div style=\"padding: 0.55rem 0.9rem; background: var(--bg-window); border-top: 1px solid var(--border-color); font-size: 0.82rem; font-style: italic; color: var(--text-color); display: flex; align-items: center; gap: 0.5rem;\">\n"
            if !speaker.empty?
              str << "              <span style=\"font-style: normal; font-weight: 700; color: var(--accent-color);\">" << HTML.escape(speaker) << "</span>\n"
            end
            str << "              <span>" << LayoutRenderer.tint_emojis(HTML.escape(quote)) << "</span>\n"
            str << "            </div>\n"
          end

          str << "          </div>\n"
        end

        if card
          c_title = card["title"]?.try(&.as_s) || ""
          c_color = card["color"]?.try(&.as_s) || "purple"
          c_items = Array(String).new
          if raw_items = card["items"]?.try(&.as_a)
            raw_items.each { |it| c_items << it.as_s }
          end
          str << render_card(c_title, c_color, c_items, "col-2") << "\n"
        end

        str << "        </div>"
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      media = slide.raw["media"]?
      card = slide.raw["card"]?

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << "\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if media
          m_src = media["src"]?.try(&.as_s) || ""
          m_title = media["title"]?.try(&.as_s) || ""
          quote = media["caption"]?.try(&.["quote"]?.try(&.as_s)) || ""
          str << "- **Embedded Media**: `" << m_src << "` (" << m_title << (quote.empty? ? "" : " — #{quote}") << ")\n"
        end

        if card
          str << "- **" << card["title"]?.try(&.as_s) << "**:\n"
          if raw_items = card["items"]?.try(&.as_a)
            raw_items.each do |it|
              str << "  - " << LayoutRenderer.clean_text(it.as_s) << "\n"
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
