require 'redismetrics/version'
require 'redismetrics/client'
require 'tins/xt'

module Redismetrics
  class << self
    def configure(&block)
      mutex.synchronize do
        unless @client
          block.nil? and raise ArgumentError,
            '&block returning Redis instance needed as argument'
          @client = Redismetrics::Client.new(redis: block.())
        end
      end
      self
    end

    def meter(&block)
      mutex.synchronize do
        block.(@client)
      end
    end

    private

    def mutex
      @mutex ||= Mutex.new
    end
  end

  def meter(&block)
    ::Redismetrics.meter(&block)
  end
end
