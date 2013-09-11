require "cf/cli"

module MessageWriter
  include CF::Interactive

  def write(app, output, message)
    msg = [format_time(message.timestamp), app.name, message.source_type_name, message.source_id, message.message_type_name, message.message].join(" ")
    msg = c(msg.chomp, :error) if message.message_type == LogMessage::MessageType::ERR
    output.puts(msg)
  end

  def format_time(timestamp)
    Time.at(timestamp).strftime("%b %d %H:%M:%S")
  end
end
