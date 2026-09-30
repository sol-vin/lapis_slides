require "html"
require "../models/slide"
require "../models/palette"

module LapisSlides
  abstract class LayoutRenderer
    abstract def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
    abstract def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String

    # Number of presentation slides produced by this slide definition (default 1, can be overridden by 2-step layouts)
    def slide_count(slide : Slide) : Int32
      1
    end

    # Renders all slides (single or multi-step) for HTML
    def render_html_all(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      render_html(slide, palette, slide_num, total_slides, author)
    end

    # Renders all slides (single or multi-step) for Markdown
    def render_markdown_all(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      render_markdown(slide, palette, slide_num, total_slides)
    end

    # Shared HTML helpers
    def self.escape(text : String) : String
      HTML.escape(text)
    end

    def self.tint_emojis(text : String) : String
      # Wrap all emojis and pictographs in .emoji-tint class so they are covered by the SVG monochrome color matrix
      text.gsub(/((\p{Extended_Pictographic}|\p{Emoji_Presentation}|[\x{2600}-\x{27BF}\x{1F300}-\x{1FAFF}★■▲●✖])[\x{FE00}-\x{FE0F}\x{200D}]*)/) do |m|
        "<span class=\"emoji-tint\">#{m}</span>"
      end
    end

    def self.extract_item_text(node : YAML::Any) : String
      if h = node.as_h?
        h.map { |k, v| "#{k} #{v}" }.join(" ")
      else
        node.as_s? || node.to_s
      end
    end

    def self.clean_text(html : String) : String
      html.gsub(/<[^>]+>/, "")
          .gsub("&amp;", "&")
          .gsub("&lt;", "<")
          .gsub("&gt;", ">")
          .gsub("&quot;", "\"")
          .gsub("&#123;", "{")
          .gsub("&#125;", "}")
          .gsub("&mdash;", "—")
          .strip
    end

    def render_section_wrapper(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String, inner_body : String, custom_notes : String? = nil) : String
      cube_color = palette.cube_color
      cube_hover = palette.cube_hover
      notes_to_show = custom_notes || slide.notes

      String.build do |str|
        str << "      <!-- ===================================================================\n"
        str << "           SLIDE " << slide_num << ": " << palette.name << " (" << slide.title << ")\n"
        str << "           =================================================================== -->\n"
        str << "      <section data-background-color=\"" << palette.bg_color << "\"\n"
        str << "               data-palette-name=\"" << palette.name << "\"\n"
        str << "               data-palette-cube=\"" << cube_color << "\"\n"
        str << "               data-palette-cube-hover=\"" << cube_hover << "\"\n"
        str << "               class=\"solvin-slide " << palette.id << "\"\n"
        str << "               style=\"" << palette.css_vars << "\">\n"
        str << "        <div class=\"palette-corner-badge\" title=\"Theme: " << palette.name << "\">\n"
        str << "          <span class=\"palette-corner-dot\"></span> PALETTE: " << palette.name << "\n"
        str << "        </div>\n"
        str << inner_body << "\n"
        str << "        <div class=\"slide-footer\">\n"
        str << "          <span>Lapis for Crystal • Godot 4.8+</span>\n"
        str << "          <span>" << author << " (" << palette.name << ")</span>\n"
        str << "          <span>Slide " << slide_num << " / " << total_slides << "</span>\n"
        str << "        </div>\n"
        if !notes_to_show.empty?
          str << "        <aside class=\"notes\">\n"
          str << "          " << notes_to_show.strip.gsub("\n", "\n          ") << "\n"
          str << "        </aside>\n"
        end
        str << "      </section>"
      end
    end

    def render_slide_header(slide : Slide, right_element : String? = nil) : String
      String.build do |str|
        str << "        <div class=\"slide-header\" style=\""
        if right_element
          str << "border: none; padding-bottom: 0; display: flex; align-items: center; justify-content: space-between;"
        end
        str << "\">\n"
        str << "          <div>\n"
        str << "            <span class=\"badge-pill " << slide.badge_color << "\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.badge)) << "</span>\n"
        str << "            <h2 class=\"slide-title\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.title)) << "</h2>\n"
        unless slide.subtitle.empty?
          str << "            <p class=\"slide-subtitle\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.subtitle)) << "</p>\n"
        end
        str << "          </div>\n"
        if right_element
          str << "          " << right_element << "\n"
        end
        str << "        </div>"
      end
    end

    def render_code_container(title : String, lang : String, code : String, tag : String? = nil, col_class : String = "col", border_color : String? = nil) : String
      border_style = border_color ? " border-color: #{border_color};" : ""
      line_count = code.strip.lines.size
      density_class = if line_count > 24
                        " code-compact"
                      elsif line_count > 16
                        " code-dense"
                      else
                        ""
                      end
      String.build do |str|
        str << "          <div class=\"code-container " << col_class << density_class << "\" style=\"" << border_style << "\">\n"
        str << "            <div class=\"code-header\">\n"
        str << "              <div class=\"terminal-dots\">\n"
        str << "                <span class=\"terminal-dot dot-1\" title=\"Close\"></span>\n"
        str << "                <span class=\"terminal-dot dot-2\" title=\"Minimize\"></span>\n"
        str << "                <span class=\"terminal-dot dot-3\" title=\"Maximize\"></span>\n"
        str << "              </div>\n"
        str << "              <span class=\"code-title\">" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</span>\n"
        str << "              <div class=\"window-controls\">\n"
        str << "                <span class=\"code-lang-tag\">" << (tag || lang.upcase) << "</span>\n"
        str << "                <span class=\"window-btn close\" title=\"Close\">✕</span>\n"
        str << "              </div>\n"
        str << "            </div>\n"
        str << "            <pre><code class=\"language-" << lang.downcase << density_class << "\">" << HTML.escape(code.strip) << "</code></pre>\n"
        str << "          </div>"
      end
    end

    def render_card(title : String, color : String, items : Array(String), col_class : String = "col", badge : String? = nil) : String
      String.build do |str|
        str << "          <div class=\"card " << color << " " << col_class << "\">\n"
        str << "            <div class=\"card-title " << color << "\">\n"
        str << "              <span>" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</span>\n"
        if badge
          str << "              <span class=\"badge-pill " << color << "\" style=\"font-size: 0.65rem; margin-left: auto;\">" << HTML.escape(badge) << "</span>\n"
        end
        str << "            </div>\n"
        str << "            <ul class=\"card-list\">\n"
        items.each do |item|
          str << "              <li>" << LayoutRenderer.tint_emojis(item) << "</li>\n"
        end
        str << "            </ul>\n"
        str << "          </div>"
      end
    end
  end
end
