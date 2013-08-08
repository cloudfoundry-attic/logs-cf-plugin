require 'cf'

module TailCfPlugin
  require 'tail-cf-plugin/loggregator_client'
  require 'tail-cf-plugin/log_target'

  class Plugin < CF::CLI
    include LoginRequirements

    desc "Tail or dump logs for CF applications or spaces"
    group :apps
    input :app, :desc => "App to tail logs from", :argument => :optional, :from_given => by_name(:app)
    input :space, :type => :boolean, :desc => "Logs of all apps in the current space", :default => false
    input :org, :type => :boolean, :desc => "Logs of all apps and spaces in the current organization", :default => false
    input :recent, :type => :boolean, :desc => "Dump recent logs instead of tailing", :default => false

    def logs
      guids = [client.current_organization.guid, client.current_space.guid, input[:app].try(:guid)]

      log_target = LogTarget.new(input[:org], input[:space], guids)

      if log_target.ambiguous?
        Mothership::Help.command_help(@@commands[:logs])
        fail "Please provide either --space or --org, but not both."
      end

      unless log_target.valid?
        Mothership::Help.command_help(@@commands[:logs])
        fail "Please provide an application to log."
      end

      loggregator_client = LoggregatorClient.new(loggregator_host, client.token.auth_header, STDOUT)

      if input[:recent]
        loggregator_client.dump(log_target.query_params)
      else
        loggregator_client.listen(log_target.query_params)
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
