require "./layout_renderer"

module LapisSlides
  class ArchitectureLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      tiers = slide.raw["tiers"]?.try(&.as_a)

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body arch-stack-body\">\n"

        if tiers
          tiers.each_with_index do |t, idx|
            tier_title = t["title"]?.try(&.as_s) || ""
            tier_label = t["label"]?.try(&.as_s) || ""
            tier_badge = t["badge"]?.try(&.as_s)
            color = t["color"]?.try(&.as_s) || "cyan"
            blocks = t["blocks"]?.try(&.as_a) || Array(YAML::Any).new

            cols_count = case t["id"]?.try(&.as_s)
                         when "tier_app", "tier_framework" then 5
                         when "tier_bindings", "tier_foundation" then 2
                         else blocks.size
                         end

            str << "          <div class=\"arch-tier-row " << color << "\">\n"
            str << "            <div class=\"arch-tier-header\">\n"
            str << "              <span class=\"arch-tier-name\">" << LayoutRenderer.tint_emojis(HTML.escape(tier_title)) << "</span>\n"
            str << "              <span class=\"arch-tier-label\">" << LayoutRenderer.tint_emojis(HTML.escape(tier_label)) << "</span>\n"
            if tier_badge
              str << "              <span class=\"badge-pill " << color << "\" style=\"font-size: 0.58rem; margin: 0;\">" << HTML.escape(tier_badge) << "</span>\n"
            end
            str << "            </div>\n"

            str << "            <div class=\"arch-tier-grid cols-" << cols_count << "\">\n"
            blocks.each do |b|
              b_title = b["title"]?.try(&.as_s) || ""
              b_desc = b["desc"]?.try(&.as_s) || ""
              str << "              <div class=\"arch-block " << color << "\">\n"
              str << "                <div class=\"arch-block-title\">" << LayoutRenderer.tint_emojis(HTML.escape(b_title)) << "</div>\n"
              str << "                <div class=\"arch-block-desc\">" << LayoutRenderer.tint_emojis(b_desc) << "</div>\n"
              str << "              </div>\n"
            end
            str << "            </div>\n"
            str << "          </div>\n"

            if idx < (tiers.size - 1)
              str << "          <div class=\"arch-tier-flow\">\n"
              str << "            <span class=\"arch-flow-arrow\">&#9660;</span>\n"
              str << "          </div>\n"
            end
          end
        end

        str << "        </div>"
      end

      render_section_wrapper(slide, palette, slide_num, total_slides, author, body)
    end

    def render_markdown(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32) : String
      tiers = slide.raw["tiers"]?.try(&.as_a)

      String.build do |str|
        str << "### Slide " << slide_num << ": " << slide.title << "\n"
        str << "- **Sol.vin Theme Palette**: `" << palette.id << "` (" << palette.name << ") "
        str << "[BG: `" << palette.bg_color << "` | Window: `" << palette.bg_window << "` | Text: `" << palette.text_color << "` | Accent: `" << palette.accent_color << "`]\n"
        str << "- **Category Badge**: `" << slide.badge << "`\n"
        str << "- **Title**: " << slide.title << "\n"
        str << "- **Subtitle**: " << slide.subtitle << "\n"

        if tiers
          str << "- **Modular Architectural Technology Stack (Top to Bottom)**:\n"
          tiers.each do |t|
            t_title = t["title"]?.try(&.as_s) || "Tier"
            t_label = t["label"]?.try(&.as_s) || ""
            str << "  - **" << t_title << " (" << t_label << ")**:\n"
            if blocks = t["blocks"]?.try(&.as_a)
              blocks.each do |b|
                str << "    - **" << b["title"]?.try(&.as_s) << "**: " << LayoutRenderer.clean_text(b["desc"]?.try(&.as_s) || "") << "\n"
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
