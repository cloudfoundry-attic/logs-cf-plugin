require 'tail-cf-plugin/plugin'

describe TailCfPlugin::LoggregatorClient do
  before do
    TailCfPlugin::Plugin.any_instance.stub(:wait_for_ws_connection_close)
  end

  it "shows the help and fails if neither app nor space are given" do
    plugin = TailCfPlugin::Plugin.new
    plugin.input = {
        loggregator_host: "host",
        space: false
    }

    TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:listen)
    Mothership::Help.should_receive(:command_help)
    expect {
      plugin.tail
    }.to raise_exception
  end

  it "calls the loggregator_client for logging from an app" do
    plugin = TailCfPlugin::Plugin.new
    plugin.input = {
        app: double("app", guid: 'app_id'),
        space: false
    }
    plugin.stub(:client).and_return(double("client",
                                           token: double("token", {auth_header: "auth_header"}),
                                           current_space: double("space", guid: 'space_id'),
                                           target: "http://some_cc.subdomain.cfapp.com"
                                    ))

    TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).
        with('loggregator.subdomain.cfapp.com', 'space_id', 'app_id', "auth_header")
    plugin.tail
  end

  it "calls the loggregator_client for logging from the current space" do
    plugin = TailCfPlugin::Plugin.new
    plugin.input = {
        loggregator_host: "host",
        app: double("app", guid: 'app_id'),
        space: true
    }
    plugin.stub(:client).and_return(double("client",
                                           token: double("token", {auth_header: "auth_header"}),
                                           current_space: double("space", guid: 'space_id'),
                                           target: "http://some_cc.subdomain.cfapp.com"
                                    ))

    TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).
        with('loggregator.subdomain.cfapp.com', 'space_id', nil, "auth_header")
    plugin.tail
  end
end
