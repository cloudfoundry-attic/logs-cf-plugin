require 'cf'

module TailCfPlugin
  require 'tail-cf-plugin/loggregator_client'
  require 'log_message/log_message.pb'

  class Plugin < CF::CLI
    include LoginRequirements

    desc "Tail logs for CF applications or spaces"
    group :apps
    input :app, :desc => "App to tail logs from", :argument => :optional, :from_given => by_name(:app)
    input :space, :type => :boolean, :desc => "Logs of all apps in the current space", :default => false

    def tail
      if input[:space]
        app_guid = nil
      else
        unless input[:app]
          Mothership::Help.command_help(@@commands[:tail])
          fail "Please provide an application to log or call with --space"
        end
        app_guid = input[:app].guid
      end

      loggregator_client = LoggregatorClient.new(STDOUT)
      loggregator_client.listen(loggregator_host, client.current_space.guid, app_guid, client.token.auth_header)
      wait_for_ws_connection_close
    end

    ::ManifestsPlugin.default_to_app_from_manifest(:tail, false)

    private

    def loggregator_host
      target_base = client.target.sub(/^https?:\/\/([^\.]+\.)?(.+)\/?/, '\2')
      "loggregator.#{target_base}"
    end

    def wait_for_ws_connection_close
      sleep
    end

  end
end
