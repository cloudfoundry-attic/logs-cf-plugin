module LogsCfPlugin
  class ClientConfig
    attr_reader :loggregator_host, :user_token, :output, :trace, :use_ssl

    def initialize(loggregator_host, user_token, output, trace, use_ssl = true)
      @output = output
      @loggregator_host = loggregator_host
      @user_token = user_token
      @trace = trace
      @use_ssl = use_ssl
    end
  end
end
