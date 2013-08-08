require 'cf'

module TailCfPlugin
  require 'tail-cf-plugin/loggregator_client'

  class Plugin < CF::CLI
    include LoginRequirements

    desc "Tail or dump logs for CF applications or spaces"
    group :apps
    input :app, :desc => "App to tail logs from", :argument => :optional, :from_given => by_name(:app)
    input :space, :type => :boolean, :desc => "Logs of all apps in the current space", :default => false
    input :recent, :type => :boolean, :desc => "Dump recent logs instead of tailing", :default => false

    def logs
      unless input[:space] || input[:app]
        Mothership::Help.command_help(@@commands[:logs])
        fail "Please provide an application to log or call with --space"
      end

      loggregator_client = LoggregatorClient.new(loggregator_host, STDOUT, client.token.auth_header)

      app_guid = !input[:space] ? input[:app].guid : nil

      if input[:recent]
        loggregator_client.dump(client.current_space.guid, app_guid)
      else
        loggregator_client.listen(client.current_space.guid, app_guid)
      end
    end

    ::ManifestsPlugin.default_to_app_from_manifest(:logs, false)

    private

    def loggregator_host
      target_base = client.target.sub(/^https?:\/\/([^\.]+\.)?(.+)\/?/, '\2')
      "loggregator.#{target_base}"
    end
  end
end
