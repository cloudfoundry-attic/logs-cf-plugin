require 'support/fake_loggregator'
require 'tail-cf-plugin/plugin'
require 'thin'

describe TailCfPlugin::LoggregatorClient do

  let(:fake_output) { StringIO.new }
  subject(:loggregator_client) { described_class.new(fake_output) }

  it "outputs data from the server" do
    fake_server = TailCfPlugin::FakeLoggregator.new(9001)
    fake_server.start

    client_thread = Thread.new do
      loggregator_client.listen('localhost:9001', "something")
    end

    expect(server_response).to eq("1234 5678 STDOUT Hello\n")

    Thread.kill(client_thread)
    fake_server.stop
  end

  it "requires an application id" do
    EM.stub(:run).and_yield

    mock_ws_server = double("mock_ws_server").as_null_object

    Faye::WebSocket::Client.should_receive(:new).with("ws://host/tail/app_id", nil, anything).and_return(mock_ws_server)
    loggregator_client.listen('host', 'app_id')
  end

  def server_response
    tries = 0
    loop do
      break if fake_output.string != ''
      tries += 1
      raise 'No output recieved from server' if tries > 10
      sleep(0.2)
    end
    fake_output.string
  end
end
