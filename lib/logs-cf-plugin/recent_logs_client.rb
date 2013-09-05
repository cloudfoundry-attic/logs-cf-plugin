module LogsCfPlugin
  class RecentLogsClient
    include CFoundry::TraceHelpers
    include MessageWriter

    def initialize(config)
      @config = config
    end

    def logs_for(app)
      prefix = use_ssl ? 'https' : 'http'
      uri = "#{prefix}://#{loggregator_host}#{loggregator_port ? ":#{loggregator_port}" : ""}/dump/?app=#{app.guid}"
      response = make_dump_request(uri, app)
      return unless response

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
        write(app, output, m)
      end
    rescue Beefcake::Message::WrongTypeError, Beefcake::Message::RequiredFieldNotSetError, Beefcake::Message::InvalidValueError
      output.puts("Error parsing data. Please ensure your gem is the latest version.")
    end

    private

    attr_reader :config

    delegate :output, :loggregator_host, :loggregator_port, :user_token, :trace, :use_ssl,
             to: :config

    def make_dump_request(uri, app)
      uri = URI.parse(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = use_ssl
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = user_token

      if trace
        request_hash = {
            :url => uri.to_s,
            :method => "GET",
            :headers => sane_headers(request),
            :body => ""
        }
        output.puts(request_trace(request_hash))
      end

      response = http.request(request)

      case response.code
        when "200"
          return response
        when "302"
          response = make_dump_request(response['location'], app)
          return response
        when "401"
          output.puts("Unauthorized")
          return
        when "404"
          output.puts("App #{app.name} not found")
          return
        else
          output.puts("Error connecting to server #{response.code}")
          return
      end
    end

    def sane_headers(obj)
      hds = {}

      obj.each_header do |k, v|
        hds[k] = v
      end

      hds
    end
  end
end
