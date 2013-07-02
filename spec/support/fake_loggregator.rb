module TailCfPlugin
  class FakeLoggregator
    def initialize(port)
      @port = port
    end

    def start
      app = lambda do |env|
        ws = Faye::WebSocket.new(env)

        ws.on :open do |event|
          ws.send("Hello".unpack("U*"))
        end

        # Return async Rack response
        ws.rack_response
      end

      Faye::WebSocket.load_adapter('thin')
      @em_server_thread = Thread.new do
        EM.run {
          thin = Rack::Handler.get('thin')
          thin.run(app, :Port => port)
        }
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
      Thread.kill(em_server_thread)
    end

    private

    attr_reader :port, :em_server_thread
  end
end
