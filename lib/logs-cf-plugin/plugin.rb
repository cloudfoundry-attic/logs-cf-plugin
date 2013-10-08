require 'cf'

module LogsCfPlugin
  class Plugin < CF::CLI
    desc "DEPRECATED: Tail or dump logs for CF applications"
    group :apps

    def logs
      puts "This command is deprecated. Please use the new CLI (https://github.com/cloudfoundry/cli)"
      exit 1
    end

    ::ManifestsPlugin.default_to_app_from_manifest(:logs, false)
  end
end
