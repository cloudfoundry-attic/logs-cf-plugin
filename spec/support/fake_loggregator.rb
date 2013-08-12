module LogsCfPlugin
  class FakeLoggregator
    attr_reader :messages

    def initialize(ws_port, dump_port)
      @ws_port = ws_port
      @dump_port = dump_port
      @messages = []
    end

    def start
      runApp(websocket_app, ws_port)
      runApp(dump_app, dump_port)
    end

    def stop
      Thread.kill(em_server_thread)
    end

    private

    attr_reader :ws_port, :dump_port, :em_server_thread

    def runApp(app, port)
      Faye::WebSocket.load_adapter('thin')
      @em_server_thread = Thread.new do
        EM.run {
          thin = Rack::Handler.get('thin')

          thin.run(app, :Port => port) do |server|
            # You can set options on the server here, for example to set up SSL:
            server.ssl_options = {
                :private_key_file => File.join(File.dirname(__FILE__), 'server.key'),
                :cert_chain_file => File.join(File.dirname(__FILE__), 'server.crt')
            }
            server.ssl = true
          end
        }
      end

      tries = 0
      loop do
        `lsof -w -i :#{port} | grep LISTEN`
        break if $?.exitstatus == 0
        tries += 1
        raise "could not connect to fake loggregator #{port}" if tries > 50
        sleep(0.2)
      end
    end

    def log_message
      message = LogMessage.new()
      message.timestamp = Time.now.to_i * 1000 * 1000 * 1000
      message.message = "Hello"
      message.message_type = LogMessage::MessageType::OUT
      message.app_id = "1234"
      message.source_id = "5678"
      message.organization_id = "9876"
      message.source_type = LogMessage::SourceType::DEA
      result = message.encode.buf
      result.unpack("C*")
    end

    def websocket_app
      lambda do |env|
        ws = Faye::WebSocket.new(env)

        ws.on :open do |event|
          ws.send(log_message)
        end

        ws.on :message do |event|
          @messages << event.data
        end

        # Return async Rack response
        ws.rack_response
      end
    end

    def dump_app
      lambda do |env|
        request = Rack::Request.new(env)

        response = if env['HTTP_AUTHORIZATION'] != "auth_token"
                     Rack::Response.new(["Unauthorized"], 401, {})

                   elsif request.request_method == "GET" && request.path == "/dump/" && request.params == {"org" => "org_id", "space" => "space_id", "app" => "app_id"}
                     Rack::Response.new(["\x00\x00\x000\n\tSome data\x10\x01\x18\xF2\xC1\xE2\xE6\x93\xF5\xD9\x99&\"\x05myApp(\x04:\amySpaceB\x05myOrg\x00\x00\x001\n\nMore stuff\x10\x01\x18\xB4\x96\xEA\xE6\x93\xF5\xD9\x99&\"\x05myApp(\x04:\amySpaceB\x05myOrg"], 200, {})
                   else
                     Rack::Response.new(["Not found"], 404, {})
                   end
        response.finish
      end
    end
  end
end
