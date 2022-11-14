module Redismetrics
  module Middleware
    class Sidekiq
      include Sidekiq::ServerMiddleware if defined? Sidekiq::ServerMiddleware

      class << self
        attr_accessor :prefix

        attr_accessor :retention

        def configure(options = {})
          if block_given?
            yield self
          else
            options.each do |key, val|
              self.send("#{key}=", val)
            end
          end
        end
      end

      self.prefix    = 'job'

      self.retention = 7 * 86_400

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
          key = '%s_%s' % [
            self.class.prefix,
            msg['class'].underscore.parameterize(separator: ?_),
          ]
          client.write(
            key:          key,
            value:        duration,
            on_duplicate: 'MAX',
            retention:    self.class.retention,
            labels: {
              module: 'sidekiq',
              type:   'job_duration',
              queue:  queue,
              failed: failed.to_s,
            }
          )
          client.write(
            key:          key,
            value:        duration,
            on_duplicate: 'SUM',
            retention:    self.class.retention,
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

