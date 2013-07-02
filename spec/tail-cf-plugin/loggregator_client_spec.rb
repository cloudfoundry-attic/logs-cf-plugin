require 'support/fake_loggregator'
require 'tail-cf-plugin/loggregrator_client'
require 'thin'

describe TailCfPlugin::LoggregatorClient do

  let(:fake_output) { StringIO.new }
  subject(:loggregator_client) { described_class.new(fake_output) }

  it "outputs data from the server" do
    fake_server = TailCfPlugin::FakeLoggregator.new(9001)
    fake_server.start

    client_thread = Thread.new do
      loggregator_client.listen('localhost:9001')
    end

    expect(server_response).to eq("Hello\n")

    Thread.kill(client_thread)
    fake_server.stop
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
