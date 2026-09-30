require "./models/deck"
require "./models/palette"
require "./layouts/router"

module LapisSlides
  class Generator
    getter deck : Deck
    getter palettes : Hash(String, Palette)

    def initialize(@deck : Deck, @palettes : Hash(String, Palette))
    end

    def generate_html(output_file : String)
      total = 0
      @deck.slides.each do |slide|
        renderer = LayoutRouter.renderer_for(slide.layout)
        total += renderer.slide_count(slide)
      end

      slides_html = String.build do |str|
        current_num = 1
        @deck.slides.each do |slide|
          palette = @palettes[slide.palette]? || @palettes.values.first
          renderer = LayoutRouter.renderer_for(slide.layout)
          str << renderer.render_html_all(slide, palette, current_num, total, @deck.author) << "\n\n"
          current_num += renderer.slide_count(slide)
        end
      end

      palette_filters_svg = String.build do |str|
        str << "  <!-- Sol.vin Dynamic SVG Palette Color Matrix Filters for Emojis -->\n"
        str << "  <svg class=\"solvin-palette-filters\" style=\"position: absolute; width: 0; height: 0; pointer-events: none; overflow: hidden;\" aria-hidden=\"true\">\n"
        str << "    <defs>\n"
        @palettes.each_value do |p|
          str << "      <filter id=\"emoji-filter-#{p.id}\" color-interpolation-filters=\"sRGB\">\n"
          str << "        <feColorMatrix type=\"matrix\" values=\"#{p.emoji_color_matrix}\" />\n"
          str << "      </filter>\n"
        end
        str << "    </defs>\n"
        str << "  </svg>\n"
      end

      full_html = <<-HTML
      <!DOCTYPE html>
      <html lang="en">

      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{HTML.escape(@deck.title)} — #{HTML.escape(@deck.subtitle)}</title>

        <!-- Reveal.js Core CSS -->
        <link rel="stylesheet" href="vendor/reveal/reveal.min.css">

        <!-- Highlight.js Atom One Dark Syntax Theme -->
        <link rel="stylesheet" href="vendor/highlight/styles/atom-one-dark.min.css">

        <!-- Asciinema Player CSS -->
        <link rel="stylesheet" href="vendor/asciinema/asciinema-player.css">

        <!-- Lapis Brand Presentation Theme -->
        <link rel="stylesheet" href="theme.css">
      </head>

      <body>
      #{palette_filters_svg}
        <div class="reveal">
          <!-- Sol.vin Persistent Deck Header with 3D Spinning Isometric Cube -->
          <div class="solvin-deck-header">
            <div id="header-cube-app" class="deck-cube-app" title="Spinning 3D Isometric Cube • Click or Drag to Spin!"></div>
            <span class="deck-solvin-label">SOL.VIN // LAPIS</span>
          </div>
          <div class="slides">

      #{slides_html.rstrip}

          </div>
        </div>

        <!-- Reveal.js Engine with Speaker Notes & Highlight Plugins -->
        <script src="vendor/reveal/reveal.min.js"></script>
        <script src="vendor/reveal/plugin/highlight/highlight.min.js"></script>
        <script src="vendor/reveal/plugin/notes/notes.min.js"></script>

        <!-- Highlight.js Engine with Explicit Crystal Language Definition -->
        <script src="vendor/highlight/highlight.min.js"></script>
        <script src="vendor/highlight/languages/crystal.min.js"></script>
        <script src="vendor/highlight/languages/rust.min.js"></script>
        <script src="vendor/highlight/languages/cpp.min.js"></script>
        <script src="vendor/highlight/languages/python.min.js"></script>

        <script>
          // Initialize Reveal.js Presentation Engine
          Reveal.initialize({
            width: #{@deck.width},
            height: #{@deck.height},
            margin: 0.04,
            minScale: 0.2,
            maxScale: 2.5,

            // Navigation & Display
            controls: true,
            progress: true,
            center: false,
            hash: true,
            history: true,
            slideNumber: 'c/t',
            overview: true,
            help: true,
            keyboard: true,

            // Transitions
            transition: 'fade',
            backgroundTransition: 'fade',
            transitionSpeed: 'fast',

            // Highlight plugin configuration
            highlight: {
              beforeHighlight: (internalHljs) => {
                if (window.hljs && window.hljs.registerAliases) {
                  try { window.hljs.registerAliases(['gdscript', 'gd'], { languageName: 'python' }); } catch(e) {}
                  try { window.hljs.registerAliases(['ruby', 'rb'], { languageName: 'crystal' }); } catch(e) {}
                }
                if (internalHljs && internalHljs.registerAliases) {
                  try { internalHljs.registerAliases(['gdscript', 'gd'], { languageName: 'python' }); } catch(e) {}
                  try { internalHljs.registerAliases(['ruby', 'rb'], { languageName: 'crystal' }); } catch(e) {}
                }
                if (window.hljs && window.hljs.listLanguages) {
                  window.hljs.listLanguages().forEach((lang) => {
                    const def = window.hljs.getLanguage(lang);
                    if (def && !internalHljs.getLanguage(lang)) {
                      internalHljs.registerLanguage(lang, def.rawDefinition || (() => def));
                    }
                  });
                }
              }
            },

            // Plugins
            plugins: [RevealHighlight, RevealNotes]
          }).then(() => {
            const urlParams = new URLSearchParams(window.location.search);
            const sParam = urlParams.get('s');
            if (sParam !== null) {
              const targetIdx = parseInt(sParam, 10);
              Reveal.slide(targetIdx, 0, 0);
            }
          });
        </script>
        <!-- Sol.vin 3D Isometric Wireframe Cube Engine -->
        <script src="cube.js"></script>

        <!-- Asciinema Player Engine & Reveal.js Synchronization -->
        <script src="vendor/asciinema/asciinema-player.min.js"></script>
        <script>
          (function() {
            const asciinemaInstances = new Map();

            function decodeBase64Utf8(base64) {
              const binaryString = atob(base64);
              const bytes = new Uint8Array(binaryString.length);
              for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
              }
              return new TextDecoder('utf-8').decode(bytes);
            }

            function mountPlayer(mount) {
              if (asciinemaInstances.has(mount)) return asciinemaInstances.get(mount);
              if (!window.AsciinemaPlayer) return null;

              const src = mount.dataset.castSrc;
              const url = mount.dataset.castUrl;
              let playerSrc = null;

              if (src && src.startsWith('data:')) {
                try {
                  const base64Content = src.split(',')[1];
                  const decoded = decodeBase64Utf8(base64Content);
                  const lines = decoded.split(String.fromCharCode(10)).map(l => l.trim()).filter(l => l.length > 0);
                  const parsed = lines.map(l => JSON.parse(l));
                  playerSrc = { data: parsed };
                } catch (e) {
                  console.warn('Failed to parse inlined base64 cast, using URL fallback:', e);
                  playerSrc = { url: url || src };
                }
              } else if (url) {
                playerSrc = { url: url };
              } else if (src) {
                playerSrc = { url: src };
              }

              if (!playerSrc) return null;

              const speed = parseFloat(mount.dataset.speed || '1.0');
              const loop = mount.dataset.loop === 'true';
              const autoplay = mount.dataset.autoplay === 'true';
              const theme = mount.dataset.theme || 'monokai';
              const cols = parseInt(mount.dataset.cols || '80', 10);
              const rows = parseInt(mount.dataset.rows || '18', 10);
              const fontSize = mount.dataset.fontSize || '0.60rem';
              const controlsVal = mount.dataset.controls;
              const controls = controlsVal === 'true' ? true : (controlsVal === 'false' ? false : 'auto');

              try {
                const player = AsciinemaPlayer.create(playerSrc, mount, {
                  cols: cols,
                  rows: rows,
                  speed: speed,
                  loop: loop,
                  autoPlay: autoplay,
                  theme: theme,
                  terminalFontSize: fontSize,
                  fit: 'both',
                  controls: controls
                });
                asciinemaInstances.set(mount, player);
                return player;
              } catch (err) {
                console.error('Asciinema mount failed:', err);
                return null;
              }
            }

            function activateSlide(slideEl) {
              if (!slideEl) return;
              slideEl.querySelectorAll('.asciinema-player-mount').forEach(mount => {
                let player = asciinemaInstances.get(mount);
                if (!player) {
                  player = mountPlayer(mount);
                }
                if (player && typeof player.play === 'function') {
                  if (typeof player.seek === 'function') {
                    try { player.seek(0); } catch(e) {}
                  }
                  try { player.play(); } catch(e) {}
                }
              });
            }

            function deactivateSlide(slideEl) {
              if (!slideEl) return;
              slideEl.querySelectorAll('.asciinema-player-mount').forEach(mount => {
                const player = asciinemaInstances.get(mount);
                if (player && typeof player.pause === 'function') {
                  try { player.pause(); } catch(e) {}
                }
              });
            }

            document.addEventListener('click', event => {
              const replayBtn = event.target && event.target.closest ? event.target.closest('.asciinema-window .code-lang-tag') : null;
              if (replayBtn) {
                const win = replayBtn.closest('.asciinema-window');
                const mount = win ? win.querySelector('.asciinema-player-mount') : null;
                const player = mount ? asciinemaInstances.get(mount) : null;
                if (player) {
                  try { player.seek(0); } catch(e) {}
                  try { player.play(); } catch(e) {}
                }
              }
            });

            if (window.Reveal) {
              if (typeof Reveal.isReady === 'function' && Reveal.isReady()) {
                setTimeout(() => activateSlide(Reveal.getCurrentSlide()), 50);
              } else {
                Reveal.on('ready', () => {
                  setTimeout(() => activateSlide(Reveal.getCurrentSlide()), 50);
                });
              }

              Reveal.on('slidechanged', event => {
                deactivateSlide(event.previousSlide);
                setTimeout(() => activateSlide(event.currentSlide), 50);
              });

              // Extra safeguard for direct hash landings
              setTimeout(() => {
                activateSlide(Reveal.getCurrentSlide());
              }, 300);
            } else {
              document.addEventListener('DOMContentLoaded', () => {
                document.querySelectorAll('.asciinema-player-mount').forEach(mountPlayer);
              });
            }
          })();
        </script>
      </body>

      </html>
      HTML

      File.write(output_file, full_html)
      puts "✓ Generated #{output_file} (#{total} slides)"
    end

    def generate_markdown(output_file : String)
      total = 0
      @deck.slides.each do |slide|
        renderer = LayoutRouter.renderer_for(slide.layout)
        total += renderer.slide_count(slide)
      end

      md_content = String.build do |str|
        str << "# " << @deck.title << " — Complete " << total << "-Slide Presentation Deck Reference\n\n"
        str << "Welcome to the definitive reference document for the " << total << "-slide presentation deck: "
        str << "**" << @deck.title << ": " << @deck.subtitle << "**.\n\n"
        str << "This document outlines each slide's exact theme palette, architectural category, on-screen card structures, code examples, and full presenter speaking script.\n\n"
        str << "---\n\n"

        current_num = 1
        @deck.slides.each do |slide|
          palette = @palettes[slide.palette]? || @palettes.values.first
          renderer = LayoutRouter.renderer_for(slide.layout)
          str << renderer.render_markdown_all(slide, palette, current_num, total)
          current_num += renderer.slide_count(slide)
        end
      end

      File.write(output_file, md_content)
      puts "✓ Generated #{output_file} (#{total} slides)"
    end
  end
end
