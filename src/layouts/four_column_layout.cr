require "./layout_renderer"

module LapisSlides
  class FourColumnLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body four-cols\" style=\"display: flex; gap: 0.6rem; align-items: stretch; flex: 1;\">\n"

        if columns = slide.raw["columns"]?.try(&.as_a)
          columns.each do |col|
            item_type = col["type"]?.try(&.as_s) || "card"
            if item_type == "code"
              title = col["title"]?.try(&.as_s) || ""
              lang = col["lang"]?.try(&.as_s) || "crystal"
              code = col["code"]?.try(&.as_s) || ""
              tag = col["tag"]?.try(&.as_s)
              str << render_code_container(title, lang, code, tag, "col") << "\n"
            else
              title = col["title"]?.try(&.as_s) || ""
              color = col["color"]?.try(&.as_s) || "blue"
              badge = col["badge"]?.try(&.as_s)
              items = Array(String).new
              if raw_items = col["items"]?.try(&.as_a)
                raw_items.each { |it| items << LayoutRenderer.extract_item_text(it) }
              end
              str << render_card(title, color, items, "col", badge) << "\n"
            end
          end
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

        if columns = slide.raw["columns"]?.try(&.as_a)
          columns.each do |c|
            item_type = c["type"]?.try(&.as_s) || "card"
            if item_type == "code"
              title = c["title"]?.try(&.as_s) || "Code"
              lang = c["lang"]?.try(&.as_s) || "crystal"
              code = c["code"]?.try(&.as_s) || ""
              str << "- **Code Example (`" << title << "`)**:\n"
              str << "  ```" << lang << "\n  " << code.strip.gsub("\n", "\n  ") << "\n  ```\n"
            else
              str << "- **" << c["title"]?.try(&.as_s) << "**:\n"
              if raw_items = c["items"]?.try(&.as_a)
                raw_items.each do |it|
                  str << "  - " << LayoutRenderer.clean_text(LayoutRenderer.extract_item_text(it)) << "\n"
                end
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
