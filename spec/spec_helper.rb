require 'bundler/setup'
Bundler.setup

Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].each { |f| require f unless f.end_with?('version.rb')}
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

require 'rspec/its'
RSpec.configure do |config|

end
