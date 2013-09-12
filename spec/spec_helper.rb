require 'rspec'

require 'logs-cf-plugin/plugin'
require 'support/fake_loggregator'
require 'thin'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end

TEST_TIME = 1379025677549451000 # Sep 12 16:41:17.549451 -0600

def test_time
  Time.at(TEST_TIME/1000000000.0).strftime("%b %d %H:%M:%S.%3N")
end