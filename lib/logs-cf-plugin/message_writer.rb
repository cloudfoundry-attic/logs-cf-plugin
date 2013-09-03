require "cf/cli"

module MessageWriter
  include CF::Interactive
  def write(log_target, output, message)
    msg = [log_target.app_name, message.source_type_name, message.source_id, message.message_type_name, message.message].join(" ")
    msg = c(msg.chomp, :error) if message.message_type == LogMessage::MessageType::ERR
    output.puts(msg)
  end
end
