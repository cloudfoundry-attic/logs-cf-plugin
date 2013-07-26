require 'celluloid/websocket/client'

module TailCfPlugin
  class LoggregatorClient
    include Celluloid

    def initialize(output)
      @output = output
    end

    def listen(loggregator_host, space_id, app_id, user_token)
      websocket_address = "ws://#{loggregator_host}/tail/spaces/#{space_id}"
      websocket_address += "/apps/#{app_id}" if app_id
      websocket_address += "?authorization=#{URI.encode(user_token)}"

      @client = Celluloid::WebSocket::Client.new(websocket_address, current_actor, headers: {"Origin" => "http://localhost" })
    end

    def on_open
      output.puts("Connected to server.")
    end

    def on_message(data)
      received_message = LogMessage.decode(data.pack("C*"))
      output.puts([received_message.app_id, received_message.source_id, received_message.message_type_name, received_message.message].join(" "))
    end

    def on_close(code, reason)
      output.puts("Server dropped connection...goodbye. #{code} #{reason}")
    end

    private

    attr_reader :output
  end
end
