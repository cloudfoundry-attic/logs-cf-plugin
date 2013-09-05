module LogsCfPlugin
  class TailingLogsClient
    #include CFoundry::TraceHelpers
    include MessageWriter

    def initialize(config)
      @config = config
    end

    def logs_for(app)
      protocol = use_ssl ? "wss" : "ws"
      websocket_address = "#{protocol}://#{loggregator_host}#{loggregator_port ? ":#{loggregator_port}" : ""}/tail/?app=#{app.guid}"

      output.puts "websocket_address: #{websocket_address}" if trace

      make_websocket_request(app, websocket_address)
    end

    def make_websocket_request(app, websocket_address)
      redirect_uri = nil
      @em_client_thread = Thread.new do
        EM.run {
          ws = Faye::WebSocket::Client.new(websocket_address, nil, :headers => {"Origin" => "http://localhost", "Authorization" => user_token})
          ws.on :open do |event|
            output.puts("Connected to server.")
            EventMachine.add_periodic_timer(keep_alive_interval) do
              ws.send([42])
            end
          end

          ws.on :message do |event|
            begin
              received_message = LogMessage.decode(event.data.pack("C*"))
              write(app, output, received_message)
            rescue Beefcake::Message::WrongTypeError, Beefcake::Message::RequiredFieldNotSetError, Beefcake::Message::InvalidValueError
              output.puts("Error parsing data. Please ensure your gem is the latest version.")
              ws.close
              @em_client_thread.kill
            end
          end

          ws.on :error do |event|
            if !redirect_uri
              if event.current_target.status == 302
                redirect_uri = event.current_target.headers["location"]
                ws.close
                @em_client_thread.kill
                ws = nil
              else
                output.puts("Server error: #{websocket_address}")
                output.puts(event.data.inspect) if trace
              end
              end
          end

          ws.on :close do |event|
            unless redirect_uri
              ws.close
              case event.code
                when 4000
                  output.puts("Error: No space given.")
                when 4001
                  output.puts("Error: No authorization token given.")
                when 4002
                  output.puts("Error: Not authorized.")
              end
              output.puts("Server dropped connection...goodbye.")
              @em_client_thread.kill
              ws = nil
            end
          end
        }
      end

      wait_for_em_thread_to_finish

      make_websocket_request(app, redirect_uri) if redirect_uri
    end

    def wait_for_em_thread_to_finish
      while @em_client_thread.alive? do
        sleep 0.1
      end
    end

    private

    attr_reader :config

    delegate :output, :loggregator_host, :loggregator_port, :user_token, :trace, :use_ssl,
             to: :config

    def keep_alive_interval
      25
    end
  end
end
