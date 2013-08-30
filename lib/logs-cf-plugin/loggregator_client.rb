module LogsCfPlugin
  class LoggregatorClient
    include CFoundry::TraceHelpers
    include MessageWriter

    def initialize(loggregator_host, user_token, output, trace, use_ssl = true)
      @output = output
      @loggregator_host = loggregator_host
      @user_token = user_token
      @trace = trace
      @use_ssl = use_ssl
    end

    def listen(log_target)
      if use_ssl
        websocket_address = "wss://#{loggregator_host}:4443/tail/?#{hash_to_query(log_target.query_params)}"
      else
        websocket_address = "ws://#{loggregator_host}/tail/?#{hash_to_query(log_target.query_params)}"
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
            write(log_target, output, received_message)
          rescue Beefcake::Message::WrongTypeError, Beefcake::Message::RequiredFieldNotSetError,  Beefcake::Message::InvalidValueError
            output.puts("Error parsing data. Please ensure your gem is the latest version.")
            ws.close
            EM.stop
          end
        end

        ws.on :error do |event|
          output.puts("Server error")
          output.puts(event.data.inspect) if trace
        end

        ws.on :close do |event|
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
          EM.stop
          ws = nil
        end
      }
    end

    def dump_messages(log_target)
      prefix = use_ssl ? 'https' : 'http'
      uri = URI.parse("#{prefix}://#{loggregator_host}/dump/?#{hash_to_query(log_target.query_params)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = use_ssl
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = user_token

      if trace
        request_hash = {
            :url => uri.request_uri,
            :method => "GET",
            :headers => sane_headers(request),
            :body => ""
        }
        output.puts(request_trace(request_hash))
      end

      response = http.request(request)

      case response.code
        when "200"
          # fall thru
        when "401"
          output.puts("Unauthorized")
          return
        when "404"
          output.puts("App #{log_target.app_name} not found")
          return
        else
          output.puts("Error connecting to server #{response.code}")
          return
      end

      response_bytes = StringIO.new(response.body)
      messages = []
      while len = response_bytes.read(4)
        len = len.unpack("N")[0] # 32-bit length, BigEndian stylie
        record = response_bytes.read(len) # This returns a string even if len is 0.
        msg = LogMessage.decode(record)
        messages << msg
      end

      if trace
        response_hash = {
            :headers => sane_headers(response),
            :status => response.code,
            :body => messages
        }
        output.puts(response_trace(response_hash))
      end

      messages.each do |m|
        write(log_target, output, m)
      end
    rescue Beefcake::Message::WrongTypeError, Beefcake::Message::RequiredFieldNotSetError, Beefcake::Message::InvalidValueError
      output.puts("Error parsing data. Please ensure your gem is the latest version.")
      []
    end

    private

    def sane_headers(obj)
      hds = {}

      obj.each_header do |k, v|
        hds[k] = v
      end

      hds
    end

    def keep_alive_interval
      25
    end

    def hash_to_query(hash)
      return URI.encode(hash.map { |k, v| "#{k}=#{v}" }.join("&"))
    end

    attr_reader :output, :loggregator_host, :user_token, :trace, :use_ssl
  end
end
