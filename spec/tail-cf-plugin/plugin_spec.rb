require 'tail-cf-plugin/plugin'

describe TailCfPlugin::LoggregatorClient do
  let(:plugin) { TailCfPlugin::Plugin.new }

  it "shows the help and fails if neither app nor space are given" do
    plugin.input = {
        loggregator_host: "host",
    }

    TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:listen)
    Mothership::Help.should_receive(:command_help)
    expect {
      plugin.logs
    }.to raise_exception
  end

  let!(:client_double) {
    double("client",
           token: double("token", {auth_header: "auth_header"}),
           current_space: double("space", guid: 'space_id'),
           target: "http://some_cc.subdomain.cfapp.com"
    )
  }

  let!(:app_double) { double("app", guid: 'app_id') }

  describe "when you are tailing a log" do
    it "calls the loggregator_client with app and space id when tailing for an app" do
      plugin.input = {
          app: app_double,
          space: false,
          recent: false
      }
      plugin.stub(:client).and_return(client_double)

      TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with('space_id', 'app_id')
      plugin.logs
    end

    it "calls the loggregator_client with only space id when tailing for a space" do
      plugin.input = {
          app: app_double,
          space: true,
          recent: false
      }
      plugin.stub(:client).and_return(client_double)

      TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with('space_id', nil)
      plugin.logs
    end
  end

  describe "when you are dumping logs" do
    it "calls the loggregator client for dumping with app and space id" do
      plugin.input = {
          app: app_double,
          space: false,
          recent: true
      }
      plugin.stub(:client).and_return(client_double)

      TailCfPlugin::LoggregatorClient.any_instance.should_receive(:dump).with('space_id', "app_id")
      plugin.logs
    end

    it "calls the loggregator client for dumping with only space id" do
      plugin.input = {
          app: app_double,
          space: true,
          recent: true
      }
      plugin.stub(:client).and_return(client_double)

      TailCfPlugin::LoggregatorClient.any_instance.should_receive(:dump).with('space_id', nil)
      plugin.logs
    end
  end
end
