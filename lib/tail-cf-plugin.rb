require 'cf'
require 'faye/websocket'
require 'eventmachine'

module TailCfPlugin
  require 'tail-cf-plugin/plugin'
  require 'tail-cf-plugin/loggregrator_client'
  require 'log_message/log_message.pb'
end
