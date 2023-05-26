require 'spec_helper'

describe Redismetrics::IRB do
  describe '.redismetrics' do
    it 'calls meter' do
      expect(Redismetrics).to receive(:meter)
      object = Object.new
      object.extend described_class
      object.redismetrics
    end
  end
end
