require 'redismetrics/version'
require 'redismetrics/labels'
require 'redismetrics/client'
require 'tins/xt'

module Redismetrics
  class << self
    def configure(&block)
      monitor.synchronize do
        unless @client
          block.nil? and raise ArgumentError,
            '&block returning Redis instance needed as argument'
          @client = Redismetrics::Client.new(redis: block.())
        end
      end
      self
    end

    def meter(&block)
      monitor.synchronize do
        if @client
          block.(@client)
        else
          block.(NULL)
        end
      end
    end

    def duration(**write_options, &block)
      meter do |client|
        start = Time.now

        block.(client)

        duration = (Time.now - start).to_f

        client.write(
          **({ value: duration } | write_options)
        )
      end
    end

    private

    def monitor
      @monitor ||= Monitor.new
    end
  end

  def meter(&block)
    ::Redismetrics.meter(&block)
  end

  def duration(**write_options, &block)
    ::Redismetrics.duration(**write_options, &block)
  end
end
