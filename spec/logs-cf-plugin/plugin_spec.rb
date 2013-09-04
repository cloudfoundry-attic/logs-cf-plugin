require "spec_helper"

describe LogsCfPlugin::Plugin do
  let(:plugin) { LogsCfPlugin::Plugin.new }

  def stub_plugin_client_to_prevent_test_failure_on_travis(use_ssl = true)
    #even if not directly used in the tests below, client needs to be stubbed for all tests!
    #If removed, locally these tests might still pass, if ~/.cf is present. It will, however, fail on travis

    target_uri = use_ssl ? 'https' : 'http'

    client_double = double('client',
                           token: double('token', {auth_header: 'auth_header'}),
                           current_space: double('space', guid: 'space_id'),
                           current_organization: double('org', guid: 'org_id', name: 'org'),
                           target: "#{target_uri}://test.io"
    )

    plugin.input = {trace: false,
                    app: double(name: 'app', guid: 'app_id')}

    #yep. stubbing the object under test. better way to test this appreciated!
    LogsCfPlugin::Plugin.any_instance.stub(:client).and_return(client_double)
    LogsCfPlugin::Plugin.any_instance.stub(:loggregator_host).and_return("stubbed host")
  end

  before do
    stub_plugin_client_to_prevent_test_failure_on_travis
  end

  it "should new up a loggregator client correctly" do
    config = double("config")
    mock_loggreator_client = double().as_null_object

    LogsCfPlugin::ClientConfig.should_receive(:new).with("stubbed host", "auth_header", STDOUT, false, true).and_return(config)
    LogsCfPlugin::TailingLogsClient.should_receive(:new).with(config).and_return(mock_loggreator_client)

    plugin.logs
  end

  it "should new up a loggregator client when no ssl target given" do
    stub_plugin_client_to_prevent_test_failure_on_travis(false)
    LogsCfPlugin::TailingLogsClient.any_instance.stub(:logs_for)

    LogsCfPlugin::ClientConfig.should_receive(:new).with("stubbed host", "auth_header", STDOUT, false, false)

    plugin.logs
  end

  describe "failure cases" do
    before do
      LogsCfPlugin::TailingLogsClient.any_instance.should_not_receive(:logs_for)
      LogsCfPlugin::RecentLogsClient.any_instance.should_not_receive(:logs_for)
    end

    it "shows the help and fails if app not given" do
      plugin.input = {
        app: nil,
        recent: false
      }

      Mothership::Help.should_receive(:command_help)
      expect {
        plugin.logs
      }.to raise_exception
    end
  end

  describe "success cases" do
    describe "when you are tailing a log" do
      it "calls the TailingLogsClient with the app" do
        LogsCfPlugin::TailingLogsClient.any_instance.should_receive(:logs_for).with(plugin.input[:app])
        plugin.logs
      end
    end

    describe "when you are dumping a log" do
      it "calls the loggregator_client with the app" do
        plugin.input.merge!(recent: true)
        LogsCfPlugin::RecentLogsClient.any_instance.should_receive(:logs_for).with(plugin.input[:app])
        plugin.logs
      end
    end
  end
end
