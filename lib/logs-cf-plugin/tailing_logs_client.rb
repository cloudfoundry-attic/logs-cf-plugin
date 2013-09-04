module LogsCfPlugin
  class TailingLogsClient
    #include CFoundry::TraceHelpers
    include MessageWriter

    def initialize(config)
      @config = config
    end

    def logs_for(app)
      if use_ssl
        websocket_address = "wss://#{loggregator_host}:4443/tail/?app=#{app.guid}"
      else
        websocket_address = "ws://#{loggregator_host}/tail/?app=#{app.guid}"
      end

      output.puts "websocket_address: #{websocket_address}" if trace

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
            EM.stop
          end
        end

        ws.on :error do |event|
          @config.output.puts("Server error")
          @config.output.puts(event.data.inspect) if trace
        end

        ws.on :close do |event|
          ws.close
          case event.code
            when 4000
              @config.output.puts("Error: No space given.")
            when 4001
              @config.output.puts("Error: No authorization token given.")
            when 4002
              @config.output.puts("Error: Not authorized.")
          end
          @config.output.puts("Server dropped connection...goodbye.")
          EM.stop
          ws = nil
        end
      }
    end

    private

    attr_reader :config

    delegate :output, :loggregator_host, :user_token, :trace, :use_ssl,
             to: :config

    def keep_alive_interval
      25
    end
  end
end
