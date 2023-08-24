require 'tins/xt'

class Redismetrics::Config
  extend Tins::DSLAccessor

  def initialize(&block)
    block.nil? and raise ArgumentError,
      '&block required for configuration'
    instance_eval(&block)
  end

  dsl_accessor(:redis_client, -> { NULL })

  dsl_accessor(:reconnect_pause, 30)

  dsl_accessor(:default_retention, Float::INFINITY)
end
