require "cf/cli"

module MessageWriter
  include CF::Interactive

  def write(app, output, message)
    msg = [format_time(message.timestamp), app.name, message.source_type_name, message.source_id, message.message_type_name, message.message].join(" ")
    msg = c(msg.chomp, :error) if message.message_type == LogMessage::MessageType::ERR
    output.puts(msg)
  end

  def format_time(timestamp_nsec)
    Time.at(timestamp_nsec/1000000000.0).strftime("%b %d %H:%M:%S.%3N")
  end
end
