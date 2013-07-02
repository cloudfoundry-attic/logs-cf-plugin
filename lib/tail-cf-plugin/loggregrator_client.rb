require 'faye/websocket'
require 'eventmachine'

module TailCfPlugin
  class LoggregatorClient
    def initialize(output)
      @output = output
    end

    def listen(loggregator_host)
      websocket_address = "ws://#{loggregator_host}/tail"

      EM.run {
        ws = Faye::WebSocket::Client.new(websocket_address, nil, :headers => { "Origin" => "http://localhost" } )

        ws.on :message do |event|
          output.puts(event.data.pack('U*'))
        end

        ws.on :error do |event|
          output.puts("Server error")
        end

        ws.on :close do |event|
          output.puts("Server dropped connection")
        end
      }
    end

    private

    attr_reader :output
  end
end
