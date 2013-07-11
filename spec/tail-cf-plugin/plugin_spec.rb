require 'tail-cf-plugin/plugin'

describe TailCfPlugin::LoggregatorClient do
  it "calls the loggregator_client correctly" do
    plugin = TailCfPlugin::Plugin.new
    plugin.input = {loggregator_host: "host", app: double("app", guid: 'app_id')}
    plugin.stub(:client).and_return(double("client", token: double("token", {auth_header: "auth_header"})))

    TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with('host', 'app_id', "auth_header")
    plugin.tail
  end
end
