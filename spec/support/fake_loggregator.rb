module TailCfPlugin
  class FakeLoggregator
    def initialize(port, fails = false)
      @port = port
      @fails = fails
    end

    def start
      app = lambda do |env|
        if fails
          [401, {}, ["Unauthorized"]]
        else
          [200, {}, [log_message]]
        end
      end

      @server_thread = Thread.new do
        thin = Rack::Handler.get('thin')
        thin.run(app, :Port => port)
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

    def stop
      Thread.kill(server_thread)
    end

    private

    attr_reader :port, :server_thread, :fails

    def log_message
      message = LogMessage.new()
      message.timestamp = Time.now.to_i * 1000 * 1000 * 1000
      message.message = "Hello"
      message.message_type = LogMessage::MessageType::OUT
      message.app_id = "1234"
      message.source_id = "5678"
      message.source_type = LogMessage::SourceType::DEA
      message.encode.buf
    end
  end
end
