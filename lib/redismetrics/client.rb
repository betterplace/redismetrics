require 'redis'
require 'redistimeseries'

using Redistimeseries::RedisRefinement

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
  def write(key:, value:, timestamp: nil, retention: Redismetrics.config.default_retention, labels: {}, on_duplicate: nil)
    retention    = interpret_retention(retention)
    labels       = Redismetrics::Labels.new(labels)
    labels[:key] = key
    timestamp = timestamp.nil? ? ?* : (timestamp.to_f * MS).round(0)
    @redis.ts_add key: key, value: value, timestamp: timestamp,
      retention: retention, labels: labels.to_a, on_duplicate: on_duplicate
    self
  rescue Redis::CommandError => e
    # Catch all command errors and log them instead of crashing here when only
    # writng metrics.
    #
    # NOTE
    # They can happen due to timestamp collisions during high congestion
    # scenarios atm we need to be able to set DUPLICATE_POLICY for created
    # metric sequences in order to handle them accordingly for every case.
    Redismetrics.warn_about "Caught: #{e.class}: #{e}"
    self
  end

  # Return the retention time in seconds for the metric +key+.
  def retention(key:)
    duration = retention_for_key(key).to_f
    if duration.zero?
      Float::INFINITY
    else
      duration / MS
    end
  end

  # Set the retention time for the metric +key+ to +time+ in seconds.
  def retention!(key:, time:)
    @redis.ts_alter(key: key, retention: (time * MS).ceil) == "OK"
  end

  # Return the labels metric +key+.
  def labels(key:)
    labels_for_key(key)
  end

  # Set the labels for the metric +key+ to +labels+.
  def labels!(key:, labels: {})
    labels       = Redismetrics::Labels.new(labels)
    labels[:key] = key
    @redis.ts_alter key: key, labels: labels.to_a
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

  def alive?
    @redis.ping == "PONG"
  rescue Redis::CannotConnectError
  end

  private

  def interpret_retention(retention)
    retention = Float(retention)
    if retention.infinite?
      0
    else
      (retention * MS).ceil
    end
  end

  def info_entry(key, info_entry_name)
    @redis.ts_info(key: key)&.each_slice(2)&.find { |name,|
      name == info_entry_name
    }&.last
  rescue
  end

  def retention_for_key(key)
    info_entry(key, 'retentionTime')
  end

  def labels_for_key(key)
    Redismetrics::Labels.new(Hash[Array(info_entry(key, 'labels'))])
  end

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
