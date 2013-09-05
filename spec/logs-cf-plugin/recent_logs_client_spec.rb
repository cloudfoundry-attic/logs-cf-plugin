require "spec_helper"

describe LogsCfPlugin::RecentLogsClient do

  let(:fake_output) { StringIO.new }

  before(:all) do
    @fake_server = LogsCfPlugin::FakeLoggregator.start_dump_app(8000)
  end

  before(:each) do
    $stdout.stub(tty?: true)
    @fake_server.close_code = nil
  end

  after(:all) do
    @fake_server.stop
  end

  let(:app) { double(guid: "app_id", name: "app_name") }

  describe "dumping logs" do
    it "outputs the messages from the server" do
      loggregator_client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", 8000, "auth_token", fake_output, false))
      loggregator_client.logs_for(app)

      output = fake_output.string.split("\n")

      expect(output[0]).to eq "app_name CF[DEA]  STDOUT Some data"
      expect(output[1]).to eq "app_name CF[DEA]  STDOUT More stuff"
    end

    it "colors the stderr messages" do
      loggregator_client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", 8000, "auth_token", fake_output, false))
      app.stub(:guid).and_return("stderr")
      loggregator_client.logs_for(app)

      output = fake_output.string.split("\n")

      expect(output[0]).to eq "\e[35mapp_name CF[DEA]  STDERR Some data\e[0m"
      expect(output[1]).to eq "\e[35mapp_name CF[DEA]  STDERR More stuff\e[0m"
    end

    it "outputs message the auth code is invalid" do
      loggregator_client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", 8000, "bad_auth_token", fake_output, false))
      loggregator_client.logs_for(app)

      expect(fake_output.string).to eq "Unauthorized\n"
    end

    it "outputs message if the app is not found" do
      loggregator_client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", 8000, "auth_token", fake_output, false))
      app.stub(:guid).and_return("unknown")
      loggregator_client.logs_for(app)

      expect(fake_output.string).to eq "App #{app.name} not found\n"
    end

    describe "redirects" do
      before do
        @server = LogsCfPlugin::FakeLoggregator.new
        redirector = proc do |env|
          [302, {'Content-Type' => 'text','Location' => "http://localhost:8000#{env['REQUEST_URI']}"}, ['302 found'] ]
        end
        @server.runApp(redirector, 8001)
      end

      after do
        @server.stop
      end

      it "follows redirects until it gets a 200" do
        loggregator_client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", 8001, "auth_token", fake_output, false))
        loggregator_client.logs_for(app)

        output = fake_output.string.split("\n")

        expect(output[0]).to eq "app_name CF[DEA]  STDOUT Some data"
        expect(output[1]).to eq "app_name CF[DEA]  STDOUT More stuff"
      end
    end

    describe "with tracing" do

      let(:loggregator_client) { described_class.new(LogsCfPlugin::ClientConfig.new("localhost", 8000, "auth_token", fake_output, true)) }

      it "returns the messages from the server" do
        loggregator_client.logs_for(app)

        expect(fake_output.string).to include "REQUEST: GET https://localhost:8000/dump/?app=app_id"
        expect(fake_output.string).to include "RESPONSE: [200]"
        expect(fake_output.string).to include "RESPONSE_BODY:"
      end
    end
    it "encourages the user to upgrade" do
      app.stub(:guid).and_return("bad_app_id")
      loggregator_client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", 8000, "auth_token", fake_output, false))
      loggregator_client.logs_for(app)

      sleep 2.5

      expect(fake_output.string).to include("Error parsing data. Please ensure your gem is the latest version.")
    end
  end

  describe "connect sever without ssl enabled" do
    # Only check the uri since we already check the protocol for ssl scenario
    let(:loggregator_client) { described_class.new(LogsCfPlugin::ClientConfig.new("localhost", nil, "auth_token", fake_output, false, false)) }

    it "dump messages via http 80 port" do
      Net::HTTP.should_receive(:new).with('localhost', 80).and_return(Net::HTTP)
      Net::HTTP.should_receive(:use_ssl=).with(false)
      Net::HTTP.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      Net::HTTP.should_receive(:request).and_return(Net::HTTPResponse)
      Net::HTTPResponse.should_receive(:code).and_return("401")
      loggregator_client.logs_for(app)
    end
  end
end
