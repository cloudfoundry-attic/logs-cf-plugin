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
    input :app, :desc => "App to tail logs from", :argument => :required, :from_given => by_name(:app)

    def tail
      loggregrator_client = LoggregatorClient.new(STDOUT)
      loggregrator_client.listen(input[:loggregator_host], input[:app].guid)
    end
  end
end
