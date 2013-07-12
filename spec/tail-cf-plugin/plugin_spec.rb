require 'tail-cf-plugin/plugin'

describe TailCfPlugin::LoggregatorClient do
  it "calls the loggregator_client correctly given an app" do
    plugin = TailCfPlugin::Plugin.new
    plugin.input = {loggregator_host: "host", app: double("app", guid: 'app_id', space_guid: 'space_id')}
    plugin.stub(:client).and_return(double("client", token: double("token", {auth_header: "auth_header"})))

    TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with('host', 'space_id', 'app_id', "auth_header")
    plugin.tail
  end

  it "calls the loggregator_client correctly given a space" do
    plugin = TailCfPlugin::Plugin.new
    plugin.input = {loggregator_host: "host", space: double("space", guid: 'space_id')}
    plugin.stub(:client).and_return(double("client", token: double("token", {auth_header: "auth_header"})))

    TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with('host', 'space_id', nil, "auth_header")
    plugin.tail
  end
end
