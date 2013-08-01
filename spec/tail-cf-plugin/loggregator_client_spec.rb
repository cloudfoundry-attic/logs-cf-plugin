require 'support/fake_loggregator'
require 'tail-cf-plugin/plugin'
require 'thin'

describe TailCfPlugin::LoggregatorClient do

  let(:fake_output) { StringIO.new }
  subject(:loggregator_client) { described_class.new(fake_output) }

  it "outputs data from the server" do
    fake_server = TailCfPlugin::FakeLoggregator.new(4443)
    fake_server.start

    client_thread = Thread.new do
      loggregator_client.listen("localhost", "space_id", "something", "auth_token")
    end

    expect(server_response).to eq("Connected to server.\n1234 5678 STDOUT Hello\n")

    Thread.kill(client_thread)
    fake_server.stop
  end

  it "constructs a query url with space_id, app_id and uri encoded authorization token" do
    EM.stub(:run).and_yield

    mock_ws_server = double("mock_ws_server").as_null_object

    Faye::WebSocket::Client.should_receive(:new).with("wss://host:4443/tail/spaces/space_id/apps/app_id?authorization=auth%20token", nil, anything).and_return(mock_ws_server)
    loggregator_client.listen('host', 'space_id', 'app_id', "auth token")
  end

  it "constructs a query url with space_id and uri encoded authorization token" do
    EM.stub(:run).and_yield

    mock_ws_server = double("mock_ws_server").as_null_object

    Faye::WebSocket::Client.should_receive(:new).with("wss://host:4443/tail/spaces/space_id?authorization=auth%20token", nil, anything).and_return(mock_ws_server)
    loggregator_client.listen('host', 'space_id', nil, "auth token")
  end

  it "sends a keep alive every configured interval" do
    TailCfPlugin::LoggregatorClient.any_instance.stub(:keep_alive_interval).and_return(1)

    fake_server = TailCfPlugin::FakeLoggregator.new(4443)
    fake_server.start

    client_thread = Thread.new do
      loggregator_client.listen("localhost", "space_id", "something", "auth_token")
    end

    sleep 2.5

    expect(fake_server.messages).to eq([[42], [42]])

    Thread.kill(client_thread)
    fake_server.stop

  end

  def server_response
    tries = 0
    loop do
      break if fake_output.string != ''
      tries += 1
      raise 'No output recieved from server' if tries > 50
      sleep(0.2)
    end
    fake_output.string
  end
end
