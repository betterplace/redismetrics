require 'redis'
require 'redistimeseries'
require 'redismetrics/local_redis_refinement'

using Redistimeseries::RedisRefinement
using Redismetrics::LocalRedisRefinement

class Redismetrics::Client
  MS = 1_000.0 # This constant is used to convert ruby floating point
               # timestamps in seconds into redis millsecond timestamps

  # Returns a Redismetrics::Client object using the Redis instance passed as
  # +redis+ which has to have the redistimeseries plugin enabled in order to
  # work.
  def initialize(redis:)
    @redis = redis
    check_connection
  end

  # Writes the value +value+ as a metric named +key+ using +retention+ in
  # seconds as a floating point value.
  def write(key:, value:, retention: 0.0)
    begin
      @redis.ts_create key: key, retention: (retention * MS).ceil
    rescue Redis::CommandError # assume it already exists
    end
    @redis.ts_add key: key, value: value
    self
  rescue Redis::CommandError => e
    # Catch all command errors and log them instead of crashing here when only
    # writng metrics.
    #
    # NOTE
    # They can happen due to timestamp collisions during high congestion
    # scenarios atm we need to be able to set DUPLICATE_POLICY for created
    # metric sequences in order to handle them accordingly for every case.
    msg = "Caught: #{e.class}: #{e}"
    if defined?(::Log)
      ::Log.warn(msg)
    else
      warn msg
    end
    self
  end

  # Return the retention time in seconds for the metric +key+.
  def retention(key:)
    duration = @redis.ts_info(key: key).each_slice(2).to_a.
      assoc('retentionTime')&.last
    if duration.zero?
      Float::INFINITY
    else
      duration / MS
    end
  end

  def retention!(key:, time:)
    @redis.ts_alter(key: key, retention: (time * MS).ceil) == "OK"
  end

  # Reads the range of entries from timestamp +from+ to timestamp +to+ (given
  # as Time objects) and return it as an enum consisting of Time and value
  # pairs. If a conversion method is defined as +convert+ apply it to the each
  # entry pair.
  def read(key:, from: nil, to: nil, convert: nil)
    range = @redis.ts_range(
      key:  key,
      from: from ? (from.to_f * MS).floor : ?-,
      to:   to ? (to.to_f * MS).ceil : ?+
    ).lazy.to_enum
    apply_conversion(convert, range)
  end

  # Returns true if metric +key+ exists,
  def exist?(key:)
    @redis.exists?(key)
  end
  alias exists? exist?

  # Destroys the metric +key+ returning true if it existed or false otherwise.
  def destroy(key:)
    @redis.del(key) == 1
  end

  # Returns the keys of the currently existing metrics.
  def keys
    @redis.keys
  end

  private

  # Checks the redis connection and raise an error if invalid.
  def check_connection
    @redis.ts_info key: Tins::Token.new(bits: 256)
  rescue Redis::CannotConnectError
    raise
  rescue Redis::CommandError => e
    unless e.message == 'ERR TSDB: the key does not exist'
      raise e.class, 'redis server has to be a redistimeseries server'
    end
  end

  # Applys the conversion method +convert+ by mapping the enum +enum+ in
  # various ways and returning another enum.
  def apply_conversion(convert, enum)
    case convert
    when Symbol
      enum.map { |t, v| [ Time.at(t / MS), v.send(convert) ] }
    when Proc
      case convert.arity
      when 1
        enum.map { |t, v| [ Time.at(t / MS), convert.(v) ] }
      when 2
        enum.map { |t, v| convert.(Time.at(t / MS), v) }
      else
        raise ArgumentError, 'convert arity has to be 1 or 2'
      end
    when nil
      enum.map { |t, v| [ Time.at(t / MS), v ] }
    else
      if c = convert.ask_and_send(:to_proc) and (1..2).include?(c.arity)
        apply_conversion(c, enum)
      else
        raise ArgumentError, 'convert has to be either symbol or proc'
      end
    end
  end
end
