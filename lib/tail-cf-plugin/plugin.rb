require 'cf'
require 'faye/websocket'
require 'eventmachine'

module TailCfPlugin
  require 'tail-cf-plugin/loggregrator_client'
  require 'log_message/log_message.pb'

  class Plugin < CF::CLI

    desc "Tail a CF application's logs"
    group :apps
    input :loggregator_host, :argument => :required, :desc => "The ip:port of the loggregator"
    def tail
      loggregrator_client = LoggregatorClient.new(STDOUT)
      loggregrator_client.listen(input[:loggregator_host])
    end
  end
end
