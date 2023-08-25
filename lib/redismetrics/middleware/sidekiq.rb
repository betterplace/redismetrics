module Redismetrics
  module Middleware
    class Sidekiq
      include Sidekiq::ServerMiddleware if defined? Sidekiq::ServerMiddleware

      def call(job_instance, msg, queue)
        start = Time.now
        failed = false
        yield
      rescue
        failed = true
        raise
      ensure
        duration = Time.now - start
        Redismetrics.meter do |client|
          klass = msg['wrapped'] || msg['class']
          prefix = '%s_%s' % [
            Redismetrics.config.sidekiq_prefix,
            klass.underscore.parameterize(separator: ?_),
          ]
          client.write(
            key:          prefix + "_duration_seconds",
            value:        duration,
            on_duplicate: 'MAX',
            labels: {
              module: 'sidekiq',
              type:   'job_duration',
              queue:  queue,
              failed: failed.to_s,
            }
          )
          client.write(
            key:          prefix + "_count",
            value:        duration,
            on_duplicate: 'SUM',
            labels: {
              module: 'sidekiq',
              type:   'job_count',
              queue:  queue,
              failed: failed.to_s,
            }
          )
        end
      end
    end
  end
end

