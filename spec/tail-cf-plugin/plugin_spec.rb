require 'tail-cf-plugin/plugin'

describe TailCfPlugin::LoggregatorClient do
  let(:plugin) { TailCfPlugin::Plugin.new }

  it "should new up a loggregator client correctly" do
    client_double = double("client",
               token: double("token", {auth_header: "auth_header"}),
               current_space: double("space", guid: 'space_id'),
               current_organization: double("org", guid: 'org_id'),
        )

    plugin.input = {}
    #yep. stubbing the object under test. better way to test this appreciated!
    TailCfPlugin::Plugin.any_instance.stub(:client).and_return(client_double)
    TailCfPlugin::Plugin.any_instance.stub(:loggregator_host).and_return("stubbed host")

    mock_log_target = double("logtarget", :valid? => true, :ambiguous? => false, :query_params => {})
    TailCfPlugin::LogTarget.stub(:new).and_return(mock_log_target)

    mock_loggreator_client = double().as_null_object
    TailCfPlugin::LoggregatorClient.should_receive(:new).with("stubbed host", "auth_header", STDOUT).and_return(mock_loggreator_client)

    plugin.logs
  end

  it "shows the help and fails if neither app nor space are given" do
    plugin.input = {
        app: nil,
        space: false,
        org: false,
        recent: false
    }

    TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:listen)
    TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:dump)
    Mothership::Help.should_receive(:command_help)
    expect {
      plugin.logs
    }.to raise_exception
  end

  it "shows the help and fails if the space/org selection is ambiguous" do
    plugin.input = {
        app: nil,
        space: true,
        org: true,
        recent: false
    }

    TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:listen)
    TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:dump)
    Mothership::Help.should_receive(:command_help)
    expect {
      plugin.logs
    }.to raise_exception
  end

  describe "when you are tailing a log" do
    it "calls the loggregator_client the query_params hash from the log_target" do
      plugin.input = {}

      TailCfPlugin::LogTarget.any_instance.stub(:valid?).and_return(true)
      TailCfPlugin::LogTarget.any_instance.stub(:ambiguous?).and_return(false)
      TailCfPlugin::LogTarget.any_instance.stub(:query_params).and_return({some: "hash"})

      TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with({some: "hash"})
      plugin.logs
    end
  end

  describe "when you are dumping a log" do
    it "calls the loggregator_client the query_params hash from the log_target" do
      plugin.input = {recent: true}

      TailCfPlugin::LogTarget.any_instance.stub(:valid?).and_return(true)
      TailCfPlugin::LogTarget.any_instance.stub(:ambiguous?).and_return(false)
      TailCfPlugin::LogTarget.any_instance.stub(:query_params).and_return({some: "hash"})

      TailCfPlugin::LoggregatorClient.any_instance.should_receive(:dump).with({some: "hash"})
      plugin.logs
    end
  end
end
