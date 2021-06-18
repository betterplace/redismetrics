class Redismetrics::Labels
  def initialize(spec = {})
   hash = Hash(spec)
   @spec = {}
   hash.each { |name, value| @spec[name.to_sym] = value.to_s }
  end

  def []=(name, value)
    @spec[name.to_sym] = value.to_s
  end

  def empty?
    @spec.empty?
  end

  def to_s
    @spec.inspect
  end

  alias inspect to_s

  def to_a
    @spec.to_a.sort_by(&:first)
  end

  def to_h
    @spec.to_hash
  end

  alias to_hash to_h

  def ==(other)
    to_a == other.to_a
  end
end
