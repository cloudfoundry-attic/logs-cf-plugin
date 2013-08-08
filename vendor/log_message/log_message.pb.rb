## Generated from log_message.proto for logMessage
require "beefcake"


class LogMessage
  include Beefcake::Message

  module MessageType
    OUT = 1
    ERR = 2
  end
  module SourceType
    CLOUD_CONTROLLER = 1
    ROUTER = 2
    UAA = 3
    DEA = 4
    WARDEN_CONTAINER = 5
  end

  required :message, :bytes, 1
  required :message_type, LogMessage::MessageType, 2
  required :timestamp, :sint64, 3
  required :app_id, :string, 4
  required :source_type, LogMessage::SourceType, 5
  optional :source_id, :string, 6
  optional :space_id, :string, 7
  required :organization_id, :string, 8

  def message_type_name
    {MessageType::OUT => 'STDOUT', MessageType::ERR => 'STDERR'}[message_type]
  end
end
