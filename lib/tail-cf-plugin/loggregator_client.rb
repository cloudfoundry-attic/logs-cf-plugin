require 'log_message/log_message.pb'
require 'faye/websocket'
require 'eventmachine'
require 'uri'

module TailCfPlugin
  class LoggregatorClient
    def initialize(loggregator_host, user_token, output)
      @output = output
      @loggregator_host = loggregator_host
      @user_token = user_token
    end

    def listen(query_params)
      websocket_address = "wss://#{loggregator_host}:4443/tail/?#{hash_to_query(query_params)}"

      EM.run {
        ws = Faye::WebSocket::Client.new(websocket_address, nil, :headers => {"Origin" => "http://localhost", "Authorization" => user_token})

        ws.on :open do |event|
          output.puts("Connected to server.")
          EventMachine.add_periodic_timer(keep_alive_interval) do
            ws.send([42])
          end
        end

        ws.on :message do |event|
          received_message = LogMessage.decode(event.data.pack("C*"))
          output.puts([received_message.app_id, received_message.source_id, received_message.message_type_name, received_message.message].join(" "))
        end

        ws.on :error do |event|
          output.puts("Server error")
        end

        ws.on :close do |event|
          ws.close
          output.puts("Server dropped connection...goodbye.")
          EM.stop
          ws = nil
        end
      }
    end

    def dump(query_params)
      uri = URI.parse("http://#{loggregator_host}/dump/?#{hash_to_query(query_params)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)

      response = http.request(request)
      response.body
    end

    private

    def keep_alive_interval
      25
    end

    def hash_to_query(hash)
      return URI.encode(hash.map{|k,v| "#{k}=#{v}"}.join("&"))
    end

    attr_reader :output, :loggregator_host, :user_token
  end
end
