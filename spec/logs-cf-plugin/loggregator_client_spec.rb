require 'support/fake_loggregator'
require 'logs-cf-plugin/plugin'
require 'thin'

describe LogsCfPlugin::LoggregatorClient do

  let(:fake_output) { StringIO.new }

  before(:all) do
    @fake_server = LogsCfPlugin::FakeLoggregator.new(4443, 8000)
    @fake_server.start
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

    it "outputs data from the server" do
      client_thread = Thread.new do
        loggregator_client.listen({org: "org_id", space: "space_id", app: "app_id"})
      end

      expect(server_response).to eq("Connected to server.\n1234 5678 STDOUT Hello\n")

      Thread.kill(client_thread)
    end

    describe "with tracing" do
      let(:loggregator_client) { described_class.new("localhost", "auth_token", fake_output, true) }

      it "outputs data from the server" do
        client_thread = Thread.new do
          loggregator_client.listen({org: "org_id", space: "space_id", app: "app_id"})
        end

        expect(server_response).to eq("websocket_address: wss://localhost:4443/tail/?org=org_id&space=space_id&app=app_id\nConnected to server.\n1234 5678 STDOUT Hello\n")

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
        loggregator_client.listen({org: "org_id", space: "space_id", app: "app_id"})
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
          loggregator_client.listen({org: "org_id", space: "space_id", app: "bad_app_id"})
        end

        sleep 2.5

        expect(fake_output.string).to include("Error parsing data. Please ensure your gem is the latest version.")

        Thread.kill(client_thread)
      end
    end
  end

  describe "dumping logs" do
    it "returns the messages from the server" do
      loggregator_client = described_class.new("localhost:8000", "auth_token", fake_output, false)
      output = loggregator_client.dump_messages({org: "org_id", space: "space_id", app: "app_id"})

      expect(output.length).to eq 2

      expect(output[0].message).to eq "Some data"
      expect(output[1].message).to eq "More stuff"
    end

    it "returns an empty array when the auth code is invalid" do
      loggregator_client = described_class.new("localhost:8000", "bad_auth_token", fake_output, false)
      output = loggregator_client.dump_messages({org: "org_id", space: "space_id", app: "app_id"})

      expect(output.length).to eq 0
    end

    describe "with tracing" do

      let(:loggregator_client) { described_class.new("localhost:8000", "auth_token", fake_output, true) }

      it "returns the messages from the server" do

        output = loggregator_client.dump_messages({org: "org_id", space: "space_id", app: "app_id"})

        expect(output.length).to eq 2

        expect(fake_output.string).to include "REQUEST: GET /dump/?org=org_id&space=space_id&app=app_id"
        expect(fake_output.string).to include "RESPONSE: [200]"
        expect(fake_output.string).to include "RESPONSE_BODY:"
      end
    end
    it "encourages the user to upgrade" do
      loggregator_client = described_class.new("localhost:8000", "auth_token", fake_output, false)
      output = loggregator_client.dump_messages({org: "org_id", space: "space_id", app: "bad_app_id"})

      sleep 2.5

      expect(fake_output.string).to include("Error parsing data. Please ensure your gem is the latest version.")
      expect(output).to eq []

    end

  end
end
