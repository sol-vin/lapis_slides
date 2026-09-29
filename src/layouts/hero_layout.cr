require "./layout_renderer"

module LapisSlides
  class HeroLayout < LayoutRenderer
    def render_html(slide : Slide, palette : Palette, slide_num : Int32, total_slides : Int32, author : String) : String
      cube_size = slide.raw["cube_size"]?.try(&.as_i) || 72
      hero_cube = "<div class=\"hero-cube\" data-size=\"#{cube_size}\" title=\"Spinning 3D Isometric Cube • Click or Drag to Spin!\"></div>"

      body = String.build do |str|
        str << render_slide_header(slide, hero_cube) << "\n"
        str << "        <div class=\"slide-body\" style=\"margin-top: 1rem;\">\n"

        if cards = slide.raw["cards"]?.try(&.as_a)
          cards.each do |c|
            title = c["title"]?.try(&.as_s) || ""
            color = c["color"]?.try(&.as_s) || "cyan"
            badge = c["badge"]?.try(&.as_s)
            items = Array(String).new
            if raw_items = c["items"]?.try(&.as_a)
              raw_items.each { |it| items << it.as_s }
            end
            str << render_card(title, color, items, "col", badge) << "\n"
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

        if cards = slide.raw["cards"]?.try(&.as_a)
          str << "- **Cards & Structure**:\n"
          cards.each do |c|
            str << "  - **" << c["title"]?.try(&.as_s) << "**:\n"
            if raw_items = c["items"]?.try(&.as_a)
              raw_items.each do |it|
                str << "    - " << LayoutRenderer.clean_text(it.as_s) << "\n"
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
