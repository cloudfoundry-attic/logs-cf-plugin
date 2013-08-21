require "spec_helper"

class TestMessageWriter
  include MessageWriter
end

def log_message(type = LogMessage::MessageType::OUT)
  message = LogMessage.new()
  message.message = "Hello"
  message.message_type = type
  message.app_id = "1234"
  message.source_id = "5678"
  message
end

describe MessageWriter do
  let (:output) { StringIO.new }
  subject (:test_writer) { TestMessageWriter.new }
  before(:each) {
    $stdout.stub(tty?: true)
  }

  it 'colorizes messages with source of stderr' do
    subject.write(output, log_message(LogMessage::MessageType::ERR))
    expect(output.string).to include "\e[35m1234 5678 STDERR Hello\e[0m\n"
  end

  it 'does not colorize message with source of stdout' do
    subject.write(output, log_message(LogMessage::MessageType::OUT))
    expect(output.string).to include "1234 5678 STDOUT Hello\n"
  end
end