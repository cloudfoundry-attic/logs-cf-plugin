require "spec_helper"

class TestMessageWriter
  include MessageWriter
end

TEST_TIME = Time.at(1379025677.549451) # Sep 12 16:41:17.549451 -0600

def formatted_test_time
  TEST_TIME.strftime("%b %d %H:%M:%S.%3N")
end

def log_message(type)
  message = LogMessage.new()
  message.message = "Hello"
  message.message_type = type
  message.app_id = "1234"
  message.source_type = 2
  message.source_id = 12
  message.time = TEST_TIME
  message
end

describe MessageWriter do
  let(:app) { double(guid: "app_id", name: "app_name") }
  let (:output) { StringIO.new }
  subject (:test_writer) { TestMessageWriter.new }
  before(:each) {
    $stdout.stub(tty?: true)
  }

  it 'shows the full message' do
    subject.write(app, output, log_message(LogMessage::MessageType::OUT))
    expect(output.string).to eql "#{formatted_test_time} app_name CF[Router/12] STDOUT Hello\n"
  end

  it 'colorizes messages with source of stderr' do
    subject.write(app, output, log_message(LogMessage::MessageType::ERR))
    expect(output.string).to include "\e[35m#{formatted_test_time} app_name CF[Router/12] STDERR Hello\e[0m\n"
  end

  it 'removes trailing newlines from the message' do
    message = log_message(LogMessage::MessageType::ERR)
    message.message = "Hello\n"

    subject.write(app, output, message)
    expect(output.string).to include "\e[35m#{formatted_test_time} app_name CF[Router/12] STDERR Hello\e[0m\n"
  end

  it 'removes trailing newlines from the message' do
    message = log_message(LogMessage::MessageType::ERR)
    message.source_id = nil
    message.message = "Hello\n"

    subject.write(app, output, message)
    expect(output.string).to include "\e[35m#{formatted_test_time} app_name CF[Router] STDERR Hello\e[0m\n"
  end
end
