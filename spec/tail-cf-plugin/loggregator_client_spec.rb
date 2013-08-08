require 'support/fake_loggregator'
require 'tail-cf-plugin/plugin'
require 'thin'

describe TailCfPlugin::LoggregatorClient do

  let(:fake_output) { StringIO.new }

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

    let(:loggregator_client) { described_class.new("localhost", "auth_token", fake_output) }

    it "outputs data from the server" do
      fake_server = TailCfPlugin::FakeLoggregator.new(4443)
      fake_server.startListenEndpoint

      client_thread = Thread.new do
        loggregator_client.listen({org: "org_id", space: "space_id", app: "app_id"})
      end

      expect(server_response).to eq("Connected to server.\n1234 5678 STDOUT Hello\n")

      Thread.kill(client_thread)
      fake_server.stop
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
      TailCfPlugin::LoggregatorClient.any_instance.stub(:keep_alive_interval).and_return(1)

      fake_server = TailCfPlugin::FakeLoggregator.new(4443)
      fake_server.startListenEndpoint

      client_thread = Thread.new do
        loggregator_client.listen({org: "org_id", space: "space_id", app: "app_id"})
      end

      sleep 2.5

      expect(fake_server.messages).to eq([[42], [42]])

      Thread.kill(client_thread)
      fake_server.stop
    end
  end

  describe "dumping logs" do
    subject(:loggregator_client) { described_class.new("localhost:8000", "auth_token", fake_output) }

    it "outputs the logs from the server" do
      fake_server = TailCfPlugin::FakeLoggregator.new(8000)
      fake_server.startDumpEndpoint

      output = loggregator_client.dump({org: "org_id", space: "space_id", app: "app_id"})

      expect(output).to eq "6bd8483a-7f7f-4e11-800a-4369501752c3  STDOUT Hello on STDOUT"
      fake_server.stop
    end
  end
end
