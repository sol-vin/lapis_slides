require "./layout_renderer"

module LapisSlides
  class CodeComparisonLayout < LayoutRenderer
    # Determines if this slide expands into 2 presentation slides:
    # Slide 1: Side-by-side code only (clean, large IDE text boxes, no notes)
    # Slide 2: Analysis & Critique (code in background, critique notes overlaid directly over IDE text boxes)
    def slide_count(slide : Slide) : Int32
      if slide.raw["two_step"]?.try(&.as_bool) == false
        return 1
      end

      has_points = slide.raw["gdscript"]?.try(&.["points"]?) ||
                   slide.raw["crystal"]?.try(&.["points"]?) ||
                   slide.raw["points"]? ||
                   slide.raw["takeaway"]?

      has_points ? 2 : 1
    end

    def render_html_all(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      if slide_count(slide) == 2
        step1 = render_step1_code_only(slide, palette, slide_num, total_slides, author)
        step2 = render_step2_notes_overlay(slide, palette, slide_num + 1, total_slides, author)
        "#{step1}\n\n#{step2}"
      else
        render_html(slide, palette, slide_num, total_slides, author)
      end
    end

    def render_markdown_all(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      if slide_count(slide) == 2
        md1 = render_step1_markdown(slide, palette, slide_num, total_slides)
        md2 = render_step2_markdown(slide, palette, slide_num + 1, total_slides)
        "#{md1}\n#{md2}"
      else
        render_markdown(slide, palette, slide_num, total_slides)
      end
    end

    # Step 1: Code side-by-side without any notes
    def render_step1_code_only(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      gd_data = slide.raw["gdscript"]?
      cr_data = slide.raw["crystal"]?

      body = String.build do |str|
        badge_header = "<span class=\"badge-pill\" style=\"font-size: 0.72rem; margin: 0;\">CODE VIEW</span>"
        str << render_slide_header(slide, badge_header) << "\n"
        str << "        <div class=\"slide-body code-comparison-body code-only-mode\" style=\"display: flex; gap: 1rem; align-items: stretch; flex: 1;\">\n"

        if gd_data
          gd_title = gd_data["title"]?.try(&.as_s) || "GDScript Anti-Pattern"
          gd_lang = gd_data["lang"]?.try(&.as_s) || "gdscript"
          gd_code = gd_data["code"]?.try(&.as_s) || ""
          gd_tag = gd_data["tag"]?.try(&.as_s) || "GDScript"
          gd_font_size = gd_data["font_size"]?.try(&.as_s) || slide.raw["font_size"]?.try(&.as_s) || slide.raw["code_font_size"]?.try(&.as_s)
          str << "          <div class=\"col comparison-pane antipattern-pane\" style=\"display: flex; flex-direction: column; flex: 1;\">\n"
          str << render_code_container(gd_title, gd_lang, gd_code, gd_tag, "col antipattern-code", "var(--border-color)", gd_font_size) << "\n"
          str << "          </div>\n"
        end

        if cr_data
          cr_title = cr_data["title"]?.try(&.as_s) || "Crystal Clean Solution"
          cr_lang = cr_data["lang"]?.try(&.as_s) || "crystal"
          cr_code = cr_data["code"]?.try(&.as_s) || ""
          cr_tag = cr_data["tag"]?.try(&.as_s) || "Crystal (Lapis)"
          cr_font_size = cr_data["font_size"]?.try(&.as_s) || slide.raw["font_size"]?.try(&.as_s) || slide.raw["code_font_size"]?.try(&.as_s)
          str << "          <div class=\"col comparison-pane solution-pane\" style=\"display: flex; flex-direction: column; flex: 1;\">\n"
          str << render_code_container(cr_title, cr_lang, cr_code, cr_tag, "col solution-code", "var(--border-color)", cr_font_size) << "\n"
          str << "          </div>\n"
        end

        str << "        </div>"
      end

      code_notes = slide.raw["code_notes"]?.try(&.as_s) || "Side-by-side comparison: Review the syntax, structure, and ergonomics between GDScript on the left and Crystal on the right before we step into the critique."
      render_section_wrapper(slide, palette, slide_num, total_slides, author, body, code_notes)
    end

    # Step 2: Critique notes overlaid directly over the IDE text boxes
    def render_step2_notes_overlay(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      gd_data = slide.raw["gdscript"]?
      cr_data = slide.raw["crystal"]?
      takeaway = slide.raw["takeaway"]?

      body = String.build do |str|
        badge_header = "<span class=\"badge-pill\" style=\"font-size: 0.72rem; margin: 0;\">ANALYSIS &amp; CRITIQUE</span>"
        str << render_slide_header(slide, badge_header) << "\n"
        str << "        <div class=\"slide-body code-comparison-body with-overlay-mode\" style=\"position: relative; display: flex; gap: 1rem; align-items: stretch; flex: 1;\">\n"

        # Background dimmed code panes
        if gd_data
          gd_title = gd_data["title"]?.try(&.as_s) || "GDScript Anti-Pattern"
          gd_lang = gd_data["lang"]?.try(&.as_s) || "gdscript"
          gd_code = gd_data["code"]?.try(&.as_s) || ""
          gd_tag = gd_data["tag"]?.try(&.as_s) || "GDScript"
          gd_font_size = gd_data["font_size"]?.try(&.as_s) || slide.raw["font_size"]?.try(&.as_s) || slide.raw["code_font_size"]?.try(&.as_s)
          str << "          <div class=\"col comparison-pane antipattern-pane dimmed-code\" style=\"display: flex; flex-direction: column; flex: 1;\">\n"
          str << render_code_container(gd_title, gd_lang, gd_code, gd_tag, "col antipattern-code", "var(--border-color)", gd_font_size) << "\n"
          str << "          </div>\n"
        end

        if cr_data
          cr_title = cr_data["title"]?.try(&.as_s) || "Crystal Clean Solution"
          cr_lang = cr_data["lang"]?.try(&.as_s) || "crystal"
          cr_code = cr_data["code"]?.try(&.as_s) || ""
          cr_tag = cr_data["tag"]?.try(&.as_s) || "Crystal (Lapis)"
          cr_font_size = cr_data["font_size"]?.try(&.as_s) || slide.raw["font_size"]?.try(&.as_s) || slide.raw["code_font_size"]?.try(&.as_s)
          str << "          <div class=\"col comparison-pane solution-pane dimmed-code\" style=\"display: flex; flex-direction: column; flex: 1;\">\n"
          str << render_code_container(cr_title, cr_lang, cr_code, cr_tag, "col solution-code", "var(--border-color)", cr_font_size) << "\n"
          str << "          </div>\n"
        end

        # Overlay critique cards positioned over the IDE text boxes
        str << "          <div class=\"ide-notes-overlay\">\n"

        # Left overlay over GDScript IDE
        if gd_data && (points = gd_data["points"]?.try(&.as_a))
          str << "            <div class=\"overlay-card antipattern\">\n"
          str << "              <div class=\"overlay-card-header\">\n"
          str << "                <div class=\"card-title antipattern\">\n"
          str << "                  <span>" << LayoutRenderer.tint_emojis("⚠️ GDScript Friction &amp; Pitfalls") << "</span>\n"
          str << "                </div>\n"
          str << "                <span class=\"badge-pill antipattern\" style=\"font-size: 0.68rem; margin: 0;\">ANTIPATTERN</span>\n"
          str << "              </div>\n"
          str << "              <ul class=\"card-list\">\n"
          points.each do |p|
            str << "                <li>" << LayoutRenderer.tint_emojis(extract_point_text(p)) << "</li>\n"
          end
          str << "              </ul>\n"
          str << "            </div>\n"
        end

        # Right overlay over Crystal IDE
        if cr_data && (points = cr_data["points"]?.try(&.as_a))
          str << "            <div class=\"overlay-card solution\">\n"
          str << "              <div class=\"overlay-card-header\">\n"
          str << "                <div class=\"card-title solution\">\n"
          str << "                  <span>" << LayoutRenderer.tint_emojis("✨ Crystal Zen Solution") << "</span>\n"
          str << "                </div>\n"
          str << "                <span class=\"badge-pill solution\" style=\"font-size: 0.68rem; margin: 0;\">SOLUTION</span>\n"
          str << "              </div>\n"
          str << "              <ul class=\"card-list\">\n"
          points.each do |p|
            str << "                <li>" << LayoutRenderer.tint_emojis(extract_point_text(p)) << "</li>\n"
          end
          str << "              </ul>\n"
          str << "            </div>\n"
        end

        str << "          </div>\n" # /ide-notes-overlay
        str << "        </div>\n"   # /slide-body

        # Bottom Takeaway Banner
        if takeaway
          t_badge = takeaway["badge"]?.try(&.as_s) || "TAKEAWAY"
          t_text = takeaway["text"]?.try(&.as_s) || ""
          str << "        <div class=\"takeaway-banner\" style=\"margin-top: 0.6rem; padding: 0.45rem 0.9rem; background: var(--bg-window); border: 1.5px solid var(--accent-color); border-radius: 8px; display: flex; align-items: center; gap: 0.75rem; font-size: 0.88rem;\">\n"
          str << "          <span class=\"badge-pill\" style=\"margin-bottom: 0; padding: 0.15rem 0.55rem; font-size: 0.72rem; border-color: var(--accent-color); color: var(--accent-color);\">" << HTML.escape(t_badge) << "</span>\n"
          str << "          <span>" << LayoutRenderer.tint_emojis(t_text) << "</span>\n"
          str << "        </div>\n"
        end
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    # Fallback single-slide renderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      render_step2_notes_overlay(slide, palette, slide_num, total_slides, author)
    end

    def render_step1_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      gd_data = slide.raw["gdscript"]?
      cr_data = slide.raw["crystal"]?

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << " (Code Comparison)\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << " • CODE VIEW`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if gd_data
          gd_title = gd_data["title"]?.try(&.as_s) || "GDScript Anti-Pattern"
          gd_lang = gd_data["lang"]?.try(&.as_s) || "gdscript"
          gd_code = gd_data["code"]?.try(&.as_s) || ""
          str << "- **GDScript Code Example (`" << gd_title << "`)**:\n"
          str << "  ```" << gd_lang << "\n  " << gd_code.strip.gsub("\n", "\n  ") << "\n  ```\n"
        end

        if cr_data
          cr_title = cr_data["title"]?.try(&.as_s) || "Crystal Clean Solution"
          cr_lang = cr_data["lang"]?.try(&.as_s) || "crystal"
          cr_code = cr_data["code"]?.try(&.as_s) || ""
          str << "- **Crystal Code Example (`" << cr_title << "`)**:\n"
          str << "  ```" << cr_lang << "\n  " << cr_code.strip.gsub("\n", "\n  ") << "\n  ```\n"
        end

        str << "- **Presenter Script**:\n"
        str << "  > *\"Examining the code side-by-side: Notice the contrast in structure, verbosity, and safety between the GDScript implementation on the left and the Crystal implementation on the right before we review the specific friction points.\"*\n"
        str << "\n---\n"
      end
    end

    def render_step2_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      gd_data = slide.raw["gdscript"]?
      cr_data = slide.raw["crystal"]?
      takeaway = slide.raw["takeaway"]?

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << " (Analysis & Critique)\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << " • CRITIQUE`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if gd_data && (points = gd_data["points"]?.try(&.as_a))
          str << "- **⚠️ GDScript Friction & Pitfalls**:\n"
          points.each do |p|
            str << "  - " << LayoutRenderer.clean_text(extract_point_text(p)) << "\n"
          end
        end

        if cr_data && (points = cr_data["points"]?.try(&.as_a))
          str << "- **✨ Crystal Zen Advantages**:\n"
          points.each do |p|
            str << "  - " << LayoutRenderer.clean_text(extract_point_text(p)) << "\n"
          end
        end

        if takeaway
          str << "- **Key Takeaway**: " << LayoutRenderer.clean_text(takeaway["text"]?.try(&.as_s) || "") << "\n"
        end

        if !slide.notes.empty?
          str << "- **Presenter Script**:\n"
          str << "  > *\"" << slide.notes.strip.gsub("\n", " ") << "\"*\n"
        end
        str << "\n---\n"
      end
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      render_step2_markdown(slide, palette, slide_num, total_slides)
    end

    private def extract_point_text(p : YAML::Any) : String
      if h = p.as_h?
        h.map { |k, v| "#{k} #{v}" }.join(" ")
      else
        p.as_s? || p.to_s
      end
    end
  end
end
