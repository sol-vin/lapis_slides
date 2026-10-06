require "./layout_renderer"

module LapisSlides
  class DemoRoadmapLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      steps = slide.raw["steps"]?.try(&.as_a)
      summary = slide.raw["summary"]?.try(&.as_s)

      body = String.build do |str|
        str << render_slide_header(slide) << "\n"
        str << "        <div class=\"slide-body demo-roadmap-body\" style=\"display: flex; flex-direction: column; gap: 0.65rem; flex: 1;\">\n"

        if steps
          str << "          <div class=\"demo-steps-grid\" style=\"grid-template-columns: repeat(#{steps.size}, 1fr) !important;\">\n"
          steps.each do |s|
            phase = s["phase"]?.try(&.as_s) || ""
            title = s["title"]?.try(&.as_s) || ""
            color = s["color"]?.try(&.as_s) || ""
            cmd = s["cmd"]?.try(&.as_s)
            code = s["code"]?.try(&.as_s)
            lang = s["lang"]?.try(&.as_s) || (code ? "crystal" : "bash")
            items = s["items"]?.try(&.as_a)
            highlight = s["highlight"]?.try(&.as_s)

            str << "            <div class=\"demo-step-card " << color << "\">\n"
            str << "              <div class=\"demo-step-header\">\n"
            if !phase.empty?
              str << "                <span class=\"badge-pill " << color << "\" style=\"font-size: 0.58rem; margin: 0;\">" << HTML.escape(phase) << "</span>\n"
            end
            str << "                <div class=\"demo-step-title\">" << LayoutRenderer.tint_emojis(HTML.escape(title)) << "</div>\n"
            str << "              </div>\n"

            if cmd
              str << "              <div class=\"demo-step-box terminal-box\">\n"
              str << "                <pre><code class=\"language-bash\">" << HTML.escape(cmd.strip) << "</code></pre>\n"
              str << "              </div>\n"
            elsif code
              str << "              <div class=\"demo-step-box code-box\">\n"
              str << "                <pre><code class=\"language-" << lang << "\">" << HTML.escape(code.strip) << "</code></pre>\n"
              str << "              </div>\n"
            end

            if items
              str << "              <ul class=\"demo-step-list\">\n"
              items.each do |it|
                str << "                <li>" << LayoutRenderer.tint_emojis(it.as_s) << "</li>\n"
              end
              str << "              </ul>\n"
            end

            if highlight
              str << "              <div class=\"demo-step-highlight " << color << "\">\n"
              str << "                " << LayoutRenderer.tint_emojis(highlight) << "\n"
              str << "              </div>\n"
            end

            str << "            </div>\n"
          end
          str << "          </div>\n"
        end

        if summary
          str << "          <div class=\"demo-roadmap-summary\">\n"
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

        if steps = slide.raw["steps"]?.try(&.as_a)
          str << "- **Demo Timeline Stages**:\n"
          steps.each do |s|
            phase = s["phase"]?.try(&.as_s) || ""
            title = s["title"]?.try(&.as_s) || ""
            str << "  - **" << phase << ": " << title << "**\n"
            if cmd = s["cmd"]?.try(&.as_s)
              str << "    - *Command*:\n      ```bash\n      " << cmd.strip.gsub("\n", "\n      ") << "\n      ```\n"
            end
            if code = s["code"]?.try(&.as_s)
              str << "    - *Code*:\n      ```crystal\n      " << code.strip.gsub("\n", "\n      ") << "\n      ```\n"
            end
            if items = s["items"]?.try(&.as_a)
              items.each do |it|
                str << "    - " << LayoutRenderer.clean_text(it.as_s) << "\n"
              end
            end
          end
        end

        if summary = slide.raw["summary"]?.try(&.as_s)
          str << "- **Demonstration Goal**: " << LayoutRenderer.clean_text(summary) << "\n"
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
