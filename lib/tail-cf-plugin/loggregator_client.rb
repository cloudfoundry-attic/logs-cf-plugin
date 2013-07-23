module TailCfPlugin
  class LoggregatorClient
    def initialize(output)
      @output = output
    end

    def listen(loggregator_host, space_id, app_id, user_token)
      address = "#{loggregator_host}/tail/spaces/#{space_id}"
      address += "/apps/#{app_id}" if app_id

      address += "?authorization=#{URI.encode(user_token)}"

      uri = URI.parse(address)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Get.new uri.request_uri
      output.puts "Connected to #{loggregator_host}"
      http.request request do |response|
        case response.code.to_i
          when 200
            response.read_body do |chunk|
              received_message = LogMessage.decode(chunk)
              output.puts([received_message.app_id, received_message.source_id, received_message.message_type_name, received_message.message].join(" "))
            end
          else
            output.puts("Error #{response.code}: #{response.body}")
        end
      end
    end

    private

    attr_reader :output
  end
end
