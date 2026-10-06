require "./layout_renderer"

module LapisSlides
  class ChapterLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      act_label = slide.raw["act"]?.try(&.as_s) || slide.raw["chapter"]?.try(&.as_s) || slide.badge
      badge_color = slide.badge_color.empty? ? "cyan" : slide.badge_color
      cube_size = slide.raw["cube_size"]?.try(&.as_i) || 160
      pillars = slide.raw["pillars"]?.try(&.as_a)

      hero_cube = "<div class=\"hero-cube chapter-cube\" data-size=\"#{cube_size}\" title=\"Spinning 3D Isometric Cube • Click or Drag to Spin!\"></div>"

      body = String.build do |str|
        str << "        <div class=\"chapter-content\">\n"

        # Top Act & Title Header
        str << "          <div class=\"chapter-top\">\n"
        if !act_label.empty?
          str << "            <div class=\"chapter-badge-wrap\">\n"
          str << "              <span class=\"badge-pill " << badge_color << " chapter-act-badge\">" << LayoutRenderer.tint_emojis(HTML.escape(act_label)) << "</span>\n"
          str << "            </div>\n"
        end
        str << "            <h1 class=\"chapter-title\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.title)) << "</h1>\n"
        if !slide.subtitle.empty?
          str << "            <p class=\"chapter-subtitle\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.subtitle)) << "</p>\n"
        end
        str << "          </div>\n"

        # Centered Isometric Wireframe Cube
        str << "          <div class=\"chapter-cube-wrap\">\n"
        str << "            " << hero_cube << "\n"
        str << "          </div>\n"

        # Bottom 3-4 Thematic Preview Pillars
        if pillars && !pillars.empty?
          str << "          <div class=\"chapter-pillars-row\">\n"
          pillars.each do |p|
            if h = p.as_h?
              p_title = h["title"]?.try(&.as_s) || ""
              p_desc = h["desc"]?.try(&.as_s) || ""
              p_icon = h["icon"]?.try(&.as_s) || "sparkles"
              p_color = h["color"]?.try(&.as_s) || badge_color

              str << "            <div class=\"chapter-pillar-card " << p_color << "\">\n"
              str << "              <div class=\"chapter-pillar-header\">\n"
              str << "                <span class=\"chapter-pillar-icon\">" << LayoutRenderer.render_icon(p_icon) << "</span>\n"
              str << "                <span class=\"chapter-pillar-title\">" << LayoutRenderer.tint_emojis(HTML.escape(p_title)) << "</span>\n"
              str << "              </div>\n"
              if !p_desc.empty?
                str << "              <div class=\"chapter-pillar-desc\">" << LayoutRenderer.tint_emojis(p_desc) << "</div>\n"
              end
              str << "            </div>\n"
            else
              str << "            <div class=\"chapter-pillar-card " << badge_color << "\">\n"
              str << "              <div class=\"chapter-pillar-title\">" << LayoutRenderer.tint_emojis(p.as_s) << "</div>\n"
              str << "            </div>\n"
            end
          end
          str << "          </div>\n"
        end

        str << "        </div>"
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      act_label = slide.raw["act"]?.try(&.as_s) || slide.raw["chapter"]?.try(&.as_s) || slide.badge
      pillars = slide.raw["pillars"]?.try(&.as_a)

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << " (" << act_label << ")\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Section Badge**: `" << act_label << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if pillars && !pillars.empty?
          str << "- **Chapter Agenda & Highlights**:\n"
          pillars.each do |p|
            if h = p.as_h?
              p_title = h["title"]?.try(&.as_s) || ""
              p_desc = h["desc"]?.try(&.as_s) || ""
              str << "  - **" << LayoutRenderer.clean_text(p_title) << "**: " << LayoutRenderer.clean_text(p_desc) << "\n"
            else
              str << "  - " << LayoutRenderer.clean_text(p.as_s) << "\n"
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
