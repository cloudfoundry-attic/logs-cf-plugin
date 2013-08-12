module MessageWriter
  def self.write(output, message)
    output.puts([message.app_id, message.source_id, message.message_type_name, message.message].join(" "))
  end
end