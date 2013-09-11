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

TEST_TIME = 1378936582 # 2013-09-11 15:56:22 -0600

def test_time
  Time.at(TEST_TIME).strftime("%b %d %H:%M:%S")
end