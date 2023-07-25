begin
  require 'sidekiq/api'
rescue LoadError
end

class Redismetrics::Plugins::SidekiqMonitor
  include Redismetrics

  def initialize(redis_url:, redis_ts_url:, retention: 7 * 86_400)
    @redis_url = redis_url
    @retention = retention.to_f
    Sidekiq.configure_client do |config|
      config.redis = { url: redis_url }
    end
    Redismetrics.configure { Redis.new(url: redis_ts_url) }
  end

  def perform
    meter do |client|
      queues.each do |queue|
        client.write(
          key:          "sidekiq_size_#{queue.name.gsub(/\W/, '_')}",
          value:        queue.size,
          retention:    @retention,
          on_duplicate: 'LAST',
          labels:       { module: 'sidekiq', type: 'size' },
        )
        client.write(
          key:          "sidekiq_latency_#{queue.name.gsub(/\W/, '_')}",
          value:        queue.latency,
          retention:    @retention,
          on_duplicate: 'LAST',
          labels:       { module: 'sidekiq', type: 'latency' },
        )
        client.write(
          key:          "sidekiq_workers_#{queue.name.gsub(/\W/, '_')}",
          value:        workers(queue),
          retention:    @retention,
          on_duplicate: 'LAST',
          labels:       { module: 'sidekiq', type: 'workers' },
        )
      end
    end
    self
  end

  private

  def queues
    Sidekiq::Queue.all.reject { |q| q.name.start_with?('sidekiq_alive-') }
  end

  def processes
    Sidekiq::ProcessSet.new
  end

  def workers(queue)
    if process = processes.find { |pro| pro['queues'].include?(queue.name) } rescue nil
      process['concurrency'].to_i
    else
      -1
    end
  end
end