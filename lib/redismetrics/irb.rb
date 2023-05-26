module Redismetrics::IRB
  def redismetrics
    Redismetrics.meter { |rm| irb(rm) }
  end
end

class Object
  include Redismetrics::IRB
end
