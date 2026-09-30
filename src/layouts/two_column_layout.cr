require "base64"
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
        font_size = data["font_size"]?.try(&.as_s) || data["code_font_size"]?.try(&.as_s)
        border_color = data["border_color"]?.try(&.as_s)
        str << render_code_container(title, lang, code, tag, "col", border_color, font_size) << "\n"
      when "terminal"
        title = data["title"]?.try(&.as_s) || "Terminal"
        code = data["code"]?.try(&.as_s) || ""
        font_size = data["font_size"]?.try(&.as_s) || data["code_font_size"]?.try(&.as_s)
        style_attr = font_size ? " style=\"font-size: #{font_size} !important;\"" : ""
        str << "            <div class=\"terminal-window col\" style=\"margin: 0;\">\n"
        str << "              <div class=\"terminal-header\">\n"
        str << "                <div class=\"terminal-dots\"><span class=\"terminal-dot dot-1\"></span><span class=\"terminal-dot dot-2\"></span><span class=\"terminal-dot dot-3\"></span></div>\n"
        str << "                <span class=\"terminal-title\">" << HTML.escape(title) << "</span>\n"
        str << "              </div>\n"
        str << "              <div class=\"terminal-body\">\n"
        str << "                <pre#{style_attr}><code class=\"language-bash\"#{style_attr}>" << HTML.escape(code.strip) << "</code></pre>\n"
        str << "              </div>\n"
        str << "            </div>\n"
      when "asciinema", "cast"
        title = data["title"]?.try(&.as_s) || "Terminal Replay"
        cast_rel = data["cast"]?.try(&.as_s) || ""
        speed = data["speed"]?.try { |v| v.as_f? || v.as_i?.try(&.to_f) } || 1.0_f64
        loop_play = data["loop"]?.try(&.as_bool) != false
        autoplay = data["autoplay"]?.try(&.as_bool) != false
        controls = data["controls"]?.try(&.as_s) || "auto"
        theme = data["theme"]?.try(&.as_s) || "monokai"
        font_size = data["font_size"]?.try(&.as_s) || data["terminal_font_size"]?.try(&.as_s) || "0.75rem"
        cols = data["cols"]?.try(&.as_i) || 86
        rows = data["rows"]?.try(&.as_i) || 19
        fallback_code = data["code"]?.try(&.as_s)

        # Inlining cast data as base64 for file:// zero-CORS safety
        cast_file = if File.exists?(cast_rel)
                      cast_rel
                    elsif File.exists?(File.expand_path(cast_rel, Dir.current))
                      File.expand_path(cast_rel, Dir.current)
                    elsif File.exists?(File.expand_path("slides/#{cast_rel}", Dir.current))
                      File.expand_path("slides/#{cast_rel}", Dir.current)
                    elsif File.exists?(File.expand_path("data/#{cast_rel}", Dir.current))
                      File.expand_path("data/#{cast_rel}", Dir.current)
                    else
                      nil
                    end

        cast_src = if cast_file
                     content = File.read(cast_file)
                     "data:text/plain;base64,#{Base64.strict_encode(content)}"
                   else
                     cast_rel
                   end

        str << "            <div class=\"terminal-window col asciinema-window\" style=\"margin: 0; display: flex; flex-direction: column;\">\n"
        str << "              <div class=\"terminal-header\">\n"
        str << "                <div class=\"terminal-dots\"><span class=\"terminal-dot dot-1\"></span><span class=\"terminal-dot dot-2\"></span><span class=\"terminal-dot dot-3\"></span></div>\n"
        str << "                <span class=\"terminal-title\">" << HTML.escape(title) << "</span>\n"
        str << "                <div class=\"window-controls\"><span class=\"code-lang-tag\">REPLAY</span></div>\n"
        str << "              </div>\n"
        str << "              <div class=\"terminal-body asciinema-body\" style=\"flex: 1; padding: 0.25rem;\">\n"
        str << "                <div class=\"asciinema-player-mount\" data-cast-url=\"" << HTML.escape(cast_rel) << "\" data-cast-src=\"" << HTML.escape(cast_src) << "\""
        str << " data-speed=\"" << speed << "\""
        str << " data-loop=\"" << loop_play << "\""
        str << " data-autoplay=\"" << autoplay << "\""
        str << " data-controls=\"" << HTML.escape(controls) << "\""
        str << " data-theme=\"" << HTML.escape(theme) << "\""
        str << " data-cols=\"" << cols << "\""
        str << " data-rows=\"" << rows << "\""
        str << " data-font-size=\"" << HTML.escape(font_size) << "\""
        str << " style=\"font-size: " << HTML.escape(font_size) << " !important;\">\n"

        if fallback_code && !fallback_code.strip.empty?
          style_attr = font_size ? " style=\"font-size: #{font_size} !important;\"" : ""
          str << "                  <noscript><pre#{style_attr}><code class=\"language-bash\"#{style_attr}>" << HTML.escape(fallback_code.strip) << "</code></pre></noscript>\n"
        end

        str << "                </div>\n"
        str << "              </div>\n"
        str << "            </div>\n"
      when "barchart"
        title = data["title"]?.try(&.as_s) || "Benchmark Results (Execution Time)"
        badge = data["badge"]?.try(&.as_s) || "LOWER IS BETTER"
        unit = data["unit"]?.try(&.as_s) || "ms"
        str << "            <div class=\"card barchart-card col\">\n"
        str << "              <div class=\"card-title\">\n"
        str << "                <span>" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</span>\n"
        str << "                <span class=\"badge-pill\" style=\"font-size: 0.65rem; margin-left: auto; border-color: var(--border-color); color: var(--accent-color);\">" << HTML.escape(badge) << "</span>\n"
        str << "              </div>\n"
        str << "              <div class=\"barchart-container\">\n"

        if benchmarks = data["benchmarks"]?.try(&.as_a)
          benchmarks.each do |b|
            b_name = b["name"]?.try(&.as_s) || ""
            gd_ms = b["gdscript"]?.try { |v| v.as_f? || v.as_i?.try(&.to_f) } || 1.0_f64
            cr_ms = b["crystal"]?.try { |v| v.as_f? || v.as_i?.try(&.to_f) } || 1.0_f64
            speedup = b["speedup"]?.try(&.as_s) || sprintf("%.1fx", gd_ms / cr_ms)
            cr_pct = [2.5, (cr_ms / gd_ms * 100.0)].max.round(1)

            str << "                <div class=\"barchart-row\">\n"
            str << "                  <div class=\"barchart-row-header\">\n"
            str << "                    <span class=\"barchart-name\">" << LayoutRenderer.tint_emojis(HTML.escape(b_name)) << "</span>\n"
            str << "                    <span class=\"barchart-speedup badge-pill\">" << HTML.escape(speedup) << " faster</span>\n"
            str << "                  </div>\n"
            str << "                  <div class=\"barchart-bars\">\n"
            str << "                    <div class=\"barchart-bar-line\">\n"
            str << "                      <span class=\"bar-platform\">GDScript</span>\n"
            str << "                      <div class=\"bar-track\"><div class=\"bar-fill gdscript\" style=\"width: 100%;\"></div></div>\n"
            str << "                      <span class=\"bar-val\">" << gd_ms.round(1) << " " << unit << "</span>\n"
            str << "                    </div>\n"
            str << "                    <div class=\"barchart-bar-line\">\n"
            str << "                      <span class=\"bar-platform\">Crystal</span>\n"
            str << "                      <div class=\"bar-track\"><div class=\"bar-fill crystal\" style=\"width: " << cr_pct << "%;\"></div></div>\n"
            str << "                      <span class=\"bar-val\">" << cr_ms.round(1) << " " << unit << "</span>\n"
            str << "                    </div>\n"
            str << "                  </div>\n"
            str << "                </div>\n"
          end
        end

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
            elsif item_type == "terminal" || item_type == "asciinema" || item_type == "cast"
              title = item["title"]?.try(&.as_s) || "Terminal Replay"
              code = item["code"]?.try(&.as_s) || "Terminal recording: #{item["cast"]?.try(&.as_s)}"
              str << "- **Terminal Replay (`" << title << "`)**:\n"
              str << "  ```bash\n  " << code.strip.gsub("\n", "\n  ") << "\n  ```\n"
            elsif item_type == "barchart"
              title = item["title"]?.try(&.as_s) || "Benchmark Results"
              unit = item["unit"]?.try(&.as_s) || "ms"
              str << "- **" << title << "**:\n"
              if benchmarks = item["benchmarks"]?.try(&.as_a)
                benchmarks.each do |b|
                  b_name = b["name"]?.try(&.as_s) || ""
                  gd_ms = b["gdscript"]?.try { |v| v.as_f? || v.as_i?.try(&.to_f) } || 1.0_f64
                  cr_ms = b["crystal"]?.try { |v| v.as_f? || v.as_i?.try(&.to_f) } || 1.0_f64
                  speedup = b["speedup"]?.try(&.as_s) || sprintf("%.1fx", gd_ms / cr_ms)
                  str << "  - **" << b_name << "**: GDScript `" << gd_ms.round(1) << " " << unit << "` vs Crystal `" << cr_ms.round(1) << " " << unit << "` (**" << speedup << " faster**)\n"
                end
              end
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
