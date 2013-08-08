module TailCfPlugin
  class FakeLoggregator
    attr_reader :messages

    def initialize(port)
      @port = port
      @messages = []
    end

    def startListenEndpoint
      app = lambda do |env|
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

      runApp(app, port)
    end

    def startDumpEndpoint
      app = lambda do |env|
        request = Rack::Request.new(env)
        if request.request_method == "GET" && request.path == "/dump/" && request.params == {"space"=>"space_id", "app"=>"app_id"}
          response = Rack::Response.new(["6bd8483a-7f7f-4e11-800a-4369501752c3  STDOUT Hello on STDOUT"], 200, {})
          response.finish
        else
          response = Rack::Response.new(["Not found"], 404, {})
          response.finish
        end
      end

      runApp(app, port)
    end

    def stop
      Thread.kill(em_server_thread)
    end

    private

    attr_reader :port, :em_server_thread

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
  end
end
