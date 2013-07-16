require 'cf'
require 'faye/websocket'
require 'eventmachine'

module TailCfPlugin
  require 'tail-cf-plugin/loggregrator_client'
  require 'log_message/log_message.pb'

  class Plugin < CF::CLI
    include LoginRequirements

    desc "Tail a CF application's logs"
    group :apps
    input :loggregator_host, :argument => :required, :desc => "The ip:port of the loggregator"
    input :app, :desc => "App to tail logs from", :argument => :optional, :from_given => by_name(:app)
    input :space, :desc => "App to tail logs from", :argument => :optional, :from_given => by_name(:space)

    def tail

      raise "Missing an app or space" unless input[:app] || input[:space]

      space_guid = (input[:space] && input[:space].guid) || input[:app].space.guid
      app_guid = input[:app] && input[:app].guid

      loggregrator_client = LoggregatorClient.new(STDOUT)
      loggregrator_client.listen(input[:loggregator_host], space_guid, app_guid, client.token.auth_header)
    end
  end
end
