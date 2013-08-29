require "cf/cli"

module MessageWriter
  include CF::Interactive
  def write(output, message)
    msg = [message.app_id, message.source_type_name, message.source_id, message.message_type_name, message.message].join(" ")
    msg = c(msg, :error) if message.message_type == LogMessage::MessageType::ERR
    output.puts(msg)
  end
end
