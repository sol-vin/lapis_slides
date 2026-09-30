require "./layout_renderer"

module LapisSlides
  class IntroLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      cube_size = slide.raw["cube_size"]?.try(&.as_i) || 310
      author_name = slide.raw["author"]?.try(&.as_s) || "Ian Rash"
      author_alias = slide.raw["author_alias"]?.try(&.as_s) || "sol.vin"
      author_role = slide.raw["author_role"]?.try(&.as_s) || "Creator of Lapis • Systems Engineer & Game Developer"
      repo_link = slide.raw["repo"]?.try(&.as_s) || "github.com/sol-vin/lapis"
      pills = slide.raw["pills"]?.try(&.as_a)

      hero_cube = "<div class=\"hero-cube intro-cube\" data-size=\"#{cube_size}\" title=\"Spinning 3D Isometric Cube • Click or Drag to Spin!\"></div>"

      body = String.build do |str|
        # Big wireframe cube perfectly centered in the screen
        str << "        " << hero_cube << "\n"

        # Foreground content container
        str << "        <div class=\"intro-content\">\n"

        # Top Block: Talk Topic Badge, Title, Subtitle
        str << "          <div class=\"intro-top-block\">\n"
        if !slide.badge.empty?
          str << "            <div class=\"intro-topic-wrap\">\n"
          str << "              <span class=\"badge-pill " << slide.badge_color << " intro-topic-badge\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.badge)) << "</span>\n"
          str << "            </div>\n"
        end
        str << "            <h1 class=\"intro-title\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.title)) << "</h1>\n"
        if !slide.subtitle.empty?
          str << "            <p class=\"intro-subtitle\">" << LayoutRenderer.tint_emojis(HTML.escape(slide.subtitle)) << "</p>\n"
        end
        str << "          </div>\n"

        # Center spacer so the interactive 3D cube remains unobstructed
        str << "          <div class=\"intro-cube-spacer\" style=\"height: #{cube_size}px;\"></div>\n"

        # Bottom Block: Author, Role, Highlight Pills
        str << "          <div class=\"intro-bottom-block\">\n"
        str << "            <div class=\"intro-author-wrap\">\n"
        str << "              <div class=\"intro-author-name\">" << HTML.escape(author_name)
        if !author_alias.empty?
          str << " <span class=\"intro-author-alias\">(" << HTML.escape(author_alias) << ")</span>"
        end
        str << "</div>\n"
        if !author_role.empty?
          str << "              <div class=\"intro-author-role\">" << LayoutRenderer.tint_emojis(HTML.escape(author_role)) << "</div>\n"
        end
        str << "            </div>\n"

        if pills && !pills.empty?
          str << "            <div class=\"intro-pills-row\">\n"
          pills.each do |p|
            str << "              <span class=\"intro-pill\">" << LayoutRenderer.tint_emojis(p.as_s) << "</span>\n"
          end
          str << "            </div>\n"
        elsif !repo_link.empty?
          str << "            <div class=\"intro-pills-row\">\n"
          str << "              <span class=\"intro-pill\">⚡ LLVM Native C-Speed</span>\n"
          str << "              <span class=\"intro-pill\">💎 Ruby-Like Zen DSL</span>\n"
          str << "              <span class=\"intro-pill\">🎮 First-Class Godot 4.8+</span>\n"
          str << "              <span class=\"intro-pill\"><code>" << HTML.escape(repo_link) << "</code></span>\n"
          str << "            </div>\n"
        end

        str << "          </div>\n"
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

        author_name = slide.raw["author"]?.try(&.as_s) || "Ian Rash"
        author_alias = slide.raw["author_alias"]?.try(&.as_s) || "sol.vin"
        author_role = slide.raw["author_role"]?.try(&.as_s) || "Creator of Lapis • Systems Engineer & Game Developer"
        repo_link = slide.raw["repo"]?.try(&.as_s) || "github.com/sol-vin/lapis"

        str << "- **Presenter & Author**: " << author_name << " (" << author_alias << ") — " << author_role << "\n"
        str << "- **Repository**: `" << repo_link << "`\n"

        if pills = slide.raw["pills"]?.try(&.as_a)
          str << "- **Key Highlights**: "
          str << pills.map { |p| LayoutRenderer.clean_text(p.as_s) }.join(" • ") << "\n"
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
