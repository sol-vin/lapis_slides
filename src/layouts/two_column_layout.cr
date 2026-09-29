require "./layout_renderer"

module LapisSlides
  class TwoColumnLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      ratio = slide.raw["ratio"]?.try(&.as_s) || "1:1"
      left_data = slide.raw["left"]?
      right_data = slide.raw["right"]?

      left_col_class = case ratio
                       when "2:1", "3:2" then "col-3"
                       when "1:2", "2:3" then "col-2"
                       else "col"
                       end

      right_col_class = case ratio
                        when "2:1", "3:2" then "col-2"
                        when "1:2", "2:3" then "col-3"
                        else "col"
                        end

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body\" style=\"display: flex; gap: 1.2rem; align-items: stretch; flex: 1;\">\n"

        # LEFT COLUMN
        if left_data
          str << "          <div class=\"" << left_col_class << "\" style=\"display: flex; flex-direction: column; gap: 0.8rem;\">\n"
          render_column_content(str, left_data)
          str << "          </div>\n"
        end

        # RIGHT COLUMN
        if right_data
          str << "          <div class=\"" << right_col_class << "\" style=\"display: flex; flex-direction: column; gap: 0.8rem;\">\n"
          render_column_content(str, right_data)
          str << "          </div>\n"
        end

        str << "        </div>"
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    private def render_column_content(str : String::Builder, data : YAML::Any)
      if data.as_a?
        data.as_a.each { |item| render_single_item(str, item) }
      else
        render_single_item(str, data)
      end
    end

    private def render_single_item(str : String::Builder, data : YAML::Any)
      item_type = data["type"]?.try(&.as_s) || "card"

      case item_type
      when "code"
        title = data["title"]?.try(&.as_s) || "Code"
        lang = data["lang"]?.try(&.as_s) || "crystal"
        code = data["code"]?.try(&.as_s) || ""
        tag = data["tag"]?.try(&.as_s)
        str << render_code_container(title, lang, code, tag, "col") << "\n"
      when "terminal"
        title = data["title"]?.try(&.as_s) || "Terminal"
        code = data["code"]?.try(&.as_s) || ""
        str << "            <div class=\"terminal-window col\" style=\"margin: 0;\">\n"
        str << "              <div class=\"terminal-header\">\n"
        str << "                <div class=\"terminal-dots\"><span class=\"terminal-dot red\"></span><span class=\"terminal-dot yellow\"></span><span class=\"terminal-dot green\"></span></div>\n"
        str << "                <span class=\"terminal-title\">" << HTML.escape(title) << "</span>\n"
        str << "              </div>\n"
        str << "              <div class=\"terminal-body\">\n"
        str << "                <pre><code class=\"language-bash\">" << HTML.escape(code.strip) << "</code></pre>\n"
        str << "              </div>\n"
        str << "            </div>\n"
      else
        title = data["title"]?.try(&.as_s) || ""
        color = data["color"]?.try(&.as_s) || "blue"
        badge = data["badge"]?.try(&.as_s)
        items = Array(String).new
        if raw_items = data["items"]?.try(&.as_a)
          raw_items.each { |it| items << LayoutRenderer.extract_item_text(it) }
        end
        str << render_card(title, color, items, "col", badge) << "\n"
      end
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      left_data = slide.raw["left"]?
      right_data = slide.raw["right"]?

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << "\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        [left_data, right_data].compact.each do |col|
          items = col.as_a? || [col]
          items.each do |item|
            item_type = item["type"]?.try(&.as_s) || "card"
            if item_type == "code"
              title = item["title"]?.try(&.as_s) || "Code Example"
              lang = item["lang"]?.try(&.as_s) || "crystal"
              code = item["code"]?.try(&.as_s) || ""
              str << "- **Code Example (`" << title << "`)**:\n"
              str << "  ```" << lang << "\n  " << code.strip.gsub("\n", "\n  ") << "\n  ```\n"
            elsif item_type == "terminal"
              title = item["title"]?.try(&.as_s) || "Terminal"
              code = item["code"]?.try(&.as_s) || ""
              str << "- **Terminal Command (`" << title << "`)**:\n"
              str << "  ```bash\n  " << code.strip.gsub("\n", "\n  ") << "\n  ```\n"
            else
              title = item["title"]?.try(&.as_s) || "Details"
              str << "- **" << title << "**:\n"
              if raw_items = item["items"]?.try(&.as_a)
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
