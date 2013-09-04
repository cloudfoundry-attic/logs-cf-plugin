require "spec_helper"

describe LogsCfPlugin::TailingLogsClient do

  let(:fake_output) { StringIO.new }

  before(:all) do
    @fake_server = LogsCfPlugin::FakeLoggregator.start_websocket_app(4443)
  end

  before(:each) do
    $stdout.stub(tty?: true)
    @fake_server.close_code = nil
  end

  after(:all) do
    @fake_server.stop
  end

  let(:app) { double(guid: "app_id", name: "app_name") }

  describe "listening to logs" do
    def server_response
      tries = 0
      loop do
        break if fake_output.string != ''
        tries += 1
        raise 'No output received from server' if tries > 50
        sleep(0.2)
      end
      fake_output.string
    end

    let(:client) { described_class.new(LogsCfPlugin::ClientConfig.new("localhost", "auth_token", fake_output, false)) }

    it "outputs data from the server's stdout without color" do
      client_thread = Thread.new do
        client.logs_for(app)
      end

      expect(server_response).to eq("Connected to server.\napp_name CF[DEA] 5678 STDOUT Hello\n")

      Thread.kill(client_thread)
    end

    it "outputs data from the server's stderr without color" do
      app.stub(:guid).and_return("stderr")
      client_thread = Thread.new do
        client.logs_for(app)
      end

      expect(server_response).to eq("Connected to server.\n\e[35mapp_name CF[DEA] 5678 STDERR Hello\e[0m\n")

      Thread.kill(client_thread)
    end

    describe "with tracing" do
      let(:client) { described_class.new(LogsCfPlugin::ClientConfig.new("localhost", "auth_token", fake_output, true)) }

      it "outputs data from the server" do
        client_thread = Thread.new do
          client.logs_for(app)
        end

        expect(server_response).to eq("websocket_address: wss://localhost:4443/tail/?app=app_id\nConnected to server.\napp_name CF[DEA] 5678 STDOUT Hello\n")

        Thread.kill(client_thread)
      end
    end

    describe "the websocket request" do
      let(:mock_ws_server) { double("mock_ws_server").as_null_object }

      before do
        EM.stub(:run).and_yield
      end

      it "constructs a query url using the given app" do
        Faye::WebSocket::Client.should_receive(:new).with("wss://localhost:4443/tail/?app=app_id", nil, anything).and_return(mock_ws_server)
        client.logs_for(app)
      end

      it "sends the authorization token as a header" do
        headers = {"Origin" => "http://localhost", "Authorization" => "auth_token"}
        Faye::WebSocket::Client.should_receive(:new).with(anything, nil, :headers => headers).and_return(mock_ws_server)
        client.logs_for(app)
      end
    end

    it "sends a keep alive every configured interval" do
      LogsCfPlugin::TailingLogsClient.any_instance.stub(:keep_alive_interval).and_return(1)

      client_thread = Thread.new do
        client.logs_for(app)
      end

      sleep 2.5

      expect(@fake_server.messages).to eq([[42], [42]])

      Thread.kill(client_thread)
    end

    describe "upgrade info" do
      before do
        app.stub(:guid).and_return("bad_app_id")
      end

      after do
        @fake_server.stop
        @fake_server = LogsCfPlugin::FakeLoggregator.start_websocket_app(4443)
      end

      it "encourages user to upgrade" do
        client_thread = Thread.new do
          client.logs_for(app)
        end

        sleep 2.5

        expect(fake_output.string).to include("Error parsing data. Please ensure your gem is the latest version.")

        Thread.kill(client_thread)
      end
    end

    describe "websocket connection closed" do
      it "outputs error when no auth token given" do
        client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", "", fake_output, false))
        client_thread = Thread.new do
          client.logs_for(app)
        end

        EM.should_receive(:stop).once
        expect(server_response).to match /Error: No authorization token given\./

        Thread.kill(client_thread)
      end

      it "outputs error when server returns 'unauthorized' code" do
        client = described_class.new(LogsCfPlugin::ClientConfig.new("localhost", "I am unauthorized", fake_output, false))
        client_thread = Thread.new do
          client.logs_for(app)
        end

        EM.should_receive(:stop).once
        expect(server_response).to match /Error: Not authorized\./

        Thread.kill(client_thread)
      end

    end
  end

  describe "connect sever without ssl enabled" do
    # Only check the uri since we already check the protocol for ssl scenario
    let(:client) { described_class.new(LogsCfPlugin::ClientConfig.new("localhost", "auth_token", fake_output, false, false)) }

    it "connect websocket using ws and 80 port" do
      exp_headers = {"Origin" => "http://localhost", "Authorization" => "auth_token"}
      exp_uri = 'ws://localhost/tail/?app=app_id'

      Faye::WebSocket::Client.should_receive(:new).with(exp_uri, nil, :headers => exp_headers).and_return(Faye::WebSocket::Client)
      Faye::WebSocket::Client.stub(:on) {}
      client.logs_for(app)
    end
  end
end
