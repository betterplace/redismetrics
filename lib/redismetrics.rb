require 'redismetrics/version'
require 'redismetrics/labels'
require 'redismetrics/client'
require 'redismetrics/irb'
require 'redismetrics/middleware/sidekiq'
require 'tins/xt'

module Redismetrics
  class << self
    def configure(&block)
      monitor.synchronize do
        unless @client
          block.nil? and raise ArgumentError,
            '&block returning Redis instance needed as argument'
          @config_block = block
          @client = Redismetrics::Client.new(redis: @config_block.())
        end
      end
      self
    end

    def warn_about(msg)
      if defined?(::Log)
        ::Log.warn(msg)
      else
        warn msg
      end
    end

    def meter(&block)
      monitor.synchronize do
        if @client
          if @client.alive?
            block.(@client)
          else
            # Attempt to reconnect once…
            @client = Redismetrics::Client.new(redis: @config_block.()) rescue nil
            if @client&.alive?
              block.(@client)
            else
              # before giving up:
              warn_about "Cannot reach redis timeseries server. => Skipping measurement."
              block.(NULL)
            end
          end
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

        client&.write(
          **({ value: duration, on_duplicate: 'MAX' } | write_options)
        )
      end
    end

    def count(**write_options, &block)
      meter do |client|
        block.(client)

        client&.write(
          **({ value: 1, on_duplicate: 'SUM' } | write_options)
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

  def count(**write_options, &block)
    ::Redismetrics.count(**write_options, &block)
  end
end
