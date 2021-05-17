if ENV['START_SIMPLECOV'].to_i == 1
  require 'simplecov'
  SimpleCov.start do
    add_filter "#{File.basename(File.dirname(__FILE__))}/"
  end
end
require 'rspec'
require 'rspec/collection_matchers'
begin
  require 'byebug'
rescue LoadError
end
require 'redismetrics'
