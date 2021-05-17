module Redismetrics
  module LocalRedisRefinement
    refine Redis do
      def ts_alter(key:, retention: nil, uncompressed: false, labels: [])
        cmd = ['TS.ALTER', key]
        cmd += ['RETENTION', retention] if retention
        cmd += ['UNCOMPRESSED'] if uncompressed
        cmd += ['LABELS'] if labels.any?
        cmd += labels if labels.any?
        _ts_call(cmd)
      end

      def _ts_call(args)
        # puts "CMD #{cmd.join(' ')}"
        synchronize do |client|
          res = client.call(args)
          raise res.first if res.is_a?(Array) && res.first.is_a?(Redis::CommandError)

          res
        end
      end
    end
  end
end
