require "option_parser"
require "./models/deck"
require "./models/palette"
require "./generator"
require "./server"
require "./cast_builder"

module LapisSlides
  class CLI
    def self.run(args = ARGV)
      command = "build"
      port = 8000
      base_dir = if File.exists?(File.expand_path("data/deck.yml", Dir.current))
                   Dir.current
                 elsif File.exists?(File.expand_path("slides/data/deck.yml", Dir.current))
                   File.expand_path("slides", Dir.current)
                 else
                   Dir.current
                 end

      slides_dir = File.expand_path("data/slides", base_dir)
      deck_file = File.expand_path("data/deck.yml", base_dir)
      palettes_file = File.expand_path("solvin_palettes.json", base_dir)
      output_html = File.expand_path("index.html", base_dir)
      output_md = File.expand_path("SLIDES.md", base_dir)
      web_root = base_dir

      skip_casts = false
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: crystal run slides/src/builder.cr -- [command] [options]"
        opts.on("build", "Compile slide YAML files into index.html and SLIDES.md (default)") { command = "build" }
        opts.on("serve", "Build and launch live HTTP presentation preview server") { command = "serve" }
        opts.on("validate", "Validate slide YAML files, layouts, and theme palettes") { command = "validate" }
        opts.on("--no-casts", "Skip rebuilding cast files") { skip_casts = true }
        opts.on("-p PORT", "--port=PORT", "Port for HTTP preview server (default: 8000)") { |p| port = p.to_i }
        opts.on("-h", "--help", "Show help and commands") do
          puts opts
          exit 0
        end
      end

      # Handle leading subcommands
      if !args.empty? && !args[0].starts_with?("-")
        case args[0].downcase
        when "build"
          command = "build"
          args.shift
        when "serve"
          command = "serve"
          args.shift
          if !args.empty? && !args[0].starts_with?("-")
            port = args[0].to_i
            args.shift
          end
        when "validate"
          command = "validate"
          args.shift
        end
      end

      parser.parse(args)

      unless File.exists?(palettes_file)
        STDERR.puts "Error: Palettes file not found at #{palettes_file}"
        exit 1
      end

      palettes = Palette.load_all(palettes_file)
      deck = Deck.load(deck_file, slides_dir)
      generator = Generator.new(deck, palettes)

      case command
      when "build"
        puts "Building presentation deck '#{deck.title}'..."
        CastBuilder.build_all(File.expand_path("casts", base_dir)) unless skip_casts
        generator.generate_html(output_html)
        generator.generate_markdown(output_md)
        puts "Successfully built #{deck.slides.size} slides!"
      when "serve"
        puts "Ensuring slides are built before serving..."
        CastBuilder.build_all(File.expand_path("casts", base_dir)) unless skip_casts
        generator.generate_html(output_html)
        generator.generate_markdown(output_md)
        Server.run(web_root, port)
      when "validate"
        puts "Validating presentation deck '#{deck.title}'..."
        valid = true
        layout_counts = Hash(String, Int32).new(0)
        palette_counts = Hash(String, Int32).new(0)

        deck.slides.each_with_index do |slide, idx|
          num = idx + 1
          layout_counts[slide.layout] += 1
          palette_counts[slide.palette] += 1

          if !palettes.has_key?(slide.palette)
            STDERR.puts "  [ERROR] Slide #{num} (#{slide.id}): Unknown palette '#{slide.palette}'"
            valid = false
          end

          if slide.title.strip.empty?
            STDERR.puts "  [WARN] Slide #{num} (#{slide.id}): Empty title"
          end
        end

        puts "\nSlide Count: #{deck.slides.size} slides"
        puts "\nLayout Breakdown:"
        layout_counts.each do |layout, count|
          puts "  • #{layout.ljust(25)} : #{count}"
        end

        puts "\nUnique Palettes Used: #{palette_counts.size} / #{palettes.size}"

        if valid
          puts "\n✓ All #{deck.slides.size} slides passed schema validation!"
        else
          puts "\n❌ Validation errors detected!"
          exit 1
        end
      end
    end
  end
end

LapisSlides::CLI.run
