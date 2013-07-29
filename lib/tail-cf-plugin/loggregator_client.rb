module TailCfPlugin
  class LoggregatorClient
    def initialize(output)
      @output = output
    end

    def listen(loggregator_host, space_id, app_id, user_token)
      websocket_address = "wss://#{loggregator_host}/tail/spaces/#{space_id}"
      websocket_address += "/apps/#{app_id}" if app_id

      websocket_address += "?authorization=#{URI.encode(user_token)}"

      EM.run {
        ws = Faye::WebSocket::Client.new(websocket_address, nil, :headers => {"Origin" => "http://localhost"})

        ws.on :message do |event|
          received_message = LogMessage.decode(event.data.pack("C*"))
          output.puts([received_message.app_id, received_message.source_id, received_message.message_type_name, received_message.message].join(" "))
        end

        ws.on :error do |event|
          output.puts("Server error")
        end

        ws.on :close do |event|
          output.puts("Server dropped connection...goodbye.")
          EM.stop
        end
      }
    end

    private

    attr_reader :output
  end
end
