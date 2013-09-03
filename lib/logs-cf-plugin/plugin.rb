require 'cf'
require 'eventmachine'
require 'faye/websocket'
require 'loggregator_messages'
require 'uri'

module LogsCfPlugin
  require 'logs-cf-plugin/message_writer'
  require 'logs-cf-plugin/loggregator_client'

  class Plugin < CF::CLI
    include LoginRequirements
    include MessageWriter

    desc "Tail or dump logs for CF applications or spaces"
    group :apps
    input :app, :desc => "App to tail logs from", :argument => :optional, :from_given => by_name(:app)
    input :recent, :type => :boolean, :desc => "Dump recent logs instead of tailing", :default => false

    def logs
      client.current_organization.name # resolve org name so CC will validate AuthToken

      unless input[:app]
        Mothership::Help.command_help(@@commands[:logs])
        fail "Please provide an application to log."
      end

      loggregator_client = LoggregatorClient.new(loggregator_host, client.token.auth_header, STDOUT, input[:trace], use_ssl)

      if input[:recent]
        loggregator_client.dump_messages(input[:app])
      else
        loggregator_client.listen(input[:app])
      end
    end

    ::ManifestsPlugin.default_to_app_from_manifest(:logs, false)

    private

    def loggregator_host
      target_base = client.target.sub(/^https?:\/\/([^\.]+\.)?(.+)\/?/, '\2')
      "loggregator.#{target_base}"
    end

    def use_ssl
      client.target.start_with?('https')
    end
  end
end
