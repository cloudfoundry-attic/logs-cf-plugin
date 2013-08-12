require 'tail-cf-plugin/plugin'

describe TailCfPlugin::LoggregatorClient do
  let(:plugin) { TailCfPlugin::Plugin.new }

  def stub_plugin_client_to_prevent_test_failure_on_travis
    #even if not directly used in the tests below, client needs to be stubbed for all tests!
    #If removed, locally these tests might still pass, if ~/.cf is present. It will, however, fail on travis

    client_double = double("client",
                           token: double("token", {auth_header: "auth_header"}),
                           current_space: double("space", guid: 'space_id'),
                           current_organization: double("org", guid: 'org_id'),
    )

    plugin.input = { trace: false}
    #yep. stubbing the object under test. better way to test this appreciated!
    TailCfPlugin::Plugin.any_instance.stub(:client).and_return(client_double)
    TailCfPlugin::Plugin.any_instance.stub(:loggregator_host).and_return("stubbed host")
  end

  before do
    stub_plugin_client_to_prevent_test_failure_on_travis
  end

  it "should new up a loggregator client correctly" do
    mock_log_target = double("logtarget", :valid? => true, :ambiguous? => false, :query_params => {})
    TailCfPlugin::LogTarget.stub(:new).and_return(mock_log_target)

    mock_loggreator_client = double().as_null_object
    TailCfPlugin::LoggregatorClient.should_receive(:new).with("stubbed host", "auth_header", STDOUT, false).and_return(mock_loggreator_client)

    plugin.logs
  end

  describe "failure cases" do
    before do
      TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:listen)
      TailCfPlugin::LoggregatorClient.any_instance.should_not_receive(:dump_messages)
    end

    it "shows the help and fails if neither app nor space are given" do
      plugin.input = {
          app: nil,
          space: false,
          org: false,
          recent: false
      }

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

      Mothership::Help.should_receive(:command_help)
      expect {
        plugin.logs
      }.to raise_exception
    end
  end

  describe "success cases" do
    before do
      TailCfPlugin::LogTarget.any_instance.stub(:valid?).and_return(true)
      TailCfPlugin::LogTarget.any_instance.stub(:ambiguous?).and_return(false)
      TailCfPlugin::LogTarget.any_instance.stub(:query_params).and_return({some: "hash"})
    end

    describe "when you are tailing a log" do
      it "calls the loggregator_client the query_params hash from the log_target" do
        plugin.input = {}
        TailCfPlugin::LoggregatorClient.any_instance.should_receive(:listen).with({some: "hash"})
        plugin.logs
      end
    end

    describe "when you are dumping a log" do
      it "calls the loggregator_client the query_params hash from the log_target" do
        plugin.input = {recent: true}
        TailCfPlugin::LoggregatorClient.any_instance.should_receive(:dump_messages).with({some: "hash"}).and_return([])
        plugin.logs
      end
    end
  end
end
