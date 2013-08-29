require "spec_helper"

describe LogsCfPlugin::LoggregatorClient do

  let(:fake_output) { StringIO.new }

  before(:all) do
    @fake_server = LogsCfPlugin::FakeLoggregator.new(4443, 8000)
    @fake_server.start
  end

  before(:each) do
    $stdout.stub(tty?: true)
    @fake_server.close_code = nil
  end

  after(:all) do
    @fake_server.stop
  end

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

    let(:loggregator_client) { described_class.new("localhost", "auth_token", fake_output, false) }

    it "outputs data from the server's stdout without color" do
      client_thread = Thread.new do
        loggregator_client.listen({app: "app_id"})
      end

      expect(server_response).to eq("Connected to server.\n1234 CF[DEA] 5678 STDOUT Hello\n")

      Thread.kill(client_thread)
    end

    it "outputs data from the server's stderr without color" do
      client_thread = Thread.new do
        loggregator_client.listen({org: "org_id", space: "space_id", app: "stderr"})
      end

      expect(server_response).to eq("Connected to server.\n\e[35m1234 CF[DEA] 5678 STDERR Hello\e[0m\n")

      Thread.kill(client_thread)
    end

    describe "with tracing" do
      let(:loggregator_client) { described_class.new("localhost", "auth_token", fake_output, true) }

      it "outputs data from the server" do
        client_thread = Thread.new do
          loggregator_client.listen({app: "app_id"})
        end

        expect(server_response).to eq("websocket_address: wss://localhost:4443/tail/?app=app_id\nConnected to server.\n1234 CF[DEA] 5678 STDOUT Hello\n")

        Thread.kill(client_thread)
      end
    end

    describe "the websocket request" do
      let(:mock_ws_server) { double("mock_ws_server").as_null_object }

      before do
        EM.stub(:run).and_yield
      end

      it "constructs a query url using the given params hash" do
        Faye::WebSocket::Client.should_receive(:new).with("wss://localhost:4443/tail/?some=query_params&other=value", nil, anything).and_return(mock_ws_server)
        loggregator_client.listen(some: 'query_params', other: 'value')
      end

      it "sends the authorization token as a header" do
        headers = {"Origin" => "http://localhost", "Authorization" => "auth_token"}
        Faye::WebSocket::Client.should_receive(:new).with(anything, nil, :headers => headers).and_return(mock_ws_server)
        loggregator_client.listen({})
      end
    end

    it "sends a keep alive every configured interval" do
      LogsCfPlugin::LoggregatorClient.any_instance.stub(:keep_alive_interval).and_return(1)

      client_thread = Thread.new do
        loggregator_client.listen({app: "app_id"})
      end

      sleep 2.5

      expect(@fake_server.messages).to eq([[42], [42]])

      Thread.kill(client_thread)
    end

    describe "upgrade info" do
      after do
        @fake_server.stop

        @fake_server = LogsCfPlugin::FakeLoggregator.new(4443, 8000)
        @fake_server.start
      end

      it "encourages user to upgrade" do
        client_thread = Thread.new do
          loggregator_client.listen({app: "bad_app_id"})
        end

        sleep 2.5

        expect(fake_output.string).to include("Error parsing data. Please ensure your gem is the latest version.")

        Thread.kill(client_thread)
      end
    end

    describe "websocket connection closed" do
      it "outputs error when no auth token given" do
        loggregator_client = described_class.new("localhost", "", fake_output, false)
        client_thread = Thread.new do
          loggregator_client.listen({app: "app_id"})
        end

        EM.should_receive(:stop).once
        expect(server_response).to match /Error: No authorization token given\./

        Thread.kill(client_thread)
      end

      it "outputs error when server returns 'unauthorized' code" do
        loggregator_client = described_class.new("localhost", "I am unauthorized", fake_output, false)
        client_thread = Thread.new do
          loggregator_client.listen({app: "app_id"})
        end

        EM.should_receive(:stop).once
        expect(server_response).to match /Error: Not authorized\./

        Thread.kill(client_thread)
      end

    end
  end

  describe "dumping logs" do
    it "outputs the messages from the server" do
      loggregator_client = described_class.new("localhost:8000", "auth_token", fake_output, false)
      loggregator_client.dump_messages({app: "app_id"})

      output = fake_output.string.split("\n")

      expect(output[0]).to eq "myApp CF[DEA]  STDOUT Some data"
      expect(output[1]).to eq "myApp CF[DEA]  STDOUT More stuff"
    end

    it "colors the stderr messages" do
      loggregator_client = described_class.new("localhost:8000", "auth_token", fake_output, false)
      loggregator_client.dump_messages({app: "stderr"})

      output = fake_output.string.split("\n")

      expect(output[0]).to eq "\e[35mmyApp CF[DEA]  STDERR Some data\e[0m"
      expect(output[1]).to eq "\e[35mmyApp CF[DEA]  STDERR More stuff\e[0m"
    end

    it "outputs nothing the auth code is invalid" do
      loggregator_client = described_class.new("localhost:8000", "bad_auth_token", fake_output, false)
      loggregator_client.dump_messages({app: "app_id"})

      expect(fake_output.string).to eq ""
    end

    describe "with tracing" do

      let(:loggregator_client) { described_class.new("localhost:8000", "auth_token", fake_output, true) }

      it "returns the messages from the server" do
        loggregator_client.dump_messages({app: "app_id"})

        expect(fake_output.string).to include "REQUEST: GET /dump/?app=app_id"
        expect(fake_output.string).to include "RESPONSE: [200]"
        expect(fake_output.string).to include "RESPONSE_BODY:"
      end
    end
    it "encourages the user to upgrade" do
      loggregator_client = described_class.new("localhost:8000", "auth_token", fake_output, false)
      output = loggregator_client.dump_messages({app: "bad_app_id"})

      sleep 2.5

      expect(fake_output.string).to include("Error parsing data. Please ensure your gem is the latest version.")
      expect(output).to eq []
    end

  end

  describe "connect sever without ssl enabled" do
    # Only check the uri since we already check the protocol for ssl scenario
    let(:loggregator_client) { described_class.new("localhost", "auth_token", fake_output, false, false) }

    it "connect websocket using ws and 80 port" do
      exp_headers = { "Origin"=>"http://localhost", "Authorization"=>"auth_token" }
      exp_uri =  'ws://localhost/tail/?app=app_id'

      Faye::WebSocket::Client.should_receive(:new).with(exp_uri, nil, :headers=> exp_headers).and_return(Faye::WebSocket::Client)
      Faye::WebSocket::Client.stub(:on) {}
      loggregator_client.listen({app: "app_id"})
    end

    it "dump messages via http 80 port" do
      Net::HTTP.should_receive(:new).with('localhost', 80).and_return(Net::HTTP)
      Net::HTTP.should_receive(:use_ssl=).with(false)
      Net::HTTP.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      Net::HTTP.should_receive(:request).and_return(Net::HTTPResponse)
      Net::HTTPResponse.should_receive(:code).and_return(200)
      loggregator_client.dump_messages({app: "app_id"})
    end

  end

end
