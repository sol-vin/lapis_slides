require "http/server"

module LapisSlides
  class RedirectRootHandler
    include HTTP::Handler

    def call(context)
      if context.request.path == "/"
        context.response.status = HTTP::Status::FOUND
        context.response.headers["Location"] = "/index.html"
      else
        call_next(context)
      end
    end
  end

  class Server
    def self.run(directory : String, port : Int32 = 8000)
      file_handler = HTTP::StaticFileHandler.new(directory, fallthrough: false, directory_listing: false)
      redirect_handler = RedirectRootHandler.new

      (port..(port + 20)).each do |candidate_port|
        server = HTTP::Server.new([redirect_handler, file_handler])
        begin
          address = server.bind_tcp("127.0.0.1", candidate_port)
          url = "http://localhost:#{candidate_port}/index.html"

          puts "================================================================"
          puts "  Lapis Presentation Server Running at:"
          puts "  --> #{url}"
          puts "  Controls:"
          puts "    • Next / Prev: Space, Arrow keys"
          puts "    • Speaker Notes: S (opens dual-screen presenter view)"
          puts "    • Overview Grid: ESC or O"
          puts "    • Fullscreen: F"
          puts "================================================================"
          puts "Press Ctrl+C to stop the server."

          # Open browser on Windows
          spawn do
            sleep 0.5.seconds
            {% if flag?(:windows) %}
              Process.run("cmd", ["/c", "start", url])
            {% elsif flag?(:darwin) %}
              Process.run("open", [url])
            {% else %}
              Process.run("xdg-open", [url])
            {% end %}
          rescue
            # Ignore browser launch failure
          end

          server.listen
          break
        rescue Socket::BindError
          next
        end
      end
    end
  end
end
