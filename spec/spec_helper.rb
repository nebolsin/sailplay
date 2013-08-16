require 'coveralls'
Coveralls.wear!

require 'rspec/autorun'
require 'webmock/rspec'

require 'sailplay'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  #config.before :suite do
  #  RestClient.log = $stdout
  #end

  config.before :each  do
    WebMock.disable_net_connect!
  end
end