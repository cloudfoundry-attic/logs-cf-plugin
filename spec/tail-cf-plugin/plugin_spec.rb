require 'tail-cf-plugin/plugin'

describe TailCfPlugin::LoggregatorClient do
  it "calls the loggregator_client correctly" do
    plugin = TailCfPlugin::Plugin.new
    plugin.input = {loggregator_host: "host", app: double("app", guid: 'app_id')}

    TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with('host', 'app_id')
    plugin.tail
  end
end
