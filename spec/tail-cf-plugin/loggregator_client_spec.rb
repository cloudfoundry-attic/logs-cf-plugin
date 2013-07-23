require 'support/fake_loggregator'
require 'tail-cf-plugin/plugin'
require 'thin'

describe TailCfPlugin::LoggregatorClient do

  let(:fake_output) { StringIO.new }
  subject(:loggregator_client) { described_class.new(fake_output) }

  it "outputs data from the server" do
    loggregator_port = 9999

    fake_server = TailCfPlugin::FakeLoggregator.new(loggregator_port)
    fake_server.start

    client_thread = Thread.new do
      loggregator_client.listen("http://localhost:#{loggregator_port}", "space_id", "something", "auth_token")
    end

    expect(server_response).to eq("Connected to http://localhost:9999\n1234 5678 STDOUT Hello\n")

    Thread.kill(client_thread)
    fake_server.stop
  end

  it "outputs non-200 erros from the server" do
    loggregator_port = 9999

    fake_server = TailCfPlugin::FakeLoggregator.new(loggregator_port, true)
    fake_server.start

    client_thread = Thread.new do
      loggregator_client.listen("http://localhost:#{loggregator_port}", "space_id", "something", "bad_token")
    end

    expect(server_response).to eq("Connected to http://localhost:9999\nError 401: Unauthorized\n")

  end

  it "constructs a query url with space_id, app_id and uri encoded authorization token" do

    mock_http = double("http").as_null_object
    mock_request = double("request").as_null_object
    Net::HTTP.should_receive(:new).and_return(mock_http)
    Net::HTTP::Get.should_receive(:new).with("/tail/spaces/space_id/apps/app_id?authorization=auth%20token").and_return(mock_request)
    loggregator_client.listen('http://localhost', 'space_id', 'app_id', "auth token")
  end

  it "constructs a query url with space_id and uri encoded authorization token" do
    mock_http = double("http").as_null_object
    mock_request = double("request").as_null_object
    Net::HTTP.should_receive(:new).and_return(mock_http)
    Net::HTTP::Get.should_receive(:new).with("/tail/spaces/space_id?authorization=auth%20token").and_return(mock_request)
    loggregator_client.listen('http://localhost', 'space_id', nil, "auth token")
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
