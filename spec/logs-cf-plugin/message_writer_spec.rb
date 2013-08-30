require "spec_helper"

class TestMessageWriter
  include MessageWriter
end

def log_message(type)
  message = LogMessage.new()
  message.message = "Hello"
  message.message_type = type
  message.app_id = "1234"
  message.source_type = 2
  message.source_id = 12
  message
end

describe MessageWriter do
  let(:log_target) { LogsCfPlugin::LogTarget.new(double(guid: "app_id", name: "app_name"))}
  let (:output) { StringIO.new }
  subject (:test_writer) { TestMessageWriter.new }
  before(:each) {
    $stdout.stub(tty?: true)
  }

  it 'shows the full message' do
    subject.write(log_target, output, log_message(LogMessage::MessageType::OUT))
    expect(output.string).to eql "app_name CF[Router] 12 STDOUT Hello\n"
  end

  it 'colorizes messages with source of stderr' do
    subject.write(log_target, output, log_message(LogMessage::MessageType::ERR))
    expect(output.string).to include "\e[35mapp_name CF[Router] 12 STDERR Hello\e[0m\n"
  end
end
